$(document).ready(function() {
    var uri = location.href;
    if (uri.match(/#\d+$/)) {
        var post_id = uri.match(/#\d+$/)[0].substr(1);
        var post = $('a[name="' + post_id + '"]').parents('.post');
        if (post) $(post).fadeOut().fadeIn().fadeOut().fadeIn();
    }

    $('.comments-show-hide').click(function() {
        var medias = $(this).parents('.media-body').first().find('> .media');
        var action = $(this).find('.comments-show-hide-action');

        if ($(medias).hasClass('hide')) {
            $(medias).fadeIn(400).removeClass('hide');
            $(action).text('Esconder');
        }
        else {
            $(medias).fadeOut(400, function() {
                $(medias).addClass('hide');
                $(action).text('Mostrar');
            });
        }

        return false;
    });

    $('.show-hide-new-comment-form').click(function(event) {
        var post_id = $(this).attr('id').match(/\d+$/)[0];
        var form = $('#comment-form-' + post_id);

        if ($(form).hasClass('hide'))
            $(form).removeClass('hide');
        else
            $(form).addClass('hide');

        event.preventDefault();
    });
});
