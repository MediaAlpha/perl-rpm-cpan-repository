package RPM::CPAN::Repository;

use strict;
use warnings;
use Config::Tiny;
use File::Basename qw(dirname);
use POSIX qw(uname);

our $REPO_FILE   = '/etc/yum.repos.d/mediaalpha-public.repo';
my $REPO_CONTENT = <<'END';
[mediaalpha-public-perl]
name     = mediaalpha-public-perl-5.42.2
baseurl  = https://mediaalpha-public-rpm-repo.s3.amazonaws.com/perl/5.42.2/$basearch
gpgcheck = 1
gpgkey   = https://mediaalpha-public-rpm-repo.s3.amazonaws.com/RPM-GPG-KEY-mediaalpha
END

# we only support AL2023
sub detect_al2023 {
    my $os_release = '/etc/os-release';

    my $config = Config::Tiny->read($os_release)
        or die "Can't read $os_release: " . Config::Tiny->errstr . "\n";

    my $name    = $config->{_}{NAME}    // '';
    my $version = $config->{_}{VERSION} // '';

    # Strip surrounding quotes if present
    $name    =~ s/^"(.*)"$/$1/;
    $version =~ s/^"(.*)"$/$1/;

    unless ($name =~ /amazon linux/i) {
        die "Error: This script requires Amazon Linux (found: $name)\n";
    }

    if ($version ne '2023') {
        die "Error: This script requires Amazon Linux 2023 (found: Amazon Linux $version)\n";
    }

    print "OK: Amazon Linux 2023 detected\n";
}

# supports x86_64 and aarch64 (Graviton)
sub detect_architecture {
    my $arch = (uname())[4];

    unless ($arch eq 'x86_64' || $arch eq 'aarch64') {
        die "Error: Unsupported architecture (found: $arch, supported: x86_64, aarch64)\n";
    }

    print "OK: $arch architecture detected\n";
    return $arch;
}

sub check_if_repo_dir_exists {
    my $dir = dirname($REPO_FILE);
    unless (-d $dir) {
        die "Error: $dir directory does not exist\n";
    }
}

sub add_the_public_ma_repo {
    open(my $fh, '>', $REPO_FILE) or die "Can't write $REPO_FILE: $!\n";
    print $fh $REPO_CONTENT;
    close($fh);
    print "OK: Wrote $REPO_FILE\n";
}

sub check_the_public_ma_repo {
    open(my $fh, '<', $REPO_FILE) or die "Error: $REPO_FILE does not exist or can't be read: $!\n";
    my $existing = do { local $/; <$fh> };
    close($fh);

    if ($existing eq $REPO_CONTENT) {
        print "OK: $REPO_FILE exists and is correct\n";
    } else {
        die "Error: $REPO_FILE exists but content differs from expected\n";
    }
}

sub remove_the_public_ma_repo {
    unless (-f $REPO_FILE) {
        print "OK: $REPO_FILE does not exist (nothing to remove)\n";
        return;
    }

    unlink($REPO_FILE) or die "Error: Failed to remove $REPO_FILE: $!\n";
    print "OK: Successfully removed $REPO_FILE\n";
}

1; # Must return true
END
