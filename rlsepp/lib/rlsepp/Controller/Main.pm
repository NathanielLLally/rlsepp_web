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

# Render the template "index.html.ep"

use rlsepp::Auth;

sub wsSession {
  my $s = shift;
  $s->app->log->debug("ws://main:wsSession");

  # Increase inactivity timeout for connection a bit (what was it?)
  $s->inactivity_timeout(300);

  $s->on( json => sub {
      my ($ws, $data) = @_;
      
      $s->app->log->debug('main::wsSession->'.dumper(\$data));
      my %json = ();
      try {
        my $sid = $s->storeSessionDb($data);
      $s->app->log->debug('main::wsSession->store returned sid '.$sid);

        $json{sid} = $sid;
      } catch {
        if ($_) {
          $s->app->log->error($_);
        }
      };
      $ws->send({json => \%json});

      });

  # Incoming message
  $s->on(message => sub ($s, $msg) {
    $s->app->log->debug("on message $msg");
  });

  # Closed
  $s->on(finish => sub ($s, $code, $reason = undef) {
    $s->app->log->debug("WebSocket closed with s[$s]code [$code] reason[$reason]");
  });
}

sub echo {
  my $c = shift;
  # Opened
  $c->app->log->debug('WebSocket opened');

  # Increase inactivity timeout for connection a bit
  $c->inactivity_timeout(300);

  # Incoming message
  $c->on(message => sub ($c, $msg) {
    $c->send("echo: $msg");
  });

  # Closed
  $c->on(finish => sub ($c, $code, $reason = undef) {
    $c->app->log->debug("WebSocket closed with status $code");
  });
}

sub index {
  my $s = shift;
  $s->app->log->debug( ' req query  '.$s->req->url->query );
  $s->app->log->info("index");
#  $s->res->headers->cache_control('max-age=1, no-cache');

#  my $sid = $s->storeSessionDb('{}');
#  $s->session(sid => $sid);
#  $s->app->log->info("db session id [$sid]");

  # TODO: hypnotoad
  $s->stash(mode => $s->app->mode);

  $s->app->log->debug("Service Mode (hypnotoad c->app->mode?): ".$s->app->mode);
  $s->render; 
}

sub brochure {
  my $s = shift;

  $s->app->log->debug( ' req query  '.$s->req->url->query );
#  if (not $s->session('guseremail')) {
#    $s->redirect_to('/');
#    return;
#  }

#  $s->res->headers->cache_control('max-age=1, no-cache');

  $s->stash(mode => $s->app->mode);
  my ($guserid, $guseremail, $gusername, $guserimageurl) = 
    ($s->session('guserid'), $s->session('guseremail'), $s->session('gusername'), $s->session('guserimageurl'));
  $s->app->log->debug("Controller::Main: session: ".$s->session);
  $s->app->log->debug("Controller::Main: session: ".dumper($s->session));
  $s->app->log->debug("$guserid, $guseremail, $gusername, $guserimageurl");

  #/index googleAuthWeb -> Cookie::js_sesh
  #this Cookie::js_sesh -> Mojolicious::Session::DOM -> session

  #  getUserID -> dB.useraccesscontrol.sso
  #
  $s->session(ssoid => $s->getUserID({guseremail => $guseremail, guserid => $guserid, gusername => $gusername, guserimageurl =>$guserimageurl}));

  my $roles = $s->userRoles($guseremail);
  $s->session(roles => $roles);
  $s->app->log->debug(dumper($roles));
#  $s->session->store;

#  my @jar = $s->res->cookies;
#  $s->app->log->info( encode_json(\@jar));
  $s->render;
}

sub portal {
  my $s = shift;

  $s->app->log->debug( ' req query  '.$s->req->url->query );
  $s->stash(mode => $s->app->mode);
	$s->session(views => $s->schemaviews);
  $s->stash(url => $s->url_for('/data/store')->to_abs->scheme('ws'));
  $s->app->log->debug("views:".dumper($s->stash('views')));
  $s->app->log->debug("sessoid:".$s->session('ssoid'));
  $s->app->log->debug("session useremail:".$s->session('useremail'));

  #$s->res->headers->cache_control('max-age=1, no-cache');

  #  session cache, session only
  #  new session can reproduce bug
  #  see confluence, make bug report
  #  sometimes, new browser, will require, a two times user interaction
  #  to avoid this redirect
  #
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

sub orderbook
{
  my $s = shift;
  $s->stash(mode => $s->app->mode);
  if (not $s->session('ssoid')) {
    $s->redirect_to('/');
    return;
  }

  $s->render(status => 200);
}

sub log
{
  my $s = shift;
  $s->stash(mode => $s->app->mode);

  if (not $s->session('ssoid')) {
    $s->redirect_to('/');
    return;
  }

  $s->render(status => 200);
}

# execute
#
sub selector
{
  my $s = shift;
  $s->stash(mode => $s->app->mode);
  if (not $s->session('ssoid')) {
    $s->redirect_to('/');
    return;
  }
  $s->render(status => 200);
}

sub wsSelector
{
  my $s = shift;
  $s->stash(mode => $s->app->mode);
  $s->stash(ssoid => $s->session('ssoid'));
  my $format = $s->stash('format');

  # Increase inactivity timeout for connection a bit
  $s->inactivity_timeout(300);

  $s->on( json => sub {
    $s->app->log->debug("on json");
      my ($ws, $data) = @_;
      
      $s->app->log->debug(dumper(\$data));

    $ws->send({json => {status => "insert status"}});
      });


  $s->on(finish => sub ($s, $code, $reason = undef) {
    $s->app->log->debug("WebSocket closed with status $code");
  });

  $s->render(status => 200);
}

1;
