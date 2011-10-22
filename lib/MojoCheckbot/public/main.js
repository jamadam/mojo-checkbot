$(function() {
    
    var status_statistics = {};
    
    $("tbody tr.dummy").remove();
    
    function fetch() {
        var offset = $('#result tbody tr').length;
        $.get('/echo?offset='+offset, function(msg){
            $.each(msg.result, function(idx, data){
                var newTr = $('<tr></tr>');
                if (data.res) {
                    newTr.addClass('r'+data.res.substr(0,1))
                    if ($("#hide2xx").get(0).checked && data.res.match(/2../)) {
                        newTr.addClass('hd');
                    }
                }
                newTr.append('<td>' + (data.context || '-') + '</td>');
                newTr.append('<td>' + (data.literalURI || '-') + '</td>');
                newTr.append('<td>' + (data.resolvedURI || '-') + '</td>');
                newTr.append('<td>' + (data.res || '-') + '</td>');
                newTr.append('<td>' + (data.referer || '-') + '</td>');
                if (data.error) {
                    error = $('<div class="error">'+data.error+'</div>').css('display','none');
                    newTr.append(error);
                }
                $("#result tbody").prepend(newTr);
                status_statistics[data.res] = (status_statistics[data.res] || 0) + 1;
                var summaryCont = $("#summary");
                summaryCont.empty();
                summaryCont.append(new_stat('Jobs', msg.remain));
                summaryCont.append(new_stat('Fixed', $('#result tbody tr').length));
                for (var key in status_statistics) {
                    summaryCont.append(new_stat(key, status_statistics[key]));
                }
            });
            $("#loadingContainer").hide();
            setTimeout(fetch, 2000);
        });
    };
    
    function new_stat(label, data) {
        return $('<p><span class="label">'+ label+ '</span>: <span class="data">' + data + '</span></p>');
    }
    fetch();
    
    $("tbody tr").live('click', function() {
        var tmp = $(this).find('td');
        $('#trLightbox .context textarea').html(tmp.eq(0).html());
        $('#trLightbox .literalURI textarea').html(tmp.eq(1).html());
        $('#trLightbox .resolvedURI textarea').html(tmp.eq(2).html());
        $('#trLightbox .statusCode textarea').html(tmp.eq(3).html());
        $('#trLightbox .referer textarea').html(tmp.eq(4).html());
        if ($(this).find('.error').length) {
            $('#trLightbox .error textarea').html($(this).find('.error').html());
            $('#trLightbox .error').parent(0).show();
        } else {
            $('#trLightbox .error').parent(0).hide();
        }
        $.lightbox("#trLightbox").show();
    });
    
    if ($("#hide2xx").get(0).checked) {
        console.log('a');
        $("tr.r2").addClass('hd');
    }
    $("#hide2xx").bind('change', function() {
        $("tr.r2").toggleClass('hd');
    });
});
