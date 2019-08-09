// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

$.widget("custom.catcomplete", $.ui.autocomplete, {
  _renderMenu: function( ul, items ) {
    var that = this;
    currentCategory = "";
    $.each( items, function( index, item ) {
      cat = item.category || '';
      if ( cat != currentCategory ) {
        ul.append( "<li class='ui-autocomplete-category'>" + cat + "</li>" );
        currentCategory = cat;
      }
      that._renderItemData( ul, item );
    });
  }
});

$.widget("custom.configcomplete", $.custom.catcomplete, {
  options: {
    _cache: {},
    minLength: 0,
    matchContains: true,
    source: function( request, response ) {
      var cache = this.options._cache;
      var term = this.options.url + request.term;
      if ( term in cache ) {
        response( cache[ term ] );
        return;
      }

      $.getJSON( '/config/complete/' + this.options.url, request ).done(function( json ) {
        // cache[ term ] = json;
        response( json );
      });
    },
  },
  _create: function() {
    this._super();
    $(this).focus(function(){
      alert('aa');
      $(this).autocomplete('search');
    });
  }
});

function onChangeLanguage() {
  var lang = $("#lang").val();

  $.ajax({
    type: 'PUT',
    url: '/i18n?lang=' + lang
  }).done(function(jsonData){
    showStatus('Language changed, please wait...', 'success');
    location.reload(true);
  }).fail(function(xhr, status){
    showStatus('Something wrong when changing language!', 'fail');
  });
}

// intercept form submit to do it with ajax
function ajaxSubmit(form) {
  form.submit(function() {
    var valuesToSubmit = $(this).serialize();
    $.ajax({
      url: $(this).attr('action'), //sumbits it to the given url of the form
      method: 'POST',
      data: valuesToSubmit,
      dataType: "JSON" // you want a difference between normal and ajax-calls, and json is standard
    }).success(function(json){
      if (json.success)
        showStatus('Success~', 'success');
      else
        showStatus('Failed!', 'fail');
    }).fail(function(xhr, status) {
      showStatus('Something wrong!', 'fail');
    });
    return false; // prevents normal behaviour
  });
}

// display flash (auto disappear)
function showStatus2(flash, flashContent, text, color) {
  flash.css('background-color', color)
  flashContent.text(text)
  flash.show()
  setTimeout(function () { flash.fadeOut() }, 2000)
}

// intercept form submit to do it with ajax
function ajaxSubmit2(flash, flashContent, form) {
  form.submit(function() {
    var valuesToSubmit = $(this).serialize();
    $.ajax({
        url: $(this).attr('action'), //sumbits it to the given url of the form
        method: 'POST',
        data: valuesToSubmit,
        dataType: "JSON" // you want a difference between normal and ajax-calls, and json is standard
    }).success(function(json){
        if (json.success)
            showStatus2(flash, flashContent, 'Success~', 'green');
        else
            showStatus2(flash, flashContent, 'Failed: ' + json.reason, 'red');
    }).fail(function(xhr, status) {
        showStatus2(flash, flashContent, 'Something wrong!', 'red');
    });
    return false; // prevents normal behaviour
  });
}

// intercept form submit to do it with ajax and with confirm
function ajaxSubmitWithConfirm(form, text) {
  form.submit(function() {
    if (confirm(text)) {
      var valuesToSubmit = $(this).serialize();
      $.ajax({
        url: $(this).attr('action'), //sumbits it to the given url of the form
        method: 'POST',
        data: valuesToSubmit,
        dataType: "JSON" // you want a difference between normal and ajax-calls, and json is standard
      }).success(function(json){
        if (json.success)
          showStatus('Success~', 'success');
        else
          showStatus('Failed!', 'fail');
      }).fail(function(xhr, status) {
        showStatus('Something wrong!', 'fail');
      });
    } else {
      // do nothing
    }
    return false; // prevents normal behaviour
  });
}
