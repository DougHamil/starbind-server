(function() {

  $(document).ready(function() {
    var launch, sync;
    launch = function() {
      return $.get('/launch');
    };
    sync = function() {
      var host;
      host = $("#hostInput").val();
      console.log(host);
      if (!(host != null) || host === "") {
        return alert("Please specify a server to synchronize with.");
      } else {
        return $.post("/sync", {
          host: host
        }).fail(function() {
          $("#info").html("<div class=\"fail\">Failed to connect to Starbind server at <b>" + host + "</b>.<br/>Please verify the server information is correct and retry.</div>");
          $("#launchBtn").hide();
          return $("#launchBtn").show();
        }).done(function() {
          $("#info").html("<div class=\"success\">Successfully synchronized to <b>" + host + "</b></div>");
          return $("#launchBtn").show();
        });
      }
    };
    $("#launchBtn").hide();
    $("#launchBtn").click(function() {
      return launch();
    });
    $("#syncBtn").click(function() {
      return sync();
    });
    return $(window).keydown(function(event) {
      if (event.keyCode === 13) {
        if (!$("#launchBtn").is(":visible")) {
          sync();
        } else {
          launch();
        }
        event.preventDefault();
        return false;
      }
    });
  });

}).call(this);
