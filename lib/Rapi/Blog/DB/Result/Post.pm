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
  "custom_summary",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
  "summary",
  { data_type => "text", default_value => \"null", is_nullable => 1 },
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
  "hits",
  "Rapi::Blog::DB::Result::Hit",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "post_tags",
  "Rapi::Blog::DB::Result::PostTag",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "updater",
  "Rapi::Blog::DB::Result::User",
  { id => "updater_id" },
  { is_deferrable => 0, on_delete => "RESTRICT", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2017-05-28 12:05:29
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dbSY8wLT8DI4YvczNjpgsA

__PACKAGE__->has_many(
  "direct_comments",
  "Rapi::Blog::DB::Result::Comment",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0, where => { parent_id => undef } },
);

__PACKAGE__->many_to_many( 'tags', 'post_tags', 'tag_name' );

use RapidApp::Util ':all';
use Rapi::Blog::Util;
use HTML::Strip;

sub schema { (shift)->result_source->schema }
# This relies on us having been loaded via RapidApp::Util::Role::ModelDBIC
sub parent_app_class { (shift)->schema->_ra_catalyst_origin_model->app_class }
sub Access { (shift)->parent_app_class->template_controller->Access }

sub public_url_path {
  my $self = shift;
  return undef unless $self->Access->default_view_path;
  $self->{_public_url_path} //= do {
    my $app = $self->parent_app_class;
    my $path = join('',$app->mount_url,'/',$self->Access->default_view_path);
    $path =~ s/\/?$/\//; # make sure there is a trailing '/';
    $path
  }
}

sub public_url {
  my $self = shift;
  my $path = $self->public_url_path or return undef;
 return join('',$path,$self->name)
}

sub preview_url_path {
  my $self = shift;
  return undef unless $self->Access->preview_path;
  $self->{_preview_url_path} //= do {
    my $app = $self->parent_app_class;
    my $path = join('',$app->mount_url,'/',$self->Access->preview_path);
    $path =~ s/\/?$/\//; # make sure there is a trailing '/';
    $path
  }
}

sub preview_url {
  my $self = shift;
  my $path = $self->preview_url_path or return undef;
 return join('',$path,$self->name)
}

sub open_url_path {
  my $self = shift;
  my $mode = shift;
  my $app = $self->parent_app_class;
  if($mode) {
    $mode = lc($mode);
    die "open_url_path(): bad argument '$mode' -- must be undef, 'direct' or 'navable'"
      unless ($mode eq 'direct' or $mode eq 'navable');
    return join('',$app->mount_url,'/rapidapp/module/',$mode,$self->getRestPath)
  }
  else {
    my $ns = $app->module_root_namespace;
    return join('',$app->mount_url,'/',$ns,'/#!',$self->getRestPath)
  }
}


sub insert {
  my $self = shift;
  my $columns = shift;
  
  if(my $User = Rapi::Blog::Util->get_User) {
    die usererr "Insert Post: PERMISSION DENIED" if ($User->id && !$User->can_post);
  }
  
  $self->set_inflated_columns($columns) if $columns;
  
  $self->_set_column_defaults('insert');

  $self->next::method;
  
  $self->_update_tags;
  
  return $self;
}

sub update {
  my $self = shift;
  my $columns = shift;
  $self->set_inflated_columns($columns) if $columns;
  
  my $uid = Rapi::Blog::Util->get_uid;
  die usererr "Update Post: PERMISSION DENIED" if ($uid && !$self->can_modify);
  
  $self->updater_id( $uid );
  
  $self->_set_column_defaults('update');
  
  $self->_update_tags if ($self->is_column_changed('body'));
  
  $self->next::method;
}

sub delete {
  my $self = shift;
  
  my $uid = Rapi::Blog::Util->get_uid;
  die usererr "Delete Post: PERMISSION DENIED" if ($uid && !$self->can_delete);

  $self->next::method(@_)
}

sub image_url {
  my $self = shift;
  $self->{_image_url} //= $self->image 
    ? join('/','_ra-rel-mnt_','simplecas','fetch_content',$self->image) 
    : undef
}


sub _set_column_defaults {
  my $self = shift;
  my $for = shift || '';
  
  # default title:
  $self->title($self->name) unless $self->title;
  
  if ($for eq 'insert' || $self->is_column_changed('body') || $self->is_column_changed('custom_summary')) {
    $self->size( length $self->body );
    $self->summary( 
      $self->custom_summary ? $self->custom_summary : $self->_generate_auto_summary
    );
    
  }
  
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

sub _update_tags {
  my $self = shift;
  
  # normalized list of keywords, lowercased and _ converted to -
  my @kw = uniq(
    map { $_ =~ s/\_/\-/g; lc($_) } 
    $self->_extract_hashtags
  );

  $self->set_tags([ map {{ name => $_ }} @kw ]);
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


sub _generate_auto_summary {
  my $self = shift;
  
  my $num_words = 70;
  
  my $body = $self->body;
  
  # Convert markdown links to plain text (labels) (provided by @deven)
  $body =~ s/(!?)\[(.*?)\]\((.*?)\)/$1 ? "" : $2/ge;
  
  # Convert ![], [] and () to <> so they will look like tags and get stripped in the next step
  $body =~ s/\!?[\[\(]/\</g;
  $body =~ s/[\]\)]/\>/g;
  
  # Strip HTML markup from body
  my $text = HTML::Strip->new->parse( $body );
  
  my $i = 0;
  my $buf = '';
  for my $line (split(/\r?\n/,$text)) {
    for my $word (split(/\s+/,$line)) {
      next if ($word =~ /^\W+$/);
      $buf .= "$word ";
      return $buf if (++$i >= $num_words);
    }
  }
  
  return $buf
}



sub record_hit {
  my $self = shift;
  
  my @args = ({ post_id => $self->id, ts => Rapi::Blog::Util->now_ts });
  if(my $c = RapidApp->active_request_context) {
    push @args, $c->request;
  }
  
  $self->hits->create_from_request(@args);
  
  return "";
}

sub can_delete {
  my $self = shift;
  my $User = Rapi::Blog::Util->get_User or return 0;
  $User->admin or ($User->author && $self->author_id == $User->id)
}

sub can_modify {
  my $self = shift;
  my $User = Rapi::Blog::Util->get_User or return 0;
  $User->admin or ($User->author && $self->author_id == $User->id)
}

sub can_change_author {
  my $self = shift;
  my $User = Rapi::Blog::Util->get_User or return 0;
  $User->admin
}


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
