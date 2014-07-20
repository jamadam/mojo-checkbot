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
        htmlError   : 12,
        mimetype    : 13,
        size        : 14
    };
    
    var tid;
    
    fetch();
    
    $("body").on('click', '.notifier .closer', function() {
        $(this).parent().fadeOut('normal', function(){
            $(this).remove();
        });
        return false;
    });
    
    $("body").on('click', '.notifier', function() {
        var data = $(this).data('checkbotData');
        if (data[dataKey.dialog]['www-authenticate']) {
            var lb = $('#trLightbox401');
        } else {
            var lb = $('#trLightboxForm');
        }
        var names = data[dataKey.dialog].names;
        var cont = $('#commonForm table');
        cont.empty();
        for (var idx in names) {
            var input = $('<input/>', {
                type:'text',
                name:names[idx].name,
                value:names[idx].value
            });
            var th = $('<th/>').html(names[idx].name);
            var td = $('<td/>').append(input);
            var tr = $('<tr/>').append(th, td);
            cont.append(tr);
        }
        lb.data('checkbotTr', $(this));
        showLightbox(lb, data);
    });
    
    $("body").on('click', 'tbody tr', function() {
        var data = $(this).data('checkbotData');
        if ($(this).hasClass('r401')) {
            var lb = $('#trLightbox401');
            lb.find('.realm').html(data[dataKey.dialog]['www-authenticate']);
        } else {
            var lb = $('#trLightbox');
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
    
    $("body").on('change', '#summary input', function() {
        var status = ($(this).attr('id').match(/check_(.+)/))[1];
        $("tr.r" + status).toggleClass('hd');
    });
    
    $("body").on('submit', '#commonForm', function() {
        var data = $('#trLightboxForm').data('checkbotTr').data('checkbotData');
        var new_data = {};
        for (var key in data) {
            new_data['key_' + key] = data[key];
        }
        new_data['key_' + dataKey.dialog] = undefined;
        new_data['key_' + dataKey.param] = $(this).serialize();
        $.post('/form.json', new_data, function(res) {
            alert('Form is successfully sent');
            fetch();
        });
        return false;
    });
    
    $("body").on('submit', '#authForm', function() {
        var data = $('#trLightbox401').data('checkbotTr').data('checkbotData');
        $.post('/auth.json', {
            'url'         : data[dataKey.resolvedURI] || data[dataKey.literalURI],
            'username'    : $(this).find(".username").val(),
            'password'    : $(this).find(".password").val()
        }, function(res) {
            alert('User infomatin is successfully sent');
            fetch();
        });
        return false;
    });
    
    $('#notifierContainer').resizable({
        handles: "w"
    });
    
    function fetch() {
        var offset      = $('#result tbody tr').length;
        var offset_d    = $('#notifierContainer .notifier').length;
        $.get('/diff.json?offset=' + offset + '&offset_d=' + offset_d, function(msg){
            var summaryCont     = $("#summary");
            var statusCodesCont     = summaryCont.find("#statusCodes");
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
                    var cont = summaryCont.find("." + key);
                    if (! cont.length) {
                        statusCodesCont.append(newStat(key, statistics[key]));
                        cont = summaryCont.find("." + key);
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
        var dom = $('<div/>', {'class':'notifier'});
        dom.append($('<div/>', {'class':'context'}).html(data[dataKey.context]));
        dom.append($('<div/>', {'class':'uri'}).html(data[dataKey.resolvedURI] || data[dataKey.literalURI]));
        dom.append($('<div/>', {'class':'closer'}).html('×'));
        dom.data('checkbotData', data);
        return dom;
    }
    
    function constructTr(data) {
        var dom = $('<tr/>');
        dom.addClass('r' + String(data[dataKey.res]).substr(0,1));
        dom.addClass('r' + String(data[dataKey.res]));
        dom.append($('<td/>').html(data[dataKey.context] || '-'));
        dom.append($('<td/>').html(data[dataKey.resolvedURI] || '-'));
        dom.append($('<td/>').html(data[dataKey.res] || '-'));
        dom.append($('<td/>').html(data[dataKey.referer] || '-'));
        if (data[dataKey.htmlError]) {
            var stat = data[dataKey.htmlError];
            var span = $('<span/>', {'class': 'html_' + stat}).html(stat);
            dom.append($('<td/>').html(span));
        } else {
            dom.append($('<td/>').html('-'));
        }
        dom.data('checkbotData', data);
        return dom;
    }
    
    function newStat(name, data) {
        var dispname = (parseInt(name) || 'N/A');
        var div = $("<div/>", {'class':name});
        var input = $('<input/>', {type : 'checkbox', id : 'check_' + name, checked : 'checked'});
        var label = $("<label/>", {for:'check_' + name});
        var span1 = $('<span/>', {'class':'name'}).html(dispname + ' : ');
        var span2 = $('<span/>', {'class':'data'}).html(data);
        return div.append(input, label.append(span1, span2));
    }
    
    function showLightbox(lb, data) {
        var p_table = $('#propetyTemplate').clone().removeAttr('id').show();
        lb.find('.propetyContainer').html(p_table);
        lb.find('.context textarea').html(data[dataKey.context]);
        lb.find('.literalURI textarea').html(data[dataKey.literalURI]);
        lb.find('.resolvedURI textarea').html(data[dataKey.resolvedURI] || '-');
        lb.find('.statusCode textarea').html(data[dataKey.res] || '-');
        lb.find('.referer textarea').html(data[dataKey.referer]);
        lb.find('.mimetype textarea').html(data[dataKey.mimetype]);
        lb.find('.depth textarea').html(data[dataKey.depth]);
        lb.find('.size textarea').html(data[dataKey.size]);
        lb.find('.parameter textarea').html(data[dataKey.param]);
        if (data[dataKey.htmlError]) {
            var stat = data[dataKey.htmlError];
            var msg = stat == 'ok' ? 'valid' : '<- click';
            var span = $('<span/>', {'class': 'html_' + stat}).html(msg);
            lb.find('.htmlError').html(span);
            span.on('click', function() {
                lb.find('.htmlError').html($('<span/>', {'class':'loadingImage'}));
                $.post('/html_validator.json', {
                    'url' : data[dataKey.resolvedURI] || data[dataKey.literalURI]
                }, function(res) {
                    var textarea = $('<textarea/>').html(res.result);
                    lb.find('.htmlError').html(textarea);
                });
                return false;
            });
        }
        var lbw = lb.jmdmbox();
        lbw.show('fast',
            function() {
                $(this).on('resize', function() {
                    lbw.centering();
                });
                $(this).customEventTrigger().add('resize',
                    function(obj){
                        return [obj.get(0).clientWidth, obj.get(0).clientHeight];
                    },
                    function(a, b){
                        if (a !== undefined) {
                            return a[0] !== b[0] || a[1] !== b[1];
                        }
                        return 0;
                    },
                    30
                );
            },
            function() {
                $(this).customEventTrigger().remove('resize');
            }
        );
    }
});
