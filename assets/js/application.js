$(function () {
  $('a').pjax('#content')

  $('dd p').live('click', function () {
    $.pjax({
      url: document.location.href + "/" + $(this).parent().attr("data-key").replace(/\./g, "/"),
      container: $(this).parent()
    })
  })
  
  $('dd form').live('submit', function () {
    $.pjax({
      url: $(this).attr("action"),
      type: $(this).attr("method"),
      data: $(this).serialize(),
      container: $(this).parent()
    })

    return false;
  })
})
