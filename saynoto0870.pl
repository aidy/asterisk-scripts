#!/usr/bin/perl

use strict;
use warnings;
use Asterisk::AGI;
use HTML::TreeBuilder::LibXML;
use LWP::UserAgent;

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
my $ua = LWP::UserAgent->new();

my $number = $AGI->get_variable('EXTEN');

my $response = $ua->post('http://www.saynoto0870.com/numbersearch.php', { number => $number } );

unless ($response->is_success) {
    exit_with_error($AGI, "Unable to connect to say no to 0 8 7 0");
}

my $tree = HTML::TreeBuilder::LibXML->new();
$tree->parse( $response->decoded_content );

my $new_number;

foreach ($tree->findnodes("//div[\@class='boardcontainer']/table[1]/tr/td[\@bgcolor='#FFFFCC'][5]")) {
    $new_number = $_->as_trimmed_text;
    $new_number =~ s/\D//g;
    $new_number = "" unless $new_number =~ m/^(0800|0808|0500)/;

    last if $new_number
}

unless ($new_number) {
    foreach ($tree->findnodes("//div[\@class='boardcontainer']/table[1]/tr/td[\@bgcolor='#FFFFCC'][4]")) {
        $new_number = $_->as_trimmed_text;
        $new_number =~ s/\D//g;
        $new_number = "" unless $new_number =~ m/^0[1-3]/;

        last if $new_number
    }

}

unless ($new_number) {
    exit_with_error($AGI, "No free phone or national number found");
}

$AGI->noop("Dialing $new_number in place of $number");
$AGI->set_extension($new_number);
$AGI->set_priority(1);
