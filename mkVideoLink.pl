#!/usr/bin/env perl
use 5.12.0;
use warnings;
use HTTP::Date qw!time2iso!;
use Path::Class;

my $SRC_DIR = dir('G:/BD/Videos');
my $DESC_DIR = dir('C:/Dropbox/Videos');

my @videos = sort {
    $b->stat->mtime <=> $a->stat->mtime
} grep { /\.m4v$/ } dir('G:/BD/Videos')->children;
@videos = @videos[0 .. 19]; # 最新 20 個のリンクを作成する

my $sum_size = 0;
for my $v (@videos) {
    ref $v or next;
    $v->basename eq 'test.m4v' or next;
    say $v->basename . " => " . time2iso($v->stat->mtime);
    my $symlink = $DESC_DIR->file($v->basename);
    my @args = ('mklink', $symlink->stringify, $v->stringify);
    say join ' ', @args;
    $sum_size += $v->stat->size;
}

say '';
printf "total : %.2f GB\n", $sum_size / 1024 / 1024 / 1024;
