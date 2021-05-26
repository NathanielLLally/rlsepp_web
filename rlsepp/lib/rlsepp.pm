package rlsepp;
use Mojo::Base 'Mojolicious', -signatures;
use Mojo::Base 'Mojolicious::Controller', -signatures;
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
#plugin 'TagHelpers::NoCaching', {key => 'v'};
  my $helper = $self->plugin('TagHelpers::NoCaching', {key => 'v'});

  # Configure the application
  $self->secrets($config->{secrets});
  $self->sessions->default_expiration(300);
#  $self->sessions->default_expiration(864000);

#$self->app->types->type(json => 'application/json+html');

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
  $r->any('/debug/')->to(controller => 'main', action => 'debug');
  $r->any('/auth/')->to(controller => 'main', action => 'index');
  $r->any('/auth/test')->to(controller => 'main', action => 'test');
  $r->any('/app/portal')->to(controller => 'main', action => 'portal');
  $r->any('/app/selector')->to(controller => 'main', action => 'selector');
  $r->any('/data/')->to('Data#test');
  $r->get('/data/view/:schema/:view')->to('Data#view');
  $r->get('/data/view/:schema/:view', [format => ['json', 'html']])->to('Data#view');
  $r->any('/data/dump/:schema/:view/')->to(controller => 'data', action => 'dump');
#  $r->get('/data/view/:proc')->to('Ajax::DBIx#dbic');
  $r->any('/brochure')->to(controller => 'main', action => 'brochure');
  #  $r->post('/overexposed/login')->to(controller => 'main', action => 'login');
  #$r->post('/overexposed/find_game')->to(controller => 'main', action => 'find_game');
  #$r->any('/overexposed/logout')->to(controller => 'main', action => 'logout');
  $r->any('/facebook/oauth/postback')->to(controller => 'main', action => 'oauth_postback');
  $r->post('/facebook/state')->to(controller => 'main', action => 'facebook_state');

}

1;