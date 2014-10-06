use utf8;
package wkp::Schema::Result::Action;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "DeleteAction", "TimeStamp");
__PACKAGE__->table("actions");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "actions_id_seq",
  },
  "name",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "token",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "posts_actions",
  "wkp::Schema::Result::PostsAction",
  { "foreign.action_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many("posts", "posts_actions", "post");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-03-15 23:52:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8fGKzekEtaiMVYjPdlejvA


# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->meta->make_immutable;

1;
