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
	#ABSTRACT_FROM => 'sbin/mindi',   # retrieve abstract from module
    AUTHOR        => 'Bruno Cornec <bruno#mondorescue.org>',
	EXE_FILES     => [ qw( sbin/mindi sbin/mranalyze-lvm sbin/mrprepare-lvm ) ],
	MAN1PODS      => { 
			'sbin/mindi' => '$(INST_MAN1DIR)/mindi.$(MAN1EXT)', 
			'sbin/mranalyze-lvm' => '$(INST_MAN1DIR)/mranalyze-lvm.$(MAN1EXT)', 
			'sbin/mrprepare-lvm' => '$(INST_MAN1DIR)/mrprepare-lvm.$(MAN1EXT)', 
					},
	MAN3PODS      => {	
			'lib/MondoRescue/Mindi/LVM.pm' => '$(INST_MAN3DIR)/MondoRescue::Mindi::LVM.$(MAN3EXT)',
					},
);
