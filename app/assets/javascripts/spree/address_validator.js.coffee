Spree.lineHash =
  address1: 'line1'
  address2: 'line2'
  city: 'city'
  zipcode: 'postalCode'
  country: 'country'
  state: 'region'

class AddressValidator
  constructor: ->
    @$addressValidator = $('.address_validator')

  validate: ->
    address = this.formatAddress()
    Spree.ajax
      method: 'GET'
      url: Spree.routes.validate_address
      data:
        address: address
        state: 'address'
      success: ((data) ->
        if data.responseCode == 'error'
          return @showFlash(data)
        validatedAddress = data.validatedAddresses[0]
        wrapper = @addressWrapper()
        $.each [
          'address1'
          'address2'
          'city'
          'zipcode'
        ], (index, value) ->
          $(wrapper + ' input[id*=\'' + value + '\']').val validatedAddress[Spree.lineHash[value]]
        @showFlash data
      ).bind(this)

  formatAddress: ->
    address = {}
    wrapper = @addressWrapper()

    $(wrapper + ' input').not('select').each ->
      id = $(this).attr('id')
      line = Spree.lineHash[id.split('_').pop()]
      address[line] = $(this).val()

    $(wrapper + ' select').each ->
      id = $(this).attr('id')
      line = Spree.lineHash[id.slice(0, -3).split('_').pop()]
      address[line] = $(this).val()
    address

  addressWrapper: ->
    return '#business-address' if $('#business-address').length != 0

    if $('#order_use_billing').is(':checked')
      '#billing'
    else
      '#shipping'

  showFlash: (data) ->
    if data.responseCode == 'error'
      details = data.errorMessages.join(', ')
      window.show_flash 'error', 'Address Validation Error: ' + details
    else
      window.show_flash 'success', 'Address Validation Successful'

Spree.ready ($) ->
  $('.address_validator').click (e) ->
    e.preventDefault()
    new AddressValidator().validate()
