package Rapi::Blog::DB::ResultSet::Post;

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
sub list_posts {
  my ($self, $search, $tag) = @_;
  
  # TODO: define some sort of simple query API
  
  my $Rs = $self
    ->published
    ->newest_published_first
    #->search_rs(undef,{
    #  columns     => [qw/name    create_ts/]
    #
    #})
    ->search_rs(undef,{ result_class => 'DBIx::Class::ResultClass::HashRefInflator' });
  
  # -- example of how a query could work --
  $Rs = $Rs->search_rs(
    { 'me.name' => { like => join('','%',$search,'%') } }
  ) if ($search);
  # --
  
  $Rs = $Rs->search_rs(
    { 'post_tags.tag_name' => $tag },
    { join => 'post_tags' }
  ) if ($tag);
  
  return [ $Rs->all ]
}


1;
