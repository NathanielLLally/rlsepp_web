package rlsepp::Controller::Ajax;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;
use URI::Escape;
use URI;
use Try::Tiny;
use Moose;
use MooseX::Params::Validate;
#use rlsepp::Controller::Ajax::DBIx;

use base 'rlsepp::DBcommon';

#  dB field to display name fixup
#
has 'shortFieldName' => (
  isa => 'HashRef',
  is => 'ro',
  default => sub {
 {
  starLoc           => 'system',
  lastScan          => 'last scan',
  guildTag          => 'tag',
  ownerTag          => 'tag',
  occupier          => 'occ',
  occupierTag       => 'tag',
  economy           => 'econ',
  ownerIncome       => 'inc %',
  tradeRoutes       => 'trades',
  jumpGate          => 'jg',
  commandCenters    => 'cc',
  barracks          => 'b',
  laserTurrets      => 'lt',
  missileTurrets    => 'mt',
  ionTurrets        => 'it',
  photonTurrets     => 'pt',
  disruptorTurrets  => 'dt',
  deflectionShields => 'ds',
  planetaryShields  => 'ps',
  planetaryRing     => 'pr',
};
  });

#
#
sub listCalls {
  my ($s, $obj) = @_;
  my @calls;
  push @calls, 'DBI->pgsql->( do select * from view';
  return \@calls;
}

sub dbic {
  my $s = shift;
  if ( not $s->session('playerID') ) {
    $s->redirect_to('/ae');
    return;
  }
  $s->schema($s->session('server'));
#  $AeWeb::Schema::Result::ServerURL = $s->session('server') . '.astroempires.com';

  my ($rs, @headers, @data, %opt) = (undef, (), (), ());
  my $proc = $s->stash('proc');
  $proc =~ s/.*\///;
  $s->app->log->debug(
    sprintf(
      "ajax response for %s [%s:%s]",
      $proc,
#      $s->session('server'),
#      $s->session('playerID')
    )
  );

  my @names = $s->param;
  foreach (@names) {
    $s->app->log->debug( $_ . " => " . $s->param($_) );
  }

  if ( defined $s->param('iDisplayLength') ) {
    $opt{rows} = $s->param('iDisplayLength');
    $opt{page} =
      ( $s->param('iDisplayStart') / $s->param('iDisplayLength') ) + 1;
    $s->app->log->debug( 'rows ' . $opt{rows} );
    $s->app->log->debug( 'page ' . $opt{page} );
  }

  if (defined $s->param('iSortingCols')) {
    my $n = $s->param('iSortingCols');
    my @orderBy;
    my @fields =  @{ $s->session('fields') };
    for (my $i = 0; $i < $n; $i++) {
      my $h = $s->param('iSortCol_'.$i);
      my $dir = $s->param('sSortDir_'.$i);

      $s->app->log->debug(sprintf("n %s i %s h %s dir %s",$n, $i, $h, $dir));
      push @orderBy, { '-'.$dir => $fields[$h] };
    }
    $s->app->log->debug(dumper \@orderBy);
    $opt{order_by} = \@orderBy;
  }

#  my $obj = new rlsepp::Controller::Ajax::DBIx;
  my @calls = @{ $s->listCalls() };
#  foreach (@calls) { $s->app->log->debug( $_ ); }

  if (grep { $_ eq $proc} @calls) {
#    no strict 'refs';

#    my $name = sprintf("%s::%s", ref($call), $proc);
#    my $dispatch = *{$name};
    $s->app->log->debug( 'calling proc '.$proc );
  }

#  $rs = $dispatch->($s, { searchOptions => \%opt });
#  $rs = $s->Test({ searchOptions => \%opt });

  my $json = {};

  
  if ( $rs != 0 ) {
    my $row;
#
#  json request performed by DataTable.js
#
    if ( exists $opt{page} ) {

      $rs = $rs->search(undef, \%opt);

#      my $view = $rs->display;
      if (1) {
        my $view = $rs->display;
        $s->app->log->debug(dumper $view);
      }

      @headers = @{ $s->session('headers') };
      #  fropm DBIX to Ajax format
      #
      foreach my $row ($rs->page($opt{page})->all) {
        my %inflated = $row->get_inflated_columns;

        #  idk why inflation would overwrite a value..
        #
        while (my ($k, $v) = each %inflated) {
          if (!defined $v) {
            $inflated{$k} = $row->get_column($k);
          }
        }
        push @data, [ map { $inflated{$_} } @headers ];
      }

#  html request that sets up DataTabe.js with headers
#
    } else {
      $row = $rs->next;
      my %cols = $row->get_columns;

      #$s->app->log->debug(dumper $rs->result_source->columns);

      #  according to DBIx ppl, this is subject to change and is 
      #  currently being worked on
      #
      @headers = @{ $rs->_resolved_attrs->{as} };
      my @fields = @{ $rs->_resolved_attrs->{select} };
#      $s->app->log->debug( dumper( \$rs->_resolved_attrs->{select} ) );
#  merge the query results from table types
#
#      @headers = grep { exists $cols{$_} } $rs->result_source->columns;
#      @headers = keys %cols;
      if (defined $s->param('dumpHeaders')) {
          $s->app->log->debug( dumper( \@headers ) );
          $s->app->log->debug( dumper( \@fields ) );
      }
      $s->session( headers => \@headers, );
      $s->session( fields => \@fields, );

    }

#    $s->app->log->debug( dumper( \@data ) );
     $json = {
#        sEcho         => 1,
        iTotalRecords => ( $rs->is_paged ) ? $rs->pager->total_entries
        : $rs->count,
        iTotalDisplayRecords => ( $rs->is_paged ) ? $rs->pager->total_entries
        : $rs->count,
        aaData => \@data
      };
  }

  $s->respond_to(
    html => { template => 'main/ajax' },
    json => {
      json => $json,
      status => 200
    }
  );
}

1;
