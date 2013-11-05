/*!
 * customEventTrigger 0.02 - Trigger events conditionally
 * 
 * https://github.com/jamadam/jquery-customEventTrigger
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
    var plugname = 'customEventTrigger';

    /**
     * inner class
     */
    var Class = function(elem, params){
        this.elem = elem;
        this.elem.data(plugname, this);
        this.params = params;
    }
    
    /**
     * add Conditional Trigger
     */
    Class.prototype.addGettingTrueEvent = function(eventName, newValue, interval){
        this.add(eventName, newValue, function(a, b){
            return ! a && b
        }, interval);
        return this;
    };
    
    /**
     * add change detect Trigger
     */
    Class.prototype.addChangeEvent = function(eventName, newValue, interval){
        this.add(eventName, newValue, function(a, b){
            return a !== b
        }, interval);
        return this;
    };
    
    /**
     * add change detect Trigger
     */
    Class.prototype.add = function(eventName, newValue, compare, interval){
        $(this.elem).each(function() {
            var obj = $(this);
            var a;
            var cb = function() {
                var b = newValue(obj);
                if (compare(a, b)) {
                    obj.trigger(eventName);
                }
                a = b;
            };
            cb();
            var tid = setInterval(cb, interval || 1);
            obj.data(generateTidDataName(eventName), tid);
        });
        return this;
    };
    
    /**
     * remove Trigger
     */
    Class.prototype.remove = function(eventName){
        $(this.elem).each(function() {
            var tidName = generateTidDataName(eventName);
            clearInterval($(this).data(tidName));
            $(this).removeData(tidName);
        });
        return this;
    };
    
    /**
     * generate tid name that stored into data
     */
    function generateTidDataName(eventName) {
        return 'tid.' + eventName + '.' + plugname;
    }

    /**
     * default parameters
     */
    var default_params = {

    };

    /**
     * Common constructer
     */
    $.fn[plugname] = function(params){
        return new Class(this, $.extend(default_params, params, {}));
    }
})(jQuery);
