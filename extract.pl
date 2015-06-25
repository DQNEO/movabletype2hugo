#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Data::Dumper;

my $host = shift;
my $user = shift;
my $passwd = shift;
my $dbname = shift;
my $dbh = DBI->connect("DBI:mysql:$dbname:".$host, $user, $passwd);

# SELECT
my $sql = "SELECT entry_id, entry_basename, entry_authored_on FROM mt_entry";
my $sth = $dbh->prepare($sql);
$sth->execute;

# iterate
my $rows = $sth->fetchall_arrayref(+{});

for my $row (@$rows) {
    warn Dumper $row;
}

