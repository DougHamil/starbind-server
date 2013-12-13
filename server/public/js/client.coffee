$(document).ready ->

  launch = ->
    $.get '/launch'

  sync = ->
    host = $("#hostInput").val()
    console.log host
    if not host? or host is ""
      alert("Please specify a server to synchronize with.")
    else
      $.post("/sync", {host:host})
        .fail ->
          $("#info").html("<div class=\"fail\">Failed to connect to Starbind server at <b>#{host}</b>.<br/>Please verify the server information is correct and retry.</div>")
          $("#launchBtn").hide()
          $("#launchBtn").show()
        .done ->
          $("#info").html("<div class=\"success\">Successfully synchronized to <b>#{host}</b></div>")
          $("#launchBtn").show()

  $("#launchBtn").hide()
  $("#launchBtn").click ->
    launch()

  $("#syncBtn").click ->
    sync()

  $(window).keydown (event) ->
    if event.keyCode == 13
      if not $("#launchBtn").is(":visible")
        sync()
      else
        launch()
      event.preventDefault()
      return false;
