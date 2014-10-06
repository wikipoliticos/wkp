package wkp::Service::Post;

use Moose;
use Carp;
use HTML::Scrubber;

has schema => (is => 'ro', required => 1);

=head1 METHODS

=head2 post

Receives

$params. Required. A hashref with the params that will be used to
create the post. Its keys:

    id. Optional. If informed, the post with the corresponding id will be
        edited to contain the information on $params.

    title. Required. The post title.

    uri. Optional. The post uri.

    body. Optional. The post body.

    parent_id. Optional. If informed, the post to be created will be
               created as a child post.

    contexts. Optional. Contexts to which the post might be attached to.
              Exemplo: "fulano-de-tal-p,fulana-de-tal-f".

$user_id. Optional. The user id to which the post will be attached. The post creator.

TODO

defining api for when the param checking fails,
checking the params,
    TO DO perform checks
    check if $params->{title} is presente. decide what to do if it is not.
all contexts, p, f, a
transaction

=cut

sub post {
    my ($self, $params, $user_id) = @_;

    my $post;
    my $schema = $self->schema;
    my $posts_rs = $schema->resultset('Post');
    my $scrubber = HTML::Scrubber->new(allow => []);

    $params->{body} ||= '';
    $params->{uri} ||= '';

    my $post_data = { title => $scrubber->scrub($params->{title}),
                      body  => $scrubber->scrub($params->{body} ),
                      uri   => $scrubber->scrub($params->{uri}  ) };

    # Post edition
    if ($params->{id}) {
        $post = $posts_rs->find($params->{id});
        $post_data->{id} = $scrubber->scrub($params->{id});
        $post->update($post_data);

        return $post; # TODO Check if $post returned is updated or the original one
    }

    # Post addition
    $post_data->{user_id}   = $user_id             if $user_id;
    $post_data->{parent_id} = $params->{parent_id} if $params->{parent_id};

    $post = $posts_rs->create($post_data);

    # Contexts TO DO
    if ($params->{contexts}) {
        my $contexts = $params->{contexts};
        my @contexts_split = split ',', $contexts;

        for my $context (@contexts_split) {
            $context =~ s/(^\s*|\s*$)//g;

            if ($context =~ /-p$/) { # Politicians
                $context =~ s/-p$//;

                my $politician =
                  $schema->resultset('Politician')->find({ token => $context });

                if ($politician) {
                    $post->add_to_posts_politicians({ politician_id => $politician->id });
                }
                else {
                    confess 'Could not find politician to attach to a post';
                }
            }
            elsif ($context =~ /-l$/) { # Locations
                $context =~ s/-l$//;

                my $location =
                  $schema->resultset('Location')->find({ id => $context });

                if ($location) {
                    $post->add_to_posts_locations({ location_id => $location->id });
                }
                else {
                    confess 'Could not find location to attach to a post';
                }
            }
            #elsif ($context =~ /-f$/) { # Financiers
            #}
            #elsif ($context =~ /-a$/) { # Social Actions
            #}
            #etc.
        }
    }

    return $post;
}

=head2 posts_without_comments

Returns a list. First element: a resultset. Second: its pager

=cut

sub posts_without_comments {
    my ( $self, $conditions, $page, $rows ) = @_;

    my $rs = $self->schema->resultset('Post');

    $conditions->{'me.parent_id'} = undef;

    $rs = $rs->search_rs(
        $conditions,
        { prefetch => [ 'user',
                        'parent',
                        { 'posts_politicians' => 'politician' },
                        { 'posts_financiers' => 'financier' },
                        { 'posts_locations' => 'location' },
                       ],
          order_by => { -desc => 'me.created' },
          rows => $rows || 10,
          page => $page || 1 });

    my $pager = $rs->pager;

    return $rs, $pager;
}

=head2 allowed_to_post_now

Must receive an user id or an IP. If it doesn't receive one of them,
it Carp::confesses. If an user id is present, check if it can post now. If an user
id is not present, check if the IP can post.

Receives \%opts

    user_id User id
    ip User IP

Returns 1 or 0 (allowed or not allowed)

=cut

sub allowed_to_post_now {
    my ($self, $opts) = @_;
}

1;

__END__

=head2 post

Add or update a post.

Receives $c, considering that
    $c->req->param('id') might exist
    $c->req->param('title') must exist
    $c->req->param('uri') might exist
    $c->req->param('body') might exist
    $c->req->param('parent_id') might exist

If 'id' exists, then the post which hold this id will be updated.

If 'id' does not exist, a post with the attributes (title, uri and
body) will be created. If 'parent_id' exists, the post to be created
will be created as a child of the post which has its id equal to
'parent_id'.

Returns $post or

=cut

sub old_post {
    my ($self, $c) = @_;

    my $posts_rs = $c->model('DB::Post');
    my $post;
    my $scrubber = HTML::Scrubber->new(allow => []);

    # Post edition

    if ($c->req->param('id')) {
        $post = $posts_rs->find($c->req->param('id'));
        my $post_data = { id    => $scrubber->scrub($c->req->param('id')   ),
                          title => $scrubber->scrub($c->req->param('title')),
                          uri   => $scrubber->scrub($c->req->param('uri')  ),
                          body  => $scrubber->scrub($c->req->param('body') ) };

        $post->update($post_data);

        return $post; # Check if $post returned is updated or the original one
    }

    # Post addition

    my $post_data = { title => $scrubber->scrub($c->req->param('title')),
                      body  => $scrubber->scrub($c->req->param('body') ),
                      uri   => $scrubber->scrub($c->req->param('uri')  ) };

    $post_data->{user_id}   = $c->user->id                if $c->user_exists;
    $post_data->{parent_id} = $c->req->param('parent_id') if $c->req->param('parent_id');

    $post = $posts_rs->create($post_data);

    if ($c->req->param('contexts')) {
        my $contexts = $c->req->param('contexts');
        my @contexts_split = split ',', $contexts;

        for my $context (@contexts_split) {
            $context =~ s/(^\s*|\s*$)//g;

            if ($context =~ /-p$/) {
                $context =~ s/-p$//;
                my $politician = $c->model('DB::Politician')->find({ token => $context });
                $post->add_to_posts_politicians({ politician_id => $politician->id })
                  if $politician;
            }
            elsif ($context =~ /^f-/) {
            }
            elsif ($context =~ /^a-/) {
            }
        }
    }

    return $post;
}
