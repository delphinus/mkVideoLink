#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Encode;
use File::Temp qw!tempfile!;
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

    my ($bat_fh, $bat) = tempfile('mkVideoLink_XXXX',
        SUFFIX => '.bat', TMPDIR => 1);
    binmode $bat_fh => ':encoding(cp932)';
    $bat = Path::Class::File->new_foreign(Win32 => $bat);

    my $desc = $DESC_DIR->file($filename)->as_foreign('Win32')->stringify;
    my $src = $v->as_foreign('Win32')->stringify;

    $bat_fh->print(decode(utf8 => qq!mklink "$desc" "$src"!));
    $bat_fh->close;
    system 'cygstart', $bat->stringify;

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
