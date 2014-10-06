package wkp::Service::Politician;
use Moose;
use Carp;
use HTML::Scrubber;
use Text::Unidecode;

has schema => (is => 'ro', required => 1);

sub find_more {
    my ($self, $token) = @_;

    return $self->{schema}->resultset('Politician')
      ->find({ token => $token });
}

sub search_more_rs {
    my ($self, $p, $page, $rows) = @_;

    my $where;

    if ($p) {
        $p = lc unidecode $p;
        $p =~ s/\s{1,}/%/g;

        $where = { 'me.token' => { like => '%' . $p . '%' } }
    }

    my $rs = $self->{schema}->resultset('Politician')
      ->search_rs($where,
                  { order_by => { -asc => 'name'},
                    rows => $rows || 10 })
        ->page($page || 1);

    return $rs;
}

1;
