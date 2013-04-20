# -*- coding: utf-8 -*-
module Hikkmemo
  module Util
    module_function
    def delocalize_ru_date(string)
      string.gsub /Пнд|Втр|Срд|Чтв|Птн|Суб|Вск|Янв|Фев|Мар|Апр|Май|Июн|Июл|Авг|Сен|Окт|Ноя|Дек/, {
        'Пнд' => 'Mon', 'Втр' => 'Tue', 'Срд' => 'Wed',
        'Чтв' => 'Thu', 'Птн' => 'Fri', 'Суб' => 'Sat', 'Вск' => 'Sun',
        'Янв' => 'Jan', 'Фев' => 'Feb', 'Мар' => 'Mar', 'Апр' => 'Apr', 'Май' => 'May', 'Июн' => 'Jun',
        'Июл' => 'Jul', 'Авг' => 'Aug', 'Сен' => 'Sep', 'Окт' => 'Oct', 'Ноя' => 'Nov', 'Дек' => 'Dec'
      }
    end
  end
end
