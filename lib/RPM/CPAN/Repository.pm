package RPM::CPAN::Repository;

use strict;
use warnings;
use Config::Tiny;

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

# for now we only support x86_64
sub detect_architecture {
    my $arch = `uname --processor 2>&1`;
    if ($? != 0) {
        die "Error: Failed to run 'uname --processor': $!\n";
    }
    chomp $arch;

    if ($arch ne 'x86_64') {
        die "Error: This script requires x86_64 architecture (found: $arch)\n";
    }
}

sub check_if_repo_dir_exists {
    unless (-d "/etc/yum.repos.d/") {
        die "Error: /etc/yum.repos.d/ directory does not exist\n";
    }
}

sub add_the_public_ma_repo {
    my $repo_file = '/etc/yum.repos.d/mediaalpha-public.repo';

    my $content = <<'END';
[mediaalpha]
name     = mediaalpha-public
baseurl  = http://s3.amazonaws.com/mediaalpha-public
gpgcheck = 1
priority = 10
END

    open(my $fh, '>', $repo_file) or die "Can't write $repo_file: $!";
    print $fh $content;
    close($fh);
    print "OK: Successfully wrote $repo_file\n";
}

sub remove_the_public_ma_repo {
    my $repo_file = '/etc/yum.repos.d/mediaalpha-public.repo';

    unless (-f $repo_file) {
        print "OK: $repo_file does not exist (nothing to remove)\n";
        return;
    }

    unlink($repo_file) or die "Error: Failed to remove $repo_file: $!\n";
    print "OK: Successfully removed $repo_file\n";
}

1; # Must return true
