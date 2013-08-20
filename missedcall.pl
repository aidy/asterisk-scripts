#!/usr/bin/perl

use strict;
use warnings;
use Asterisk::AGI;
use Email::Sender::Simple qw(sendmail);
use Email::Sender::Transport::SMTP::TLS;

my @recipients = ('x@y.com');

my $AGI = Asterisk::AGI->new();

my $dialstatus = $AGI->get_variable("DIALSTATUS");
my $callerid = $AGI->get_variable("CALLERID(all)");
my ($number) = ($callerid =~ m/<(.*)>/);

exit if $dialstatus eq 'ANSWER';

my $transport = Email::Sender::Transport::SMTP::TLS->new(
    host        => 'smtp.gmail.com',
    port        => 587,
    username    => '',
    password    => '',
);


my $message = Email::Simple->create(
    header => [
        From => 'Missed call',
        Subject => "Missed call from $number",
    ],
    body => "Missed call from $callerid",
);

$message->header_set( To  => @recipients );

sendmail( $message, { transport => $transport });
