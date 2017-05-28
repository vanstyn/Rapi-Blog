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
  my ($self, @args) = @_;
  
  my %P = ();
  if((ref($args[0])||'') eq 'HASH') {
    # Our caller has supplied arguments already as name/values:
    %P = %{ $args[0] };
  } 
  else {
    # Also support ordered list arguments:
    ($P{search}, $P{tag}, $P{page}, $P{limit}) = @args;
  }
  
  $P{limit} = 500 unless ($P{limit} && $P{limit} =~ /^\d+$/);
  $P{page}  = 1   unless ($P{page}  && $P{page}  =~ /^\d+$/);

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
  
  my @rows = ();
  my $pages = 1;

  my $total = $Rs->_safe_count;
  if($total > 0) {
    my $pages = int($total/$P{limit});
    $pages++ if ($total % $P{limit});
  }
  
  $P{page} = $pages if ($P{page} > $pages);
  
  @rows = $Rs
    ->search_rs(undef,{ page => $P{page}, rows => $P{limit} })
    ->all if ($total > 0);
    
  my $count = (scalar @rows);
  
  my $thru = $P{page} == 1 ? $count : ($P{page}-1) * $P{limit} + $count;
  my $remaining = $total - $thru;
  
  my $last_page = $P{page} == $pages ? 1 : 0;
  
  return {
    # ArrayRef of Posts (this page)
    rows      => \@rows,
    
    # Number of Posts returned (this page)
    count     => $count,
    
    # Total number of posts (all pages)
    total     => $total,
    
    # Page number of current page
    page      => $P{page},
    
    # Total number of pages
    pages     => $pages,
    
    # True is the current page is the last page
    last_page => $P{page} == $pages ? 1 : 0,
    
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
    limit     => $P{limit}
  }
}


sub _safe_count {
  my $self = shift;
  
  # There seems to be a DBIC bug in count -
  # Get errors like: 
  #  Single parameters to new() must be a HASH ref data => DBIx::Class::ResultSource::Table=HASH(0xc8ce240)
  # When we try to call ->count when we have { join => 'post_tags', group_by => 'me.id' } in the attrs.
  # The line which is barfing is:
  #  https://metacpan.org/source/RIBASUSHI/DBIx-Class-0.082840/lib/DBIx/Class/ResultSet.pm#L3389
  # Which is DBIC trying to create a fresh_rs where it passes $self->result_source to ->new() so
  # it seems to be an internal inconsistency. I don't have time to deal with it now so I created this
  # ugly fallback for now. FIXME
  
  
  my $count = try{ $self->count };
  return $count if (defined $count);
  
  # Do a manual query and count the results, but try to make it least expensive as possible
  my @rows = $self->search_rs(undef, {
    columns => [], select => ['me.id'], as => ['id'],
    result_class => 'DBIx::Class::ResultClass::HashRefInflator'
  })->all;
  
  return scalar(@rows);
}


1;
