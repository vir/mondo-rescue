#!/usr/bin/perl -w
#
# $Id$
#
# mondo-web perl script 
# ======================
# The script is a cgi-bin script serving as a Web interface for mondoarchive
# It generates the right mondoarchive command depending on answers to questions
# it asks to the user.
#
# This program is free software and is made available under the GPLv2.
# (c) B. Cornec 2007
#

use strict;
use CGI;
use CGI::Carp qw(fatalsToBrowser);
use Data::Dumper;
use AppConfig;

my $cgi = new CGI;
my $default = "";
my @default;

# Handling Configuration files
my $file1 = "/etc/mondo/mondo.conf.dist";
my $file2 = "/etc/mondo/mondo.conf";

my $config = AppConfig->new({
				# Auto Create variables mentioned in Conf file
				CREATE => 1, 
				DEBUG => 0, 
				GLOBAL => {
					# Each conf item has one single parameter
					ARGCOUNT => AppConfig::ARGCOUNT_ONE
				}
			});
$config->file($file1, $file2);

my $command="";

# Fake it for now
my %media = (
		"CDR" => "CD-R", 
		"CDRW" => "CD-RW", 
		"DVD" => "DVD+/-R/RW", 
		"ISO" => "ISO Image", 
		"USB" => "USB disk/key", 
		"TAPE" => "Tape", 
		"NFS" => "NFS File System", 
		"STREAM" => "Streaming"
);
my @media = sort keys %media;
my %options = (
		'NOBOOTABLE' => 'Create Non-Bootable media',
		'AUTO', => 'Auto Restore Mode',
		'NFSEXCL' => 'Exclude Network File Systems',
		'MANEJECT' => 'Manual media ejection',
		'DIFF' => 'Differential Backup',
		'VERIF' => 'Media verification (Slower)',
		'XATTR' => 'Extended Attributes and ACL Management (Slower)'
);
my @options = sort keys %options;
my %speed = (
		1 => '1x',
		2 => '2x',
		4 => '4x',
		8 => '8x',
		16 => '16x',
		24 => '24x',
		48 => '48x',
		52 => '52x',
);
my @speed = sort {$a <=> $b} keys %speed;
my %suffix = (
		GZIP => 'gz',
		BZIP2 => 'bz2',
		LZO => 'lzo',
);
my @suffix = sort keys %suffix;
my %comp = (
		GZIP => 'gzip (average)',
		BZIP2 => 'bzip2 (size)',
		LZO => 'lzo (speed)',
);
my @comp = sort keys %comp;
my %ratio = (
		0 => '0',
		1 => '1',
		2 => '2',
		3 => '3',
		4 => '4',
		5 => '5',
		6 => '6',
		7 => '7',
		8 => '8',
		9 => '9',
);
my @ratio = sort {$a <=> $b} keys %ratio;
my %boot = (
		'LILO' => "LILO",
		'GRUB' => "GRUB",
		'ELILO' => "ELILO (ia64)",
		'RAW' => "RAW",
		'BOOT0' => "BOOT0 (FreeBSD)",
		'DD' => "DD (FreeBSD)",
		'NATIVE' => "Autodetected",
);
my @boot = sort keys %boot;

print $cgi->header;
print $cgi->start_html('Web Based MondoArchive');
print << 'EOF';
<IMG SRC="mondo_logo.gif" HEIGHT=66 WIDTH=66 ALIGN=LEFT>
EOF
print $cgi->h1('MondoArchive Image Creation');

if (not ($cgi->param())) {
	print $cgi->start_form;
	print $cgi->hr;
	print $cgi->h2('Mandatory Info');
	print "<TABLE><TR><TD WIDTH=230>\n";
	print "Media type: ",$cgi->popup_menu(-name=>'media',
			-values=>\@media,
			-default=>$media[0],
			-labels=>\%media);
	print "</TD><TD WIDTH=300>\n";
	print "Destination path or device:\n";
	print $cgi->textfield(-name=>'dest',
				-default=>$config->get("mondo_images_dir"),
				-size=>15,
				-maxlenght=>150);
	print "</TD><TD WIDTH=250>\n";
	print "Size of media (MB):\n";
	print $cgi->textfield(-name=>'size',
				-default=>$config->get("mondo_media_size"),
				-size=>6,
				-maxlenght=>6);
	print "</TD></TR></TABLE>\n";
	print $cgi->hr;

	print $cgi->h2('Compression Info');
	print "<TABLE><TR><TD WIDTH=330>\n";
	$default = 'GZIP' if ($config->get("mondo_compression_tool") =~ /gzip/);
	$default = 'BZIP2' if ($config->get("mondo_compression_tool") =~ /bzip2/);
	$default = 'LZO' if ($config->get("mondo_compression_tool") =~ /lzo/);
	print "Compression tool: ",$cgi->popup_menu(-name=>'comp',
			-values=>\@comp,
			-default=>$default,
			-labels=>\%comp);
	print "</TD><TD WIDTH=300>\n";
	print "Compression ratio: ",$cgi->popup_menu(-name=>'compratio',
			-values=>\@ratio,
			-default=>$config->get("mondo_compression_level"),
			-labels=>\%ratio);
	print "</TD><TD WIDTH=300>\n";
	print "Compression suffix: ",$cgi->popup_menu(-name=>'compsuffix',
			-values=>\@suffix,
			-default=>$config->get("mondo_compression_suffix"),
			-labels=>\%suffix);
	print "</TD></TR></TABLE>\n";
	print $cgi->hr;

	print $cgi->h2('Optional Info');
	print "<TABLE><TR><TD WIDTH=360>\n";

	@default = (@default,'AUTO') if ($config->get("mondo_automatic_restore") =~ /yes/);
	@default = (@default,'DIFF') if ($config->get("mondo_differential") =~ /yes/);
	#'NFSEXCL' => 'Exclude Network File Systems',
	@default = (@default, 'NFSEXCL');
	#'NOBOOTABLE' => 'Create Non-Bootable media',
	#'MANEJECT' => 'Manual media ejection',
	#'VERIF' => 'Media verification (Slower)',
	#'XATTR' => 'Extended Attributes and ACL Management (Slower)'
	print $cgi->checkbox_group(-name=>'options',
			-values=>\@options,
			-defaults=>\@default,
			-linebreak=>'true',
			-labels=>\%options);
	print "</TD><TD WIDTH=350>\n";
	print "Temporary Directory:\n";
	print $cgi->textfield(-name=>'temp',
				-default=>$config->get("mondo_tmp_dir"),
				-size=>25,
				-maxlenght=>150);
	print "<BR>";
	print "Scratch Directory:\n";
	print $cgi->textfield(-name=>'scratch',
				-default=>$config->get("mondo_scratch_dir"),
				-size=>25,
				-maxlenght=>150);
	print "<BR>";
	print "ISO Image Name Prefix:\n";
	print $cgi->textfield(-name=>'prefix',
				-default=>$config->get("mondo_prefix"),
				-size=>15,
				-maxlenght=>150);
	print "<BR>";
	print "Tape block size:\n";
	print $cgi->textfield(-name=>'block',
				-default=>$config->get("mondo_external_tape_blocksize"),
				-size=>10,
				-maxlenght=>10);
	print "<BR>";
	print "Media Speed (if pertinent): ",$cgi->popup_menu(-name=>'speed',
			-values=>\@speed,
			-default=>$config->get("mondo_iso_burning_speed"),
			-labels=>\%speed);
	print "<BR>";
	print "Kernel:\n";
	print $cgi->textfield(-name=>'kernel',
				-default=>$config->get("mondo_kernel"),
				-size=>30,
				-maxlenght=>150);
	print "<BR>";
	print "Postnuke script:\n";
	print $cgi->textfield(-name=>'postnuke',
				-default=>'',
				-size=>30,
				-maxlenght=>150);
	print "<BR>";
	print "NFS (server:export):\n";
	print $cgi->textfield(-name=>'nfs',
				-default=>'',
				-size=>30,
				-maxlenght=>150);
	print "<BR>";
	print "</TD></TR>\n";
	print "<TR><TD>\n";
	print "Bootloader:<BR>\n",$cgi->radio_group(-name=>'boot',
			-values=>\@boot,
			-default=>$config->get("mondo_boot_loader"),
			-linebreak=>'true',
			-labels=>\%boot);
	print "<BR>";
	print "Debug:\n";
	print $cgi->popup_menu(-name=>'debug',
			-values=>\@ratio,
			-default=>$config->get("mondo_log_level"),
			-labels=>\%ratio);
	print "</TD><TD>\n";
	print "Excluded directories:\n";
	print $cgi->textfield(-name=>'exclude',
				-default=>$config->get("mondo_exclude_files"),
				-size=>30,
				-maxlenght=>150);
	print "<BR>";
	print "Included directories:\n";
	print $cgi->textfield(-name=>'include',
				-default=>$config->get("mondo_include_files"),
				-size=>30,
				-maxlenght=>150);
	print "<BR>";
	print "Command to launch before burning:\n";
	print $cgi->textfield(-name=>'before',
				-default=>'',
				-size=>50,
				-maxlenght=>150);
	print "<BR>";
	print "Command to launch after burning:\n";
	print $cgi->textfield(-name=>'after',
				-default=>'',
				-size=>50,
				-maxlenght=>150);
	print "<BR>";
	print "</TD></TR></TABLE>\n";
	print $cgi->hr;
	print $cgi->submit;
	print $cgi->end_form;
} else {
	$command="mondoarchive -O -K ".$cgi->param('debug')." ";
	if ($cgi->param('debug') eq 'STATIC') {
	} else {
	}
	foreach my $s ($cgi->param('options')) {
		$command .= "-W " if ($s =~ /NOBOOTABLE/);
		$command .= "-H " if ($s =~ /AUTO/);
		$command .= "-N " if ($s =~ /NFSEXCL/);
		$command .= "-m " if ($s =~ /MANEJECT/);
		$command .= "-D " if ($s =~ /DIFF/);
		$command .= "-V " if ($s =~ /VERIF/);
		$command .= "-z " if ($s =~ /XATTR/);
	}
	my $speed = $cgi->param('speed');
	$command .= "-c $speed " if ($cgi->param('media') =~ /^CDR$/);
	$command .= "-w $speed " if ($cgi->param('media') =~ /^CDRW$/);
	$command .= "-n ".$cgi->param('nfs')." " if (($cgi->param('media') =~ /NFS/) && ($cgi->param('nfs') ne ""));
	$command .= "-r " if ($cgi->param('media') =~ /DVD/);
	$command .= "-i " if ($cgi->param('media') =~ /ISO/);
	$command .= "-U " if ($cgi->param('media') =~ /USB/);
	$command .= "-t " if ($cgi->param('media') =~ /TAPE/);
	$command .= "-b ".$cgi->param('block')." " if (($cgi->param('media') =~ /TAPE/) && ($cgi->param('block') ne ""));
	$command .= "-u " if ($cgi->param('media') =~ /STREAM/);
	$command .= "-L " if ($cgi->param('comp') =~ /LZO/);
	$command .= "-G " if ($cgi->param('comp') =~ /GZIP/);
	$command .= "-E \"".$cgi->param('exclude')."\" " if ($cgi->param('exclude') ne "");
	$command .= "-I \"".$cgi->param('include')."\" " if ($cgi->param('include') ne "");
	$command .= "-T ".$cgi->param('temp')." " if ($cgi->param('temp') ne "");
	$command .= "-S ".$cgi->param('scratch')." " if ($cgi->param('scratch') ne "");
	$command .= "-B ".$cgi->param('before')." " if ($cgi->param('before') ne "");
	$command .= "-A ".$cgi->param('after')." " if ($cgi->param('after') ne "");
	$command .= "-p ".$cgi->param('prefix')." " if ($cgi->param('prefix') ne "");
	$command .= "-P ".$cgi->param('postnuke')." " if ($cgi->param('postnuke') ne "");
	$command .= "-l ".$cgi->param('boot')." " if ($cgi->param('boot') ne 'NATIVE');
	$command .= "-k ".$cgi->param('kernel')." " if (($cgi->param('kernel') ne "") && ($cgi->param('kernel') ne 'NATIVE'));
	$command .= "-d ".$cgi->param('dest')." -s ".$cgi->param('size')." -".$cgi->param('compratio')." ";

	print $cgi->h2('Here is the mondoarchive command generated:');
	print $cgi->hr;
	print $command;

	print $cgi->hr;
	print "That mondoarchive is now being commited to the server which launch the disaster recovery procedure.<P>";
	print "Please wait till it's done ...";
	print $cgi->end_form;

	#
	# Now doing the job ...
	#
	#system("sudo $command");
	}
