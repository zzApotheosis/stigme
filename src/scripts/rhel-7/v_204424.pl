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
my $password_auth_file = "/etc/pam.d/password-auth";
my $system_auth_file = "/etc/pam.d/system-auth";
my $PASSWORD_ERR = 0b01;
my $SYSTEM_ERR   = 0b10;

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
    
    # Check system-auth
    if (open($fh, '<', $system_auth_file)) {
        @file_data = <$fh>;
        close($fh);
        chomp(@file_data);
        if (grep(/nullok/, @file_data)) {
            $test_result |= $SYSTEM_ERR;
        }
    } else {
        warn($!);
        $test_result |= $SYSTEM_ERR;
    }

    # Check password-auth
    if (open($fh, '<', $password_auth_file)) {
        @file_data = <$fh>;
        close($fh);
        chomp(@file_data);
        if (grep(/nullok/, @file_data)) {
            $test_result |= $PASSWORD_ERR;
        }
    } else {
        warn($!);
        $test_result |= $PASSWORD_ERR;
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
    
    # Apply fix for PASSWORD_ERR
    if ($status & $PASSWORD_ERR) {
        STIGPatcher::fix_password();
    }
    
    # Apply fix for SYSTEM_ERR
    if ($status & $SYSTEM_ERR) {
        STIGPatcher::fix_system();
    }
}

# Fix password-auth Subroutine
sub fix_password {
    # Define subroutine variables
    my $fh;
    my @file_data;
    
    # Open file for reading
    if (open($fh, '<', $password_auth_file)) {
        @file_data = <$fh>;
        close($fh);
        chomp(@file_data);
    } else {
        warn($!);
        return;
    }
    
    # Remove nullok
    for (my $i = 0; $i < scalar(@file_data); $i++) {
        $file_data[$i] =~ s/\s*nullok\s*/ /;
    }
    
    # Open file for writing
    if (open($fh, '>', $password_auth_file)) {
        foreach (@file_data) {
            print($fh "$_\n");
        }
        close($fh);
    } else {
        warn($!);
        return;
    }
}

# Fix system-auth Subroutine
sub fix_system {
    # Define subroutine variables
    my $fh;
    my @file_data;
    
    # Open file for reading
    if (open($fh, '<', $system_auth_file)) {
        @file_data = <$fh>;
        close($fh);
        chomp(@file_data);
    } else {
        warn($!);
        return;
    }
    
    # Remove nullok
    for (my $i = 0; $i < scalar(@file_data); $i++) {
        $file_data[$i] =~ s/\s*nullok\s*/ /;
    }
    
    # Open file for writing
    if (open($fh, '>', $system_auth_file)) {
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
