/*!
 * jquery.jmdmbox v0.02
 *
 * SYNOPSIS
 *
 * var instance = $('#target').jmdmbox();
 * instance.show();
 * instance.hide();
 * instance.centering();
 * 
 * Copyright (c) jamadam
 * 
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 */
;(function($) {

    /**
     * plugin name
     */
    var plugname = 'jmdmbox';
    
    /**
     * inner class
     */
    var Class = function(elem, params){
        this.elem = elem;
        this.elem.data(plugname, this);
        this.params = params;
    }
    
    /**
     * Center the box
     */
    Class.prototype.centering = function() {
        this.elem.css({
            'marginTop': (-1 * this.elem.get(0).clientHeight / 2) + 'px',
            'marginLeft': (-1 * this.elem.get(0).clientWidth / 2) + 'px'
        });
        
        return this;
    }
    
    /**
     * show
     */
    Class.prototype.show = function(speed, cb1, cb2) {
        var obj = this;
        var wrapper = this.elem.wrap('<div></div>').parent(0);
        wrapper.addClass('lightboxContainer');
        wrapper.prepend($('<div class="lightboxMask"></div>'));
        
        wrapper.find('.lightboxMask').on('click.' + plugname, function(){
            obj.hide(speed, cb2);
        });
        
        wrapper.find('.close').on('click.' + plugname, function(){
            obj.hide(speed, cb2);
        });
        
        wrapper.find('.lightboxMask').css(this.params['mask-style']);
        
        wrapper.css({
            'position': 'relative',
            'zIndex': this.params['z-index'],
        });
        
        this.elem.css({
            'position' : 'fixed',
            'top': '50%',
            'left': '50%'
        });
        
        this.elem.fadeIn(speed, cb1);
        
        this.elem.on('click.' + plugname, function(e) {
            e.stopPropagation();
        });
        
        this.centering();
        
        return this;
    };
    
    /**
     * hide
     */
    Class.prototype.hide = function(speed, cb) {
        this.elem.fadeOut(speed, function(e) {
            if ($(this).parent(0).hasClass('lightboxContainer')) {
                $(this).prev().remove();
                $(this).unwrap();
                $(this).off('resize.' + plugname);
            }
            if (cb != undefined) {
                cb.call(this, e);
            }
        });
        this.elem.find('.close').off('click.' + plugname);
        return this;
    };
    
    /**
     * default params
     */
    var default_params = {
        'mask-style' : {
            'position':'fixed',
            'top':'0',
            'left':'0',
            'width':'100%',
            'height':'100%',
            'opacity':'0.7',
            'filter': 'alpha(opacity=70)',
            'backgroundColor':'#000'
        },
        'z-index' : 4000
    };

    /**
     * register constructer
     */
    $.fn[plugname] = function(params){
        return new Class(this, $.extend(default_params, params, {}));
    }
})(jQuery);