#!/usr/bin/env perl
#

# This script is designed specifically to import posts from frew's blog
# https://blog.afoolishmanifesto.com/ which he have me permission to use for
# TPC 2017 demo

use strict;
use warnings;

use RapidApp::Util ':all';
use Path::Class qw/file dir/;

use YAML::XS 0.64 qw/LoadFile Load/;
use DateTime;

use FindBin;
use lib "$FindBin::Bin/../lib";

my $today = DateTime->now( time_zone => 'local' )->ymd('-');

my $HugoDir = dir( "$FindBin::Bin/external_data/frew_blog/content/posts" )->resolve;

my $dir = $ARGV[0] or die "missing site_path argument";

$dir = dir( $dir )->resolve->absolute->stringify;

use Rapi::Blog;

my $Blog = Rapi::Blog->new({ site_path => $dir });

$Blog->to_app; # init

my $Rs = $Blog->base_appname->model('DB::Post');

my $User = $Blog->base_appname->model('DB::User')
  ->find_or_create({
    username => 'frew',
    full_name => 'fREW Schmidt',
    author => 1, admin => 0, comment => 1
  },{ key => 'username_unique' });


my $uid = $User->id;

my @posts = sort { $a->{date} cmp $b->{date} } &_posts;
for my $post (@posts) {
  print "\n  $post->{name} :   ";

  $Rs->search_rs({ name => $post->{name} })->count > 0 and print "exists" and next;
  
  my $content = $post->{body} or die "no body";
  
  my $packet = {
    name => $post->{name},
    title => $post->{title},
    author_id  => $uid,
    creator_id => $uid,
    updater_id => $uid,
    body => $content,
    published => 1,
    ts => join(' ',$post->{date},'12:00:00')
  };

  try {
    $Rs->create($packet) and print "created";
  }
  catch { warn RED.BOLD . $_ . CLEAR };

}



print "\n\n";




########################################

sub _posts {

  my @posts = ();

  $HugoDir->recurse(
    preorder => 1,
    callback => sub {
      my $File = shift;
      if (-f $File && $File =~ /\.md$/) {
        try{
          my @parts = split(/\r?\n---\r?\n/,$File->slurp);
          my $meta = Load($parts[0]);
          my $body = $parts[1];
          
          die "no body!" unless ($body);
          
          # strip hugo tpl directives:
          $body =~ s/\{\{.*?\}\}//g;
          
          my $date = $meta->{date} ? substr $meta->{date}, 0, 10 : $today;
          my $name = $File->basename;
          my $title = $meta->{title};
          $title ||= $name;
          
          my @tags = uniq(map {
            $_ =~ s/\s+/\-/;
            "\#$_"
          } (@{$meta->{tags}||[]}) );
          
          $body .= "\n\ntags: " . join(' ', @tags) if(scalar(@tags) > 0);
          
          if (my $orig = ($meta->{aliases}||[])->[0]) {
            my $url = join('https://blog.afoolishmanifesto.com',$orig);
            $body .= join('',
              "\n\n<i style='font-size:.8em;'>original post: ",
              "<a target='_blank' href='$url'>$url</a></i>"
            );
          }
          
          push @posts, { name => $name, title => $title, date => $date, body => $body };
        
        }
        catch {
          warn $File->basename . ': ' .RED.BOLD . "$_\n" . CLEAR;
        };
      }
    }
  );
  
  return @posts
}

