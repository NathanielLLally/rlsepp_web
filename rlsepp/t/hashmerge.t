#!/usr/bin/perl
use Hash::Merge qw/merge/;
use Data::Dumper;

use strict;

my %a = (
    'foo'    => 1,
    'bar'    => [qw( a b e )],
    'querty' => { 'bob' => 'alice' },
);
my %b = (
    'foo'    => 2,
    'bar'    => [qw(c d)],
    'querty' => { 'ted' => 'margeret' },
);
 
my %c = %{ merge( \%a, \%b ) };
print Dumper(\%c);
 
Hash::Merge::set_behavior('RIGHT_PRECEDENT');
 
# This is the same as above
 
Hash::Merge::add_behavior_spec(
    {   'SCALAR' => {
            'SCALAR' => sub { $_[1] },
            'ARRAY'  => sub { [ $_[0], @{ $_[1] } ] },
            'HASH'   => sub { $_[1] },
        },
        'ARRAY' => {
            'SCALAR' => sub { $_[1] },
            'ARRAY'  => sub { [ @{ $_[0] }, @{ $_[1] } ] },
            'HASH'   => sub { $_[1] },
        },
        'HASH' => {
            'SCALAR' => sub { $_[1] },
            'ARRAY'  => sub { [ values %{ $_[0] }, @{ $_[1] } ] },
            'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
        },
    },
    'My Behavior',
);
 
# Also there is OO interface.
 
my $merger = Hash::Merge->new('LEFT_PRECEDENT');
my %c = %{ $merger->merge( \%a, \%b ) };
 
# All behavioral changes (e.g. $merge->set_behavior(...)), called on an object remain specific to that object
# The legacy "Global Setting" behavior is respected only when new called as a non-OO function.
 
# re-use globally specified behavior
my $merger = Hash::Merge->new();
$merger->add_behavior_spec(Hash::Merge::get_behavior_spec("My Behavior"), "My Behavior");
my %c = %{ $merger->merge( \%a, \%b ) };
 
# re-use externally specified behavior
use Hash::Merge::Extra ();
my $merger = Hash::Merge->new();
$merger->add_behavior_spec(Hash::Merge::Extra::L_REPLACE, "L_REPLACE");
my %c = %{ $merger->merge( \%a, \%b ) };
