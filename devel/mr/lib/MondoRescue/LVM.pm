#!/usr/bin/perl -w
#
# Subroutines related to LVM brought by the MondoRescue project
#
# $Id$
#
# Copyright B. Cornec 2008-2010
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
our @EXPORT = qw(mr_lvm_check mr_lvm_get_conf mr_lvm_read_conf mr_lvm_write_conf mr_lvm_edit_conf mr_lvm_apply_from_conf);

=pod

=head1 NAME

MondoRescue::LVM, part of the mondorescue.org

=head1 DESCRIPTION

This modules provides low level functions for LVM support in the Mondorescue project

=head1 USAGE

=over 4

=item B<mr_lvm_check>

This function checks the usage of LVM and gets the version used
It returns 2 parameters, the LVM version, and the lvm command to use if needed
The LVM version could be undef, 0 (no LVM), 1 or 2 at the moment, or further not yet supported version
It potentially takes one parameter, the LVM version, already known, in which case it easily deduced the LVM command.
If LVM version is undefined then no LVM Handling should be done.
It has to run on on a system where LVM is activated to return useful results so typically on the system to backup

=cut

sub mr_lvm_check {

my $lvmver = shift;

# Get params from the conf file
my ($lvmds_t,$lvmproc_t,$lvmcmd_t,$lvmpath_t) = pb_conf_get("mr_cmd_lvmdiskscan","mr_proc_lvm","mr_cmd_lvm","mr_path_lvm");
my $lvmds = $lvmds_t->{$ENV{PBPROJ}};
my $lvmproc = $lvmproc_t->{$ENV{PBPROJ}};
my $lvmcmd = $lvmcmd_t->{$ENV{PBPROJ}};
my $lvmpath = $lvmpath_t->{$ENV{PBPROJ}};

# That file is not mandatory anymore
if (not defined $lvmver) {
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
}

# Check LVM version
if (not defined $lvmver) {
	pb_log(2,"LVM version value is not known\n");
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
		pb_log(2,"Found a LVM version of $lvmver with $lvmds --help\n") if (defined $lvmver);
	}
}

if (not defined $lvmver) {
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
		pb_log(2,"Found a LVM version of $lvmver with $lvmcmd version\n") if (defined $lvmver);
	}
}

if (not defined $lvmver) {
	# Still not found
	mr_log(0,"Unable to determine LVM version.\nIf you think this is wrong, please report to the dev team with the result of the commands:\n$lvmds --help and $lvmcmd version\n");
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

=item B<mr_lvm_get_conf>

This function returns 1 parameters, the LVM structure or undef if no LVM
That LVM structure contains all the information related to the current LVM configuration

=cut

sub mr_lvm_get_conf {

my $lvm = undef;

my ($lvmver,$lvmcmd) = mr_lvm_check();
return(undef) if ((not defined $lvmver) || ($lvmver == 0));

# Analyze the existing physical volumes
open(LVM,$lvmcmd."pvs --noheadings --nosuffix --units m --separator : -o pv_name,vg_name,pv_all,pv_fmt,pv_uuid,dev_size,pv_mda_free,pv_mda_size |") || mr_exit(-1,"Unable to execute ".$lvmcmd."pvs");
while (<LVM>) {
	s/^[\s]*//;

	my ($pv_name,$vg_name,$pe_start,$pv_size,$pv_free,$pv_used,$pv_attr,$pv_pe_count,$pv_pe_alloc_count,$pv_tags,$pv_mda_count,$pv_uuid,$dev_size,$pv_mda_free,$pv_mda_size) = split(/:/);

=pod 

The LVM hash is indexed by VGs, provided by the vg_name attribute of the pvs command
vg_name              - Name of the volume group linked to this PV

=cut

	$lvm->{$vg_name}->{'pvnum'}++;

=pod

The structure contains an array of PVs called pvs and starting at 1, containing the name of the PV as provided by the pv_name attribute of the pvs command
pv_name              - Name of the physical volume PV

=cut

	# Array of PVs for that VG
	$lvm->{$vg_name}->{'pvs'}->[$lvm->{$vg_name}->{'pvnum'}] = $pv_name;

=pod

All the PV fields from the pvs command are gathered under their PV name (substructure)
The following names are used:

From pvs -o help
pe_start             - Offset to the start of data on the underlying device.
pv_size              - Size of PV in current units.
pv_free              - Total amount of unallocated space in current units.
pv_used              - Total amount of allocated space in current units.
pv_attr              - Various attributes - see man page.
pv_pe_count          - Total number of Physical Extents.
pv_pe_alloc_count    - Total number of allocated Physical Extents.
pv_tags              - Tags, if any.
pv_mda_count         - Number of metadata areas on this device.
pv_fmt               - Type of metadata.                                            
pv_uuid              - Unique identifier.                                           
dev_size             - Size of underlying device in current units.                  
pv_mda_free          - Free metadata area space on this device in current units.    
pv_mda_size          - Size of smallest metadata area on this device in current units.

=cut

	$lvm->{$vg_name}->{$pv_name}->{'pe_start'} = $pe_start;
	$lvm->{$vg_name}->{$pv_name}->{'pv_size'} = $pv_size;
	$lvm->{$vg_name}->{$pv_name}->{'pv_free'} = $pv_free;
	$lvm->{$vg_name}->{$pv_name}->{'pv_used'} = $pv_used;
	$lvm->{$vg_name}->{$pv_name}->{'pv_attr'} = $pv_attr;
	$lvm->{$vg_name}->{$pv_name}->{'pv_pe_count'} = $pv_pe_count;
	$lvm->{$vg_name}->{$pv_name}->{'pv_pe_alloc_count'} = $pv_pe_alloc_count;
	$lvm->{$vg_name}->{$pv_name}->{'pv_tags'} = $pv_tags;
	$lvm->{$vg_name}->{$pv_name}->{'pv_mda_count'} = $pv_mda_count;
	$lvm->{$vg_name}->{$pv_name}->{'pv_uuid'} = $pv_uuid;
	$lvm->{$vg_name}->{$pv_name}->{'dev_size'} = $dev_size;
	$lvm->{$vg_name}->{$pv_name}->{'pv_mda_free'} = $pv_mda_free;
	$lvm->{$vg_name}->{$pv_name}->{'pv_mda_size'} = $pv_mda_size;
}
close(LVM);

# Analyze the existing volume groups
#open(LVM,$lvmcmd."vgdisplay -c |") || mr_exit(-1,"Unable to execute ".$lvmcmd."vgdisplay -c");
open(LVM,$lvmcmd."vgs --noheadings --nosuffix --units m --separator : | -o vg_all") || mr_exit(-1,"Unable to execute ".$lvmcmd."vgs");
while (<LVM>) {

=pod

All the VG fields from the vgs command are gathered under the VG name
The following names are used:

From vgs -o help
vg_fmt               - Type of metadata.                                              
vg_uuid              - Unique identifier.                                             
vg_attr              - Various attributes - see man page.                             
vg_size              - Total size of VG in current units.                             
vg_free              - Total amount of free space in current units.                   
vg_sysid             - System ID indicating when and where it was created.            
vg_extent_size       - Size of Physical Extents in current units.                     
vg_extent_count      - Total number of Physical Extents.                              
vg_free_count        - Total number of unallocated Physical Extents.                  
max_lv               - Maximum number of LVs allowed in VG or 0 if unlimited.         
max_pv               - Maximum number of PVs allowed in VG or 0 if unlimited.         
pv_count             - Number of PVs.                                                 
lv_count             - Number of LVs.                                                 
snap_count           - Number of snapshots.                                           
vg_seqno             - Revision number of internal metadata.  Incremented whenever it changes.
vg_tags              - Tags, if any.                                                          
vg_mda_count         - Number of metadata areas in use by this VG.                            
vg_mda_free          - Free metadata area space for this VG in current units.                 
vg_mda_size          - Size of smallest metadata area for this VG in current units.

=cut
	s/^[\s]*//;
	my ($vg_fmt,$vg_uuid,$vg_name,$vg_attr,$vg_size,$vg_free,$vg_sysid,$vg_extend_size,$vg_extend_count,$vg_free_count,$max_lv,$max_pv,$pv_count,$lv_count,$snap_count,$vg_seqno,$vg_tags,$vg_mda_count,$vg_mda_free,$vg_mda_size) = split(/:/);
	$lvm->{$vg_name}->{'vg_fmt'} = $vg_fmt;
	$lvm->{$vg_name}->{'vg_uuid'} = $vg_uuid;
	$lvm->{$vg_name}->{'vg_attr'} = $vg_attr;
	$lvm->{$vg_name}->{'vg_size'} = $vg_size;
	$lvm->{$vg_name}->{'vg_free'} = $vg_free;
	$lvm->{$vg_name}->{'vg_sysid'} = $vg_sysid;
	$lvm->{$vg_name}->{'vg_extend_size'} = $vg_extend_size;
	$lvm->{$vg_name}->{'vg_extend_count'} = $vg_extend_count;
	$lvm->{$vg_name}->{'vg_free_count'} = $vg_free_count;
	$lvm->{$vg_name}->{'max_lv'} = $max_lv;
	$lvm->{$vg_name}->{'max_pv'} = $max_pv;
	$lvm->{$vg_name}->{'pv_count'} = $pv_count;
	$lvm->{$vg_name}->{'lv_count'} = $lv_count;
	$lvm->{$vg_name}->{'snap_count'} = $snap_count;
	$lvm->{$vg_name}->{'vg_seqno'} = $vg_seqno;
	$lvm->{$vg_name}->{'vg_tags'} = $vg_tags;
	$lvm->{$vg_name}->{'vg_mda_count'} = $vg_mda_count;
	$lvm->{$vg_name}->{'vg_mda_free'} = $vg_mda_free;
	$lvm->{$vg_name}->{'vg_mda_size'} = $vg_mda_size;
}
close(LVM);

# Analyze the existing logical volumes
#open(LVM,$lvmcmd."lvdisplay -c |") || mr_exit(-1,"Unable to execute ".$lvmcmd."lvdisplay -c");
open(LVM,$lvmcmd."lvs --noheadings --nosuffix --units m --separator : -o vg_name,lv_all|") || mr_exit(-1,"Unable to execute ".$lvmcmd."lvs");
while (<LVM>) {
	s/^[\s]*//;

=pod

The structure contains an array of LVs called lvs and starting at 1, containing the name of the PV as provided by the pv_name attribute of the pvs command

=cut

	my ($vg_name,$lv_uuid,$lv_name,$lv_attr,$lv_major,$lv_minor,$lv_read_ahead,$lv_kernel_major,$lv_kernel_minor,$lv_kernel_read_ahead,$lv_size,$seg_count,$origin,$origin_size,$snap_percent,$copy_percent,$move_pv,$convert_lv,$lv_tags,$mirror_log,$modules) = split(/:/);

=pod

All the PV fields from the pvs command are gathered under their PV name (substructure)
The following names are used:


	# From lvs -o help

	#vg_name              - Name of the related volume group
	#lv_uuid              - Unique identifier.                           
	#lv_name              - Name.  LVs created for internal use are enclosed in brackets.
	#lv_attr              - Various attributes - see man page.                           
	#lv_major             - Persistent major number or -1 if not persistent.             
	#lv_minor             - Persistent minor number or -1 if not persistent.             
	#lv_read_ahead        - Read ahead setting in current units.                         
	#lv_kernel_major      - Currently assigned major number or -1 if LV is not active.   
	#lv_kernel_minor      - Currently assigned minor number or -1 if LV is not active.   
	#lv_kernel_read_ahead - Currently-in-use read ahead setting in current units.        
	#lv_size              - Size of LV in current units.                                 
	#seg_count            - Number of segments in LV.                                    
	#origin               - For snapshots, the origin device of this LV.                 
	#origin_size          - For snapshots, the size of the origin device of this LV.     
	#snap_percent         - For snapshots, the percentage full if LV is active.          
	#copy_percent         - For mirrors and pvmove, current percentage in-sync.          
	#move_pv              - For pvmove, Source PV of temporary LV created by pvmove.     
	#convert_lv           - For lvconvert, Name of temporary LV created by lvconvert.    
	#lv_tags              - Tags, if any.                                                
	#mirror_log           - For mirrors, the LV holding the synchronisation log.         
	#modules              - Kernel device-mapper modules required for this LV.

=cut

	# The LVM hash is indexed by VGs
	$lvm->{$vg_name}->{'lvnum'}++;
	# That array will start at 1 then
	# Array of LVs for that VG
	$lvm->{$vg_name}->{'lvs'}->[$lvm->{$vg_name}->{'lvnum'}] = $lv_name;
	# All LV fields gathered under the LV name
	$lvm->{$vg_name}->{$lv_name}->{'lv_uuid'} = $lv_uuid;
	$lvm->{$vg_name}->{$lv_name}->{'lv_attr'} = $lv_attr;
	$lvm->{$vg_name}->{$lv_name}->{'lv_major'} = $lv_major;
	$lvm->{$vg_name}->{$lv_name}->{'lv_minor'} = $lv_minor;
	$lvm->{$vg_name}->{$lv_name}->{'lv_read_ahead'} = $lv_read_ahead;
	$lvm->{$vg_name}->{$lv_name}->{'lv_kernel_major'} = $lv_kernel_major;
	$lvm->{$vg_name}->{$lv_name}->{'lv_kernel_minor'} = $lv_kernel_minor;
	$lvm->{$vg_name}->{$lv_name}->{'lv_kernel_read_ahead'} = $lv_kernel_read_ahead;
	$lvm->{$vg_name}->{$lv_name}->{'lv_size'} = $lv_size;
	$lvm->{$vg_name}->{$lv_name}->{'origin'} = $origin;
	$lvm->{$vg_name}->{$lv_name}->{'origin_size'} = $origin_size;
	$lvm->{$vg_name}->{$lv_name}->{'snap_percent'} = $snap_percent;
	$lvm->{$vg_name}->{$lv_name}->{'copy_percent'} = $copy_percent;
	$lvm->{$vg_name}->{$lv_name}->{'move_pv'} = $move_pv;
	$lvm->{$vg_name}->{$lv_name}->{'convert_lv'} = $convert_lv;
	$lvm->{$vg_name}->{$lv_name}->{'lv_tags'} = $lv_tags;
	$lvm->{$vg_name}->{$lv_name}->{'mirror_log'} = $mirror_log;
	$lvm->{$vg_name}->{$lv_name}->{'modules'} = $modules;
}
close(LVM);
return($lvm);
}

=item B<mr_lvm_analyze>

This function outputs in a file descriptor the LVM analysis done
It returns 1 parameters, the LVM version or 0 if no LVM

=cut

sub mr_lvm_analyze {

my $OUTPUT = shift;

my ($lvmver,$lvmcmd) = mr_lvm_check();
my $lvm = mr_lvm_get_conf();
return(undef) if ($lvmver == 0);

print $OUTPUT "LVM:$lvmver\n";

# Analyze the existing physical volumes
#open(LVM,$lvmcmd."pvdisplay -c |") || mr_exit(-1,"Unable to execute ".$lvmcmd."pvdisplay -c");
open(LVM,$lvmcmd."pvs --noheadings --nosuffix --units m --separator : |") || mr_exit(-1,"Unable to execute ".$lvmcmd."pvs");
while (<LVM>) {
		s/^[\s]*//;
		my ($pv,$vg,$foo,$foo2,$size,$foo3) = split(/:/);
		$lvm->{$vg}->{'pvnum'}++;
		# that array will start at 1 then
		$lvm->{$vg}->{'pv'}->[$lvm->{$vg}->{'pvnum'}] = $pv;
		$lvm->{$vg}->{$pv}->{'size'} = $size;
		print $OUTPUT "PV:$_";
}
close(LVM);

# Analyze the existing volume groups
#open(LVM,$lvmcmd."vgdisplay -c |") || mr_exit(-1,"Unable to execute ".$lvmcmd."vgdisplay -c");
open(LVM,$lvmcmd."vgs --noheadings --nosuffix --units m --separator : |") || mr_exit(-1,"Unable to execute ".$lvmcmd."vgs");
while (<LVM>) {
		s/^[\s]*//;
		print $OUTPUT "VG:$_";
}
close(LVM);

# Analyze the existing logical volumes
#open(LVM,$lvmcmd."lvdisplay -c |") || mr_exit(-1,"Unable to execute ".$lvmcmd."lvdisplay -c");
open(LVM,$lvmcmd."lvs --noheadings --nosuffix --units m --separator : |") || mr_exit(-1,"Unable to execute ".$lvmcmd."lvs");
while (<LVM>) {
		s/^[\s]*//;
		print $OUTPUT "LV:$_";
}
close(LVM);
return($lvm);
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
my $lvmcmd;
my $lvmver;

# Generate the startup scrit needed to restore LVM conf
# from what is given on input
# Multiply by the multiplier given in input or 1 of none

my $firsttime = 0;
while (<$INPUT>) {
	if (/^LVM:/) {
		my $tag;
		my $foo;
		($tag,$lvmver) = split(/:/);
		($foo,$lvmcmd) = mr_lvm_check($lvmver);

	print $OUTPUT "# Desactivate Volume Groups\n";
	print $OUTPUT $lvmcmd."vgchange -an\n";
	print $OUTPUT "\n";

	} elsif (/^PV:/) {
		# This is for pvdisplay -c
		#my ($tag,$pvname,$vgname,$pvsize,$ipvn,$pvstat,$pvna,$lvnum,$pesize,$petot,$pefree,$pelloc) = split(/:/);
		my ($tag,$pvname,$vgname,$lvmv,$more,$pesize,$pefree) = split(/:/);
		print $OUTPUT "# Creating Physical Volumes $pvname\n";
		print $OUTPUT $lvmcmd."pvcreate -ff -y";
		print $OUTPUT " -s ".$pesize*$mrmult if (defined $pesize);
		print $OUTPUT " $pvname\n";
		print $OUTPUT "\n";
	} elsif (/^VG:/) {
		# This if for vgdisplay -c
		#my ($tag,$vgname,$vgaccess,$vgstat,$vgnum,$lvmaxnum,$lvnum,$ocalvinvg,$lvmaxsize,$pvmaxnum,$cnumpv,$anumpv,$vgsize,$pesize,$penum,$pealloc,$pefree,$uuid) = split(/:/);
		my ($tag,$vgname,$pvnum,$lvnum,$attr,$vgsize,$vgfree) = split(/:/);
		if ($lvmver < 2) {
			print $OUTPUT "# Removing device first as LVM v1 doesn't do it\n";
			print $OUTPUT "rm -Rf /dev/$vgname\n";
		}
		#$lvmaxnum = 255 if (($lvmaxnum > 256) or (not defined $lvmaxnum));
		#$pvmaxnum = 255 if (($pvmaxnum > 256) or (not defined $pvmaxnum));
		print $OUTPUT "# Create Volume Group $vgname\n";
		# Pb sur pesize unite ?
		print $OUTPUT $lvmcmd."vgcreate $vgname ";
		#print $OUTPUT "-p $pvmaxnum -l $lvmaxnum";
		#print $OUTPUT " -s ".$pesize."\n" if (defined $pesize);
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
		print $OUTPUT $lvmcmd."lvcreate -n $lvname -L ".$lvsize*$mrmult;
		print $OUTPUT " -r $readahead" if (defined $readahead);
		print $OUTPUT " $vgname\n";
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

