#!/usr/bin/perl -w
use strict;
use diagnostics;
use UI::Dialog;

my $mrui = "UI::Dialog";
my @mrui_opt = (
		backtitle => 'Mindi', 
		title => 'Mindi',
		height => 24, 
		width => 80, 
		listheight => 5,
		debug => 0,
		order => [ 'gdialog', 'xdialog', 'whiptail', 'cdialog', 'ascii' ]
);

my $d = new $mrui ( @mrui_opt );

$d->infobox( text => [ "This message box is provided by one of the following: zenity, Xdialog or gdialog. ",
					  "(Or if from a console: dialog, whiptail, ascii)" ] );

sleep(3);

my $d2 = new $mrui ( title => "Mindi",
						 debug => 0, height => 20, width => 75 );

$d2->yesno( text => [ "Are you OK. " ] );

$d->infobox( text => [ "This message box is provided by one of the following: zenity, Xdialog or gdialog. ",
					  "(Or if from a console: dialog, whiptail, ascii)" ] );
