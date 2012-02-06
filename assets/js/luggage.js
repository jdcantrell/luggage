/*jshint forin:true, noarg:true, noempty:true, eqeqeq:true, bitwise:true, undef:true, curly:true, browser:true, jquery:true, indent:2, maxerr:50 */
$(function () {
  //This code is for /view/file
  $('.image img').bind('click', function () {
    $(this).toggleClass('full');
  });

  $('a[href*=edit]').bind('click', function (event) {
    $('#edit_form').modal('show');
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

  //generic confirmation code
  $('a.confirm').bind('click', function (event) {
    $('.confirm_button').attr('href', this.href);
    event.preventDefault();
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
        var files = (originalEvent.files || originalEvent.dataTransfer.files);
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
  var _uploadComplete = function (data) {
    var rowHTML = '<tr><td><a href="view/{key}">{name}</a></td><td>0</td><td><span class="label label-success">New!</span> </td><td class="remove"><a href="/remove/{key}" class="confirm" data-target="#confirm_remove" data-toggle="modal"><span class="icon-remove"></span></a></td></tr>';
    var newRow = rowHTML.replace(/\{key\}/g, data.item.key).replace('{name}', data.item.name);
    $('.file-list > tbody > tr').first().before(newRow);
    $('#no_files').parent().remove();

    if (files.length) {
      var file = files.pop();
      _beginUpload(file);
    }
    else {
      uploading = false;
      $('#upload_status_text').html('All files uploaded. Ready to go!');
      $('#upload_status_bar').hide();
      $('#upload_status_progress_text').hide();
      $('#upload_status_text').show();
    }
  };

  var _beginUpload  = function (file) {
    //using XHR directly because jquery does not expose the upload
    //property - works in chrome and FF (IE shouldn't get this code)
    uploading = true;
    var xhr = new XMLHttpRequest();

    $('#upload_status_text').hide();
    $('#upload_status_progress').css("width", 0);
    $('#upload_status_bar').show();
    $('#upload_status_progress_text').show();

    xhr.upload.addEventListener("progress", function (e) {
      if (e.lengthComputable) {
        var percentage = Math.round((e.loaded * 100) / e.total);
        $('#upload_status_progress_text').html("Uploading " + file.name + '. ' + files.length + " more queued for upload.");
        $('#upload_status_progress').css("width", percentage + '%');
      }
    }, false);

    xhr.onreadystatechange = function () {
      if (xhr.readyState === 4) {
        if ((xhr.status >= 200 && xhr.status <= 200) || xhr.status === 304) {
          if (xhr.responseText !== "") {
            var item = $.parseJSON(xhr.responseText);
            _uploadComplete(item);
          }
        }
      }
    };

    var data = new FormData();
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
