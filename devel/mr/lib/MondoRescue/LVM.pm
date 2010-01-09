#!/usr/bin/perl -w
#
# Mindi subroutines related to LVM brought by the MondoRescue project
#
# $Id$
#
# Copyright B. Cornec 2008
# Provided under the GPL v2

package MondoRescue::LVM;

use strict 'vars';
use Data::Dumper;
use English;
use lib qw (lib);
use ProjectBuilder::Base;
use ProjectBuilder::Conf;
use MondoRescue::Base;

# Inherit from the "Exporter" module which handles exporting functions.

use Exporter;

# Export, by default, all the functions into the namespace of
# any code which uses this module.

our @ISA = qw(Exporter);
our @EXPORT = qw(mr_lvm_check mr_lvm_analyze mr_lvm_prepare);

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
If LVM version is null then no LVM Handling should be done.

=cut

sub mr_lvm_check {

# Get params from the conf file
my ($lvmds_t,$lvmproc_t,$lvmcmd_t,$lvmpath_t) = pb_conf_get("mr_lvmdiskscan","mr_lvmprocfile","mr_lvmcmd","mr_lvmpath");
my $lvmds = $lvmds_t->{$ENV{PBPROJ}};
my $lvmproc = $lvmproc_t->{$ENV{PBPROJ}};
my $lvmcmd = $lvmcmd_t->{$ENV{PBPROJ}};
my $lvmpath = $lvmpath_t->{$ENV{PBPROJ}};

# That file is not mandatory anymore
if (! -x $lvmproc) {
	pb_log(1,"$lvmproc doesn't exist\n");
} else {
	# Check LVM volumes presence
	pb_log(2,"Checking with $lvmproc\n");
	open(LVM,$lvmproc) || mr_exit(-1,"Unable to open $lvmproc");
	while (<LVM>) {
		if (/0 VGs 0 PVs 0 LVs/) {
			pb_log(1,"No LVM volumes found in $lvmproc\n");
			return(0,undef);
		}
	}
	close(LVM);
}

# Check LVM version
my $lvmver = 0;
if (-x $lvmds) {
	pb_log(2,"Checking with $lvmds\n");
	open(LVM,"$lvmds --help 2>&1 |") || mr_exit(-1,"Unable to execute $lvmds");
	while (<LVM>) {
		if (/Logical Volume Manager/ || /LVM version:/) {
				$lvmver = $_;
				chomp($lvmver);
				$lvmver =~ s/:([0-9])\..*/$1/;
		}
	}
	close(LVM);
	pb_log(2,"Found a LVM version of $lvmver with $lvmds --help\n");
}

if ($lvmver == 0) {
	pb_log(2,"LVM version value is still not known\n");
	if (-x $lvmcmd) {
		pb_log(2,"Checking with $lvmcmd\n");
		open(LVM,"$lvmcmd version |") || mr_exit(-1,"Unable to execute $lvmcmd");
		while (<LVM>) {
			if (/LVM version/) {
				$lvmver = $_;
				chomp($lvmver);
				$lvmver =~ s/:([0-9])\..*/$1/;
				$lvmver =~ s/[\s]*LVM version[:]*[\s]+([0-9])\..*/$1/;
			}
		}
		close(LVM);
		pb_log(2,"Found a LVM version of $lvmver with $lvmcmd version\n");
	}
}

if ($lvmver == 0) {
	# Still not found
	mr_exit(-1,"Unable to determine LVM version.\nPlease report to the dev team with the result of the commands:\n$lvmds --help and $lvmcmd version\n");
} elsif ($lvmver == 1) {
	$lvmcmd = "$lvmpath";
} elsif ($lvmver == 2) {
	$lvmcmd .= " ";
} else {
	pb_log(0,"Unknown LVM version $lvmver\n");
}
# Here $lvmcmd contains a full path name
pb_log(1,"Found LVM version $lvmver\n");
return ($lvmver,$lvmcmd);

}

=over 4

=item B<mr_lvm_analyze>

This function outputs in a file descriptor the LVM analysis done
It returns 1 parameters, the LVM version or 0 if no LVM

=cut

sub mr_lvm_analyze {

my $OUTPUT = shift;

my ($lvmver,$lvmcmd) = mr_lvm_check();
return(0) if ($lvmver == 0);

print $OUTPUT "LVM:$lvmver";

# Analyze the existing physical volumes
open(LVM,$lvmcmd."pvdisplay -c |") || mr_exit(-1,"Unable to execute ".$lvmcmd."pvdisplay -c");
while (<LVM>) {
		print $OUTPUT "PV:$_";
}
close(LVM);

# Analyze the existing volume groups
open(LVM,$lvmcmd."vgdisplay -c |") || mr_exit(-1,"Unable to execute ".$lvmcmd."vgdisplay -c");
while (<LVM>) {
		print $OUTPUT "VG:$_";
}
close(LVM);

# Analyze the existing logical volumes
open(LVM,$lvmcmd."lvdisplay -c |") || mr_exit(-1,"Unable to execute ".$lvmcmd."lvdisplay -c");
while (<LVM>) {
		print $OUTPUT "LV:$_";
}
close(LVM);
return($lvmver);
}


=over 4

=item B<mr_lvm_prepare>

This function outputs in a file descriptor the LVM setup needed to restore LVM conf
It returns 1 parameters, the LVM version or 0 if no LVM

=cut

sub mr_lvm_prepare {

my $INPUT = shift;
my $OUTPUT = shift;
my $mrmult = shift;

my ($lvmver,$lvmcmd) = mr_lvm_check();

# Generate the startup scrit needed to restore LVM conf
# from what is given on input
# Multiply by the multiplier given in input or 1 of none

print $OUTPUT "# Desactivate Volume Groups\n";
print $OUTPUT $lvmcmd."vgchange -an\n";
print $OUTPUT "\n";

my $firsttime = 0;
while (<$INPUT>) {
	if (/^PV:/) {
		my ($tag,$pvname,$vgname,$pvsize,$ipvn,$pvstat,$pvna,$lvnum,$pesize,$petot,$pefree,$pelloc) = split(/:/);
		print $OUTPUT "# Creating Physical Volumes $pvname\n";
		print $OUTPUT $lvmcmd."pvcreate -ff -y -s ".$pesize*$mrmult." $pvname\n";
		print $OUTPUT "\n";
	} elsif (/^VG:/) {
		my ($tag,$vgname,$vgaccess,$vgstat,$vgnum,$lvmaxnum,$lvnum,$ocalvinvg,$lvmaxsize,$pvmaxnum,$cnumpv,$anumpv,$vgsize,$pesize,$penum,$pealloc,$pefree,$uuid) = split(/:/);
		if ($lvmver < 2) {
			print $OUTPUT "# Removing device first as LVM v1 doesn't do it\n";
			print $OUTPUT "rm -Rf /dev/$vgname\n";
		}
		$lvmaxnum = 255 if ($lvmaxnum > 256);
		$pvmaxnum = 255 if ($pvmaxnum > 256);
		print $OUTPUT "# Create Volume Group $vgname\n";
		# Pb sur pesize unite ?
		print $OUTPUT $lvmcmd."vgcreate $vgname -p $pvmaxnum -s $pesize -l $lvmaxnum\n";
		print $OUTPUT "\n";
	} elsif (/^LV:/) {
		if ($firsttime == 0) {
			print $OUTPUT "\n";
			print $OUTPUT "# Activate All Volume Groups\n";
			print $OUTPUT $lvmcmd."vgchange -ay\n";
			print $OUTPUT "\n";
			$firsttime = 1;
		}
		my ($tag,$lvname,$vgname,$lvaccess,$lvstat,$lvnum,$oclv,$lvsize,$leinlv,$lealloc,$allocpol,$readahead,$major,$minor) = split(/:/);
		print $OUTPUT "# Create Logical Volume $lvname\n";
		print $OUTPUT $lvmcmd."lvcreate -n $lvname -L ".$lvsize*$mrmult." -r $readahead $vgname\n";
		#[ "$stripes" ]    && output="$output -i $stripes"
		#[ "$stripesize" ] && output="$output -I $stripesize"
	}
}
print $OUTPUT "\n";
print $OUTPUT "# Scanning again Volume Groups\n";
print $OUTPUT $lvmcmd."vgscan\n";
print $OUTPUT "\n";

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

