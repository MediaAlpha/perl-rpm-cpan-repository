package RPM::CPAN::Repository;

use strict;
use warnings;

# we only support AL2023
sub detect_al2023 {
    unless (-f "/etc/os-release") {
        die "Error: /etc/os-release not found\n";
    }

    my $os_release = '/etc/os-release';
    my %os;

    open(my $fh, '<', $os_release) or die "Can't open $os_release: $!";

    while (my $line = <$fh>) {
        chomp $line;
        if ($line =~ /^(NAME|VERSION)="?([^"]+)"?$/) {
            $os{$1} = $2;
        }
    }
    close($fh);

    # Check if this is AL2023
    if ($os{NAME} ne 'Amazon Linux') {
        die "Error: This script requires Amazon Linux (found: $os{NAME})\n";
    }

    if ($os{VERSION} ne '2023') {
        die "Error: This script requires Amazon Linux 2023 (found: Amazon Linux $os{VERSION})\n";
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

    # Check if file exists and matches
    if (-f $repo_file) {
        open(my $fh, '<', $repo_file) or die "Can't read $repo_file: $!";
        my $existing = do { local $/; <$fh> };
        close($fh);

        if ($existing eq $content) {
            print "OK: $repo_file already exists and is correct\n";
            return;
        }
        print "Updating $repo_file (content differs)\n";
    }
    else {
        print "Creating $repo_file\n";
    }

    # Write the file
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
