#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Date::Manip;
use Path::Class;

my @videos = sort {
    $b->stat->mtime <=> $a->stat->mtime
} grep { /\.m4v$/ } dir('G:/BD/Videos')->children;
@videos = @videos[0 .. 19]; # 最新 20 個のリンクを作成する

for my $v (@videos) {
    say $v->basename . " => " .
        UnixDate 'epoch ' . $v->stat->mtime => '%Y/%m/%d %H:%M:%S';
}
