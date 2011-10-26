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
                data[dataKey.res] = data[dataKey.res] ? data[dataKey.res] : 0;
                var newTr = $('<tr/>');
                newTr.addClass('r'+String(data[dataKey.res]).substr(0,1));
                newTr.addClass('r'+String(data[dataKey.res]));
                newTr.append($('<td/>').html(data[dataKey.content] || '-'));
                newTr.append($('<td/>').html(data[dataKey.literalURI] || '-'));
                newTr.append($('<td/>').html(data[dataKey.resolvedURI] || '-'));
                newTr.append($('<td/>').html(data[dataKey.res] || '-'));
                newTr.append($('<td/>').html(data[dataKey.referer] || '-'));
                if (data[dataKey.error]) {
                    error = $('<div/>', {class: 'error'});
                    error.html(data[dataKey.error]);
                    error.css('display','none');
                    newTr.append(error);
                }
                statistics[data[dataKey.res]] =
                                    (statistics[data[dataKey.res]] || 0) + 1;
                var summaryCont = $("#summary");
                summaryCont.find("#fixed .data").html(msg.fixed + '/' + msg.queues);
                summaryCont.find("#reported .data").html($('#result tbody tr').length);
                for (var key in statistics) {
                    var cont = summaryCont.find("p." + key);
                    if (! cont.length) {
                        summaryCont.append(new_stat(key, statistics[key]));
                        cont = summaryCont.find("p." + key);
                    }
                    cont.find(".data").html(statistics[key]);
                }
                if (! isChecked(data[dataKey.res])) {
                    newTr.addClass('hd');
                }
                $("#result tbody").prepend(newTr);
            });
            $("#loadingContainer").hide();
            if (msg.queues) {
                setTimeout(fetch, 2000);
            }
        });
    };
    
    function isChecked(status) {
        return $("input#check_" + status).is(':checked');
    }
    
    function new_stat(name, data) {
        var dispname = (parseInt(name) || 'N/A');
        var p = $("<p/>", {class:name});
        var input = $('<input />', {type : 'checkbox', id : 'check_' + name, checked : 'checked'});
        var label = $("<label/>", {for:'check_' + name});
        var span1 = $('<span/>', {class:'name'}).html(dispname + ' : ');
        var span2 = $('<span/>', {class:'data'}).html(data);
        return p.append(input, label.append(span1, span2));
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
    
    $("#summary").find('input').live('change', function() {
        var status = ($(this).attr('id').match(/check_(.+)/))[1];
        $("tr.r" + status).toggleClass('hd');
    });
});
