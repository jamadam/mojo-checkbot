$(function() {
    
    function fetch() {
        var offset = $('#result tbody tr').length;
        $.get('/echo?offset='+offset, function(msg){
            $("#jobs").html(msg.remain);
            $.each(msg.result, function(idx, data){
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
        });
    };
    
    fetch();
    
    $("tr").live('click', function() {
            console.log('a');
        $("#trLightbox").html('');
        $(this).find('td').each(function(idx, obj){
           $("#trLightbox").append(obj);
        });
        $.lightbox("#trLightbox").show();
    });
});
