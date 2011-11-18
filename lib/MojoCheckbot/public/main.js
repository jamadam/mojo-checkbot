$(function() {
    
    var statistics = {};
    
    $("tbody tr.dummy").remove();
    
    var dataKey = {
        context     : 1,
        literalURI  : 2,
        resolvedURI : 3,
        referer     : 4,
        res         : 5,
        error       : 6,
        dialog      : 7,
        method      : 8,
        param       : 9,
        parent      : 10,
        depth       : 11,
        htmlError   : 12
    };
    
    var tid;
    
    fetch();
    
    $(".notifier").live('click', function() {
        var data = $(this).data('checkbotData');
        var lb = $('#trLightboxForm');
        if (data[dataKey.dialog]['www-authenticate']) {
            var lb = $('#trLightbox401');
        }
        var names = data[dataKey.dialog].names;
        var cont = $('#commonForm table');
        cont.empty();
        for (var idx in names) {
            var input = $('<input/>', {type:'text', name:names[idx].name, value:names[idx].value});
            var th = $('<th/>').html(names[idx].name);
            var td = $('<td/>').append(input);
            var tr = $('<tr/>').append(th, td);
            cont.append(tr);
        }
        lb.data('checkbotTr', $(this));
        showLightbox(lb, data);
        $(this).fadeOut();
    });
    
    $("tbody tr").live('click', function() {
        var lb;
        var data = $(this).data('checkbotData');
        if ($(this).hasClass('r401')) {
            lb = $('#trLightbox401');
            lb.find('.realm').html(data[dataKey.dialog]['www-authenticate']);
        } else {
            lb = $('#trLightbox');
            if (data[dataKey.error]) {
                lb.find('.error textarea').html(data[dataKey.error]);
                lb.find('.error').parent(0).show();
            } else {
                lb.find('.error').parent(0).hide();
            }
        }
        lb.data('checkbotTr', $(this));
        showLightbox(lb, data);
    });
    
    $("#summary").find('input').live('change', function() {
        var status = ($(this).attr('id').match(/check_(.+)/))[1];
        $("tr.r" + status).toggleClass('hd');
    });
    
    $("#commonForm").live('submit', function(){
        var data = $('#trLightboxForm').data('checkbotTr').data('checkbotData');
        var new_data = {};
        for (var key in data) {
            new_data['key_' + key] = data[key];
        }
        new_data['key_' + dataKey.dialog] = undefined;
        new_data['key_' + dataKey.param] = $(this).serialize();
        $.post('/form', new_data, function(res) {
            fetch();
        });
        return false;
    });
    
    $("#authForm").live('submit', function() {
        $.post('/auth', {
            'url'         : $("#trLightbox401 .resolvedURI textarea").html(),
            'username'    : $(this).find(".username").val(),
            'password'    : $(this).find(".password").val()
        }, function(res) {
            fetch();
        });
        return false;
    });
    
    function fetch() {
        var offset      = $('#result tbody tr').length;
        var offset_d    = $('#notifierContainer .notifier').length;
        $.get('/diff?offset=' + offset + '&offset_d=' + offset_d, function(msg){
            var summaryCont     = $("#summary");
            var fixed_data      = summaryCont.find("#fixed .data");
            var queues_data      = summaryCont.find("#queues .data");
            var reported_data   = summaryCont.find("#reported .data");
            $.each(msg.dialog, function(idx, data){
                var notifier = constructNotifier(data).css('display', 'none');
                $("#notifierContainer").prepend(notifier);
                notifier.fadeIn();
            });
            $.each(msg.result, function(idx, data){
                data[dataKey.res] = data[dataKey.res] ? data[dataKey.res] : 0;
                var newTr = constructTr(data);
                statistics[data[dataKey.res]] =
                                    (statistics[data[dataKey.res]] || 0) + 1;
                fixed_data.html(msg.fixed);
                queues_data.html(msg.queues);
                reported_data.html($('#result tbody tr').length);
                for (var key in statistics) {
                    var cont = summaryCont.find("p." + key);
                    if (! cont.length) {
                        summaryCont.append(newStat(key, statistics[key]));
                        cont = summaryCont.find("p." + key);
                    }
                    cont.find(".data").html(statistics[key]);
                }
                if (! $("input#check_" + data[dataKey.res]).is(':checked')) {
                    newTr.addClass('hd');
                }
                $("#result tbody").prepend(newTr);
            });

            $("#loadingContainer").hide();
            if (msg.queues > 0) {
                clearTimeout(tid);
                tid = setTimeout(fetch, 2000);
            }
        });
    };
    
    function constructNotifier(data) {
        var dom = $('<div/>', {class:'notifier'});
        dom.append($('<div/>', {class:'context'}).html(data[dataKey.context]));
        dom.append($('<div/>', {class:'uri'}).html(data[dataKey.resolvedURI] || data[dataKey.literalURI]));
        dom.data('checkbotData', data);
        return dom;
    }
    
    function constructTr(data) {
        var dom = $('<tr/>');
        dom.addClass('r' + String(data[dataKey.res]).substr(0,1));
        dom.addClass('r' + String(data[dataKey.res]));
        dom.append($('<td/>').html(data[dataKey.context] || '-'));
        dom.append($('<td/>').html(data[dataKey.literalURI] || '-'));
        dom.append($('<td/>').html(data[dataKey.resolvedURI] || '-'));
        dom.append($('<td/>').html(data[dataKey.res] || '-'));
        dom.append($('<td/>').html(data[dataKey.referer] || '-'));
        dom.append($('<td/>').html(data[dataKey.htmlError] || '-'));
        dom.data('checkbotData', data);
        return dom;
    }
    
    function newStat(name, data) {
        var dispname = (parseInt(name) || 'N/A');
        var p = $("<p/>", {class:name});
        var input = $('<input/>', {type : 'checkbox', id : 'check_' + name, checked : 'checked'});
        var label = $("<label/>", {for:'check_' + name});
        var span1 = $('<span/>', {class:'name'}).html(dispname + ' : ');
        var span2 = $('<span/>', {class:'data'}).html(data);
        return p.append(input, label.append(span1, span2));
    }
    
    function showLightbox(lb, data) {
        var p_table = $('#propetyTemplate').clone().removeAttr('id').show();
        lb.find('.propetyContainer').html(p_table);
        lb.find('.context textarea').html(data[dataKey.context]);
        lb.find('.literalURI textarea').html(data[dataKey.literalURI]);
        lb.find('.resolvedURI textarea').html(data[dataKey.resolvedURI] || '-');
        lb.find('.statusCode textarea').html(data[dataKey.res] || '-');
        lb.find('.referer textarea').html(data[dataKey.referer]);
        lb.find('.depth textarea').html(data[dataKey.depth]);
        lb.find('.parameter textarea').html(data[dataKey.param]);
        lb.find('.htmlError textarea').html(data[dataKey.htmlError] || '-');
        $.lightbox(lb).show();
    }
});
