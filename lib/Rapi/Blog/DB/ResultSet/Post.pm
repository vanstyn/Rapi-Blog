package Rapi::Blog::DB::ResultSet::Post;

use strict;
use warnings;

use Moo;
extends 'DBIx::Class::ResultSet';

use RapidApp::Util ':all';

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


__PACKAGE__->load_components('+Rapi::Blog::DB::Component::ResultSet::ListAPI');

sub _default_limit { 20 }
sub _default_page  { 1 }
sub _param_arg_order { [qw/search tag page limit/] } 

# Method exposed to templates:

sub list_posts {
  my ($self, @args) = @_;
  
  my %P = %{ $self->_list_api_params(@args) };
  
  my $Rs = $self
    ->published
    ->newest_first
    ->_all_columns_except('body')
    ->search_rs(undef, { 
      join     => 'post_tags',
      group_by => 'me.id'
    })
  ;
  
  if($P{search}) {
    my $as_tag = $P{search};
    $as_tag =~ s/\s+/\-/g;
    $as_tag =~ s/\_/\-/g;
    
    $Rs = $Rs->search_rs({ -or => [
      { 'post_tags.tag_name' => lc($as_tag) },
      { 'me.name'    => { like => join('','%',$P{search},'%') } },
      { 'me.summary' => { like => join('','%',$P{search},'%') } },
      { 'me.body'    => { like => join('','%',$P{search},'%') } }
    ]});
  }
  
  $Rs = $Rs->search_rs({ 'post_tags.tag_name' => $P{tag} }) if ($P{tag});
  
  return $Rs->_list_api
}


1;
