#!/usr/bin/env perl

use warnings;
use strict;
#use DateTime;

use File::Basename;
use Cwd 'getcwd';
use User::grent;
use Sys::Hostname;

no warnings 'once';

sub print_base_info {
    print "===== Base Info =====\n";

    # 実行日時取得
    my ($sec, $min, $hour, $mday, $mon, $year) = gmtime($^T);
    $year += 1900;
    $mon += 1;

    # ホスト名とIPアドレスを取得
    print "OS           : $^O\n";
    my $host = hostname();
    my $ipaddr_bin = gethostbyname($host);
    my @ipaddr_arr = unpack("C4",$ipaddr_bin);
    my $ipaddr_str = sprintf("%u.%u.%u.%u",@ipaddr_arr);

    # 各種情報を表示
    printf("Exec Date    : %04d/%02d/%02d %02d:%02d:%02d\n", $year ,$mon, $mday, $hour, $min, $sec);
    print "Exec Program : ", basename(__FILE__) ,"\n";
    print "Exec User    : ", getlogin, "\n";
    print "HOSTNAME     : $host\n";
    print "IP Addr      : $ipaddr_str\n";
    print "Perl version : $^V\n";
    print "Current Dir  : ", getcwd, "\n\n";
}

sub exec_command {
    print "===== Yum Package Check =====\n";
    my @exec_command = ('docker', 'docker-compose', 'pip');
    push @exec_command, @_;

    foreach(@exec_command) {
        if (system("which " . $_ . "> /dev/null 2>&1")) {
            warn "[FAILED] Not Installed : $_";
        } else {
            s/ version//;
            printf "[OK] : $_\n";
        }
    }
}

sub check_installed {
    my $item = shift;
    my $packages = shift;

     foreach(@$packages) {
        return 0 if $_ eq $item;
    }
    return 1;
}

sub get_pip_list{
    print "===== Pip Package Check =====\n";
    my $file_path = $_[0];
    my @installed_package_list;
    my @res_buf;

     # 現状インストールされているパッケージを取得
    my $command = "pip3 list";
    open my $rs, "$command 2>&1 |";
    my @rlist = <$rs>;
    close $rs;
    foreach(@rlist) {
        if (/Package|----/) {
            next;
        }
        s/ .*$//;
        push @installed_package_list, $_;
    }

     # 要求されているパッケージのリストが入っているか確認
    open(FH, "< $file_path") or die("error :$!");
    while (<FH>) {
        s/=.*$//;
        if (check_installed $_, \@installed_package_list) {
            push @res_buf, "[FAILED] : $_";
        } else {
            push @res_buf, "[OK] : $_";
        }
    }
    foreach(reverse sort @res_buf) {
        print $_;
    }
}

sub main {
    if ($ARGV[0]) {
        print_base_info;
    }

    exec_command @_;
    get_pip_list "./rankingbot/requirements.txt";
    exit(0);
}

main(@ARGV);

