package Rapi::Blog::DB::ResultSet::ContentName;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

sub published {
  (shift)
    ->search_rs({ 'me.published' => 1 })

}

sub newest_created_first {
  (shift)
    ->search_rs(undef,{ 
      join => ['content'],
      order_by => { -desc => 'content.created_ts' }
    })

}

# Method exposed to templates:
sub content_list {
  my ($self, $query) = @_;
  
  # TODO: define some sort of simple query API
  
  
  my @rows = $self
    ->published
    ->newest_created_first
    ->search_rs(undef,{
      select => [qw/me.name content.created_ts/],
      as     => [qw/name    created_ts/]
    
    })
    ->search_rs(undef,{ result_class => 'DBIx::Class::ResultClass::HashRefInflator' })
    ->all;
  
  return \@rows
}


1;
