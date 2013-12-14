(function() {

  $(document).ready(function() {
    $("div.prop").each(function(i, el) {
      var file, input, inputs, prop, saveBtn;
      el = $(el);
      file = el.data('file');
      prop = el.data('prop');
      inputs = el.children('input');
      input = $(inputs.get(0));
      saveBtn = $(el.children('.savebtn'));
      saveBtn.click(function() {
        return $.post('/prop', {
          file: file,
          prop: prop,
          value: input.val()
        }, function(data) {
          return console.log("Saved property " + prop);
        });
      });
      return $.get('/prop?file=' + file + "&prop=" + prop, function(data) {
        return input.val(data);
      });
    });
    return $("div.propArray").each(function(i, el) {
      var file, inputs, prop, saveBtn;
      el = $(el);
      file = el.data('file');
      prop = el.data('prop');
      saveBtn = $(el.children('.savebtn'));
      inputs = [];
      return $.get('/prop?file=' + file + "&prop=" + prop, function(data) {
        var entry, l, _i, _len, _results;
        _results = [];
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          entry = data[_i];
          inputs.push($('<input>'));
          l = inputs[inputs.length - 1];
          l.val(entry);
          _results.push(l.insertBefore(saveBtn));
        }
        return _results;
      });
    });
  });

}).call(this);
