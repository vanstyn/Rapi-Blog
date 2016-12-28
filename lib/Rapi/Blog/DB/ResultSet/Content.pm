package Rapi::Blog::DB::ResultSet::Content;

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
      order_by => { -desc => 'me.created_ts' }
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
      columns     => [qw/name    created_ts/]
    
    })
    ->search_rs(undef,{ result_class => 'DBIx::Class::ResultClass::HashRefInflator' })
    ->all;
  
  return \@rows
}


1;
