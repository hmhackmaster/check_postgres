#!perl

## Test the "prepare_txns" action

use strict;
use warnings;
use Data::Dumper;
use DBI;
use Test::More tests => 10;
use lib 't','.';
use CP_Testing;

use vars qw/$dbh $SQL $t $info/;

my $cp = CP_Testing->new( {default_action => 'prepared_txns'} );

$dbh = $cp->test_database_handle();

my $S = q{Action 'prepare_txns'};
my $label = 'POSTGRES_PREPARED_TXNS';

$t=qq{$S fails when called with an invalid option};
like ($cp->run('foobar=12'), qr{^\s*Usage:}, $t);

## Clear any outstanding transactions
$info = $dbh->selectall_arrayref('SELECT gid FROM pg_prepared_xacts');
local $dbh->{AutoCommit} = 1;
for (@$info) {
	my $gid = $_->[0];
	$dbh->do("ROLLBACK PREPARED '$gid'");
}
local $dbh->{AutoCommit} = 0;

$t=qq{$S works when called without warning or critical};
like ($cp->run(''), qr{^$label OK: .+No prepared transactions found}, $t);

$dbh->do("PREPARE TRANSACTION '123'");

$t=qq{$S gives correct message when all databases excluded};
like ($cp->run('--include=sbsp'), qr{^$label UNKNOWN: .+No matching databases found due to exclusion}, $t);

$t=qq{$S fails when called with invalid warning};
like ($cp->run('-w foo'), qr{ERROR: Invalid argument}, $t);

$t=qq{$S fails when called with invalid critical};
like ($cp->run('-c foo'), qr{ERROR: Invalid argument}, $t);

$t=qq{$S gives correct output with warning};
like ($cp->run('-w 0'), qr{^$label WARNING}, $t);

$t=qq{$S gives correct output with warning};
like ($cp->run('-w 30'), qr{^$label OK}, $t);

$t=qq{$S gives correct output with critical};
like ($cp->run('-c 0'), qr{^$label CRITICAL}, $t);

$t=qq{$S gives correct output with critical};
like ($cp->run('-c 30'), qr{^$label OK}, $t);

$t=qq{$S gives correct output for MRTG output};
like ($cp->run('--output=MRTG'), qr{^\d\n0\n\npostgres\n$}, $t);

## Clear any outstanding transactions
$info = $dbh->selectall_arrayref('SELECT gid FROM pg_prepared_xacts');
local $dbh->{AutoCommit} = 1;
for (@$info) {
	my $gid = $_->[0];
	$dbh->do("ROLLBACK PREPARED '$gid'");
}
local $dbh->{AutoCommit} = 0;

exit;

