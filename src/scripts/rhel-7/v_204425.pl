#!/bin/perl -w

# STIGPatcher Class
package STIGPatcher;

# Imports
use strict;
use warnings;
use FindBin;
use Cwd;

# Class Fields
my $exec_name = "$FindBin::RealScript";
my $exec_path = "$FindBin::RealBin/$FindBin::RealScript";
my $exec_dir = "$FindBin::RealBin";
my $original_cwd = getcwd();
my $sshd_file = "/etc/ssh/sshd_config";
my $PEP_ERR = 0b1; # PermitEmptyPasswords error

# Main Subroutine
sub main {
    # Define subroutine variables
    my $exit_code = 0;
    
    # Perform tests
    $exit_code = STIGPatcher::test();
    
    # Perform patches
    if ($exit_code) {
        STIGPatcher::patch($exit_code);
        $exit_code = STIGPatcher::test();
    }
    
    # Done
    return($exit_code);
}

# Test Subroutine
sub test {
    # Define subroutine variables
    my $test_result = 0;
    my $fh;
    my @file_data;
    
    # Open file for reading
    if (open($fh, '<', $sshd_file)) {
        @file_data = <$fh>;
        close($fh);
        chomp(@file_data);
    } else {
        warn($!);
        $test_result |= $PEP_ERR;
    }
    
    # Check if the required STIG is already implemented
    if (!grep(/^\s*PermitEmptyPasswords\s+no/, @file_data)) {
        $test_result |= $PEP_ERR;
    }
    
    # Done
    return($test_result);
}

# Patch Subroutine
sub patch {
    # Define subroutine variables
    my $status;

    # Check for arguments
    if (!scalar(@_)) {
        return;
    }

    # Fetch arguments
    ($status) = @_;
    
    # Apply fix for PEP_ERR
    if ($status & $PEP_ERR) {
        STIGPatcher::fix_pep();
    }
}

# Fix PEP Subroutine
sub fix_pep {
    # Define subroutine variables
    my $fh;
    my @file_data;

    # Open sshd_config for reading
    if (open($fh, '<', $sshd_file)) {
        @file_data = <$fh>;
        close($fh);
        chomp(@file_data);
    } else {
        warn($!);
        return;
    }
    
    # Check for any existing value
    if (grep(/^\s*PermitEmptyPasswords\s+\S*/, @file_data)) {
        # Loop through the contents of the file to update the existing value
        for (my $i = 0; $i < scalar(@file_data); $i++) {
            $file_data[$i] =~ s/\s*PermitEmptyPasswords.*$/PermitEmptyPasswords no/;
        }
    } else {
        # Append to the end of the file if a current value does not exist
        push(@file_data, "PermitEmptyPasswords no");
    }
    
    # Open file for writing
    if (open($fh, '>', $sshd_file)) {
        foreach (@file_data) {
            print($fh "$_\n");
        }
        close($fh);
    } else {
        warn($!);
        return;
    }
}

# End STIGPatcher Class
1;

# Execute
exit(STIGPatcher::main());
