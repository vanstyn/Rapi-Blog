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
  from    => 'mail-test@intellitree.com',
  to      => 'vanstyn@intellitree.com',
  subject => 'A coolm test subject',
  body => 'A dumb body'
);
