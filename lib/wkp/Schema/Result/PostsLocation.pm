use utf8;
package wkp::Schema::Result::PostsLocation;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "DeleteAction", "TimeStamp");
__PACKAGE__->table("posts_locations");
__PACKAGE__->add_columns(
  "location_id",
  {
    data_type      => "text",
    is_foreign_key => 1,
    is_nullable    => 0,
    original       => { data_type => "varchar" },
  },
  "post_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("location_id", "post_id");
__PACKAGE__->belongs_to(
  "location",
  "wkp::Schema::Result::Location",
  { id => "location_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);
__PACKAGE__->belongs_to(
  "post",
  "wkp::Schema::Result::Post",
  { id => "post_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-03-15 23:52:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:tRNa42B5mHCmX0HFunFxxQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
