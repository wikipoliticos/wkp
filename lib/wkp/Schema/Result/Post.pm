use utf8;
package wkp::Schema::Result::Post;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "DeleteAction", "TimeStamp");
__PACKAGE__->table("posts");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "posts_id_seq",
  },
  "user_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "parent_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "title",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "body",
  { data_type => "text", is_nullable => 1 },
  "uri",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "created",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "updated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "parent",
  "wkp::Schema::Result::Post",
  { id => "parent_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->has_many(
  "posts",
  "wkp::Schema::Result::Post",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "posts_actions",
  "wkp::Schema::Result::PostsAction",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "posts_financiers",
  "wkp::Schema::Result::PostsFinancier",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "posts_locations",
  "wkp::Schema::Result::PostsLocation",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "posts_politicians",
  "wkp::Schema::Result::PostsPolitician",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "user",
  "wkp::Schema::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->many_to_many("actions", "posts_actions", "action");
__PACKAGE__->many_to_many("financiers", "posts_financiers", "financier");
__PACKAGE__->many_to_many("locations", "posts_locations", "location");
__PACKAGE__->many_to_many("politicians", "posts_politicians", "politician");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-03-15 23:52:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:QbrA5pR47z6YRJmJRC8aDg

__PACKAGE__->add_columns('+created' => { set_on_create => 1 },
                         '+updated' => {  set_on_create => 1,  set_on_update => 1 });

sub posts_with_posts {
    shift->posts(undef, { prefetch => ['posts'], order_by => { -asc => 'me.created' } });
}

__PACKAGE__->has_many(
  "posts",
  "wkp::Schema::Result::Post",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0, delete_action => 'cascade' },
);



__PACKAGE__->has_many(
  "posts_politicians",
  "wkp::Schema::Result::PostsPolitician",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0, delete_action => 'cascade' },
);

__PACKAGE__->has_many(
  "posts_locations",
  "wkp::Schema::Result::PostsLocation",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0, delete_action => 'cascade' },
);
# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
