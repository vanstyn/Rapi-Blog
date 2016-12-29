package Rapi::Blog::DB::ResultSet::Content;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

sub published {
  (shift)
    ->search_rs({ 'me.published' => 1 })

}

sub newest_published_first {
  (shift)
    ->search_rs(undef,{ 
      order_by => { -desc => 'me.publish_ts' }
    })

}

# Method exposed to templates:
sub content_list {
  my ($self, $search) = @_;
  
  # TODO: define some sort of simple query API
  
  my $Rs = $self
    ->published
    ->newest_published_first
    ->search_rs(undef,{
      columns     => [qw/name    create_ts/]
    
    })
    ->search_rs(undef,{ result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
  
  # -- example of how a query could work --
  $Rs = $Rs->search_rs(
    { 'me.name' => { like => join('','%',$search,'%') } }
  ) if ($search);
  # --
  
  return [ $Rs->all ]
}


1;
