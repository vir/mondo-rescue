use 5.006001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME		 => 'PBPKG',
	DISTNAME	 => 'PBPKG',
	VERSION	  => 'PBVER',
	INST_SCRIPT  => 'blib/bin',
	INSTALLDIRS  => 'vendor',
	PREREQ_PM	=> {
			#HTTP::Headers					=> 1.59,
			#Template						 => 0,
	},	# e.g., Module::Name => 1.1
	#ABSTRACT_FROM => 'bin/',   # retrieve abstract from module
	AUTHOR		=> 'Bruno Cornec <bruno#mondorescue.org>',
	EXE_FILES	 => [ qw( sbin/mranalyze-lvm sbin/mrcheck-lvm ) ],
	MAN1PODS	  => {
			'sbin/mranalyze-lvm' => '$(INST_MAN1DIR)/mranalyze-lvm.$(MAN1EXT)',
			'sbin/mrcheck-lvm' => '$(INST_MAN1DIR)/mranalyze-lvm.$(MAN1EXT)',
					},
	MAN3PODS	  => {	
			'lib/MondoRescue/Base.pm' => '$(INST_MAN3DIR)/MondoRescue::Base.$(MAN3EXT)',
			'lib/MondoRescue/LVM.pm' => '$(INST_MAN3DIR)/MondoRescue::LVM.$(MAN3EXT)',
			'lib/MondoRescue/Inventory.pm' => '$(INST_MAN3DIR)/MondoRescue::Inventory.$(MAN3EXT)',
			'lib/MondoRescue/DynConf.pm' => '$(INST_MAN3DIR)/MondoRescue::DynConf.$(MAN3EXT)',
				},
);

package MY;

sub postamble {

		# Determine location of etc conf files
		my $text ="";

		# Grab out any CONFDIR or other build param
		my $confdir = undef;
		my $target = undef;
		my $mandir = undef;
		my $cachedir = undef;
		my $sharedir = undef;

		while (my $arg = shift @ARGV) {
				my ($key, $value) = split /=/, $arg;
				if ($key =~ /^CONFDIR$/) {
						$confdir = $value;
				} elsif ($key =~ /^MANDIR$/) {
						$mandir = $value;
				} elsif ($key =~ /^CACHEDIR$/) {
						$cachedir = $value;
				} elsif ($key =~ /^SHAREDIR$/) {
						$sharedir = $value;
				} elsif ($key =~ /^TARGET$/) {
						$target = $value;
				}
		}

		if (not defined $target) {
			$target = "/usr/local";
			if (not defined $confdir) {
				$confdir = "$target/etc";
			}
			if (not defined $cachedir) {
				$cachedir = "$target/var/cache";
			}
		} else {
			$cachedir = $cachedir || "$target/var/cache";
			if (not defined $confdir) {
				die "CONFDIR should be defined if PREFIX is defined";
			}
			if (not defined $cachedir) {
				die "CACHEDIR should be defined if PREFIX is defined";
			}
		}
		$sharedir = $sharedir || "$target/share";
		$mandir = $mandir || "$sharedir/man";

		my $conff = "etc/PBPROJ.conf";
		open(CONF, ">> $conff") || die "Unable to append to $conff";
		print CONF << "EOF";
#
# Configuration information added at install time
#
#
# installation target
#
mr_install_dir default = $target
#
# conf dir
#
mr_conf_dir default = $confdir/PBPROJ
#
# cache directory
#
mr_cache_dir default = $cachedir/PBPROJ
#
# share directory
#
mr_share_dir default = $sharedir/PBPROJ
#
# version
#
mr_version default = PBVER-rPBREV
EOF
		close(CONF);
		# Create the dynamic content for MondoRescue
		my $dynf = "lib/MondoRescue/DynConf.pm";
		open(DYN, "> $dynf") || die "Unable to create $dynf";

		$text .= "install ::\n";
		$text .= "\t".'@echo PBPKG PBVER-rPBREV will be installed under $(DESTDIR)'."\n";
		$text .= "\t".'install -m 755 -d $(DESTDIR)'."$confdir/PBPROJ".' $(DESTDIR)'."$cachedir/PBPROJ".' $(DESTDIR)'."$sharedir/PBPROJ\n";
		$text .= "\t".'cp etc/PBPROJ.conf $(DESTDIR)'."$confdir/PBPROJ/PBPROJ.conf.dist ; install -m 755 -d ".' $(DESTDIR)'."$mandir/man5 ; pod2man etc/PBPROJ.conf > ".'$(DESTDIR)'."$mandir/man5/PBPROJ.conf.5\n";
		$text .= "\t".'md5sum $(DESTDIR)'."$confdir/PBPROJ/PBPROJ.conf.dist > ".'$(DESTDIR)'."$confdir/PBPROJ/PBPROJ.conf.dist.md5\n";
		$text .= "\t".'cp lib/MondoRescue/DynConf.pm $(DESTDIR)/$(VENDORLIBEXP)/MondoRescue/'."\n";

		# Now generate a perl module used by every other one in the project
		print DYN << "EOF";
#!/usr/bin/perl -w
#
# Declare variables for the MondoRescue project
# This module has been GENERATED at installation time
# DO NOT MODIFY WITHOUT GOOD REASONS.
#
# Copyright B. Cornec 2008
# Provided under the GPL v2
#
package MondoRescue::DynConf;

use strict 'vars';

# Inherit from the "Exporter" module which handles exporting functions.
 
use Exporter;
 
# Export, by default, all the functions into the namespace of
# any code which uses this module.
our \@ISA = qw(Exporter);
our \@EXPORT = qw(mr_dynconf_init);

=pod

=head1 NAME

MondoRescue::DynConf, part of the mondorescue.org project

=head1 DESCRIPTION

This modules provides environment variables setup for the Mondorescue project

=head1 USAGE

=over 4

=item B<mr_dynconf_init>

This function returns all the installation PATH info needed by the project
It takes no parameter and returns 2 values
First value is the conf dir
Second value is the project name

=cut

sub mr_dynconf_init {
	return("$confdir/PBPROJ","PBPROJ");
}
1;
=pod
=back 

=head1 WEB SITES

The main Web site of the project is available at L<http://www.mondorescue.org/>. Bug reports should be filled using the trac instance of the project at L<http://trac.mondorescue.org/>.

=head1 USER MAILING LIST

The mailing list of the project is available at L<mailto:mondo\@lists.sf.net>

=head1 AUTHORS

The Mondorescue.org team L<http://www.mondorescue.org/> lead by Bruno Cornec L<mailto:bruno\@mondorescue.org>.

=head1 COPYRIGHT

mrmini is distributed under the GPL v2.0 license
described in the file C<COPYING> included with the distribution.

=cut


EOF
	close(DYN);
	return($text);
}
