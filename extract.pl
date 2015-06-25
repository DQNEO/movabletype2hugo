#!/usr/bin/env perl
use strict;
use warnings;
use DBI;
use Data::Dumper;
use Time::Piece;

my $host = shift;
my $user = shift;
my $passwd = shift;
my $dbname = shift;
my $dbh = DBI->connect("DBI:mysql:$dbname:".$host, $user, $passwd);

# SELECT
my $sql = "
SELECT   entry_id
       , entry_basename
       , entry_authored_on
       , entry_title
       , entry_text
       , entry_text_more
FROM mt_entry LIMIT 20
";
my $sth = $dbh->prepare($sql);
$sth->execute;

# iterate
my $rows = $sth->fetchall_arrayref(+{});

my $out_dir = "public";
mkdir($out_dir) if ! -d $out_dir;

for my $row (@$rows) {

    my $t = Time::Piece->strptime($row->{entry_authored_on}, "%Y-%m-%d %H:%M:%S");
    my $permalink = sprintf( "%04d@%02d@%s.html"
        , $t->year
        , $t->mon
        , $row->{entry_basename});

    #warn Dumper $row;
    my $front_matter = {
        date => "2015-06-22T20:17:39+09:00",
        title => $row->{entry_title},
        categories => [ "Development" ],
    };

    make_entry_file($out_dir , $permalink, $front_matter, $row->{entry_text}, $row->{entry_text_more});
}

sub make_entry_file {
    my ($out_dir, $filename, $front_matter, $text, $more_text) = @_;

    open(my $fh,  ">", $out_dir . "/" . $filename);
    print $fh $text;

    if ($more_text) {
        print $fh '<!--more-->';
        print $fh $more_text;
    }

    close($fh);
}
