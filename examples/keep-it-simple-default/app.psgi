BEGIN {
  use Path::Class qw/file dir/;
  $Bin = file($0)->parent->parent->parent->stringify; # Like FindBin  
}

use lib "$Bin/lib";
use Rapi::Blog;

use Path::Class qw/file dir/;

my $site_dir     = file($0)->parent;

my $scaffold_dir = $site_dir
  ->parent->parent
  ->subdir('share/scaffolds/keep-it-simple')
  ->resolve;

my $app = Rapi::Blog->new({
  site_path     => $site_dir->stringify,
  scaffold_path => $scaffold_dir->stringify
});
 
# Plack/PSGI app:
$app->to_app
