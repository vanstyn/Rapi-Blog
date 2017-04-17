use utf8;
package Rapi::Blog::DB::Result::Preprocessor;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("preprocessor");
__PACKAGE__->add_columns(
  "code",
  { data_type => "varchar", is_nullable => 0, size => 8 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 32 },
);
__PACKAGE__->set_primary_key("code");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);
__PACKAGE__->has_many(
  "posts",
  "Rapi::Blog::DB::Result::Post",
  { "foreign.pp_code" => "self.code" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-04-17 07:32:05
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:v17UijJD6EpIxvjmT5hsPg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
