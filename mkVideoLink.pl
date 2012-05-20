#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Path::Class;

my @videos = grep { /\.m4v$/ } dir('G:/BD/Videos')->children;
say scalar @videos;
