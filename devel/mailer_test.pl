#!/usr/bin/env perl
#

use strict;
use warnings;

use RapidApp::Util ':all';
use Path::Class qw/file dir/;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Rapi::Blog::Util::Mailer;


Rapi::Blog::Util::Mailer->send(
  envelope_to   => 'mm@hvs.io',
  from => 'wicket-test@vansttyn.com',
  message_file  => $ARGV[0],
  importance => 'high'
);


exit;



Rapi::Blog::Util::Mailer->send(
  envelope_to => 'mm@hvs.io',
  from    => '"Cool H" <h@hvs.io>',
  to      => ['vanstyn@intellitree.com','hvs@hvs.io'],
  cc      => 'clown@vanstyn.com',
  bcc     => 'hvanstyn@intellitree.com',
  subject => 'NEW!!!A coolm test subject',
  body => '!!!!! A more involved, but still dump message'
);








exit;




use Email::Address;





#my $adr = join(' ',@ARGV);


#my $adr = '"Henry Van Styn" <h@vanstyn.com>';

my $adr = '"Cool H" <h@hvs.io>';


scream($adr);

my @List = Email::Address->parse($adr);

scream(\@List);


for my $A (@List) {

scream({
  address => $A->address,
  original => $A->original,
  format => $A->format,
  stringify => "$A"


});

}

exit;


