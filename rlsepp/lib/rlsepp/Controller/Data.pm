package rlsepp::Controller::Data;

use base 'rlsepp::DBcommon';
#use Mojo::Base 'rlsepp::DBCommon';
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;
use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper;
use Hash::Merge qw/merge/;
use Mojolicious::Sessions;

# Render the template "index.html.ep"

use rlsepp::Auth;

sub wsSession {
  my $s = shift;
  $s->app->log->debug("ws://data:wsSession");

  # Increase inactivity timeout for connection a bit (what was it?)
  $s->inactivity_timeout(300);

  $s->on( json => sub {
      my ($ws, $data) = @_;
      
      my $json = {};
      try {
        my $sid = undef;
        my $session = {};

        if (exists $data->{sid}) {
          $sid = $data->{sid};
          delete $data->{sid};
          $session = $s->retrieveSessionDb($sid);
        }
       
        #  if data passed in sans sid contains keys
        #
        my $count = 0;
        foreach my $key (keys %$data) {
          if (exists $data->{$key}  && defined $data->{$key}) {
            $count++;
          }
        }

        #
        if ($count > 0) {
#          $session = merge($session, $data);
          foreach my $k (keys %$data) {
            $session->{$k} = $data->{$k};
          }

          #  handshake is as follows
          #
          #  index has sign in buttons which will result in populating
          #     useremail along side SSO provider specific session variables
          #  this is the initial insert not having an sid
          #
          #  all subsequent calls to this function will either be a session read request
          #  or a store request having said sid in data->sid which will then contain ssoid & roles
          #
          #  placed here to handle the SSO handoff ^_^
          #
          if (not exists $session->{ssoid}) {
            $session->{ssoid} = $s->getUserID($session);
          }
          if (not exists $session->{roles}) {
            $session->{roles} = $s->userRoles($session->{useremail});
          }
        }

        #  or if existing session is missing ssoid generated from 
        #  DBCommon::getUserID (rlsepp.useraccesscontrol.googlesso)
        #  or the users roles
        #

        #  then perform a store 
        #
        if ($count > 0) {
          $s->app->log->debug("session: sid [$sid] is:\n".dumper($session));
          $sid = $s->storeSessionDb($session, $sid);
        }

      $s->app->log->debug('data::wsSession->store returned sid '.$sid);

      # if no retrieval was done, $session should have passed data from merge plus ssoid & roles
      #
      $json = $session;
      $json->{sid} = $sid;

      } catch {
        if ($_) {
          $s->app->log->error($_);
        }
      };

      $ws->send({json => $json});

      });

  # Incoming message
  $s->on(message => sub ($s, $msg) {
    $s->app->log->debug("data:wsSession on message [$msg]");
  });

  # Closed
  $s->on(finish => sub ($s, $code, $reason = undef) {
    $s->app->log->debug("WebSocket closed with s[$s]code [$code] reason[$reason]");
  });
}

sub view {
  my $s = shift;
  my ($dbh, $sth, $rs, %opt, @headers, @data) = ($s->dbh, (undef) x 2, (), (), ());

  my $ssoid = $s->session('ssoid');
  $s->app->log->debug('ssoid '.$ssoid);

  $s->redirect_to('/') if (not defined $s->session('sid'));
  my $sid = $s->session('sid');
  my $dbSession = $s->retrieveSessionDb($sid);

  my $view = $s->stash('view');
  my $schema = $s->stash('schema');
  my $format = $s->stash('format');
  $s->stash(ssoid => $ssoid);
  $s->app->log->debug("Data::View schema [$schema] view [$view] format [$format] ssoid [$ssoid]");

  $s->stash(url => $s->url_for('/data/store')->to_abs->scheme('wss'));
  #$s->stash(socket => $s->url_for('/data/store')->to_abs->scheme('ws')->port('2324'));
  $s->stash(socket => 'wss://min_max_order_notify.grandstreet.group:2324'); #mode
  $s->stash(mode => $s->app->mode);
	$s->session(views => $s->schemaviews);

  #authenticated user is logged in
  $s->stash(roles => $s->session('roles'));


#  my @names = $s->param;
#my $foo = $c->req->param('foo');
  $s->app->log->debug( 'server side, req query -> ajax javascript variables ***** '.$s->req->url->query );
#  foreach (@names) {
#    $s->app->log->debug( $_ . " => " . $s->param($_) );
#  }
#
#  parse request params
#
  if ( defined $s->param('iDisplayLength') ) {
    $opt{rows} = $s->param('iDisplayLength');
    $opt{page} =
      ( $s->param('iDisplayStart') / $s->param('iDisplayLength') ) + 1;
  }

  # search
  if (defined $s->param('sSearch') and length $s->param('sSearch') > 2) {
    $opt{search} = $s->param('sSearch');
    $s->stash(search => $opt{search});
  }

  if (exists $prefs->{sortorder}) {
  $s->app->log->debug( "prefs sortorder" );
    my @o = split(/,/, $prefs->{sortorder});
    $opt{order_by} = \@o;
  }
  $s->app->log->debug('user prefs from dB :'.dumper(\$prefs));


  if (defined $s->param('iSortingCols')) {
  my $c = $dbSession->{'colOrder'};
  my @c = ();
  if (defined $c) {
    @c = @$c;
  } else {
    my $i = -1;
    @c = map { $i++ } @$fields;
  }
  my $out = join(",",@c);
  $s->app->log->debug( "iSortingCols, colOrder:[$out]" );
    my $n = $s->param('iSortingCols');
    my @orderBy;
    my @fields =  @{ $dbSession->{'fields'} };
  $s->app->log->debug( "fields[".join(',', @fields)."]" );
    for (my $i = 0; $i < $n; $i++) {
      my $h = $s->param('iSortCol_'.$i);
  $s->app->log->debug( "$h" );
      my $dir = $s->param('sSortDir_'.$i);
     if (length $fields[$c[$h]]) { 
       push @orderBy, $fields[$c[$h]]. " $dir";
     }
    }
    if ($#orderBy > -1) {
      $opt{order_by} = \@orderBy;
      $s->session(order_by => \@orderBy);
    }
  }

#TODO check list of views agains schema.view before running
  #
  #my @calls = @{ $s->listCalls() };

  my $prefs = $s->getPrefs($schema,$view,$ssoid);
  my $fields = '*';
  @headers = @{$s->schemaviewForColumns("$schema.$view")};
  my %visible = ();
  if (exists $prefs->{fields}) {
#    $fields = $prefs->{fields};
#    @headers = split(/, /,$prefs->{fields});
    my @h = split(/, /,$prefs->{fields});
    foreach my $f (@h) {
     $visible{$f} = 1;
    }
  }
  $s->stash(visible => \%visible);


  $s->session(headers => \@headers);
  $s->stash(headers => \@headers);
  $s->session(fields => \@headers);
  $s->stash(fields => \@headers);

  $s->stash(order_by => $s->session('order_by'));

  my $json = {};
  my ($limit, $offset) = ($opt{'rows'} + 1, 0);
  if ( exists $opt{page} ) {
    $offset = $opt{'page'} - 1;
  }

  my $where = '';
	
	#TODO: guard from SQL injection
  if (exists $opt{search}) {
    $where = ' where '.$opt{search};
  }

  my $sql = "select count(*) as count from $schema.$view $where;";
  $s->app->log->debug( $sql );
  $sth = $dbh->prepare($sql);
	$sth->execute();
	$rs = $sth->fetchall_arrayref();
	$rowcount = $rs->[0]->[0];
	
  #  Ajax call with DataTables params
  #
  #  search will also .json
  #
  my $o = '';
  my $l = '';
    $s->app->log->debug('session fields ['.join(',',@fields).']');
  if (exists $opt{'order_by'}) {
    $o = "order by ". join(", ", @{$opt{'order_by'}});
    $s->app->log->debug("order by opt $o");
  }
  if (exists $opt{'page'} or exists $opt{'rows'}) {
    $l = "limit $limit offset $offset";
  } else {
    $l = "limit 1000";
  }
  if ($format eq 'json') {
    $s->app->log->debug('Data::view json request');
    $s->session(order_by => $opt{'order_by'});

    $fields = '*' unless length $fields > 0;
    my @g = grep { !/transaction_tag/} @headers;
    my $group = 'group by transaction_tag,'.join(', ',@g);
    my @sql = ("select $fields from $schema.$view",
        $where, $group, $o, $l, ";"
        );
    $sql = join(' ', @sql);
  $s->app->log->debug( $sql );

    $sth = $dbh->prepare($sql);
    $sth->execute();
    $rs = $sth->fetchall_arrayref({});

    my @data = ();
    foreach my $row (@$rs) {
      push @data, $row;
    }


  $s->app->log->debug( 'returning' );
    $json = {
#        sEcho         => 1,
        iTotalRecords => $rowcount,
        iTotalDisplayRecords => $rowcount,
        aaData => \@data,
      };
  }

#  $s->stash(useremail => $s->session('_useremail'));
#  $s->render(status => 200, text => $s->session('_useremail'));
  $s->respond_to(
#    html => { template => 'data/ajax' },
    html => { template => "data/$schema$view" },
    json => {
      json => $json,
      status => 200
    }
  );
}

sub wsStore {
  my $s = shift;
  my $format = $s->stash('format');
  $s->app->log->debug("ws://Data:wsStore format $format");

  # Increase inactivity timeout for connection a bit (what was it?)
  $s->inactivity_timeout(300);

  $s->on( json => sub {
      my ($ws, $data) = @_;
      
      $s->app->log->debug('Data::wsStore->'.dumper(\$data));
      my $err = 'sahksess';
      try {
        $s->saveUIPrefs($data);
      } catch {
        if ($_) {
          $err = $_;
        }
      };
      $ws->send({json => {status => "insert status: $err"}});

      });

  # Incoming message
#  $s->on(message => sub ($s, $msg) {
#    $s->app->log->debug("on message $msg");
#    $s->send("echo: $msg");
#  });

  # Closed
  $s->on(finish => sub ($s, $code, $reason = undef) {
    $s->app->log->debug("WebSocket closed with s[$s]code [$code] reason[$reason]");
  });
}

sub store {
  my $s = shift;
  my $view = $s->stash('view');
  my $schema = $s->stash('schema');
  $s->stash(ssoid => $s->session('ssoid'));
  $s->app->log->debug("Data:Store schema $schema view $view");

  my $json = {
    };
  $s->render(status => 200, ,json => $json);
}

sub dump {
  my $s = shift;
  $s->app->log->debug( ' req query  '.$s->req->url->query );
  my $view = $s->stash('view');
  my $schema = $s->stash('schema');
  $s->app->log->debug("Data::Dump schema $schema view $view");

  $s->stash(mode => $s->app->mode);
  $s->stash(procs => $s->getProcs());


  #authenticated user is logged in
  $s->stash(ssoid => $s->session('ssoid'));
  $s->stash(roles => $s->session('roles'));


  my @names = $s->param;
  foreach (@names) {
    $s->app->log->debug( $_ . " => " . $s->param($_) );
  }

#TODO check list of views agains schema.view before running
  #
  #my @calls = @{ $s->listCalls() };

  my ($dbh, $sth, $rs, %opt, @headers, @data) = ($s->dbh, (undef) x 2, (), (), ());
  @headers = qw/date transaction_tag moves/;
  $s->stash(headers => \@headers);


  my ($limit, $offset) = (25, 0);
  my $sql = "select * from $schema.$view limit $limit offset $offset;";
  $sth = $dbh->prepare($sql);
  $sth->execute();
  $rs = $sth->fetchall_arrayref({});
 
  my @data = ();
  foreach my $row (@$rs) {
    push @data, $row;
  }
  $s->app->log->debug(dumper(\@data));

  my $json = {
#        sEcho         => 1,
    iTotalRecords => $#{$rs},
    iTotalDisplayRecords => $#{$rs},
    aaData => \@data,
  };
#  $s->app->log->debug(dumper(\$rs));

  $s->render(status => 200, html => { dumper(\@data) },json => $json);
}

sub test {
  my $s = shift;
  $s->render(status => 200, json => { ip => $s->app->ip_address }); 
}

sub debug {
  my $s = shift;
  $s->render(status => 200, json => $s->session ); 
}

1;
