(function ($) {
  'use strict';
  window.tidyoffice = {
    checked: function () {
      return $('#list').find('.list-checkbox').filter(':checked').map(function () {
        return $(this).val();
      }).toArray().join(',');
    },
    select_all_checked: function (value) {
      return $('#list').find('.list-checkbox').prop('checked', value);
    }
  };
  $(document).ready(function () {
    $('select').selectize({ sortField: 'text' });
  });
})(jQuery);
