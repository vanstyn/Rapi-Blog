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


# Method exposed to templates:
sub list_posts {
  my ($self, $search, $tag, $page, $limit) = @_;
  
  # support alternate hashref named key/val argument
  if(ref($search) && ref($search) eq 'HASH') {
    my $h = $search;
    ($search, $tag, $page, $limit) = ($h->{search}, $h->{tag}, $h->{page}, $h->{limit});
  }
  
  $limit = 500 unless ($limit && $limit =~ /^\d+$/);
  $page  = 1   unless ($page  && $page  =~ /^\d+$/);

  my $Rs = $self
    ->published
    ->newest_first
    ->_all_columns_except('body')
    ->search_rs();
  
  # -- example of how a query could work --
  $Rs = $Rs->search_rs(
    { 'me.name' => { like => join('','%',$search,'%') } }
  ) if ($search);
  # --
  
  $Rs = $Rs->search_rs(
    { 'post_tags.tag_name' => $tag },
    { join => 'post_tags' }
  ) if ($tag);
  
  my @rows = ();
  my $pages = 1;

  my $total = $Rs->count;
  if($total > 0) {
    my $pages = int($total/$limit);
    $pages++ if ($total % $limit);
  }
  
  $page  = $pages if ($page > $pages);
  
  @rows = $Rs
    ->search_rs(undef,{ page => $page, rows => $limit })
    ->all if ($total > 0);
    
  my $count = (scalar @rows);
  
  my $thru = $page == 1 ? $count : ($page-1) * $limit + $count;
  my $remaining = $total - $thru;
  
  my $last_page = $page == $pages ? 1 : 0;
  
  return {
    # ArrayRef of Posts (this page)
    rows      => \@rows,
    
    # Number of Posts returned (this page)
    count     => $count,
    
    # Total number of posts (all pages)
    total     => $total,
    
    # Page number of current page
    page      => $page,
    
    # Total number of pages
    pages     => $pages,
    
    # True is the current page is the last page
    last_page => $page == $pages ? 1 : 0,
    
    # True if this page already contains all Posts
    complete  => $total == $count ? 1 : 0,
    
    # The number (out of total Posts) this page starts at
    start     => $thru - $count + 1,
    
    # The number (out of total Posts) this page ends at
    end       => $thru,
    
    # The number of Posts remaining after this page
    remaining => $remaining,
    
    # The number of Posts in all the pages before this one
    before    => $thru - $count,
    
    # The limit of Posts per page
    limit     => $limit
  }
}


1;
