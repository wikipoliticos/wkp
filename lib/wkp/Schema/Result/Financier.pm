use utf8;
package wkp::Schema::Result::Financier;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "DeleteAction", "TimeStamp");
__PACKAGE__->table("financiers");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "financiers_id_seq",
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
  "biography_notes",
  { data_type => "text", is_nullable => 1 },
  "cnpjf",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "economic_sector",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "economic_sector_code",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "donations_2012_candidates_sum",
  { data_type => "numeric", default_value => 0, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("financiers_token_key", ["token"]);
__PACKAGE__->has_many(
  "donations_2010_candidates",
  "wkp::Schema::Result::Donations2010Candidate",
  { "foreign.financier_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "donations_2012s",
  "wkp::Schema::Result::Donations2012",
  { "foreign.financier_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "posts_financiers",
  "wkp::Schema::Result::PostsFinancier",
  { "foreign.financier_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->many_to_many("posts", "posts_financiers", "post");


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-03-18 19:08:02
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:IEma6Nkd6qZH/xhk+mcvBQ


sub cnpjf_safe {
    my $self = shift;

    return unless $self->cnpjf;

    my $length = length $self->cnpjf;

    return $self->cnpjf if $length > 11;

    my $cpf_safe = substr $self->cnpjf, 0, -3;
    $cpf_safe .= 'xxx';

    return $cpf_safe;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
