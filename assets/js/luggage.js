$(function () {
  $('.image img').bind('click', function () {
    $(this).toggleClass('full');
  });

  $('.view-tabs').tabs()

  //This code deals with the original upload form
  $('#upload_input input').bind('change', function () {
    if ($(this).val() !== "") {
      $('#upload_input').removeClass('error')
    }
  })

  $('#upload_form').bind('submit', function () {
    if ($('#upload').val() == "") {
      $('#upload_input').addClass('error')
      event.preventDefault()
    }
    else {
      $('#upload_input').removeClass('error')
      $('#upload_submit').val('Uploading file...');
      $('#upload_submit').button('loading');
    }
  });

  //TODO: Add in File.API code (replaces the above forms)
  if (typeof FileReader === "function") {
    //replace the above forms with drag and drop area
    //https://developer.mozilla.org/en/Using_files_from_web_applications
    //http://stackoverflow.com/questions/4722500/html5s-file-api-example-with-jquery
    //http://stackoverflow.com/questions/5157361/jquery-equivalent-to-xmlhttprequests-upload
  }

  //Edit Handlers
  $('a[href*=edit]').bind('click', function (event) {
    $('#edit_form').modal({backdrop: true, keyboard: true, show:true});
    event.preventDefault();
  })
});
