package rlsepp::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;
use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);
use rlsepp::Auth;
use Data::Dumper;
use Mojolicious::Sessions;

# Render the template "index.html.ep"

sub index {
  my $s = shift;
  $s->app->log->info("index");
  $s->res->headers->cache_control('max-age=1, no-cache');

  # TODO: hypnotoad
  $s->stash(mode => $s->app->mode);

  $s->app->log->debug("Service Mode (hypnotoad c->app->mode?): ".$s->app->mode);
  $s->render; 
}

sub brochure {
  my $s = shift;

  $s->res->headers->cache_control('max-age=1, no-cache');

  $s->stash(mode => $s->app->mode);
  $s->session('yo' => 5);
#  $sesh->store;

#  my @jar = $s->res->cookies;
#  $s->app->log->info( encode_json(\@jar));
  $s->render;
}

sub portal {
  my $s = shift;

  $s->stash(mode => $s->app->mode);
  my $session = $s->session;
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
