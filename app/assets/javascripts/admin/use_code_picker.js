$.fn.usecodeAutocomplete = function () {
    'use strict';

    this.select2({
        minimumInputLength: 1,
        multiple: false,
        initSelection: function (element, callback) {
            //console.log(element.val());
            $.get(Spree.routes.use_code_search, {
                ids: element.val()
            }, function (data) {
                console.log( JSON.stringify(data));
                callback(data[0]);
            });
        },
        ajax: {
            url: Spree.routes.use_code_search,
            datatype: 'json',
            data:  function (term) {
                return {
                    q: term
                };
            },
            results: function (data) {
                return {
                    results: data
                };
            }
        },
        formatResult: function (use_codes) {
            return use_codes.use_code + ') Description: ' + use_codes.use_code_description;
        },
        formatSelection: function (use_codes) {
            return use_codes.use_code + ') Description: ' + use_codes.use_code_description;
        }
    });

    function log(e) {
        //var e=$("<li>"+e+"</li>");
        alert(e);
        //$("#events_11").append(e);
        //e.animate({opacity:1}, 10000, 'linear', function() { e.animate({opacity:0}, 2000, 'linear', function() {e.remove(); }); });
    }


};

$(document).ready(function () {
    $('.use_code_picker').usecodeAutocomplete();
});
