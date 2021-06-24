package rlsepp::Controller::Store;
use rlsepp::DBcommon;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::JSON;
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;
use URI::Escape;
use URI;
use DateTime;
use DBI;
use Try::Tiny;
use DateTime::Format::DateManip;
use Date::Manip;
use Data::Dumper;

use base 'rlsepp::DBcommon';

sub storeDataC
{
  my ($s, $ae) = @_;
  my ($server, $time, $playerID, $daysOld) = 
    map { $ae->{$_}; } qw/server time playerID daysOld/;

  my $dbh = $s->dbh($server);
  my $schema = $s->schema;
  my $dtServer = DateTime::Format::DateManip->parse_datetime(ParseDate($time));

  my $guildTag = '';
  my $dbPlayer = $schema->resultset('Player')->find($playerID);
  if (defined $dbPlayer) {
    $guildTag = $dbPlayer->guildTag;
  }

  if (defined $daysOld) {
    my $dtData = $dtServer->clone->subtract(days => $daysOld);
    $time = $dtData->strftime("%Y-%m-%d %H:%M:%S");
  #  die ("data is $daysOld days old");
  }

  if (exists $ae->{player}) {
    foreach my $id (keys %{$ae->{player}}) {
      my $e = $ae->{player}->{$id};
      my $guild = $e->{guild};
      $schema->resultset('Player')->update_or_create({
        id => $id,
        name => $e->{name},
        level => $e->{level},
        upgraded => $e->{upgraded},
        guildTag => $guild->{tag} || '',
        defaultServer => $server,
        });
    }
  }

  #  parsing of a recently downloaded galaxy map
  #
  if (exists $ae->{regionStars}) {
    my $sth = $dbh->prepare(qq/
      insert into regionStars (starLoc) values (?)
      /);

    foreach my $starLoc (@{ $ae->{regionStars} }) 
    {
      try {
        $sth->execute($starLoc);
      } catch {
        if ($_ !~ /Duplicate entry/) {
          die "regionStars insert: $_";
        }
      };
    }
  }

  #  if there is an astro with no base,
  #    somebody disbanded
  #
  my %baseRemoval = ();
  if (exists $ae->{astro}) {
    foreach my $location (keys %{$ae->{astro}}) {
      my $e = $ae->{astro}->{$location};

      my %col = map { $_ => $e->{$_} } qw/terrain type/;
      $col{location} = $location,
      $col{time} = $time;
      $col{guildTag} = $guildTag;

      $baseRemoval{$location}++;
      
      my $dbAstro = $schema->resultset('Astro')->update_or_create(%col);
    }

    if (defined $dbPlayer) {
      $schema->resultset('PlayerUsage')->update_or_create(
          {id => $dbPlayer->id, name => 'astroScan', last => $time});
    }
  }

###############################################################################
  return if (defined $daysOld);
###############################################################################

  if (exists $ae->{base}) {
    foreach my $id (keys %{$ae->{base}}) {
      my $e = $ae->{base}->{$id};
      my %col = map { $_ => $e->{$_} } qw/location owner occupier/;
      $col{id} = $id;
      $col{time} = $time;
      $col{guildTag} = $guildTag;

      my $dbBase =  $schema->resultset('Base')->update_or_create(%col);

      delete $baseRemoval{$col{location}};

      #  possibly not in packet
      #
      %col = map { $_ => $e->{$_} } 
        grep {exists $e->{$_}} qw/name economy ownerIncome tradeRoutes/;

      if (keys %col) {
        $col{id} = $id;
        $col{time} = $time;
        $col{guildTag} = $guildTag;
        my $dbBaseDetail =  $schema->resultset('BaseDetail')->update_or_create(%col);
      }

      if (exists $e->{structures}) {
        my $e = $e->{structures};
        foreach (keys %$e) {
          %col = (
            id => $id,
            name => $_,
            number => $e->{$_},
            time => $time,
            guildTag => $guildTag,
            );
#          $dbBase->update_or_create_related('baseStructures', %col);
          my $rsBS =  $schema->resultset('BaseStructures')->update_or_create(%col);
        }

        if (defined $dbPlayer) {
          $schema->resultset('PlayerUsage')->update_or_create(
              {id => $dbPlayer->id, name => 'baseScan', last => $time});
        }
      }
    }
  }

  foreach my $loc (keys %baseRemoval) {
    my @rs = $schema->resultset('Base')->search({
      guildTag => $guildTag,
      location => $loc
    })->all;
    if ($#rs >= 0) {
#  multiple entries from multiple reporters
      $s->app->log->debug('removing orphan base '.$loc. " ".$#rs);
      $rs[0]->delete;

    } else {
      $s->app->log->debug('no orphans at '.$loc);
    }
  }

  if (exists $ae->{fleet}) {

# parseMapFleet is going to parse every fleet in a location
#   so we can use that to keep the ghosts down
#
    my %location;
    foreach my $id (keys %{$ae->{fleet}}) {
      my $e = $ae->{fleet}->{$id};
      if (not exists $e->{ships}) {
        $location{$e->{location}}++;
      }
    }
    if (keys %location == 1) {
      my @loc = keys %location;
      $schema->resultset('Fleet')->search({location => $loc[0]})->delete;
    }

    foreach my $id (keys %{$ae->{fleet}}) {
      my $e = $ae->{fleet}->{$id};
      my ($dbFleet, %col);
# add the new fleets
#
      %col = map { $_ => $e->{$_} }
        grep { exists($e->{$_}) } qw/name owner size origin location/;

      if (exists $e->{arrival}) {
        my $dtArrival = $dtServer->clone->add(seconds => $e->{arrival});
        $col{arrival} = $dtArrival->strftime("%Y-%m-%d %H:%M:%S");
      }
      $col{id} = $id;
      $col{time} = $time;
      $col{guildTag} = $guildTag;
      $dbFleet = $schema->resultset('Fleet')->update_or_create(%col);
# with details
#     
      $e = $e->{ships};
      if (defined $e) {
        foreach (keys %$e) {
          %col = (
            id => $id,
            name => $_,
            number => $e->{$_},
            time => $time,
            guildTag => $guildTag,
            );
          $schema->resultset('FleetShips')->update_or_create(%col);
#          $dbFleet->update_or_create_related('ships', %col);
        }
        if (defined $dbPlayer) {
          $schema->resultset('PlayerUsage')->update_or_create(
              {id => $dbPlayer->id, name => 'fleetScan', last => $time});
        }
      }
    }
  }
}


sub dumpPost {
  my $s = shift;

  $s->app->log->debug($s->req->body);

  my $json = Mojo::JSON->new;
  my $aeData = $json->decode( $s->req->body );
  my $err  = $json->error;

  if ($json->error) {
    $s->stash(json => { error => $json->error });
    $s->render(status => 400);
  } else {
    my ($server, $time, $playerID, $daysOld) = map { $aeData->{$_}; } qw/server time playerID daysOld/;

    my $schema = $s->schema($server);
    if (defined $schema) {
      my $rs = $schema->resultset('Player')->find($playerID);
      if ($rs != 0) {
        my $reqIP = $s->req->headers->header('x-real-ip');
        $s->app->log->debug(sprintf("%s %s(%u) %s", $rs->guildTag, $rs->name, $playerID, $reqIP));
        my $rsPU = $schema->resultset('PlayerUsage')->find_or_create( 
            {name => $reqIP, id => $playerID });
        $rsPU->update({ last => $time });

      }

    }

    try {
      $s->storeDataC($aeData);
      $s->app->log->debug("storeData2 succeeded");
      $s->stash(json => { response => 'success' });
      $s->render(status => 200);
    } catch{
      $s->app->log->debug("norm error: $_");
      if ($_ =~ /^(.*?)at \//) {
        $s->stash(json => {response => $1 });
      }
      $s->render(status => 500);
    };

  }
}

sub log {
  my $s = shift;

  $s->app->log->debug($s->req->body);

  my $json = Mojo::JSON->new;
  my $data = $json->decode( $s->req->body );
  my $err  = $json->error;

  if ($json->error) {
    $s->stash(json => { error => $json->error });
    $s->render(status => 400);
  } else {
    my ($server, $time, $playerID, $daysOld) = map { $data->{$_}; } qw/server time playerID daysOld/;

    my %ctx = map { $_ => $data->{$_} } grep { /time|playerID|line/ }keys %$data;

    my $schema = $s->schema($server);

    try {
      $schema->resultset('Log')->create(\%ctx);

      $s->stash(json => { response => 'success' });
      $s->render(status => 200);
    } catch{
      $s->app->log->debug("norm error: $_");
      if ($_ =~ /^(.*?)at \//) {
        $s->stash(json => {response => $1 });
      }
      $s->render(status => 500);
    };

  }
}

1;
