use utf8;
package wkp::Schema::Result::Candidature;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "DeleteAction", "TimeStamp");
__PACKAGE__->table("candidatures");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "candidatures_id_seq",
  },
  "politician_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "year",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "state",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "city",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "political_position",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "result",
  { data_type => "boolean", is_nullable => 1 },
  "notes",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "mandates",
  "wkp::Schema::Result::Mandate",
  { "foreign.candidature_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "politician",
  "wkp::Schema::Result::Politician",
  { id => "politician_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07035 @ 2014-03-15 23:52:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6wkrN1rPRgFwjzGj1arCfQ

sub print_ok {
    if ($_[0]->city) {
        return
          $_[0]->year . ', ' .
                $_[0]->political_position . ', ' .
            $_[0]->city . ' - ' .
              $_[0]->state;
    }
    return
      $_[0]->year  . ', ' .
          $_[0]->political_position. ', ' .

        $_[0]->state;
}

# You can replace this text with custom code or comments, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
