package rlsepp::Controller::Data;

use lib '/home/nathaniel/src/git/rlsepp_web/rlsepp/lib';
use lib '/home/nathaniel/src/git/rlsepp_web/rlsepp/lib/rlsepp';
use lib '../../';
use base 'rlsepp::DBcommon';
#use Mojo::Base 'rlsepp::DBCommon';
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;
use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper;
use Mojolicious::Sessions;

# Render the template "index.html.ep"

use rlsepp::Auth;

sub view {
  my $s = shift;
  my ($dbh, $sth, $rs, %opt, @headers, @data) = ($s->dbh, (undef) x 2, (), (), ());

  my $view = $s->stash('view');
  my $schema = $s->stash('schema');
  my $format = $s->stash('format');
  $s->app->log->debug("Data::View schema $schema view $view format $format");

  $s->stash(mode => $s->app->mode);
	$s->session(views => $s->schemaviews);
#	$s->session(rowcounts => $s->SVrowcounts);
  $s->app->log->debug("views:".dumper($s->stash('views')));
  $s->app->log->debug("views:".dumper($s->stash('rowcounts')));
#	$s->stash(views => $s->views() );
  

  #authenticated user is logged in
  $s->stash(ssoid => $s->session('ssoid'));
  $s->stash(roles => $s->session('roles'));


  my @names = $s->param;
  $s->app->log->debug( "params" );
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
      push @orderBy, $fields[$h]. " $dir";
    }
    $s->app->log->debug(dumper \@orderBy);
    $opt{order_by} = \@orderBy;
  }

#TODO check list of views agains schema.view before running
  #
  #my @calls = @{ $s->listCalls() };

  @headers = qw/date transaction_tag moves/;
  $s->session(headers => \@headers);
  $s->stash(headers => \@headers);
  $s->session(fields => \@headers);
  $s->stash(fields => \@headers);


  my $json = {};


  my ($limit, $offset) = ($opt{'rows'} + 1, 0);
  if ( exists $opt{page} ) {
    $offset = $opt{'page'} - 1;
  }

  my $sql = "select count(*) as count from $schema.$view;";
  $sth = $dbh->prepare($sql);
	$sth->execute();
	$rs = $sth->fetchall_arrayref();
	$rowcount = $rs->[0]->[0];
	

  #  Ajax call with DataTables params
  #
  if ($format eq 'json') {
    my @sql = ("select * from $schema.$view",
        "order by " . join(", ", @{$opt{'order_by'}}),
        "limit $limit offset $offset",
        ";"
        );
#    $s->app->log->debug(dumper(\$opt));
    $sql = join(' ', @sql);
  $sth = $dbh->prepare($sql);
  $sth->execute();
  $rs = $sth->fetchall_arrayref({});

  my @data = ();
  foreach my $row (@$rs) {
    push @data, $row;
  }
#  $s->app->log->debug(dumper(\@data));

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
    html => { template => 'main/ajax' },
    json => {
      json => $json,
      status => 200
    }
  );
}

sub dump {
  my $s = shift;
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
