$(function() {
    
    var statistics = {};
    
    $("tbody tr.dummy").remove();
    
    var dataKey = {
        content     : 1,
        literalURI  : 2,
        resolvedURI : 3,
        referer     : 4,
        res         : 5,
        error       : 6,
        dialog      : 7
    };
    
    var tid;
    
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
                newTr.data('error', data[dataKey.error]);
                newTr.data('dialog', data[dataKey.dialog]);
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
            if (msg.queues > 0) {
                tid = setTimeout(fetch, 2000);
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
        var lb;
        if ($(this).hasClass('r401')) {
            lb = $('#trLightbox401');
            lb.find('.realm').html($(this).data('dialog')['www-authenticate'][0]);
        } else {
            lb = $('#trLightbox');
            if ($(this).data('error')) {
                lb.find('.error textarea').html($(this).data('error'));
                lb.find('.error').parent(0).show();
            } else {
                lb.find('.error').parent(0).hide();
            }
        }
        var tmp = $(this).find('td');
        lb.find('.context textarea').html(tmp.eq(0).html());
        lb.find('.literalURI textarea').html(tmp.eq(1).html());
        lb.find('.resolvedURI textarea').html(tmp.eq(2).html());
        lb.find('.statusCode textarea').html(tmp.eq(3).html());
        lb.find('.referer textarea').html(tmp.eq(4).html());
        $.lightbox(lb).show();
    });
    
    $("#summary").find('input').live('change', function() {
        var status = ($(this).attr('id').match(/check_(.+)/))[1];
        $("tr.r" + status).toggleClass('hd');
    });
    
    $("#authForm").bind('submit', function() {
        $.post('/auth', {
            'url'         : $("#trLightbox401 .resolvedURI textarea").html(),
            'username'    : $(this).find(".username").val(),
            'password'    : $(this).find(".password").val()
        }, function(res) {
            fetch();
        });
        return false;
    });
});
