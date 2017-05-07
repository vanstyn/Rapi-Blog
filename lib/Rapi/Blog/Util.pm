package Rapi::Blog::Util;

use strict;
use warnings;

use DateTime;

sub now_ts {
  my $dt = DateTime->now( time_zone => 'local' );
  join(' ',$dt->ymd('-'),$dt->hms(':'));
}


1;
