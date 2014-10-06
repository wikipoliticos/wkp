package wkp::Controller::Posts;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/') PathPart('h') :CaptureArgs(0) {
    my ( $self, $c ) = @_;
    $c->stash(posts_rs => $c->model('DB::Post'),
              page_title => 'Postagens');
}

sub object :Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $id ) = @_;
    my $post = $c->stash->{posts_rs}->find($id); #, { prefetch => ['posts'] });

    $c->stash(post => $post,
              page_title => $post->title . ' - Postagens');
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    my $post_srv = $c->model('Service', 'Post');
    my $schema = $c->model('DB');

    my $page = $c->req->param('pagina') || 1;
    my ($posts_rs, $pager) = $post_srv->posts_without_comments(undef, $page);

    $c->stash(posts => [$posts_rs->all], pager => $pager);
}

sub details :Chained('object') PathPart('') Args(0) {
    my ( $self, $c ) = @_;

    if ($c->req->method eq 'POST') {
        if (!$c->validate_captcha($c->req->param('captcha'))) {
            my $parent_id = $c->req->param('parent_id');
            $c->stash->{'form_params_' . $parent_id} = $c->req->params; # params to use in the form
            $c->flash->{'alert_error_' . $parent_id} = 'Código de validação incorreto.';
        }
        else {
            my $user_id = $c->user_exists ? $c->user->id : '';
            my $post = $c->model('Service', 'Post')->post($c->req->params, $user_id);
            $c->res->redirect($c->uri_for_action('/posts/details', [$c->stash->{post}->id]) . '#' . $post->id);
        }
    }
}

# very raw post edition for admins
sub edit :Chained('object') PathPart('editar') Args(0) {
   my ($self, $c) = @_;

   $c->go('index') unless $c->user_exists && $c->user->role eq 'admin';

   $c->stash(form_params => $c->stash->{post});

   if ($c->req->method eq 'POST') {
       $c->stash->{post}->update( $c->req->params );
       $c->res->redirect
         ($c->uri_for_action('/posts/details', [$c->stash->{post}->id]));
   }
}

sub delete :Chained('object') PathPart('deletar') Args(0) {
    my ($self, $c) = @_;

    my $post = $c->stash->{post};

    if (
        (!$c->user_exists || !$post->user_id || $post->user_id ne $c->user->id)
          && $c->user->role ne 'admin'
         ) {
        $c->flash->{alert_error} = 'Permissão negada.';
        $c->res->redirect($c->uri_for_action('/posts/index'));
    }
    else {
        my $schema = $c->model('DB');

        $schema->txn_do( sub { $c->stash->{post}->delete } );
        $c->flash->{alert_success} = 'Postagem deletada.';
        $c->res->redirect($c->uri_for_action('/posts/index'));
    }
}

__PACKAGE__->meta->make_immutable;

1;
