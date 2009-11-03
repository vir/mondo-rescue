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
use POSIX qw(strftime);
use lib qw (lib);
use ProjectBuilder::Base;
use ProjectBuilder::Conf;

# Inherit from the "Exporter" module which handles exporting functions.

use Exporter;

# Export, by default, all the functions into the namespace of
# any code which uses this module.

our @ISA = qw(Exporter);
our @EXPORT = qw(mr_exit);

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
	# messages/dmesg
	# Kernel / Initrd
	# Kernel Modules
	# cmdline

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
