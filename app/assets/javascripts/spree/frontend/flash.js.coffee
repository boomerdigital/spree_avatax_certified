window.show_flash = (type, message) ->
  $addressValidator = $('.address_validator')
  $flashWrapper = $(".js-flash-wrapper")

  if type == 'success'
    $flashWrapper.find('.error.flash').hide()
    $addressValidator.attr('disabled', true).text(message).addClass('flash success disabled')
  else
    if $flashWrapper.length == 0
      $addressValidator.before("<div class=\"js-flash-wrapper\" />")
      $flashWrapper = $(".js-flash-wrapper")
    $flashWrapper.empty()
    flash_div = $("<div class='flash " + type + "' />")
    $flashWrapper.prepend(flash_div)
    flash_div.html(message).show()
