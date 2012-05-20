#!/usr/bin/env perl
use 5.12.0;
use warnings;
use HTTP::Date qw!time2iso!;
use Path::Class;

my $SRC_DIR = dir('G:/BD/Videos');
my $DESC_DIR = dir('C:/Users/delphinus/Dropbox/Videos');

$ENV{CYGWIN} = 'nodosfilewarning';

# DESC_DIR にある symlink を全部消す
while (my $f = $DESC_DIR->next) {
    $f =~ /\.m4v$/ or next;
    say 'delete ' . $f->basename;
    unlink $f; 
}

my @videos = sort {
    $b->stat->mtime <=> $a->stat->mtime
} grep { /\.m4v$/ } $SRC_DIR->children;
@videos = @videos[0 .. 19]; # 最新 20 個のリンクを作成する

my $sum_size = 0;
for my $v (@videos) {
    ref $v or next;
    say $v->basename . "\n    => " . time2iso($v->stat->mtime);
    my $symlink = $DESC_DIR->file($v->basename);
    my @args = (
        qw!cygstart cmd /c mklink!,
        $symlink->as_foreign('Win32')->stringify,
        $v->as_foreign('Win32')->stringify
    );
    system @args;
    $sum_size += $v->stat->size;
}

say '';
printf "total : %.2f GB\n", $sum_size / 1024 / 1024 / 1024;
