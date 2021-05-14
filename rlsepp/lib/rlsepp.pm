package rlsepp;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;
use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper;
use Mojolicious::Sessions::DOM;
use Net::Address::IP::Local;

has ip_address => sub {
  my $s = shift;
  $s->app->log->info("begin app->ip_address");
  my $address = Net::Address::IP::Local->public;
  return $address;
};

# This method will run once at server start
sub startup {
  my $self = shift;


  # Load configuration from config file
  my $config = $self->plugin('NotYAMLConfig');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;
  
  $self->sessions(Mojolicious::Sessions::DOM->new);
#  $self->app->log(Dumper($self->sessions));

  $self->sessions->cookie_domain('.grandstreet.group');
  $self->sessions->samesite('None');

  $self->app->log->info($self->sessions);
# Render the template "index.html.ep"
#get '/' => sub ($c) {
#  $c->render;
#} => 'index';

  # Normal route to controller
  $r->any('/')->to(controller => 'main', action => 'index');
  $r->any('/auth/')->to(controller => 'main', action => 'index');
  $r->any('/auth/test')->to(controller => 'main', action => 'test');
  $r->any('/app/portal')->to(controller => 'main', action => 'portal');
  $r->any('/app/selector')->to(controller => 'main', action => 'selector');
  $r->any('/data/view')->to(controller => 'data', action => 'view');
  $r->any('/brochure')->to(controller => 'main', action => 'brochure');
  #  $r->post('/overexposed/login')->to(controller => 'main', action => 'login');
  #$r->post('/overexposed/find_game')->to(controller => 'main', action => 'find_game');
  #$r->any('/overexposed/logout')->to(controller => 'main', action => 'logout');
  $r->any('/facebook/oauth/postback')->to(controller => 'main', action => 'oauth_postback');
  $r->post('/facebook/state')->to(controller => 'main', action => 'facebook_state');

}

1;
