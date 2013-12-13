$(document).ready ->
  $("div.prop").each (i, el) ->
    el = $(el)
    file = el.data('file')
    prop = el.data('prop')
    inputs = el.children('input')
    input = $(inputs.get(0))
    saveBtn = $(el.children('.savebtn'))
    saveBtn.click ->
      $.post '/prop', {file:file, prop:prop, value:input.val()}, (data) ->
        console.log "Saved property #{prop}"
    $.get '/prop?file='+file+"&prop="+prop, (data) ->
      input.val data

  $("div.propArray").each (i, el) ->
    el = $(el)
    file = el.data('file')
    prop = el.data('prop')
    saveBtn = $(el.children('.savebtn'))
    inputs = []
    $.get '/prop?file='+file+"&prop="+prop, (data) ->
      for entry in data
        inputs.push $('<input>')
        l = inputs[inputs.length-1]
        l.val entry
        l.insertBefore saveBtn


