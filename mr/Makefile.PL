use 5.006001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'PBPKG',
    DISTNAME     => 'PBPKG',
    VERSION      => 'PBVER',
    INST_SCRIPT  => 'blib/bin',
	INSTALLDIRS  => 'perl',
    PREREQ_PM    => {
			#HTTP::Headers                    => 1.59,
			#Template                         => 0,
    },    # e.g., Module::Name => 1.1
	#ABSTRACT_FROM => 'bin/',   # retrieve abstract from module
    AUTHOR        => 'Bruno Cornec <bruno#mondorescue.org>',
	EXE_FILES     => [ qw( sbin/mranalyze-lvm sbin/mrcheck-lvm ) ],
	MAN1PODS      => { 
			'sbin/mranalyze-lvm' => '$(INST_MAN1DIR)/mranalyze-lvm.$(MAN1EXT)', 
			'sbin/mrcheck-lvm' => '$(INST_MAN1DIR)/mranalyze-lvm.$(MAN1EXT)', 
					},
	MAN3PODS      => {	
						'lib/MondoRescue/Base.pm' => '$(INST_MAN3DIR)/MondoRescue::Base.$(MAN3EXT)', 
						'lib/MondoRescue/LVM.pm' => '$(INST_MAN3DIR)/MondoRescue::LVM.$(MAN3EXT)', 
						'lib/MondoRescue/Inventory.pm' => '$(INST_MAN3DIR)/MondoRescue::Inventory.$(MAN3EXT)', 
				},
);
