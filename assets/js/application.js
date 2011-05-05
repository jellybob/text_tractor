$(function () {
  $('a').pjax('#content')

  $('dd p.translation').live('click', function () {
    $.ajax(document.location.href + "/" + $(this).parent().attr("data-key").replace(/\./g, "/"), {
      headers: {
        'X-PJAX': true
      },
      context: $(this).parent(),
      success: function (data) {
        $(this).html(data)
        $(this).find('textarea').focus()
      }
    })
  })
  
  $('dd form').live('submit', function () {
    $.ajax($(this).attr("action"), {
      type: $(this).attr("method"),
      data: $(this).serialize(),
      context: $(this).parent(),
      success: function (data) {
        $(this).html(data)
      },
      headers: {
        'X-PJAX': true
      }
    })

    return false;
  })
})
