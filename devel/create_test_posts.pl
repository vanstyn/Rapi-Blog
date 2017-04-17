#!/usr/bin/env perl
#

use strict;
use warnings;

use RapidApp::Util ':all';
use Path::Class qw/file dir/;

use FindBin;
use lib "$FindBin::Bin/../lib";

my $PostDir = dir( "$FindBin::Bin/test_posts" )->resolve;

my $dir = $ARGV[0] or die "missing site_path argument";

use Rapi::Blog;

my $Blog = Rapi::Blog->new({ site_path => $dir });

$Blog->to_app; # init

my $Rs = $Blog->base_appname->model('DB::Post');


my $uid = 0;

my @posts = sort { $a->{date} cmp $b->{date} } &_posts;
for my $post (@posts) {
  print "\n  $post->{name} :   ";

  $Rs->search_rs({ name => $post->{name} })->count > 0 and print "exists" and next;
  
  my $File = $PostDir->file( $post->{name} )->resolve;
  my $content = $File->slurp;
  
  $Rs->create({
    name => $post->{name},
    title => $post->{title},
    author_id  => $uid,
    creator_id => $uid,
    updater_id => $uid,
    body => $content,
    published => 1,
    ts => join(' ',$post->{date},'12:00:00')
  }) and print "created";

}



print "\n\n";




########################################

sub _posts {(
  { date => '2014-03-24', name => 'emscripten.md',          title => 'Emscripten'   },
  { date => '2015-01-21', name => 'gotalk.md',              title => 'Gotalk'       },
  { date => '2016-03-14', name => 'marked.md',              title => 'marked'       },
  { date => '2016-03-14', name => 'metacpan-readme.md',     title => 'Web interface for MetaCPAN (README)' },
  { date => '2017-02-14', name => 'reveal.js.md',           title => 'reveal.js'    },
  { date => '2017-02-15', name => 'metacpan-dev-readme.md', title => 'MetaCPAN Developer (README)' },
  { date => '2017-03-29', name => 'mosh.md',                title => 'Mosh: the mobile shell'  },
  { date => '2017-04-14', name => 'jsoneditor.md',          title => 'JSON Editor'  },


)}

