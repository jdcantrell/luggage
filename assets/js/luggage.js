$(function () {
  $('.image img').bind('click', function () {
    $(this).toggleClass('full');
  });

  $('.view-tabs').tabs();

  //This code deals with the original upload form
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

  $('#toggle_form').bind('click', function () {
    $('#file_api').hide();
    $('#fallback').show();
  });

  //TODO: Add in File.API code (replaces the above forms)
  if (typeof FileReader === "function") {
    
    $('#fallback').hide();
    $('#file_api').show();

    //replace the above forms with drag and drop area
    //https://developer.mozilla.org/en/Using_files_from_web_applications
    //http://stackoverflow.com/questions/4722500/html5s-file-api-example-with-jquery
    //http://stackoverflow.com/questions/5157361/jquery-equivalent-to-xmlhttprequests-upload
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
      dragend: function (event) {
        $(this).addClass('info');
        $(this).removeClass('success');
        event.preventDefault();
      },
      drop: function (event) {
        event.preventDefault();
        var originalEvent = event.originalEvent
        var files = ( originalEvent.files || originalEvent.dataTransfer.files )
        for (var i = 0; i < files.length; i += 1) {
          console.log(files[i]);
          upload_file(files[i]);
        }
        console.log('drop');
      }
    });
  }

  function add_file(data) {
    var rowHTML = '<tr><td><a href="/open/{key}">{name}</a></td><td>0</td><td>{created_at}</td></tr>';
    var newRow = rowHTML.replace('{key}', data.item.key).replace('{name}', data.item.name).replace('{created_at}', data.item.created_at)
    $('.file-list > tbody > tr').first().before(newRow);
  }

  function upload_file(file) {
    //using XHR directly because jquery does not expose the upload
    //property - works in chrome and FF (IE shouldn't get this code)
    var xhr = new XMLHttpRequest();
    
    xhr.upload.addEventListener("progress", function (e) {
      if (e.lengthComputable) {
        var percentage = Math.round((e.loaded * 100) / e.total);
        console.log('percentage', percentage);
      }
    }, false);
    
    xhr.onreadystatechange = function() { 
     if (xhr.readyState == 4) {
       if ((xhr.status >= 200 && xhr.status <= 200) || xhr.status == 304) {
          if (xhr.responseText != "") {
            var item = $.parseJSON(xhr.responseText)
            add_file(item);
          } 
       } 
     }
    }

    data = new FormData()
    data.append('upload', file);
    data.append('json', true);

    xhr.open("POST", "upload");
    xhr.send(data);

  }

  //Edit Handlers
  $('a[href*=edit]').bind('click', function (event) {
    $('#edit_form').modal({backdrop: true, keyboard: true, show:true});
    event.preventDefault();
  });
});
