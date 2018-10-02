package Rapi::Blog::Util;

use strict;
use warnings;

use RapidApp::Util ':all';

use DateTime;

sub now_ts { &dt_to_ts( &now_dt ) }
sub now_dt { DateTime->now( time_zone => 'local' ) }

sub dt_to_ts {
  shift if ($_[0] && $_[0] eq __PACKAGE__);
  my $dt = shift;
  join(' ',$dt->ymd('-'),$dt->hms(':'));
}

sub get_uid {
  if(my $c = RapidApp->active_request_context) {
    return $c->user->linkedRow->id if ($c->can('user') && $c->user && $c->user->linkedRow);
  }
  return 0;
}

sub get_User {
  if(my $c = RapidApp->active_request_context) {
    return $c->user->linkedRow if ($c->can('user') && $c->user);
  }
  return undef;
}

1;
