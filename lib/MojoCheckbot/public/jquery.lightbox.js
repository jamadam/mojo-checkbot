/**
 * jquery.lightbox v0.03
 *
 * SYNOPSIS
 *
 * $.lightbox("target").show();
 * $.lightbox("target").hide();
 */
;(function($) {

    /**
     * plugin name
     */
    var plugname = 'lightbox';
    
    $[plugname] = $.sub();
    
    /**
     * Dependency
     */
    if (! $['customEventTrigger']) {
        throw('customEventTrigger is required');
    }
    
    function adjustPosition (obj) {
        obj.css({
            'marginTop': (-1 * obj.get(0).clientHeight / 2) + 'px',
            'marginLeft': (-1 * obj.get(0).clientWidth / 2) + 'px'
        });
    }
    
    /**
     * show
     */
    $[plugname].fn.show = function(speed, cb) {
        var obj = $(this);
        var wrapper = obj.wrap('<div class="lightboxContainer"></div>').parent(0);
        wrapper.prepend($('<div class="lightboxMask"></div>'));
        wrapper.bind('click.' + plugname, function() {
            $.lightbox(obj).hide('fast');
            return false;
        });
        obj.css({'top': '50%', 'left': '50%'});
        obj.fadeIn(speed, cb);
        $(obj).bind('resize.' + plugname, function() {
            adjustPosition(obj);
        });
        $(this).bind('click.' + plugname, function(e) {
            e.stopPropagation();
        });
        $.customEventTrigger(obj).add('resize.' + plugname,
            function(obj){
                return [obj.get(0).clientWidth, obj.get(0).clientHeight];
            },
            function(a, b){
                if (a !== undefined) {
                    return a[0] !== b[0] || a[1] !== b[1];
                }
                return 0;
            },
            10
        );
        adjustPosition(obj);
        return this;
    };
    
    /**
     * hide
     */
    $[plugname].fn.hide = function(speed, cb) {
        $(this).fadeOut(speed, function(e) {
            if ($(this).parent(0).hasClass('lightboxContainer')) {
                $(this).prev().remove();
                $(this).unwrap();
                $.customEventTrigger(this).remove('resize.' + plugname)
                $(this).unbind('resize.' + plugname);
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
            lightbox.find('.close').live('click.' + plugname, function(e) {
                e.stopPropagation();
                $.lightbox(lightbox).hide('fast');
                return false;
            });
        });
    });
    
})(jQuery);
