#!/usr/bin/perl -w
#
# Subroutines brought by the MondoRescue project to do HW/FW/SW inventory
#
# $Id$
#
# Copyright B. Cornec 2008
# Provided under the GPL v2

package MondoRescue::Inventory;

use strict 'vars';
use Data::Dumper;
use English;
use File::Basename;
use File::Copy;
use POSIX qw(strftime uname);
use lib qw (lib);
use ProjectBuilder::Base;
use ProjectBuilder::Conf;
use ProjectBuilder::Distribution;
use MondoRescue::LVM;

# Inherit from the "Exporter" module which handles exporting functions.

use Exporter;

# Export, by default, all the functions into the namespace of
# any code which uses this module.

our @ISA = qw(Exporter);
our @EXPORT = qw(mr_inv_os $mr_os);

# Globals
our %mr_hw;
our $mr_hw = \%mr_hw;
our %mr_os;
our $mr_os = \%mr_hw;

=pod

=head1 NAME

MondoRescue::Inventory, part of the mondorescue.org

=head1 DESCRIPTION

This modules provides inventory functions for the Mondorescue project in order to report
the precise context of the system to be archived (Hardware, Firmware and Software as much as possible)
This module aims to be OS independent

=head1 USAGE

=over 4

=item B<mr_inv_hw>

This function reports Hardware inventory of the system to archive

=cut

sub mr_inv_hw {
	
	# Keyboard
	# Raid SW - DM
	# Partitions
	# FS/swaps
	# LVM / ...
	# PCI / USB / lssd / ...
	# messages/dmesg
	# Kernel / Initrd
	# Kernel Modules
	# cmdline
}

sub mr_inv_os {

$mr_os->{'pbos'} = pb_distro_init();

pb_log(2,"OS Inventory: pbos ".Dumper($mr_os)."\n");

# Get some running kernel info
($mr_os->{'uname'}->{'sysname'}, $mr_os->{'uname'}->{'nodename'}, $mr_os->{'uname'}->{'release'}, $mr_os->{'uname'}->{'version'}, $mr_os->{'uname'}->{'machine'}) = uname();

pb_log(2,"OS Inventory: uname ".Dumper($mr_os)."\n");

# Get some conf file content when they exist; Depends on genre or more precise tuple
for my $p ("mr_proc_cmdline","mr_etc_fstab","mr_etc_raidtab","mr_proc_swaps","mr_proc_partitions","mr_proc_filesystems","mr_proc_modules","mr_proc_xen","mr_proc_cpuinfo","mr_proc_devices","mr_proc_meminfo","mr_proc_misc","mr_proc_mounts") {
	my $key = $p;
	$key =~ s/mr_//;
	my ($pp) = pb_conf_get_if($p);
	if (defined $pp) {
		my $file = pb_distro_get_param($mr_os->{'pbos'},$pp);
		if (-r $file) {
			pb_log(2,"DEBUG: File found: $file\n");
			$mr_os->{'files'}->{$key} = pb_get_content($file);
		} else {
			pb_log(1,"WARNING: $file not found\n");
		}
	}
}

pb_log(2,"OS Inventory: files ".Dumper($mr_os)."\n");

return;
# Get some commands result content when they exist; Depends on genre or more precise tuple
for my $p ("mr_cmd_mount","mr_cmd_df","mr_cmd_dmidecode","mr_cmd_lshw") {
	my $key = $p;
	$key =~ s/mr_cmd_//;
	my ($pp) = pb_conf_get_if($p);
	my ($po) = pb_conf_get_if("mr_opt_".$key);
	if (defined $pp) {
		my $cmd = pb_distro_get_param($mr_os->{'pbos'},$pp);
		my $opt = "";
		$opt = pb_distro_get_param($mr_os->{'pbos'},$po) if (defined ($po));
		if (-x $cmd) {
			pb_log(2,"DEBUG: Cmd found: $cmd $opt\n");
			$mr_os->{'cmd'}->{$key} = `$cmd $opt`;
		} else {
			pb_log(1,"WARNING: $cmd not found\n");
		}
	}
}

pb_log(2,"OS Inventory: cmds ".Dumper($mr_os)."\n");
# 
# LVM setup
#
($mr_os->{'lvmver'},$mr_os->{'lvmcmd'}) = mr_lvm_check();

# Summary of conf printed.
pb_log(1,"OS Inventory: ".Dumper($mr_os)."\n");
}

=item B<mr_inv_fw>

This function reports Firmware inventory of the system to archive

=cut

sub mr_inv_fw {

	# Linked to bkphw
	# On Proliant use hpacucli, conrep, hponcfg
}

=item B<mr_inv_sw>

This function reports Software inventory of the system to archive

=cut

sub mr_inv_sw {

	# Commands presence - use FindBin
	# deplist
	# mountlist
}
