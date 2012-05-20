#!/usr/bin/env perl
use 5.12.0;
use warnings;
use Encode;
use File::Temp qw!tempfile!;
use HTTP::Date qw!time2iso!;
use Path::Class;

$|++;

# m4v ファイルがあるフォルダ
my $SRC_DIR = dir('G:/BD/Videos');
# Dropbox のフォルダ
my $DESC_DIR = dir('C:/Users/delphinus/Dropbox/Videos');

# コマンドに DOS ファイル名が含まれていると出る警告を無視
$ENV{CYGWIN} = 'nodosfilewarning';

# DESC_DIR にある symlink をリストアップ
my %existent;
while (my $f = $DESC_DIR->next) {
    $f =~ /\.m4v$/ or next;
    $existent{$f->basename} = $f;
}

# 最新 20 個のリンクを作成する
my @videos = sort {
    $b->stat->mtime <=> $a->stat->mtime
} grep { /\.m4v$/ } $SRC_DIR->children;
@videos = @videos[0 .. 19];

# 処理開始
my $total_size = 0;
my $created_size = 0;
for my $v (@videos) {
    ref $v or next;
    my $filename = $v->basename;

    # 既にシンボリックリンクが存在するなら次へ
    if ($existent{$filename}) {
        say "skip $filename";
        $total_size += $existent{$filename}->stat->size;
        delete $existent{$filename};
        next;
    }

    # 処理するファイル名
    say $filename . "\n    => " . time2iso($v->stat->mtime);

    # シンボリックリンクのファイル名
    my $desc = $DESC_DIR->file($filename)->as_foreign('Win32')->stringify;
    my $src = $v->as_foreign('Win32')->stringify;

    # バッチファイルを用意
    my ($bat_fh, $bat) = tempfile('mkVideoLink_XXXX',
        SUFFIX => '.bat', TMPDIR => 1);
    binmode $bat_fh => ':encoding(cp932)';

    # バッチファイル書き込み
    $bat_fh->print(decode(utf8 => qq!mklink "$desc" "$src"!));
    $bat_fh->close;

    # バッチファイル実行
    system qw!cygstart cmd /c!,
        Path::Class::File->new_foreign(Win32 => `cygpath -w $bat`)->stringify;

    # バッチファイル削除
    unlink $bat;

    $created_size += $v->stat->size;
    $total_size += $v->stat->size;
}

say '';

# 古いシンボリックリンクを削除
my $delete_size = 0;
while (my ($k, $v) = each %existent) {
    -f $v or next;
    say "delete $k";
    $delete_size += $v->stat->size;
    unlink $v;
}

say '';

# 今回削除したシンボリックリンクの容量
printf "deleted : %5.2f GB\n", $delete_size / 1024 / 1024 / 1024;
# 今回作ったシンボリックリンクの容量
printf "created : %5.2f GB\n", $created_size / 1024 / 1024 / 1024;
# 総容量
printf "total   : %5.2f GB\n", $total_size / 1024 / 1024 / 1024;

__END__
=head1 NAME

mkVideoLink.pl

=head1 SYNOPSIS

    $ perl mkVideoLink.pl

=head1 DESCRIPTION

作成した m4v ファイルを保存したディレクトリから最新 20 件をピックアップし、
Dropbox のフォルダにシンボリックリンクを作る。

C<mklink> コマンドを使うので Windows Vista 以降専用。
