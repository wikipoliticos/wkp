use utf8;
package wkp::Schema::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "DeleteAction", "TimeStamp");
__PACKAGE__->table("users");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "users_id_seq",
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
  "email",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "password",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "pw_recovery_hash",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "pw_recovery_expiration",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "created",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "updated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "role",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("users_email_key", ["email"]);
__PACKAGE__->add_unique_constraint("users_token_key", ["token"]);
__PACKAGE__->has_many(
  "posts",
  "wkp::Schema::Result::Post",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "users_politicians",
  "wkp::Schema::Result::UsersPolitician",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many("politicians", "users_politicians", "politician");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-03-15 23:52:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CeK4iUZNKwJ7mUZSrLd51g

__PACKAGE__->add_columns('+created' => { set_on_create => 1 },
                         '+updated' => {  set_on_create => 1,  set_on_update => 1 });

sub my_posts_qtd {
    my $self = shift;
    return scalar $self->my_posts;
}

sub my_posts {
    my $self = shift;
    return $self->posts({ 'me.parent_id' => undef });
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
