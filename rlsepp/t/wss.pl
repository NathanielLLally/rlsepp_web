use Mojo::UserAgent;
my $ua = Mojo::UserAgent->new;

$ua->websocket('wss://localhost:3000/echo' => sub {
  my ($ua, $tx) = @_;
  
  $tx->on(message => sub {
    my ($tx, $msg) = @_;
    print "Received: $msg\n";
    $tx->finish;
  });

  $tx->send('Hello Mojolicious!');
});

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
