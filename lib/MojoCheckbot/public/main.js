$(function() {
    
    var statistics = {};
    
    $("tbody tr.dummy").remove();
    
    var dataKey = {
        content     : 1,
        literalURI  : 2,
        resolvedURI : 3,
        referer     : 4,
        res         : 5,
        error       : 6
    };
    
    function fetch() {
        var offset = $('#result tbody tr').length;
        $.get('/diff?offset='+offset, function(msg){
            $.each(msg.result, function(idx, data){
                var newTr = $('<tr></tr>');
                if (data[dataKey.res]) {
                    newTr.addClass('r'+data[dataKey.res].substr(0,1))
                    if ($("#hide2xx").get(0).checked && data[dataKey.res].match(/2../)) {
                        newTr.addClass('hd');
                    }
                }
                newTr.append('<td>' + (data[dataKey.content] || '-') + '</td>');
                newTr.append('<td>' + (data[dataKey.literalURI] || '-') + '</td>');
                newTr.append('<td>' + (data[dataKey.resolvedURI] || '-') + '</td>');
                newTr.append('<td>' + (data[dataKey.res] || '-') + '</td>');
                newTr.append('<td>' + (data[dataKey.referer] || '-') + '</td>');
                if (data[dataKey.error]) {
                    error = $('<div class="error">'+data[dataKey.error]+'</div>').css('display','none');
                    newTr.append(error);
                }
                $("#result tbody").prepend(newTr);
                statistics[data[dataKey.res]] = (statistics[data[dataKey.res]] || 0) + 1;
                var summaryCont = $("#summary");
                summaryCont.empty();
                summaryCont.append(new_stat('Fixed', msg.fixed + '/' + msg.queues));
                summaryCont.append(new_stat('Reported', $('#result tbody tr').length));
                for (var key in statistics) {
                    summaryCont.append(new_stat(key, statistics[key]));
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
        $("tr.r2").addClass('hd');
    }
    $("#hide2xx").bind('change', function() {
        $("tr.r2").toggleClass('hd');
    });
});
