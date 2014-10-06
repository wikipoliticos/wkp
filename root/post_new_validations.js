$('.post-form').submit(function() {
    var title = $(this).find('input[name="title"]');
    //var uri   = $(this).find('input[name="uri"]');
    //var body_text  = $(this).find('textarea[name="body"]');

    var error_msg = 'Erro(s): ';
    var return_false = 0;

    if ($(title).val() == '') {
        $(title).parent().addClass('has-error');
        error_msg += 'O título está vazio. '
        return_false = 1
    }

    /*if ($(body_text).val() == '') {
        $(body_text).parent().addClass('has-error');
        error_msg += 'O corpo está vazio. ';
        return_false = 1;
    }*/

    if (return_false) {
        alert(error_msg);
        return false;
    }
});