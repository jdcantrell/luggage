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
});
