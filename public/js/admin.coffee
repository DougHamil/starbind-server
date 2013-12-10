$(document).ready ->
  $("#startServerBtn").click ->
    $(@).prop("disabled",true)
    $.get('/admin/server/start')
      .done ->
        location.reload()
      .fail ->
        $("#status #info").html("<div class=\"fail\">Failed to start server.<div>")
        $("#startServerBtn").prop("disabled", false)
  $("#stopServerBtn").click ->
    $(@).prop("disabled",true)
    $.get('/admin/server/stop')
      .done ->
        location.reload()
      .fail ->
        $("#status #info").html("<div class=\"fail\">Failed to stop server.<div>")
        $("#stopServerBtn").prop("disabled", false)

  logEl = $("#log")
  updateLogs = ->
    $.get('/admin/server/logs')
      .done (data) ->
        logEl.html("")
        for log in data
          console.log log.message
          div = $('<div>').addClass('logmessage')
          if log.type == 'err'
            div.addClass 'err'
          div.text(log.message)
          logEl.append div
  setInterval updateLogs, 2000

  modsEl = $("#mods")
  updateMods = ->
    $.get('/admin/mods/index')
      .done (data) ->
        console.log data
        modsEl.html("")
        for file, metadata of data
          div = $("<div>").addClass("modentry")
          name = metadata.name || file
          author = metadata.author || "Unknown"
          if author isnt 'Unknown'
            author = 'by '+author
          version = metadata.version || "Unknown"
          $("<div>").addClass('name').text(name).appendTo(div)
          $("<div>").addClass('version').text("Version: "+version).appendTo(div)
          $('<div>').addClass('author').text(author).appendTo(div)
          modsEl.append(div)
  updateMods()

