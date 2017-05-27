#!/usr/bin/env bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

eval "$dir/model_DB_updater.pl --all --go"
eval "cp $dir/../rapi_blog.db $dir/../examples/site-one/"
eval "$dir/create_test_posts.pl $dir/../examples/site-one/"
eval "$dir/import_hugo_posts.pl $dir/../examples/site-one/"
