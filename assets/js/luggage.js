$(function () {
  $('.image img').bind('click', function () {
    $(this).toggleClass('full');
  });

  $('.view-tabs').tabs()
});
