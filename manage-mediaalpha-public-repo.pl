#!/usr/bin/env perl

use strict;
use warnings;

die "Error: Must run as root\n" if $< != 0;

# Check arguments
if (@ARGV != 1) {
    die "Usage: $0 [add|remove]\n";
}

my $action = $ARGV[0];

unless ($action eq 'add' || $action eq 'remove') {
    die "Error: Invalid action '$action'. You need to choose 'add' or 'remove'\n";
}

use lib '.';
use RPM::CPAN::Repository;

if ($action eq 'add') {
    RPM::CPAN::Repository::detect_al2023();
    RPM::CPAN::Repository::detect_architecture();
    RPM::CPAN::Repository::check_if_repo_dir_exists();
    RPM::CPAN::Repository::add_the_public_ma_repo();
}
elsif ($action eq 'remove') {
    RPM::CPAN::Repository::remove_the_public_ma_repo();
}
