package Rapi::Blog::DB::ResultSet::Post;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

sub published {
  (shift)
    ->search_rs({ 'me.published' => 1 })

}

sub newest_first {
  (shift)
    ->search_rs(undef,{ 
      order_by => { -desc => 'me.ts' }
    })
}

sub newest_published_first {
  (shift)
    ->search_rs(undef,{ 
      order_by => { -desc => 'me.publish_ts' }
    })
}

sub _all_columns_except {
  my ($self, @exclude) = @_;
  scalar(@exclude) > 0 or return $self;
  
  my %excl = map {$_=>1} @exclude;
  my @cols = grep { ! $excl{$_} } $self->result_source->columns;

  $self->search_rs(undef,{ columns => \@cols });
}


# Method exposed to templates:
sub list_posts {
  my ($self, $search, $tag) = @_;
  
  # TODO: define some sort of simple query API
  
  my $Rs = $self
    ->published
    ->newest_first
    ->_all_columns_except('body');
  
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
