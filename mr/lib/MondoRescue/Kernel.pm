#!/usr/bin/perl -w
#
# Subroutines related to Kernel brought by the MondoRescue project
#
# $Id$
#
# Copyright B. Cornec 2008-2010
# Provided under the GPL v2

package MondoRescue::Kernel;

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
our @EXPORT = qw(mr_kernel_check);

=pod

=head1 NAME

MondoRescue::Kernel, part of the mondorescue.org

=head1 DESCRIPTION

This modules provides low level functions for Kernel support in the Mondorescue project

=head1 USAGE

=over 4

=item B<mr_kernel_check>

This function checks the kernel and returns back its version

=cut

sub mr_kernel_get_version {

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

