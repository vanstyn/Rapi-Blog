#!/usr/bin/env bash

dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

eval "$dir/model_DB_updater.pl --all --go"
eval "cp $dir/../rapi_blog.db $dir/../examples/site-one/"

