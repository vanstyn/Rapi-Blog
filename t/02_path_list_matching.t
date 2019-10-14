# -*- perl -*-

# This unit test checks the matching rules that are applied to scaffold options
# like static_paths and private_paths


use strict;
use warnings;

use Test::More;
use Path::Class qw(file dir);

use_ok('Rapi::Blog::Scaffold');


sub path_list_test($$) {
  my ($list, $template) = @_;
  my $re = Rapi::Blog::Scaffold->_compile_path_list_regex(@$list);
  $template =~ $re
}


my $list1 = [qw{ css/ img/ foo }];

ok( path_list_test $list1 => 'css/foo' );
ok( path_list_test $list1 => 'css/foo/' );
ok( path_list_test $list1 => 'img/something/blah.png' );
ok( path_list_test $list1 => 'foo' );
ok( ! path_list_test $list1 => 'baz/12' );
ok( ! path_list_test $list1 => 'foos' );
ok( ! path_list_test $list1 => 'foos/apples' );
ok( ! path_list_test $list1 => 'orange/css' );


my $list2 = [qw{ css/site.css some/other/path/foo.html blah.t something.yml}];

ok( path_list_test $list2 => 'css/site.css' );
ok( path_list_test $list2 => 'some/other/path/foo.html' );
ok( path_list_test $list2 => 'blah.t' );
ok( ! path_list_test $list2 => 'public/something.yml' );

done_testing;

