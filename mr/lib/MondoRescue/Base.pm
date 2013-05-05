#!/usr/bin/perl -w
#
# Base subroutines brought by the MondoRescue project
#
# $Id$
#
# Copyright B. Cornec 2008
# Provided under the GPL v2

package MondoRescue::Base;

use strict 'vars';
use Data::Dumper;
use English;
use File::Basename;
use File::Copy;
use POSIX qw(strftime);
use lib qw (lib);
use Digest::MD5;
use ProjectBuilder::Base;
use ProjectBuilder::Conf;
use MondoRescue::DynConf;

# Inherit from the "Exporter" module which handles exporting functions.

use Exporter;

# Global hash for configuration params of mr
my %mr;
our $mr = \%mr;

# Export, by default, all the functions into the namespace of
# any code which uses this module.

our @ISA = qw(Exporter);
our @EXPORT = qw(mr_init mr_exit mr_conf_get $mr);

=pod

=head1 NAME

MondoRescue::Base, part of the mondorescue.org

=head1 DESCRIPTION

This modules provides low level and generic functions for the Mondorescue project

=head1 USAGE

=over 4

=item B<mr_init>

This function initialize MondoRescue, point to the right conf files, setup stuff
It takes 1 parameter, the message to print if needed

=cut

sub mr_init {

my $msg = shift || "";

pb_log_init($pbdebug);

if (defined $msg) {
	pb_log($pbdebug,$msg);
}


my $pbproj;
# Get the various location determined at installation time
($mr->{'confdir'},$pbproj) = mr_dynconf_init();

# Temp dir
pb_temp_init();

# First use the main configuration file
pb_conf_init($pbproj);
$ENV{'PBPROJ'} = $pbproj;
#
# Conf files Management
# the $mr->{'confdir'}/mondorescue.conf.dist is delivered as part of the project and
# its checksum is verified as we need good default values that we can trust
#
open(MD5,"$mr->{'confdir'}/$pbproj.conf.dist.md5") || die "Unable to read mandatory $mr->{'confdir'}/$pbproj.conf.dist.md5: $!";
my $omd5 = <MD5>;
close(MD5);
chomp($omd5);
# remove file name
$omd5 =~ s/ .*//;
open(CONF,"$mr->{'confdir'}/$pbproj.conf.dist") || die "Unable to read mandatory $mr->{'confdir'}/$pbproj.conf.dist: $!";
binmode(CONF);
my $md5 = Digest::MD5->new->addfile(*CONF)->hexdigest;
chomp($md5);
die "Invalid MD5 found sum for $mr->{'confdir'}/$pbproj.conf.dist: *$md5* instead of *$omd5*" if ($omd5 ne $md5);
close(CONF);

pb_conf_add("$mr->{'confdir'}/$pbproj.conf.dist");
pb_conf_add("$mr->{'confdir'}/$pbproj.conf") if (-f "$mr->{'confdir'}/$pbproj.conf");

my @date = pb_get_date();
$mr->{'start_date'} = strftime("%Y-%m-%d %H:%M:%S", @date);
}

=item B<mr_exit>

This function closes opened files, clean up the environment and exits MondoRescue
It takes 2 parameters, the exit code, and the message to print if needed

=cut

sub mr_exit {

my $code = shift;
my $msg = shift;

if (defined $msg) {
	pb_log($pbdebug,$msg);
}
# CLoses log
if (defined $mr->{'logdesc'}) {
	close($mr->{'logdesc'});
}
die "ERROR returned\n" if ($code lt 0);
exit($code);
}

=item B<mr_conf_get>

This function get parameters in configuration files and returns from the least significant level (default) to the most significant level (application name), passing by the project name.
It takes a list of parameters to find and returns the values corresponding

=cut


sub mr_conf_get {
	my @params = @_;
	my @ptr = ();
	my $ptr;
	
	pb_log(2,"Entering mr_conf_get\n");
	my @args1 = pb_conf_get_if(@params);
	my $proj = $ENV{'PBPROJ'};
	$ENV{'PBPROJ'} = $ENV{'PBPKG'};
	my @args2 = pb_conf_get_if(@params);
	foreach my $i (0..$#args1) {
		$ptr = undef;
		# Process from least important to more important
		$ptr = $args1[$i]->{'default'};
		$ptr[$i] = $ptr if (defined $ptr);
		$ptr = $args1[$i]->{$ENV{'PBPROJ'}};
		$ptr[$i] = $ptr if (defined $ptr);
		$ptr = $args2[$i]->{$ENV{'PBPKG'}};
		$ptr[$i] = $ptr if (defined $ptr);
		$ptr[$i] = "Undefined" if (not defined $ptr[$i]);
		pb_log(2,"Found parameter $params[$i] with value $ptr[$i]\n");
	}
	$ENV{'PBPROJ'} = $proj;
	return(@ptr);
}
