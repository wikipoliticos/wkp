package wkp::Controller::P;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/') PathPart('p') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(politicians_rs => $c->model('DB::Politician'),
              page_title     => 'Políticos');
}

sub object :Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $token ) = @_;

    my $politician = $c->model('Service', 'Politician')->find_more($token);

    $c->stash(politician => $politician,
              page_title => $politician->name,
              og         => { title => $politician->name }); # Open Graph
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $p    = $c->req->param('p')      || '';
    $p =~ s/<|>|%3C//g;

    my $page = $c->req->param('pagina') || 1;

    my $rs;
    if ($p) {
        $rs = $c->model('Service', 'Politician')->search_more_rs($p, $page, 30);
    }
    else {
        $rs = $c->model('Service', 'Politician')->search_more_rs($p, $page, 10);
    }

    my @politicians = $rs->all;

    if (@politicians == 1) {
        $c->res->redirect($c->uri_for_action('/p/about', [$politicians[0]->token]));
    }

    $c->stash(politicians => \@politicians,
              pager       => $rs->pager,
              p           => $p);
}

sub start :Chained('object') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(action_title => 'sobre');
    $c->stash(template => 'p/about.tt');
}

sub about :Chained('object') PathPart('sobre') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash(action_title => 'sobre');
}

sub posts :Chained('object') PathPart('postagens') Args(0) {
    my ($self, $c) = @_;

    my $pagina = $c->req->param('pagina') || 1;

    my ($posts_rs, $pager) =
      $c->model('Service', 'Post')->posts_without_comments(
          { 'politician.token' => $c->stash->{politician}->token },
          $pagina,
          50
      );

    $c->stash(posts => [$posts_rs->all],
              pager => $pager,
              action_title => 'postagens');
}

sub post_add :Chained('object') PathPart('postar') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        if (!$c->validate_captcha($c->req->param('captcha'))) {
            # params to use in the form
            $c->stash->{form_params} = $c->req->params;

            $c->flash->{alert_error} = 'Código de validação incorreto.';
        }
        else {
            my $politician = $c->stash->{politician};
            my $post;
            my $post_srv = $c->model('Service', 'Post');

            my $user_id = $c->user_exists ? $c->user->id : '';
            my $post_data = $c->req->params;
            $post_data->{contexts} = get_contexts_as_str($politician);

            $post = $post_srv->post($post_data, $user_id);

            $c->res->redirect(
                $c->uri_for_action('/p/posts', [$politician->token])
                . '#' . $post->id);
        }
    }
}

sub get_contexts_as_str {
    my $politician = shift;

    my @contexts;

    push @contexts, $politician->token . '-p';

    my @locations = $politician->locations;
    push @contexts, $_->id . '-l' for @locations;

    return join ',', @contexts;
}

# TODO Completar funcionalidade.
sub edit :Chained('object') PathPart('editar') Args(0) {
    my ( $self, $c ) = @_;

    $c->go('index') unless $c->user_exists && $c->user->role eq 'admin';

    if ($c->req->method eq 'POST') {
        $c->stash->{politician}->update( $c->req->params );
    }
}

sub follow_toggle
  :Chained('object') PathPart('chavear-acompanhamento') Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists) {
        $c->flash->{alert_info} =
          'Você precisa estar logado (Entrar) para acompanhar contextos.';
        $c->res->redirect($c->uri_for_action('/login'));
    }
    else {
        my $u_p_rs = $c->model('DB::UsersPolitician');
        my $check = $u_p_rs->find(
            { user_id => $c->user->id,
              politician_id => $c->stash->{politician}->id });

        unless ($check) {
            $check = $u_p_rs->create(
                { user_id => $c->user->id,
                  politician_id => $c->stash->{politician}->id });
        }
        else {
            $check->delete;
        }

        $c->res->redirect(
            $c->uri_for_action('/p/start', [$c->stash->{politician}->token]));
    }
}

sub financing2010 :Chained('object') PathPart('financiamento2010') Args(0) {
    my ( $self, $c ) = @_;

    my @donations_all = $c->stash->{politician}->donations_2010_candidates(
        undef,
        { prefetch => ['politician', 'financier'],
          order_by => { '-desc' => 'me.receita_valor' } }
    );

    my @donations_financier = $c->stash->{politician}
      ->donations_2010_candidates(
                        undef,
                        {
                         select => [ 'financier.name', 'me.receita_tipo',
                                     'financier.token', { sum => 'me.receita_valor' } ],
                         as => [ 'name', 'tipo', 'token', 'valor' ],
                         group_by => [ 'financier.name', 'me.receita_tipo', 'financier.token' ],
                         join => [ 'financier'],
                         order_by => { '-desc' => 'sum' },
                        }
                       );

    my @donations_type = $c->stash->{politician}
      ->donations_2010_candidates(
                        undef,
                        {
                         select => [ 'me.receita_tipo', { sum => 'me.receita_valor' } ],
                         as => [ 'tipo', 'valor' ],
                         group_by => [ 'me.receita_tipo' ],
                         order_by => { '-desc' => 'sum' },
                        }
                       );

    my $donations_total = $c->stash->{politician}
      ->donations_2010_candidates(
                        undef,
                        {
                         select => [ { sum => 'me.receita_valor' } ],
                         as => [ 'valor' ],
                        }
                       )->first;

    my $year = 2010;

    my $candidature = $c->stash->{politician}->candidatures({ year => $year })->first;

    $c->stash(donations_all => \@donations_all,
              donations_financier => \@donations_financier,
              donations_type => \@donations_type,
              donations_total => $donations_total->get_column('valor'),
              year => $year,
              template => 'p/financing.tt',
              this_year_candidature => $candidature);


    $c->stash(action_title => 'financiamento eleitoral 2010');
}


sub financing2012 :Chained('object') PathPart('financiamento2012') Args(0) {
    my ( $self, $c ) = @_;

    my @donations_all = $c->stash->{politician}
      ->donations_2012s(undef,
                        { prefetch => ['politician', 'financier'],
                          order_by => { '-desc' => 'me.receita_valor' } }
                       );

    my @donations_financier = $c->stash->{politician}
      ->donations_2012s(
                        undef,
                        {
                         select => [ 'financier.name', 'me.receita_tipo',
                                     'financier.token', { sum => 'me.receita_valor' } ],
                         as => [ 'name', 'tipo', 'token', 'valor' ],
                         group_by => [ 'financier.name', 'me.receita_tipo', 'financier.token' ],
                         join => [ 'financier'],
                         order_by => { '-desc' => 'sum' },
                        }
                       );

    my @donations_type = $c->stash->{politician}
      ->donations_2012s(
                        undef,
                        {
                         select => [ 'me.receita_tipo', { sum => 'me.receita_valor' } ],
                         as => [ 'tipo', 'valor' ],
                         group_by => [ 'me.receita_tipo' ],
                         order_by => { '-desc' => 'sum' },
                        }
                       );

    my $donations_total = $c->stash->{politician}
      ->donations_2012s(
                        undef,
                        {
                         select => [ { sum => 'me.receita_valor' } ],
                         as => [ 'valor' ],
                        }
                       )->first;

    my $year = 2012;

    my $candidature = $c->stash->{politician}->candidatures({ year => $year })->first;

    $c->stash(donations_all => \@donations_all,
              donations_financier => \@donations_financier,
              donations_type => \@donations_type,
              donations_total => $donations_total->get_column('valor'),
              year => $year,
              this_year_candidature => $candidature,
              template => 'p/financing.tt');

    $c->stash(action_title => 'financiamento eleitoral 2012');
}

sub about_retrocompatibility :Chained('object') PathPart('geral') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(template => 'p/about.tt');
}

sub financing_retrocompatibility
  :Chained('object') PathPart('financiamento') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash(template => 'p/about.tt');
}

__PACKAGE__->meta->make_immutable;

1;
