$(function() {
    
    var ws = new WebSocket('ws://'+location.host+'/echo');
    
    ws.onopen = function () {
        console.log('Connection opened');
        setTimeout(fetch, 2000);
    };
    
    ws.onmessage = function (msg) {
        var res = JSON.parse(msg.data);
        $("#jobs").html(res.remain);
        $.each(res.result, function(idx, data){
            var status = data['res'];
            var newTr = $('<tr></tr>').addClass('res'+status);
            $.each(data, function(idx2, col) {
                if(col) {
                    col = col.replace(/</g, '&lt;');
                    col = col.replace(/>/g, '&gt;');
                    if (col.match(/^https?:\/\//)) {
                        col = '<a href="'+col+'">'+col+'</a>';
                    }
                }
                newTr.append('<td>'+col+'</td>');
            });
            $("#result tbody").prepend(newTr);
        });
        setTimeout(fetch, 2000);
    };
    
    function fetch() {
        var offset = $('tr').length;
        ws.send(offset || 0);
    };
    
    fetch();
    
    $("tr").live('click', function() {
        $("#trLightbox").html('');
        $(this).find('td').each(function(idx, obj){
           $("#trLightbox").append(obj);
        });
        $("#trLightbox").show();
    });
});
