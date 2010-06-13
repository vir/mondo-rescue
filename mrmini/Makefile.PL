use 5.006001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'PBPKG',
    DISTNAME     => 'PBPKG',
    VERSION      => 'PBVER',
    INST_SCRIPT  => 'blib/sbin',
	INSTALLDIRS  => 'perl',
    PREREQ_PM    => {
			#HTTP::Headers                    => 1.59,
			#Template                         => 0,
    },    # e.g., Module::Name => 1.1
	#ABSTRACT_FROM => 'sbin/mrmini',   # retrieve abstract from module
    AUTHOR        => 'Bruno Cornec <bruno#mondorescue.org>',
	EXE_FILES     => [ qw( sbin/mrmini sbin/mrprepare-lvm ) ],
	MAN1PODS      => { 
			'sbin/mrmini' => '$(INST_MAN1DIR)/mrmini.$(MAN1EXT)', 
			'sbin/mrprepare-lvm' => '$(INST_MAN1DIR)/mrprepare-lvm.$(MAN1EXT)', 
					},
	#MAN3PODS      => {	
			#'lib/MondoRescue/Mini/LVM.pm' => '$(INST_MAN3DIR)/MondoRescue::Mini::LVM.$(MAN3EXT)',
			#},
);
