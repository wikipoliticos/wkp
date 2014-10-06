use utf8;
package wkp::Schema::Result::Politician;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "DeleteAction", "TimeStamp");
__PACKAGE__->table("politicians");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "politicians_id_seq",
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
  "political_nickname",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "party",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "biography",
  { data_type => "text", is_nullable => 1 },
  "cpf",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "donations_2012_candidates_sum",
  { data_type => "numeric", is_nullable => 1 },
  "most_recent_candidature",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("politicians_token_key", ["token"]);
__PACKAGE__->has_many(
  "candidatures",
  "wkp::Schema::Result::Candidature",
  { "foreign.politician_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "donations_2010_candidates",
  "wkp::Schema::Result::Donations2010Candidate",
  { "foreign.politician_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "donations_2012s",
  "wkp::Schema::Result::Donations2012",
  { "foreign.politician_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "locations_politicians",
  "wkp::Schema::Result::LocationsPolitician",
  { "foreign.politician_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "posts_politicians",
  "wkp::Schema::Result::PostsPolitician",
  { "foreign.politician_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "users_politicians",
  "wkp::Schema::Result::UsersPolitician",
  { "foreign.politician_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many("locations", "locations_politicians", "location");
__PACKAGE__->many_to_many("posts", "posts_politicians", "post");
__PACKAGE__->many_to_many("users", "users_politicians", "user");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-03-18 19:08:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CUwGYG1HncLkXxCM6osBzQ

sub cpf_safe {
    my $self = shift;

    return unless $self->cpf;

    my $cpf_safe = substr $self->cpf, 0, -3;
    $cpf_safe .= 'xxx';

    return $cpf_safe;
}

sub followed_by_user {
    my ($self, $user_id) = @_;

    my @u_p = $self->users_politicians;
    my @result = grep { $_->user_id eq $user_id } @u_p;

    return 1 if @result;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration

__PACKAGE__->meta->make_immutable;

1;
