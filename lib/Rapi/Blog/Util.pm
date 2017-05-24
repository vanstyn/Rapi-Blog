package Rapi::Blog::Util;

use strict;
use warnings;

use DateTime;

sub now_ts {
  my $dt = DateTime->now( time_zone => 'local' );
  join(' ',$dt->ymd('-'),$dt->hms(':'));
}

sub get_uid {
  if(my $c = RapidApp->active_request_context) {
    return $c->user->linkedRow->id if ($c->can('user'));
  }
  return 0;
}

1;
