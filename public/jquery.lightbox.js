/**
 * jquery.lightbox
 *
 * SYNOPSIS
 *
 * $.lightbox("target").show();
 * $.lightbox("target").hide();
 */
;(function($) {

    /**
     * プラグインの名称
     */
    var plugname = 'lightbox';
    
    $[plugname] = $.sub();
    
    /**
     * show
     */
    $[plugname].fn.show = function(speed, cb) {
        var obj = $(this);
        var wrapper = obj.wrap('<div class="lightboxContainer"></div>').parent(0);
        wrapper.prepend($('<div class="lightboxMask"></div>'));
        wrapper.bind('click.lightbox', function() {
            $.lightbox(obj).hide('fast');
            return false;
        });
        obj.fadeIn(speed, cb);
        obj.css({
            'top': '50%',
            'left': '50%',
            'marginTop': (-1 * obj.get(0).clientHeight / 2) + 'px',
            'marginLeft': (-1 * obj.get(0).clientWidth / 2) + 'px'
        });
        $(this).bind('click.lightbox', function(e) {
            e.stopPropagation();
        });
        return this;
    };
    
    /**
     * hide
     */
    $[plugname].fn.hide = function(speed, cb) {
        $(this).fadeOut(speed, function(e) {
            if ($(this).parent(0).hasClass('lightboxContainer')) {
                $(this).prev().remove();
                $(this).unbind('click.lightbox');
                $(this).unwrap();
            }
            if (cb != undefined) {
                cb(e);
            }
        });
        return this;
    };
    
    $(document).ready(function(){
        $('.lightbox').each(function(){
            var lightbox = $(this);
            lightbox.find('.close').bind('click.lightbox', function(e) {
                e.stopPropagation();
                $.lightbox(lightbox).hide('fast');
                return false;
            });
        });
    });
    
})(jQuery);
