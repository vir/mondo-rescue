#!/usr/bin/perl -w
#
# Base subroutines for mrmini
# Mini-distribution maker for the MondoRescue project
#
# $Id$
#
# Copyright B. Cornec 2008-2010
# Provided under the GPL v2

package MondoRescue::Mini::Base;

use strict 'vars';
use Data::Dumper;
use English;
use lib qw (lib);
use ProjectBuilder::Base;
use ProjectBuilder::Conf;
use MondoRescue::DynConf;
use MondoRescue::Base;
use MondoRescue::LVM;

# Inherit from the "Exporter" module which handles exporting functions.

use Exporter;

# Export, by default, all the functions into the namespace of
# any code which uses this module.

our @ISA = qw(Exporter);
our @EXPORT = qw(mr_mini_main);

=pod

=head1 NAME

MondoRescue::Mini::Base, part of the mondorescue.org

=head1 DESCRIPTION

This modules provides low level and generic functions for the mrmini tool

=head1 USAGE

=item B<mr_mini_main>

Main function for mini. Can be called from outside

=cut

sub mr_mini_main {

#
# Configuration parameters
#
# Checks
die "mr->mini_conf not declared in environment" if (not defined $mr->{'confdir'});

# Better ?
my $ARCH = `uname -m`;
chomp($ARCH);

pb_conf_add("$mr->{'confdir'}/$ENV{'PBPROJ'}.conf.dist");
($mr->{'boot_size'},$mr->{'boot_cd'},$mr->{'boot_usb'},$mr->{'boot_tape'},$mr->{'kernel'},$mr->{'fstab'}) =  mr_conf_get("mr_boot_size","mr_boot_cd","mr_boot_usb","mr_boot_tape","mr_kernel","mr_fstab");
($mr->{'tape_mods'},$mr->{'scsi_mods'},$mr->{'ide_mods'},$mr->{'pcmcia_mods'},$mr->{'usb_mods'},$mr->{'net_mods'},$mr->{'cdrom_mods'},$mr->{'deny_mods'},$mr->{'force_mods'}) =  mr_conf_get("mr_tape_mods","mr_scsi_mods","mr_ide_mods","mr_pcmcia_mods","mr_usb_mods","mr_net_mods","mr_cdrom_mods","mr_extra_mods","mr_deny_mods","mr_force_mods");
($mr->{'cache_dir'},$mr->{'boot_msg'},$mr->{'burn_cmd'},$mr->{'burn_opt'}) = mr_conf_get("mr_cache_dir","mr_boot_msg","mr_burn_cmd","mr_burn_opt");

#
# Manage log file
#
$pbLOG = $mr->{'logdesc'};
$pbdebug = 1  if ($pbdebug == -1);
pb_log_init($pbdebug, $pbLOG);

my $sep = "-----------------------------------------------\n";

pb_log(0,"$ENV{'PBPKG'} v$mr->{'version'} start date: $mr->{'start_date'}\n");
pb_log(0,$sep);
pb_log(0,"$ARCH architecture detected\n");
pb_log(0,"$ENV{'PBPKG'} called with the following arguments: ".join(" ",@ARGV)."\n");
pb_log(0,$sep);
pb_log(1,"CONFDIR: $mr->{'confdir'}\n");
pb_log(1,"SBIN: $mr->{'install_dir'}/sbin\n");
if (-r "$ENV{'HOME'}/.mondorescuerc") {
	pb_log(0,$sep);
	pb_log(0,"Conf file $ENV{'HOME'}/.mondorescuerc\n");
	pb_display_file("$ENV{'HOME'}/.mondorescuerc",$pbLOG);
}
if (-r "$mr->{'confdir'}/mondorescue.conf") {
	pb_log(0,$sep);
	pb_log(0,"Conf file $mr->{'confdir'}/mondorescue.conf\n");
	pb_display_file("$mr->{'confdir'}/mondorescue.conf",$pbLOG);
}
pb_log(0,$sep);

#
# Prepare cache dir
#
pb_rm_rf("$mr->{'cache_dir'}/*");
pb_mkdir_p($mr->{'cache_dir'});

my $mrmini_fdisk = "$mr->{'install_dir'}/parted2fdik";
my $mrmini_deplist = "$mr->{'confdir'}/deplist.d";

# 
# LVM setup
#
my ($lvmver,$lvmcmd) = mr_lvm_check();

pb_log(0,"LVM $lvmver command set to $lvmcmd\n");
pb_log(0,$sep);
}
