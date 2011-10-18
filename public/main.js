$(function() {
    
    var status_statistics = {};
    
    function fetch() {
        var offset = $('#result tbody tr').length;
        $.get('/echo?offset='+offset, function(msg){
            $.each(msg.result, function(idx, data){
                var status = data['res'];
                var newTr = $('<tr></tr>').addClass('res'+status);
                $.each(data, function(idx2, col) {
                    newTr.append('<td>'+col+'</td>');
                });
                $("#result tbody").prepend(newTr);
                status_statistics[status] = (status_statistics[status] || 0) + 1;
                $("#summary").empty();
                $("#summary").append(new_stat('Jobs', msg.remain));
                $("#summary").append(new_stat('Fixed', $('#result tbody tr').length));
                for (var key in status_statistics) {
                    $("#summary").append(new_stat(key, status_statistics[key]));
                }
            });
            setTimeout(fetch, 2000);
        });
    };
    
    function new_stat(label, data) {
        return $('<p><span class="label">'+ label+ '</span>: <span class="data">' + data + '</span></p>');
    }
    fetch();
    
    $("tbody tr").live('click', function() {
        var tmp = $(this).find('td');
        $('#trLightbox .anchor textarea').html(tmp.eq(0).html());
        $('#trLightbox .href textarea').html(tmp.eq(1).html());
        $('#trLightbox .resolvedURI textarea').html(tmp.eq(2).html());
        $('#trLightbox .statusCode textarea').html(tmp.eq(3).html());
        $('#trLightbox .referer textarea').html(tmp.eq(4).html());
        $.lightbox("#trLightbox").show();
    });
});
