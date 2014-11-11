$.fn.usecodeAutocomplete = function () {
    'use strict';

    this.select2({
        minimumInputLength: 1,
        multiple: false,
        initSelection: function (element, callback) {
            $.get(Spree.routes.use_code_search, {
                ids: element.val()
            }, function (data) {
                console.log(JSON.stringify(data));
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
            if(use_codes.use_code === undefined || use_codes.use_code === ""){
                return "Enter Avalara Entity Use Code"
            } else {
                return use_codes.use_code + ') Description: ' + use_codes.use_code_description;
            }
        },
        formatSelection: function (use_codes) {
            if(use_codes.use_code === undefined || use_codes.use_code === ""){
                return "Enter Avalara Entity Use Code"
            } else {
                return use_codes.use_code + ') Description: ' + use_codes.use_code_description;
            }
        }
    });

    function log(e) {
        alert(e);
    }


};

$(document).ready(function () {
    $('.use_code_picker').usecodeAutocomplete();
});
