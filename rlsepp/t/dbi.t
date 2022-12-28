use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use DBI;

#goshawk.grandstreet.group 13.57.47.146 (check teusday may 18th)
my $dbh = DBI->connect_cached("DBI:Pg:dbname=rlsepp;host=db.grandstreet.group;port=5432",'postgres', '', {'RaiseError' => 1, AutoCommit => 1}) || die     $DBI::errstr; 
                  # The AutoCommit attribute should always be explicitly set
                  #
                  #       # For some advanced uses you may need PostgreSQL type values:
use DBD::Pg qw(:pg_types);



my @data_sources = DBI->data_sources('Pg');
print @data_sources;
#

#my $t = Test::Mojo->new('rlsepp');
#$t->get_ok('/')->status_is(200)->content_like(qr/Mojolicious/i);

done_testing();
