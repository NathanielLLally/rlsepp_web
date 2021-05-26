package rlsepp::Controller::Main;

use lib '/home/nathaniel/src/git/rlsepp_web/rlsepp/lib';
use lib '/home/nathaniel/src/git/rlsepp_web/rlsepp/lib/rlsepp';
#use lib '../../';
use base 'rlsepp::DBcommon';
#use Mojo::Base 'rlsepp::DBCommon';
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;
use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper;
use Mojolicious::Sessions;
use rlsepp::Controller::Ajax;

# Render the template "index.html.ep"

use rlsepp::Auth;

sub index {
  my $s = shift;
  $s->app->log->info("index");
#  $s->res->headers->cache_control('max-age=1, no-cache');

  # TODO: hypnotoad
  $s->stash(mode => $s->app->mode);

  $s->app->log->debug("Service Mode (hypnotoad c->app->mode?): ".$s->app->mode);
  $s->render; 
}

sub brochure {
  my $s = shift;

#  if (not $s->session('guseremail')) {
#    $s->redirect_to('/');
#    return;
#  }

#  $s->res->headers->cache_control('max-age=1, no-cache');

  $s->stash(mode => $s->app->mode);
  my ($guserid, $guseremail, $gusername, $guserimageurl) = 
    ($s->session('guserid'), $s->session('guseremail'), $s->session('gusername'), $s->session('guserimageurl'));

  #/index googleAuthWeb -> Cookie::js_sesh
  #this Cookie::js_sesh -> Mojolicious::Session::DOM -> session

  #  getUserID -> dB.useraccesscontrol.sso
  #
  $s->session(ssoid => $s->getUserID({guseremail => $guseremail, guserid => $guserid, gusername => $gusername, guserimageurl =>$guserimageurl}));
  $s->app->log->debug("$guserid, $guseremail, $gusername, $guserimageurl");

  my $roles = $s->userRoles($guseremail);
  $s->session(roles => $roles);
  $s->app->log->debug(dumper($roles));
#  $sesh->store;

#  my @jar = $s->res->cookies;
#  $s->app->log->info( encode_json(\@jar));
  $s->render;
}

sub portal {
  my $s = shift;

  $s->stash(mode => $s->app->mode);
	$s->session(views => $s->schemaviews);
  $s->app->log->debug("views:".dumper($s->stash('views')));
  $s->app->log->debug("sessoid:".$s->session('ssoid'));
  $s->app->log->debug("session useremail:".$s->session('useremail'));

  #$s->res->headers->cache_control('max-age=1, no-cache');

  if (not $s->session('ssoid')) {
    $s->redirect_to('/');
    return;
  }

#  my $tables = $s->getTables();
#  $s->stash(tables => $tables);
  $s->stash(procs => $s->getProcs());
#  $dbh->selectall_hashref($statement, $key_field);

  #authenticated user is logged in
  $s->stash(ssoid => $s->session('ssoid'));
  $s->stash(roles => $s->session('roles'));

  $s->app->log->debug("stash userid:".$s->stash('userid'));
#  $s->stash(useremail => $s->session('_useremail'));
#  $s->render(status => 200, text => $s->session('_useremail'));
  $s->render;
}

#  $s->render(status => 200, json => { 
###      yo => $s->session('yo'),
#      _yo => $s->session('_yo'),
#      uid => $s->session('_guserid'),
#      }); 
#}

sub test {
  my $s = shift;
  $s->render(status => 200, json => { ip => $s->app->ip_address }); 
}

sub debug {
  my $s = shift;
  $s->render(status => 200, json => $s->session ); 
}


sub status 
{
  my $s = shift;
  my $count = 0;

  my @servers;
  foreach my $server (values %{$s->app->running_servers}) {
    if (not $server->status) {
      delete $s->app->running_servers->{$server->port};
    } else {
      $count++;
      push @servers, $server->stats;
    }
  }
  $s->render(status => 200, json => {
      base_port => $s->app->base_port,
      max_servers => $s->app->max_servers,
      count => $count,
      status => \@servers,
      } );
}

1;
