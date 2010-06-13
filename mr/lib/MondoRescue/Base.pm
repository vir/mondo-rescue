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
use ProjectBuilder::Base;
use ProjectBuilder::Conf;
use MondoRescue::DynConf;

# Inherit from the "Exporter" module which handles exporting functions.

use Exporter;

# Export, by default, all the functions into the namespace of
# any code which uses this module.

our @ISA = qw(Exporter);
our @EXPORT = qw(mr_init mr_exit);

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

if (defined $msg) {
	pb_log($pbdebug,$msg);
}


# Get the various location determined at installation time
my ($etcdir,$pbproj) = mr_dynconf_init();

# Temp dir
pb_temp_init();

# First use the main configuration file
pb_conf_init($pbproj);
#
# Conf files Management
# the $MRMINI_CONF/mondorescue.conf.dist is delivered as part of the project and
# its checksum is verified as we need good default values that we can trust
#
open(MD5,"$etcdir/$pbproj.conf.dist.md5") || die "Unable to read mandatory $etcdir/$pbproj.conf.dist.md5: $!";
my $omd5 = <MD5>;
chop($omd5);
close(MD5);
open(CONF,"$etcdir/$pbproj.conf.dist") || die "Unable to read mandatory $etcdir/$pbproj.conf.dist: $!";
my $md5 = Digest::MD5->new;
binmode(CONF);
$md5->addfile(CONF);
die "Invalid MD5 found sum for $etcdir/$pbproj.conf.dist: $md5->hexdigest" if ($omd5 ne $md5->hexdigest);
close(CONF);

pb_conf_add("$etcdir/$pbproj.conf.dist");
}

=item B<mr_exit>

This function closes opened files, clean up the environment and exits MondoRescue
It takes 2 parameters, the exit code, and the message to print if needed

=cut

sub mr_exit {

my $code = shift;
my $msg = shift || "";

if (defined $msg) {
	pb_log($pbdebug,$msg);
}
die "ERROR returned\n" if ($code < 0);
exit($code);
}
