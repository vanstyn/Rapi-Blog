package Rapi::Blog::DB::ResultSet::Tag;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';

__PACKAGE__->load_components(qw(Helper::ResultSet::CorrelateRelationship));

sub most_used {
  my $self = shift;
  
  $self
    ->search_rs(undef, { 
      order_by => { '-desc' => $self->correlate('post_tags')->count_rs->as_query },
    })
}


__PACKAGE__->load_components('+Rapi::Blog::DB::Component::ResultSet::ListAPI');

sub _default_limit { 200 }
sub _default_page  { 1 }
sub _param_arg_order { [qw/search post_id/] } 


# Method exposed to templates:
sub list_tags {
  my ($self, @args) = @_;
  
  my %P = %{ $self->_list_api_params(@args) };
  
  my $Rs = $self
    ->most_used
    ->search_rs(undef,{ '+columns' => {
      # pre-load 'posts_count' -- the Row class will use it (see Result::Tag)
      posts_count => $self->correlate('post_tags')->count_rs->as_query
    }});
    
  $Rs = $Rs->search_rs(
    { 'post_tags.post_id' => $P{post_id} },
    { join => 'post_tags' }
  ) if ($P{post_id});
  
  $Rs = $Rs->search_rs(
    { 'me.name' => { like => join('','%',$P{search},'%') } }
  ) if ($P{search});
  
  return $Rs->_list_api->{rows};
}


1;
