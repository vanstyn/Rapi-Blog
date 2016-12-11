use strict;
use warnings;

use Rapi::Blog;

my $app = Rapi::Blog->apply_default_middlewares(Rapi::Blog->psgi_app);
$app;

