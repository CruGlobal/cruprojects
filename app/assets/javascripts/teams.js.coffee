$ ->
  $('.js-commits').on 'click', ->
    $('#js-commits_' + $(this).attr('data-login')).dialog({width: 'auto'})
    false

$.dash = {}
$.dash.showSpinner = ->
  $('#spinner-div').dialog({modal: true, closeOnEscape: false})

$.dash.hideSpinner = ->
  $('#spinner-div').dialog('close') if $('#spinner-div').hasClass('ui-dialog-content')

$(document).on 'ajax:before', 'a', ->
  $.dash.showSpinner()

$(document).ajaxComplete ->
  $.dash.hideSpinner()

$(document).on 'click', '.toggle_view', ->
  id = $(this).data('id')
  $('#categories_' + id).toggle()
  $('#detail_' + id).toggle()
