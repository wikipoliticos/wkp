package wkp::Service::Financier;
use Moose;
use Text::Unidecode;

has schema => (is => 'ro', required => 1);

sub search_more_rs {
    my ($self, $p, $page, $rows) = @_;

    my $where;

    if ($p) {
        $p = lc unidecode $p;
        $p =~ s/\s{1,}/%/g;

        $where = { 'me.token' => { like => '%' . $p . '%' } };
    }

    my $rs = $self->{schema}->resultset('Financier')
      ->search_rs($where,
                  { order_by => { '-desc' => 'donations_2012_candidates_sum' },
                    rows     => 30 })
        ->page($page || 1);

    return $rs;
}

1;
