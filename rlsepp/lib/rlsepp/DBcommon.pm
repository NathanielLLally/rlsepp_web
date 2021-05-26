package rlsepp::DBcommon;
use Mojo::Base 'Mojolicious::Controller';
use Moose;
use DBI;
use Try::Tiny;
use Data::Dumper;
use Mojo::Util qw/dumper/;

#our $DSN = "dbi:Pg:dbname=rlsepp;host=goshawk.grandstreet.group;port=5432";
our $DSN = "DBI:Pg:dbname=rlsepp;host=54.219.185.152;port=5432";

$ENV{DBI_TRACE} = 2;


#    schema => [get => 'schema'],
#		view => [get => 'view'],
#		setSchema => [set => 'schema'],
#		setView => [set => 'view'],

has 'schema' => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef[Str]',
  lazy => 1,
	handles => {
		setSchema => 'set',
		hasSchema => 'exists',
		schemas => 'keys'
	},
	default => sub { {} }
);

has 'view' => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef[Str]',
  lazy => 1,
	handles => {
		setSchemaView => 'set',
		hasSchemaView => 'exists',
	},
	default => sub { {} }
);

has 'column' => (
  traits => ['Hash'],
  is => 'rw',
  isa => 'HashRef[Any]',
  lazy => 1,
	handles => {
		setCol => 'set',
		getCol => 'get',
		hasCol => 'exists',
	},
	default => sub { {} }
);


#  new paradigm aeServer
#    anything non-server specific will remain in ae
#
has 'dbh' => (
	is => 'rw', 
	isa => 'Any',
  lazy =>1,
	builder => '_dbh'
);

sub _dbh {
  my ($s, $db) = @_;
	$s->app->log->info("dbh");

  $s->app->log->debug(sprintf("dbh, db[%s]", $db || 'default'));
  my $dbh;
  try {
    $dbh = DBI->connect_cached($DSN,'postgres', '', {'RaiseError' => 1, AutoCommit => 1}) || die $DBI::errstr;
  } catch {
    if ($_ =~ /Unknown database/) {
#      $s->createOrUpdateDatabase($db);
      $dbh = DBI->connect_cached($DSN,'postgres', '', {'RaiseError' => 1, AutoCommit => 1}) || die $DBI::errstr;
    }
  };

=pod
  my $default = $dbh->{HandleError};
  $dbh->{HandleError} = sub {
    if ($_[0] =~ /does not exist/) {
      $s->createOrUpdateDatabase($db);
      $s->app->log->debug('caught error '.$_[0]);
    } else {
      return 1 if $default and &$default(@_);
    }
  };
=cut  
  my @sv = $s->schemaviews($dbh);
  $dbh;
}

sub getProcs {
  my ($s) = @_;
  my ($dbh, @result, $sth, $rs) = ($s->dbh, (), (undef) x 2);
  $sth = $dbh->prepare('select proname from pg_proc where pronamespace = (select oid from pg_namespace where nspname = \'useraccesscontrol\');');
  $sth->execute();
  $rs = $sth->fetchall_arrayref();
  foreach my $row (@$rs) {
#$s->app->log->debug(join(",", @$row));
    push @result, $row->[0];
  }
  return \@result;
}

sub getTables {
  my ($s) = @_;
  $s->app->log->debug("getTables");
  my ($dbh, $sth, $rs) = ($s->dbh, (undef) x 2);
  $s->app->log->debug("have dbh");

  $sth = $dbh->table_info('', '', undef, "TABLE");
  $rs = $sth->fetchall_arrayref();
  my @tables;
  foreach my $row (@$rs) {
    $s->app->log->debug(dumper(\$row));
    push @tables, $row->[2];
  }
  \@tables;
}

{
		my $_SVrowcounts;
sub SVrowcounts
{
  my ($s, $dbh) = @_;
	return $_SVrowcounts if (defined $_SVrowcounts);
	$_SVrowcounts = {};

	my $schemaviews = $s->schemaviews;
  $s->app->log->debug(dumper(\$schemaviews));

	my ($sql, $sth, $rs) = ((undef) x 3);
	
	if (not defined $dbh) {
		$dbh = $s->dbh;
	}
	foreach my $v (@$schemaviews) {
		$sql = "select count(*) as count from $v;";
		$s->app->log->debug($sql);
  $sth = $dbh->prepare($sql);
		$sth->execute();
		$rs = $sth->fetchall_arrayref();
  $s->app->log->debug(dumper(\$rs));
		$_SVrowcounts->{$v} = $rs->[0]->[0];
	}
}
	
}

{
my $_dbInfo;
my $sv;

sub schemaviews
{
	my ($s,$dbh) = @_;
	my @out;
	if (not defined $sv) {
		my $r = $s->SVcolumns($dbh);
	}
	@out = keys %$sv if (defined $sv);
	return \@out;
}

sub SVcolumns {
  my ($s, $dbh) = @_;

	return $_dbInfo	if (defined $_dbInfo);

	my ($sql, $sth, $rs) = ((undef) x 3);
	my %sv = ();
	my %h = ();
$sql = <<EOF
select t.table_schema as schema_name,
       t.table_name as view_name,
       c.column_name
       from information_schema.tables t
    left join information_schema.columns c 
              on t.table_schema = c.table_schema 
              and t.table_name = c.table_name
where table_type = ?
      and t.table_schema not in ('information_schema', 'pg_catalog')
order by schema_name,
         view_name;
EOF
;
#	$s->app->log->debug($sql);
	if (not defined $dbh) {
		$dbh = $s->dbh;
	}
  $sth = $dbh->prepare($sql);
  $sth->execute('VIEW');
  $rs = $sth->fetchall_arrayref({});
	my ($last, $schema, $view, $columns, $column);

	$last = '';
	$columns = [];
	foreach my $row (@$rs) {
		$s->setSchema($row->{'schema_name'}, 1);

		$s->setSchemaView($row->{'schema_name'}.'.'.$row->{'view_name'}, 1);
		
	  $columns = $h{$row->{'schema_name'}.'.'.$row->{'view_name'}};
	  $sv{$row->{'schema_name'}.'.'.$row->{'view_name'}} = 1;

		if (not defined $columns) {
			$columns = [];
		}		

		if (not $s->hasCol($row->{'schema_name'}.'.'.$row->{'view_name'})) {
			$s->setCol($row->{'schema_name'}.'.'.$row->{'view_name'}, '');
		}

		my $col = $s->getCol($row->{'schema_name'}.'.'.$row->{'view_name'}) || '';
		$col .= ' '.$row->{'col_name'};
		$s->setCol($row->{'schema_name'}.'.'.$row->{'view_name'}, $col);
		
	  push @$columns,$row->{'col_name'};
  	 $h{$row->{'schema_name'}.'.'.$row->{'view_name'}} = $columns;
	}
	$_dbInfo = \%h;	
	$sv = \%sv;
}

}

sub userRoles {
  my ($s, $useremail) = @_;
  my ($dbh, $sth, $rs) = ($s->dbh, (undef) x 2);
  my $sql = "select role from useraccesscontrol.vw_useremail_role where useremail = ?;";
  $sth = $dbh->prepare($sql);
  $sth->execute($useremail);
  $rs = $sth->fetchall_arrayref();
  my @roles = map { $_->[0] } @$rs;
  \@roles;
}

sub userHasRole {
  my ($s, $useremail, $role) = @_;
  my ($dbh, $sth, $rs) = ($s->dbh, (undef) x 2);
  my $sql = "select useraccesscontrol.hasrole(?,?);";
  $sth = $dbh->prepare($sql);
  $sth->execute($useremail, $role);
  $rs = $sth->fetchrow_arrayref();
  $rs->[0] if (defined $rs);
}

sub getUserID {
  my ($s, $fields) = @_;
  my ($dbh, $sth, $rs,$uid) = ($s->dbh, (undef) x 3);
  my $sql = "select useraccesscontrol.googlesso(?,?,?,?);";
  $sth = $dbh->prepare($sql);
#  useraccesscontrol.googlesso (Pguserid varchar, Pgusername varchar, Pguseremail varchar, Pguserimageurl varchar
  $s->app->log->debug(dumper($fields));
  my @args = map { $fields->{$_} } qw/guserid gusername guseremail guserimageurl/;
  $s->app->log->debug(dumper(@args));
  $sth->execute(@args);
  $rs = $sth->fetchall_arrayref();

  if (defined $rs and defined $rs->[0]) {
    $uid = $rs->[0]->[0];
  }
  return $uid;
#  my $statement = "select * from public.useraccesscontrol.sso";
}

sub isLoggedIn {
  my ($s, $useremail) = @_;
  my ($dbh, $sth, $rs,$uid) = ($s->dbh, (undef) x 3);
  if ($uid eq 'nathaniel.lally@gmail.com') {
    return 1;
  }
#  my $statement = "select * from public.useraccesscontrol.sso";
#  $rs = $dbh->selectall_hashref($statement, 'userid');
  $s->app->log->debug(dumper($rs));
  return $uid;
}

#  replicate aeBravo schemas and triggers
#  show create table
#
sub createOrUpdateDatabase
{
  my ($s, $db) = @_;
  my @stuff = $s->schema('bravo')->storage->dbh_do(
    sub {
      my ($storage, $dbh, $dbBase, $dbNew) = @_;

      $s->app->log->debug(sprintf("%s %s", $dbBase, $dbNew));

      my ($sth, $rs, @tables, %procs, %triggers) = (undef, undef, (), (), ());

# tables
#   thanks to create table like, we just need the list
#
      $sth = $dbh->table_info('', '', undef, "TABLE");
      $rs = $sth->fetchall_arrayref();
      foreach my $row (@$rs) {
        push @tables, $row->[2];
      }

#  procedures
#
      $sth = $dbh->prepare("show procedure status");
      $sth->execute();
      $rs = $sth->fetchall_arrayref();
      foreach my $row (@$rs) {
        #$s->app->log->debug(join(",", @$row));
        if ($row->[0] eq $dbBase) {
          $procs{$row->[1]}++;
        }
      }

      foreach my $p (keys %procs) {
        $sth = $dbh->prepare("show create procedure $p");
        $sth->execute();
        $rs = $sth->fetchall_arrayref();
        foreach my $row (@$rs) {
          $procs{$p} = $row->[2];
        }
#      $s->app->log->debug("getting body of $p");
      }

#  triggers
#
      $sth = $dbh->prepare("show triggers");
      $sth->execute();
      $rs = $sth->fetchall_arrayref();
      foreach my $row (@$rs) {
        #$s->app->log->debug(join(",", @$row));
          $triggers{$row->[0]}++;
      }

      foreach my $p (keys %triggers) {
        $sth = $dbh->prepare("show create trigger $p");
        $sth->execute();
        $rs = $sth->fetchall_arrayref();
        foreach my $row (@$rs) {
          $triggers{$p} = $row->[2];
        }
#      $s->app->log->debug("getting body of $p");
      }


      try {
        $dbh->do("create database $dbNew");
        $s->app->log->debug("creating database $dbNew");

      };

      foreach my $t (@tables) {
        try {
          $dbh->do(sprintf(
                "create table %s.%s like %s", $dbNew, $t, $t
                ));
          $s->app->log->debug("adding table $t");

        }
      };

      # relies on a failure death here
      #
      $dbh->do("use $dbNew");

      foreach my $k (keys %procs) {
        my $msg = "adding procedure $k";
        try {
#          $dbh->do("drop procedure $k");
          $dbh->do($procs{$k});
        } catch {
          $msg = "error adding $k:$_";
          if ($_ =~ /already exists/) {
            $msg = "skipping existing procedure $k";
          }
        };
        $s->app->log->debug($msg);
      }
      while (my ($k, $v) = each %triggers) {
        my $msg = "adding trigger $k";
        try {
#          $dbh->do("drop trigger $k");
          $dbh->do($v);
        } catch {
          if ($_ !~ /multiple triggers with the same action time and event for one table/) {
            $msg = "error adding $k:$_";
          } else {
            $msg = "skipping existing trigger $k";
          }
        };
        $s->app->log->debug($msg);
      }

    },
    'aeBravo', $db
  );

}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
