$(function() {
    
    function fetch() {
        var offset = $('#result tbody tr').length;
        $.get('/echo?offset='+offset, function(msg){
            $("#jobs").html(msg.remain);
            $.each(msg.result, function(idx, data){
                var status = data['res'];
                var newTr = $('<tr></tr>').addClass('res'+status);
                $.each(data, function(idx2, col) {
                    newTr.append('<td>'+col+'</td>');
                });
                $("#result tbody").prepend(newTr);
            });
            setTimeout(fetch, 2000);
        });
    };
    
    fetch();
    
    $("tr").live('click', function() {
        var tmp = $(this).find('td');
        $('#trLightbox .anchor textarea').html(tmp.eq(0).html());
        $('#trLightbox .href textarea').html(tmp.eq(1).html());
        $('#trLightbox .resolvedURI textarea').html(tmp.eq(2).html());
        $('#trLightbox .statusCode textarea').html(tmp.eq(3).html());
        $('#trLightbox .referer textarea').html(tmp.eq(4).html());
        $.lightbox("#trLightbox").show();
    });
});
