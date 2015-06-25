#!/usr/bin/env perl
package main;
use strict;
use warnings;
use DBI;
use autodie;
use Time::Piece;
use Data::Dumper;
use Carp;

# MySQL DB Connection Info
my $host = shift;
my $user = shift;
my $passwd = shift;
my $dbname = shift;

# make output directory
my $out_dir = "content";
mkdir($out_dir) if ! -d $out_dir;

my $dbh = DBI->connect("DBI:mysql:$dbname:".$host, $user, $passwd);
my $db = MTDB->new({dbh=>$dbh});

my $cats_master = $db->get_categories_master;
my $relation = $db->get_relation;
my $entries = $db->get_entries;

for my $entry (@$entries) {

    die "no text in entry_id= " . $entry->{entry_id} if ! $entry->{entry_text};
    my $time = Time::Piece->strptime($entry->{entry_authored_on}, "%Y-%m-%d %H:%M:%S");
    my $permalink = sprintf( "%04d@%02d@%s.html"
        , $time->year
        , $time->mon
        , $entry->{entry_basename});

    #warn Dumper $entry;

    my $cat_ids = $relation->{$entry->{entry_id}};
    my @categories = map { $cats_master->{$_}} @$cat_ids;
    my $front_matter = FrontMatter->new({
        date => $time,
        title => $entry->{entry_title},
        categories => \@categories,
    });

    make_entry_file($out_dir , $permalink, $front_matter, $entry->{entry_text}, $entry->{entry_text_more});
}

sub make_entry_file {
    my ($out_dir, $filename, $front_matter, $text, $more_text) = @_;
    Carp::croak "undefined text" if ! $text;
    open(my $fh,  ">", $out_dir . "/" . $filename);

    print $fh $front_matter->to_text;
    print $fh "\n";
    print $fh $text;
    if ($more_text) {
        print $fh '<!--more-->';
        print $fh $more_text;
    }

    close($fh);
}

package MTDB;
use strict;
use warnings;
use autodie;

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
";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute;

    return $sth->fetchall_arrayref(+{});
}

sub get_categories_master {
    my $self = shift;
    # SELECT
    my $sql = "
SELECT   category_id
       , category_label
 FROM mt_category
 ORDER BY category_id
";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute;

    my $rows = $sth->fetchall_arrayref(+{});
    my %map = map {$_->{category_id} => $_->{category_label}  } @$rows;
    return \%map;
}

sub get_relation {
    my $self = shift;
    my $sql = "
    SELECT * FROM mt_placement
";
    my $sth = $self->{dbh}->prepare($sql);
    $sth->execute;
    my $rows = $sth->fetchall_arrayref(+{});
    my %entries;
    for my $row (@$rows)  {
        if (! defined $entries{$row->{placement_entry_id}}) {
            $entries{$row->{placement_entry_id}} = [];
        }
        push @{$entries{$row->{placement_entry_id}}}, $row->{placement_category_id};
    }

    return \%entries;
}

package FrontMatter;


sub new {
    my ($class, $self) = @_;
    bless $self, $class;
}

sub to_text {
    my $self = shift;
    my $time_shift = "+09:00";
    my @categories = map {'"'. $_ . '"'} @{$self->{categories}};

    $self->{title} =~ s/"/\\"/g;
    my @lines;
    push @lines, "date = \"" . $self->{date}->datetime . $time_shift . "\"\n";
    push @lines, "title = \"" . $self->{title} . "\"\n";
    push @lines, "categories = [" . join(",", @categories) . "]\n";
    return "+++\n" . (join "", @lines) . "\n+++\n";
}
