$(function() {
    
    var status_statistics = {};
    
    $("tbody tr.dummy").remove();
    
    function fetch() {
        var offset = $('#result tbody tr').length;
        $.get('/echo?offset='+offset, function(msg){
            $.each(msg.result, function(idx, data){
                var status = data['res'];
                var newTr = $('<tr></tr>');
                if (status) {
                    newTr.addClass('res'+(status.substr(0,1)+'xx'))
                }
                newTr.append('<td>' + (data.context || '-') + '</td>');
                newTr.append('<td>' + (data.literalURI || '-') + '</td>');
                newTr.append('<td>' + (data.resolvedURI || '-') + '</td>');
                newTr.append('<td>' + (data.res || '-') + '</td>');
                newTr.append('<td>' + (data.referer || '-') + '</td>');
                if ($("#hide2xx").get(0).checked && status.match(/2../)) {
                    console.log('a');
                    newTr.addClass('hidden');
                }
                $("#result tbody").prepend(newTr);
                status_statistics[status] = (status_statistics[status] || 0) + 1;
                var summaryCont = $("#summary");
                summaryCont.empty();
                summaryCont.append(new_stat('Jobs', msg.remain));
                summaryCont.append(new_stat('Fixed', $('#result tbody tr').length));
                for (var key in status_statistics) {
                    summaryCont.append(new_stat(key, status_statistics[key]));
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
        $('#trLightbox .context textarea').html(tmp.eq(0).html());
        $('#trLightbox .literalURI textarea').html(tmp.eq(1).html());
        $('#trLightbox .resolvedURI textarea').html(tmp.eq(2).html());
        $('#trLightbox .statusCode textarea').html(tmp.eq(3).html());
        $('#trLightbox .referer textarea').html(tmp.eq(4).html());
        $.lightbox("#trLightbox").show();
    });
    
    $("#hide2xx").bind('change', function() {
        if (this.checked) {
            $("tr.res2xx").addClass('hidden');
        } else {
            $("tr.res2xx").removeClass('hidden');
        }
    });
});
