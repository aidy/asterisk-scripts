#!/usr/bin/perl

use strict;
use warnings;
use Asterisk::AGI;
use WWW::Mechanize;
use WWW::Mechanize::TreeBuilder;

sub exit_with_error {
    my ($agi, $error) = @_;

    $agi->noop("Error: $error");
    $agi->answer;
    $agi->exec('Flite', $error);
    sleep(1);
    $agi->hangup;
    exit;
}

my $AGI = Asterisk::AGI->new();

my $mech = WWW::Mechanize->new();
WWW::Mechanize::TreeBuilder->meta->apply($mech);

my $number = $AGI->get_variable('EXTEN');

my $response = $mech->get('http://www.saynoto0870.com/search.php');

unless ($response->is_success) {
    exit_with_error($AGI, "Unable to connect to say no to 0 8 7 0");
}

$response = $mech->submit_form( with_fields => { number => $number } );

unless ($response->is_success) {
    exit_with_error($AGI, "Unable to perform search on say no to 0 8 7 0");
}

my @tables = $mech->look_down( class => 'catbg', _tag => 'td', sub { $_[0]->as_text eq 'Main Database' } );

unless (scalar @tables) {
    exit_with_error($AGI, "No results for that number or error parsing results");
}

my $table =  $tables[0]->parent->parent;

my @numbers = $table->look_down( bgcolor => '#FFFFCC' );

unless (scalar @numbers > 5) {
    exit_with_error($AGI, "No results for that number or error parsing results");
}
# 1 - 0870
# 2 - 0844/045
# 3 - 01/02/03
# 4 - Freephone

my $national = $numbers[3]->as_trimmed_text;
my $freephone = $numbers[4]->as_trimmed_text;

$national =~ s/\D//g;
$freephone =~ s/\D//g;

$freephone = "" unless $freephone =~ m/^(0800|0808|0500)/;
$national = "" unless $national =~ m/^0[1-3]/;

unless ($freephone || $national ) {
    exit_with_error($AGI, "No free phone or national number found");
}

$AGI->noop("Dialing " . ($freephone || $national) . " in place of $number");
$AGI->set_extension($freephone || $national);
$AGI->set_priority(1);
