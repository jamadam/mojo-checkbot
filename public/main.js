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
        $("#trLightbox").html('');
        var tmp = $(this).find('td');
        console.log($('#trLightbox .anchor'));
        $('#trLightbox .anchor').html(tmp.eq(0).html());
        $('#trLightbox .href').html(tmp.eq(1).html());
        $('#trLightbox .resolvedURI').html(tmp.eq(1).html());
        $('#trLightbox .statusCode').html(tmp.eq(1).html());
        $('#trLightbox .referer').html(tmp.eq(1).html());
        $.lightbox("#trLightbox").show();
    });
});
