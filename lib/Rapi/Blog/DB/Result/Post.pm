use utf8;
package Rapi::Blog::DB::Result::Post;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime");
__PACKAGE__->table("post");
__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "title",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "image",
  {
    data_type => "varchar",
    default_value => \"null",
    is_nullable => 1,
    size => 255,
  },
  "ts",
  {
    data_type     => "datetime",
    default_value => \"datetime(CURRENT_TIMESTAMP,'localtime')",
    is_nullable   => 0,
  },
  "create_ts",
  {
    data_type     => "datetime",
    default_value => \"datetime(CURRENT_TIMESTAMP,'localtime')",
    is_nullable   => 0,
  },
  "update_ts",
  {
    data_type     => "datetime",
    default_value => \"datetime(CURRENT_TIMESTAMP,'localtime')",
    is_nullable   => 0,
  },
  "author_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "creator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "updater_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "pp_code",
  {
    data_type => "varchar",
    default_value => \"null",
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "format_code",
  {
    data_type => "varchar",
    default_value => \"null",
    is_foreign_key => 1,
    is_nullable => 1,
    size => 8,
  },
  "published",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "publish_ts",
  { data_type => "datetime", default_value => \"null", is_nullable => 1 },
  "body",
  { data_type => "text", default_value => "", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("name_unique", ["name"]);
__PACKAGE__->belongs_to(
  "author",
  "Rapi::Blog::DB::Result::User",
  { id => "author_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "creator",
  "Rapi::Blog::DB::Result::User",
  { id => "creator_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);
__PACKAGE__->belongs_to(
  "format_code",
  "Rapi::Blog::DB::Result::Format",
  { code => "format_code" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->has_many(
  "post_keywords",
  "Rapi::Blog::DB::Result::PostKeyword",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "pp_code",
  "Rapi::Blog::DB::Result::Preprocessor",
  { code => "pp_code" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "RESTRICT",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->belongs_to(
  "updater",
  "Rapi::Blog::DB::Result::User",
  { id => "updater_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-04-17 16:58:50
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/lF9fAwYOVQQLrF6dZBYgg

use RapidApp::Util ':all';

sub get_uid {
  my $self = shift;
  
  if(my $c = RapidApp->active_request_context) {
    return $c->user->id if ($c->can('user'));
  }
  
  return 0;
}

sub insert {
  my $self = shift;
  my $columns = shift;
  $self->set_inflated_columns($columns) if $columns;
  
  my $uid = $self->get_uid;
  $self->creator_id( $uid );
  $self->updater_id( $uid );
  
  $self->_set_column_defaults;

  $self->next::method;
}

sub update {
  my $self = shift;
  my $columns = shift;
  $self->set_inflated_columns($columns) if $columns;
  
  my $uid = $self->get_uid;
  $self->updater_id( $uid );
  
  $self->_set_column_defaults;

  $self->next::method;
}



sub _set_column_defaults {
  my $self = shift;
  
  # defualt title:
  $self->title($self->name) unless $self->title;
  
  if ($self->published) {
    $self->publish_ts(\"datetime(CURRENT_TIMESTAMP,'localtime')") unless $self->publish_ts;
  }
  else {
    $self->publish_ts(undef) if $self->publish_ts;
  }
  


}




# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
