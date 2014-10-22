package wkp::Controller::F;
use Moose;
use namespace::autoclean;
use Text::Unidecode;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/') PathPart('f') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash(financiers_rs => $c->model('DB::Financier'),
             page_title => 'Financiadores Eleitorais');

}

sub object :Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $token ) = @_;
    my $financier = $c->stash->{financiers_rs}->find({ token => $token });

    $c->stash(financier => $financier,
              page_title => $financier->name . ' - Financiadores Eleitorais',
              og         => { title => $financier->name });
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $p = $c->req->param('p') || '';
    $p =~ s/<|>|%3C//g;

    my $page = $c->req->param('pagina') || 1;

    my $rs;
    if ($p) {
        $rs = $c->model('Service', 'Financier')->search_more_rs($p, $page, 30);
    }
    else {
        $rs = $c->model('Service', 'Financier')->search_more_rs($p, $page, 10);
    }

    my @financiers = $rs->all;

    if (@financiers == 1) {
        $c->res->redirect($c->uri_for_action('/f/about', [$financiers[0]->token]));
    }

    $c->stash(financiers => \@financiers,
              pager      => $rs->pager,
              p          => $p);
}

sub start :Chained('object') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(template => 'f/about.tt');
}

sub about :Chained('object') PathPart('sobre') Args(0) {
    my ( $self, $c ) = @_;

}

sub posts :Chained('object') PathPart('postagens') Args(0) {
    my ( $self, $c ) = @_;

}

sub about_retrocompatibility :Chained('object') PathPart('geral') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(template => 'f/about.tt');

}

sub financing_retrocompatibility :Chained('object') PathPart('financiamento') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(template => 'f/about.tt');

}

sub financing2012 :Chained('object') PathPart('financiamento2012') Args(0) {
    my ( $self, $c ) = @_;

    my $cache_id     = 'financier_' . $c->stash->{financier}->id . '_financing2012';

    my $donations_hashref;

    my $donations_all;
    my $donations_politician;
    my $donations_total;

    unless ( $donations_hashref = $c->cache->get($cache_id) ) {
        $c->log->debug('no cache ' . $cache_id);

        $donations_all = [
          $c->stash->{financier}->donations_2012s(
            undef,
            { prefetch => [ { 'politician' => 'candidatures' } ],
              order_by => { '-desc' => 'me.receita_valor' } } )
        ];

        $donations_politician = [
          $c->stash->{financier}->donations_2012s(
            undef,
            { select => [ 'politician.name', 'politician.token', 'me.cargo',
                          'me.municipio', 'me.uf', 'me.politician_id',
                          'me.partido_sigla', { sum => 'me.receita_valor' } ],
              as => [ 'name', 'token', 'cargo', 'municipio', 'uf',
                      'politician_id', 'partido_sigla', 'valor'  ],
              group_by => [ 'politician.name', 'politician.token', 'me.cargo',
                            'me.municipio', 'me.uf', 'me.politician_id',
                            'me.partido_sigla' ],
              join => [ 'politician' ],
              order_by => { '-desc' => 'sum' } } )
        ];

        $donations_total = $c->stash->{financier}->donations_2012s(
          undef,
          { select => [ { sum => 'me.receita_valor' } ],
            as => [ 'valor' ] })->first;

        $donations_hashref = { all => $donations_all,
                               politician => $donations_politician,
                               total => $donations_total };

        $c->cache->set($cache_id, $donations_hashref);
    }

    $c->stash(donations_all        => $donations_hashref->{all},
              donations_politician => $donations_hashref->{politician},
              donations_total      => $donations_hashref->{total}->get_column('valor'),
              year                 => 2012,
              template             => 'f/financing.tt');
}

sub financing2010 :Chained('object') PathPart('financiamento2010') Args(0) {
    my ( $self, $c ) = @_;

    my @donations_all = $c->stash->{financier}
      ->donations_2010_candidates(
                                  undef,
                                  { prefetch => [ { 'politician' => 'candidatures' } ],
                                    order_by => { '-desc' => 'me.receita_valor' }       }
                                 );

    my @donations_politician = $c->stash->{financier}
      ->donations_2010_candidates(
                                  undef,
                                  {
                                   select => [ 'politician.name', 'politician.token', 'me.cargo', 'me.uf', 'me.politician_id', 'me.partido_sigla', { sum => 'me.receita_valor' } ],
                                   as => [ 'name', 'token', 'cargo',  'uf', 'politician_id', 'partido_sigla', 'valor'  ],
                                   group_by => [ 'politician.name', 'politician.token', 'me.cargo',  'me.uf', 'me.politician_id', 'me.partido_sigla' ],
                                   join => [ 'politician' ],
                                   order_by => { '-desc' => 'sum' },
                                  }
                                 );

    my $donations_total = $c->stash->{financier}
      ->donations_2010_candidates(
                                  undef,
                                  {
                                   select => [ { sum => 'me.receita_valor' } ],
                                   as => [ 'valor' ],
                                  }
                                 )->first;

    $c->stash(donations_all        => \@donations_all,
              donations_politician => \@donations_politician,
              donations_total      => $donations_total->get_column('valor'),
              year                 => 2010,
              template             => 'f/financing.tt');
}

__PACKAGE__->meta->make_immutable;

1;
