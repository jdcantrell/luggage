$(function () {
  //This code is for /open/file
  $('.image img').bind('click', function () {
    $(this).toggleClass('full');
  });

  $('.view-tabs').tabs();

  $('a[href*=edit]').bind('click', function (event) {
    $('#edit_form').modal({backdrop: true, keyboard: true, show:true});
    event.preventDefault();
  });

  $('#edit_save').click(function () {
    $('#edit_form').find('form').submit();
  });

  if (typeof prettyPrint === "function") {
    prettyPrint();
  }

  //This code is for the index/uploaders
  $('#upload_input input').bind('change', function () {
    if ($(this).val() !== "") {
      $('#upload_input').removeClass('error');
    }
  });

  $('#upload_form').bind('submit', function () {
    if ($('#upload').val() === "") {
      $('#upload_input').addClass('error');
      event.preventDefault();
    }
    else {
      $('#upload_input').removeClass('error');
      $('#upload_submit').val('Uploading file...').button('loading');
    }
  });

  //Index page code

  //generic confirmation code
  $('a.confirm').bind('click', function (event) {
    $('.confirm_button').attr('href', this.href);
    $('.confirm_button').parents('.modal').modal({backdrop: true, keyboard: true, show:true});
    event.preventDefault();
  });

  $('.cancel_button').click(function () {
    $(this).parents('.modal').modal('hide');
  });

  //file api code
  if (typeof FileReader === "function") {

    $('#toggle_form').bind('click', function () {
      $('#file_api').hide();
      $('#fallback').show();
    });

    //hide the original form and show the dnd uploader
    $('#fallback').hide();
    $('#file_api').show();

    //add our dnd listeners
    $('#drag_area').bind({
      dragover: function (event) {
        $(this).addClass('success');
        $(this).removeClass('info');
        event.preventDefault();
      },
      dragleave: function (event) {
        $(this).addClass('info');
        $(this).removeClass('success');
        event.preventDefault();
      },
      drop: function (event) {
        $(this).addClass('info');
        $(this).removeClass('success');
        event.preventDefault();
        var originalEvent = event.originalEvent;
        var files = ( originalEvent.files || originalEvent.dataTransfer.files);
        for (var i = 0; i < files.length; i += 1) {
          //queue objects to be uploaded
          uploadFile(files[i]);
        }
      }
    });
  }

});

var uploadFile = function () {
  var files = [];
  var uploading = false;
  var _uploadComplete = function(data) {
    var rowHTML = '<tr><td><a href="open/{key}">{name}</a></td><td>0</td><td><span class="label success">New!</span> </td><td class="remove"><a href="remove/{key}">&times;</a></td></tr>';
    var newRow = rowHTML.replace(/\{key\}/g, data.item.key).replace('{name}', data.item.name);
    $('.file-list > tbody > tr').first().before(newRow);
    $('#no_files').parent().remove();

    if (files.length) {
      var file = files.pop();
      _beginUpload(file);
    }
    else {
      uploading = false;
      $('#upload_status').html('All files uploaded. Ready to go!');
    }
  };

  var _beginUpload  = function(file) {
    //using XHR directly because jquery does not expose the upload
    //property - works in chrome and FF (IE shouldn't get this code)
    uploading = true;
    var xhr = new XMLHttpRequest();

    xhr.upload.addEventListener("progress", function (e) {
      if (e.lengthComputable) {
        var percentage = Math.round((e.loaded * 100) / e.total);
        $('#upload_status').html('Uploading ' + file.name + ' ' + percentage + '% complete.');
      }
    }, false);

    xhr.onreadystatechange = function() {
      if (xhr.readyState == 4) {
        if ((xhr.status >= 200 && xhr.status <= 200) || xhr.status == 304) {
          if (xhr.responseText !== "") {
            var item = $.parseJSON(xhr.responseText);
            _uploadComplete(item);
          }
        }
      }
    };

    data = new FormData();
    data.append('upload', file);
    data.append('json', true);

    xhr.open("POST", "upload");
    xhr.send(data);
  };

  //external methods here
  return function (file) {
    if (!files.length && !uploading) {
      _beginUpload(file);
    }
    else {
      files.push(file);
    }
  };

}();
