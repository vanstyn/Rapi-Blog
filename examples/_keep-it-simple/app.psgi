BEGIN {
  use Path::Class qw/file dir/;
  $Bin = file($0)->parent->parent->parent->stringify; # Like FindBin  
}

use lib "$Bin/lib";
use Rapi::Blog;

use Path::Class qw/file dir/;
my $dir = file($0)->parent->stringify;

my $app = Rapi::Blog->new({
  site_path     => $dir,
  scaffold_path => "$dir/scaffold" 
  
});
 
# Plack/PSGI app:
$app->to_app
