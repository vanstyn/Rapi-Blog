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
  { data_type => "datetime", is_nullable => 0 },
  "create_ts",
  { data_type => "datetime", is_nullable => 0 },
  "update_ts",
  { data_type => "datetime", is_nullable => 0 },
  "author_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "creator_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "updater_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "published",
  { data_type => "boolean", default_value => 0, is_nullable => 0 },
  "publish_ts",
  { data_type => "datetime", default_value => \"null", is_nullable => 1 },
  "size",
  { data_type => "integer", default_value => \"null", is_nullable => 1 },
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
__PACKAGE__->has_many(
  "comments",
  "Rapi::Blog::DB::Result::Comment",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "creator",
  "Rapi::Blog::DB::Result::User",
  { id => "creator_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);
__PACKAGE__->has_many(
  "post_keywords",
  "Rapi::Blog::DB::Result::PostKeyword",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "updater",
  "Rapi::Blog::DB::Result::User",
  { id => "updater_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-24 12:06:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:gmulIrHT79xDd7DaXgRo7w

__PACKAGE__->has_many(
  "direct_comments",
  "Rapi::Blog::DB::Result::Comment",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0, where => { parent_id => undef } },
);

__PACKAGE__->many_to_many( 'keywords', 'post_keywords', 'keyword_name' );

use RapidApp::Util ':all';
use Rapi::Blog::Util;

sub schema { (shift)->result_source->schema }
# This relies on us having been loaded via RapidApp::Util::Role::ModelDBIC
sub parent_app_class { (shift)->schema->_ra_catalyst_origin_model->app_class }
sub Access { (shift)->parent_app_class->template_controller->Access }

sub public_url_path {
  my $self = shift;
  $self->{_public_url_path} //= do {
    my $app = $self->parent_app_class;
    my $path = join('',$app->mount_url,'/',$self->Access->default_view_path);
    $path =~ s/\/?$/\//; # make sure there is a trailing '/';
    $path
  }
}

sub public_url {
  my $self = shift;
 return join('',$self->public_url_path,$self->name)
}


sub insert {
  my $self = shift;
  my $columns = shift;
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_set_column_defaults('insert');

  $self->next::method;
  
  $self->_update_keywords;
  
  return $self;
}

sub update {
  my $self = shift;
  my $columns = shift;
  $self->set_inflated_columns($columns) if $columns;
  
  my $uid = Rapi::Blog::Util->get_uid;
  $self->updater_id( $uid );
  
  $self->_set_column_defaults('update');
  
  $self->_update_keywords if ($self->is_column_changed('body'));
  
  $self->next::method;
}



sub _set_column_defaults {
  my $self = shift;
  my $for = shift || '';
  
  # default title:
  $self->title($self->name) unless $self->title;
  $self->size( length $self->get_column('body') );
  
  my $uid = Rapi::Blog::Util->get_uid;
  my $now_ts = Rapi::Blog::Util->now_ts;
  
  if ($self->published) {
    $self->publish_ts($now_ts) unless $self->publish_ts;
  }
  else {
    $self->publish_ts(undef) if $self->publish_ts;
  }
  
  $self->update_ts($now_ts);
  $self->updater_id( $uid );
  $self->author_id( $uid ) unless $self->author_id;
  
  if($for eq 'insert') {
    $self->create_ts($now_ts);
    $self->creator_id( $uid );
  }

}

sub _update_keywords {
  my $self = shift;
  
  # normalized list of keywords, lowercased and _ converted to -
  my @kw = uniq(
    map { $_ =~ s/\_/\-/g; lc($_) } 
    $self->_extract_hashtags
  );

  $self->set_keywords([ map {{ name => $_ }} @kw ]);
}


sub _parse_social_entities {
  my $self = shift;
  my $body = $self->body or return ();
  
  my @ents = $body =~ /(?:^|\s)([#@][-\w]{1,64})\b/g;
  
  return uniq(@ents)
}

sub _extract_hashtags {
  my $self = shift;
  map { $_ =~ s/^#//; $_ } grep { $_ =~ /^#/ } $self->_parse_social_entities
}





# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
