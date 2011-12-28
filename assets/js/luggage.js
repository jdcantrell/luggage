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
        var originalEvent = event.originalEvent
        var files = ( originalEvent.files || originalEvent.dataTransfer.files )
        for (var i = 0; i < files.length; i += 1) {
          //queue objects to be uploaded
          upload_file(files[i]);
        }
      }
    });
  }

});

//TODO: upload_file probably needs to be a queue object
//it'll need to handle updating the interface as well as getting a list
//of files uploaded incase of multiple upload
function add_file(data) {
  var rowHTML = '<tr><td><a href="open/{key}">{name}</a></td><td>0</td><td><span class="label success">New!</span> </td></tr>';
  var newRow = rowHTML.replace('{key}', data.item.key).replace('{name}', data.item.name)
  $('.file-list > tbody > tr').first().before(newRow);
}

function upload_file(file) {
  //using XHR directly because jquery does not expose the upload
  //property - works in chrome and FF (IE shouldn't get this code)
  var xhr = new XMLHttpRequest();
  
  xhr.upload.addEventListener("progress", function (e) {
    if (e.lengthComputable) {
      var percentage = Math.round((e.loaded * 100) / e.total);
      //TODO: show progress on ui
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

  data = new FormData();
  data.append('upload', file);
  data.append('json', true);

  xhr.open("POST", "upload");
  xhr.send(data);
}

