use utf8;
package wkp::Schema::Result::Location;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "DeleteAction", "TimeStamp");
__PACKAGE__->table("locations");
__PACKAGE__->add_columns(
  "id",
  {
    data_type   => "text",
    is_nullable => 0,
    original    => { data_type => "varchar" },
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "parent_id",
  {
    data_type      => "text",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "varchar" },
  },
  "search_relevance",
  { data_type => "integer", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "locations",
  "wkp::Schema::Result::Location",
  { "foreign.parent_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "locations_politicians",
  "wkp::Schema::Result::LocationsPolitician",
  { "foreign.location_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "parent",
  "wkp::Schema::Result::Location",
  { id => "parent_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);
__PACKAGE__->has_many(
  "posts_locations",
  "wkp::Schema::Result::PostsLocation",
  { "foreign.location_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many("politicians", "locations_politicians", "politician");
__PACKAGE__->many_to_many("posts", "posts_locations", "post");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-03-16 00:05:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8TTiAAJ6L8L7dZRm/bK5/Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
