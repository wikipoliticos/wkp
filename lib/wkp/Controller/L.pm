package wkp::Controller::L;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/') PathPart('l') :CaptureArgs(0) {
    my ( $self, $c ) = @_;

    $c->stash(locations_rs => $c->model('DB::Location'),
              page_title => 'Locais');
}

sub object :Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;

    my $location = $c->model('Service', 'Location')->find_more($id);

    $c->stash(location   => $location,
              page_title => $location->name);
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $p    = $c->req->param('p')      || '';
    $p =~ s/<|>|%3C//g;

    my $page = $c->req->param('pagina') || 1;

    my $rs = $c->model('Service', 'Location')->search_more_rs($p, $page, 100);

    $c->stash(locations => [$rs->all],
              pager     => $rs->pager,
              p         => $p);
}

sub start :Chained('object') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
}

sub politicians :Chained('object') PathPart('politicos') Args(0) {
    my ( $self, $c ) = @_;

    my @sublocations = $c->stash->{locations_rs}->search
      ({ id => { like => $c->stash->{location}->id . '%' } },
       { order_by => 'id' });

    my $sublocations_ids = [ map { $_->id } @sublocations ];

    my $politicians_rs = $c->model('DB::Politician');

    my $where = { 'locations_politicians.location_id' => { -in => $sublocations_ids } };

    my $attrs = { prefetch => ['locations_politicians'],
                  rows => 10,
                  order_by => { -asc => 'me.name'} };

    if ($c->stash->{location}->id eq 'br') {
        $where = undef;
        delete $attrs->{prefetch};
    }

    $attrs->{order_by} = { -desc => 'donations_2012_candidates_sum' }
      if $c->req->param('ordenacao') and $c->req->param('ordenacao') eq 'doacoes2012';

    $politicians_rs = $politicians_rs->search_rs
      ($where,
       $attrs)
      ->page($c->req->param('pagina') || 1);

    $c->stash(politicians => [$politicians_rs->all],
              pager       => $politicians_rs->pager);
}

sub posts :Chained('object') PathPart('postagens') Args(0) {
    my ($self, $c) = @_;

    my $pagina = $c->req->param('pagina') || 1;

    my $posts_rs = $c->model('DB::Post')->search_rs(
        { 'location.id' => { like =>  $c->stash->{location}->id . '%' } },
        { prefetch => [ { posts_locations => 'location' }, 'user' ],
          order_by => { -desc => 'me.created' },
          rows     => 50,
          page     => $pagina }
    );

    my $pager = $posts_rs->pager;

    $c->stash(posts => [$posts_rs->all], pager => $pager);
}

sub post_add :Chained('object') PathPart('postar') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        if (!$c->validate_captcha($c->req->param('captcha'))) {
            $c->stash->{form_params} = $c->req->params; # params to use in the form
            $c->flash->{alert_error} = 'Código de validação incorreto.';
        }
        else {
            my $location = $c->stash->{location};
            my $post;
            my $post_srv = $c->model('Service', 'Post');

            my $user_id = $c->user_exists ? $c->user->id : '';
            my $post_data = $c->req->params;
            $post_data->{contexts} = $location->id . '-l';

            $post = $post_srv->post($post_data, $user_id);

            $c->res->redirect(
                $c->uri_for_action('/l/posts',
                                   [$location->id]) . '#' . $post->id);
        }
    }
}

# version_alpha
sub edit :Chained('object') PathPart('editar') Args(0) {
    my ( $self, $c ) = @_;

    $c->go('index') unless $c->user_exists && $c->user->role eq 'admin';

    if ($c->req->method eq 'POST') {
        $c->stash->{politician}->update( $c->req->params );
    }
}

sub follow_toggle :Chained('object') PathPart('chavear-acompanhamento') Args(0) {
    my ( $self, $c ) = @_;

    unless ($c->user_exists) {
        $c->flash->{alert_info} = 'Você precisa estar logado (Entrar) para acompanhar contextos.';
        $c->res->redirect($c->uri_for_action('/login'));
    }
    else {
        my $u_p_rs = $c->model('DB::UsersPolitician');
        my $check = $u_p_rs->find({ user_id => $c->user->id,
                                    politician_id => $c->stash->{politician}->id });
        unless ($check) {
            $check = $u_p_rs->create({ user_id => $c->user->id,
                                       politician_id => $c->stash->{politician}->id });
        }
        else {
            $check->delete;
        }

        $c->res->redirect($c->uri_for_action('/p/start', [$c->stash->{politician}->token]));
    }
}

__PACKAGE__->meta->make_immutable;

1;
