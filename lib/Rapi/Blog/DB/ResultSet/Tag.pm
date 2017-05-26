package Rapi::Blog::DB::ResultSet::Tag;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

__PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

sub most_used {
  my $self = shift;
  
  $self
    ->search_rs(undef, { 
      order_by => { '-desc' => $self->correlate('post_tags')->count_rs->as_query },
    })
}


# Method exposed to templates:
sub list_tags {
  my ($self, $search, $post_id) = @_;
    
  my $Rs = $self
    ->most_used
    ->search_rs(undef,{ '+columns' => {
      # pre-load 'posts_count' -- the Row class will use it (see Result::Tag)
      posts_count => $self->correlate('post_tags')->count_rs->as_query
    }});
    
  $Rs = $Rs->search_rs(
    { 'post_tags.post_id' => $post_id },
    { join => 'post_tags' }
  ) if ($post_id);
  
  $Rs = $Rs->search_rs(
    { 'me.name' => { like => join('','%',$search,'%') } }
  ) if ($search);
  
  return [ $Rs->all ]
}


1;
