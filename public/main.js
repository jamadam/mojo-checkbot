$(function() {
    var ws = new WebSocket('ws://127.0.0.1:3000/echo');
    ws.onopen = function () {
        console.log('Connection opened');
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
                }
                newTr.append('<td title="'+col+'">'+col+'</td>');
            });
            $("#result tbody").prepend(newTr);
        });
    };
    
    setInterval(function(){
        var offset = $('tr').length;
        ws.send(offset || 0);
    }, 2000);
    
    $("tr").live('click', function() {
        $("#trLightbox").html('');
        $(this).find('td').each(function(idx, obj){
           $("#trLightbox").append(obj);
        });
        $("#trLightbox").show();
    });
});
