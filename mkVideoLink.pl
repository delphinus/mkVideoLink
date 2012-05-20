#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Encode;
use HTTP::Date qw!time2iso!;
use Path::Class;

my $SRC_DIR = dir('G:/BD/Videos');
my $DESC_DIR = dir('C:/Users/delphinus/Dropbox/Videos');

$ENV{CYGWIN} = 'nodosfilewarning';

# DESC_DIR にある symlink
my %existent;
while (my $f = $DESC_DIR->next) {
    $f =~ /\.m4v$/ or next;
    $existent{$f->basename} = +{file => $f};
}

# 最新 20 個のリンクを作成する
my @videos = sort {
    $b->stat->mtime <=> $a->stat->mtime
} grep { /\.m4v$/ } $SRC_DIR->children;
@videos = @videos[0 .. 19];

my $sum_size = 0;
for my $v (@videos) {
    ref $v or next;
    my $filename = $v->basename;

    if ($existent{$filename}) {
        say "skip $filename";
        $existent{$filename}{skipped} = 1;
        next;
    }

    say $filename . "\n    => " . time2iso($v->stat->mtime);
    my $desc = encode(cp932 => decode(utf8 =>
            $DESC_DIR->file($filename)->as_foreign('Win32')->stringify));
    my $src = encode(cp932 => decode(utf8 =>
            $v->as_foreign('Win32')->stringify));

    my $cmd = qq!cygstart cmd /c mklink "$desc" "$src"!;
    say $cmd;

    $sum_size += $v->stat->size;
}

say '';
my @to_delete = grep { ! exists $_->{skipped} } values %existent;
for my $v (@to_delete) {
    say 'delete ' . $v->{file}->basename;
    unlink $v->{file};
}

say '';
printf "total : %.2f GB\n", $sum_size / 1024 / 1024 / 1024;
