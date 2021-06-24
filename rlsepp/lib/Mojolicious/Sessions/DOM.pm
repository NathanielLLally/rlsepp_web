package Mojolicious::Sessions::DOM;
use Mojo::Base 'Mojolicious::Sessions';
use Mojo::JSON qw/encode_json decode_json/;
use Mojo::Util qw(b64_decode b64_encode dumper);
use Try::Tiny;
use MIME::Base64;

=head2 is_base64

=cut

sub is_base64 {
  #Returns the decoded data on success, undef on failure
  my $data = shift;
  return undef unless defined $data;
  return(undef) unless ($data =~ /^[A-Za-z0-9+\/=]+$/); #test for valid Base64 string
  if (length ($data)%4==0) {
    print "Valid Base64\n";
    my $decoded = decode_base64($data);
    return( $decoded );
  } else {
    print "Invalid Base64\n";
    return(undef);
  }
}

has [qw(cookie_domain secure)];
has cookie_name        => 'mojolicious';
has cookie_path        => '/';
has default_expiration => 3600;
has deserialize        => sub { \&Mojo::JSON::j };
has samesite           => 'Lax';
has serialize          => sub { \&Mojo::JSON::encode_json };

sub load {
  my ($self, $c) = @_;

  return unless my $value = $c->signed_cookie($self->cookie_name);
  $value =~ y/-/=/;
  return unless my $session = $self->deserialize->(b64_decode $value);

  # "expiration" value is inherited
  my $expiration = $session->{expiration} // $self->default_expiration;
  return if !(my $expires = delete $session->{expires}) && $expiration;
  return if defined $expires                            && $expires <= time;

  my $stash = $c->stash;
  return unless $stash->{'mojo.active_session'} = keys %$session;
  $stash->{'mojo.session'} = $session;
  $session->{flash}        = delete $session->{new_flash} if $session->{new_flash};

  my $k = '_jssesh';
  my $fields = b64_decode $c->cookie($k);
  my $jssesh = $self->deserialize->($fields);
  $c->app->log->debug( "Mojolicious::Sessions::DOM load" );
  $c->app->log->debug($k);
  $c->app->log->debug( $fields );

  $c->app->log->info($self->serialize->($session));

  foreach my $key (@$jssesh) {
    my $val = $c->cookie($key);
    if (defined $val) {
      $key =~ s/^_//;

      if (is_base64($val)) {
        $val = decode_json(decode_base64($val));
      }
      $c->app->log->debug( "$key => $val" );
      $c->session($key, $val);
    }
  }
}

sub store {
  my ($self, $c) = @_;

  my $stash = $c->stash;

  return unless my $session = $stash->{'mojo.session'};
  return unless keys %$session || $stash->{'mojo.active_session'};

  # Don't reset flash for static files
  my $old = delete $session->{flash};
  $session->{new_flash} = $old if $stash->{'mojo.static'};
  delete $session->{new_flash} unless keys %{$session->{new_flash}};

  # Generate "expires" value from "expiration" if necessary
  my $expiration = $session->{expiration} // $self->default_expiration;
  my $default    = delete $session->{expires};
  $session->{expires} = $default || time + $expiration if $expiration || $default;

  my $options = {
    domain   => $self->cookie_domain,
    expires  => $session->{expires},
    httponly => 0,
    path     => $self->cookie_path,
    samesite => $self->samesite,
    secure   => $self->secure
  };
 
  #  of the collection populated from cookie jar [mojolicious.session]
  #    embedded within serialized base64 encoded,
  #  one must explicitly unset http only session in order for
  #  client side session as explicit cookies
  #  those, who's hash keys begin with underscore are placed into 
  $c->app->log->info( "Mojolicious::Sessions::DOM store" );

  my @fields = ();
  foreach my $k (keys %$session) {
    if ($k =~ /^_/) {
#      $c->app->log->info( $k );
      push @fields, $k;
  #    $c->cookie($k, $session->{$k}, $options);
    }
  }
  $c->app->log->info( dumper(\@fields) );
  $c->cookie('_jssesh',$self->serialize->(@fields), $options);

  
  $options->{httponly} = 1;

  my $value = b64_encode $self->serialize->($session), '';
  $value =~ y/=/-/;

  $c->signed_cookie($self->cookie_name, $value, $options);
}

1;
