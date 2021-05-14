package rlsepp::Auth;
use Mojo::Base 'Mojolicious::Controller', -signatures;

use Mojo::Base 'Mojolicious::Controller';
use Mojo::IOLoop;
use Mojo::Util qw/dumper/;
use Try::Tiny;
use Mojo::JSON qw(decode_json encode_json);
use Data::Dumper;

has ip_address => sub {
  my $s = shift;
  $s->app->log->info("begin app->ip_address");
  my $address = Net::Address::IP::Local->public;
  return $address;
};


1;
