#!/usr/bin/perl -w
#
# Mindi subroutines brought by the MondoRescue project
#
# $Id$
#
# Copyright B. Cornec 2008
# Provided under the GPL v2

package MandoRescue::Mindi;

use strict 'vars';
use Data::Dumper;
use English;
use File::Basename;
use File::Copy;
use POSIX qw(strftime);
use lib qw (lib);
use ProjectBuilder::Base;
use ProjectBuilder::Conf;

# Inherit from the "Exporter" module which handles exporting functions.

use Exporter;

# Export, by default, all the functions into the namespace of
# any code which uses this module.

our @ISA = qw(Exporter);
our @EXPORT = qw(mr_lvm_check);

=pod

=head1 NAME

MondoRescue::Mindi, part of the mondorescue.org

=head1 DESCRIPTION

This modules provides low level functions for the Mindi part of the Mondorescue project

=head1 USAGE

=over 4

=item B<mr_lvm_check>

This function checks the usage of LVM and gets the version used
It returns 2 parameters, the LVM version, and the lvm command to use if needed

=cut

sub mr_lvm_check {

# Get them from a conf file instead
my $lvmds = "/usr/sbin/lvmdiskscan";
my $lvmproc = "/proc/lvm/global";
my $lvmcmd = "/usr/sbin/lvm";

mr_exit(1,"$lvmproc doesn't exist.") if (! -x $lvmproc) ;

# Check LVM volumes presence
open(LVM,$lvmproc) || mr_exit(-1,"Unable to open $lvmproc");
while (<LVM>) {
	mr_exit(1,"No LVM volumes found in $lvmproc") if (/0 VGs 0 PVs 0 LVs/);
}
close(LVM);

# Check LVM version
my $lvmver=0;
if (-x $lvmds ) {
	open(LVM,"$lvmds --help 2>&1 |") || mr_exit(-1,"Unable to execute $lvmds");
	while (<LVM>) {
		if (/Logical Volume Manager/ || /LVM version:/) {
				$lvmver = $_;
				$lvmver =~ s/:([0-9])\..*/$1/;
		}
	}
}
close(LVM);

if ($lvmver == 0) {
	# Still not found
	if (-x $lvmcmd) {
		open(LVM,"$lvmcmd version |") || mr_exit(-1,"Unable to execute $lvmcmd");
		while (<LVM>) {
			if (/LVM version/) {
				$lvmver = $_;
				$lvmver =~ s/LVM version ([0-9])\..*/$1/;
			}
		}
		close(LVM);
	}
}

if ($lvmver == 0) {
	# Still not found
	mr_exit(-1,"Unable to determine LVM version.\nPlease report to the dev team with the result of the commands\n$lvmds and $lvmcmd version");
} elsif ($lvmver == 1) {
	$lvmcmd = "";
}
pb_log(1,"Found LVM version $lvmver");
return ($lvmver,$lvmcmd);

}

=back

=head1 WEB SITES

The main Web site of the project is available at L<http://www.mondorescue.org/>. Bug reports should be filled using the trac instance of the project at L<http://trac.mondorescue.org/>.

=head1 USER MAILING LIST

The mailing list of the project is available at L<mailto:mondo@lists.sf.net>
 
=head1 AUTHORS

The Mondorescue.org team L<http://www.mondorescue.org/> lead by Bruno Cornec L<mailto:bruno@mondorescue.org>.

=head1 COPYRIGHT

This module is distributed under the GPL v2.0 license
described in the file C<COPYING> included with the distribution.


=cut

1;

