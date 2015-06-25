#!/usr/bin/env perl
package main;
use strict;
use warnings;
use DBI;
use autodie;
use Time::Piece;
use Data::Dumper;


my $host = shift;
my $user = shift;
my $passwd = shift;
my $dbname = shift;

my $out_dir = "public";
mkdir($out_dir) if ! -d $out_dir;

my $dbh = DBI->connect("DBI:mysql:$dbname:".$host, $user, $passwd);
my $db = MTDB->new({dbh=>$dbh});
my $entries = $db->get_entries;

for my $entry (@$entries) {

    my $t = Time::Piece->strptime($entry->{entry_authored_on}, "%Y-%m-%d %H:%M:%S");
    my $permalink = sprintf( "%04d@%02d@%s.html"
        , $t->year
        , $t->mon
        , $entry->{entry_basename});

    #warn Dumper $entry;
    my $front_matter = FrontMatter->new({
        date => $t,
        title => $entry->{entry_title},
        categories => [ "Development" ],
    });

    make_entry_file($out_dir , $permalink, $front_matter, $entry->{entry_text}, $entry->{entry_text_more});
}

sub make_entry_file {
    my ($out_dir, $filename, $front_matter, $text, $more_text) = @_;

    print $front_matter->to_text;
    return;
    open(my $fh,  ">", $out_dir . "/" . $filename);

    print $fh $text;

    if ($more_text) {
        print $fh '<!--more-->';
        print $fh $more_text;
    }

    close($fh);
}

package MTDB;
sub new {
    my ($class, $self) = @_;
    bless $self, $class;
}

sub get_entries {
    my $self = shift;
    # SELECT
    my $sql = "
SELECT   entry_id
       , entry_basename
       , entry_authored_on
       , entry_title
       , entry_text
       , entry_text_more
 FROM mt_entry
 ORDER BY entry_id DESC
 LIMIT 20
";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute;

    return $sth->fetchall_arrayref(+{});
}

package FrontMatter;


sub new {
    my ($class, $self) = @_;
    bless $self, $class;
}

sub to_text {
    my $self = shift;
    my $time_shift = "+09:00";

    $self->{title} =~ s/"/\\"/g;
    my $text = "+++\n";
    $text .= "date = \"" . $self->{date}->datetime . $time_shift . "\"\n";
    $text .= "title = \"" . $self->{title} . "\"\n";
    $text .= "categories = [" . "]\n";
    $text .= "+++\n";
    return $text;
}
