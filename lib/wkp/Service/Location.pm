package wkp::Service::Location;
use Moose;
use Carp;
use HTML::Scrubber;
use Text::Unidecode;

has schema => (is => 'ro', required => 1);

sub find_more {
    my ($self, $id) = @_;

    return $self->{schema}->resultset('Location')->find
      ({ id => $id },
       { order_by => { '-asc' => 'id' } });
}

sub search_more_rs {
    my ($self, $p, $page, $rows) = @_;

    my $where;

    if ($p) {
        $p = lc unidecode $p;
        $p =~ s/\s{1,}/%/g;

        $where = { 'me.id' => { like => '%' . $p . '%' } };
    }

    my $rs = $self->{schema}->resultset('Location')->search_rs
      ($where,
       { order_by => [{ -desc => 'me.search_relevance' }, { -asc => 'me.name' }],
         rows => $rows || 10 })
        ->page($page || 1);

    return $rs;
}

1;
