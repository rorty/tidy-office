# Tidy Office
Tidy Office – очень простое Web приложение, для учета расходных материалов и оборудования

<table border="0">
  <tr>
    <td align="center">
      <a href="https://github.com/Rorty/tidy-office/blob/main/public/images/devices.PNG" target="_blank">
        <img src="https://github.com/Rorty/tidy-office/blob/main/public/images/devices_t.png">
      </a>
      <br />
      <p>Устройства</p>
    </td>
    <td align="center">
      <a href="https://github.com/Rorty/tidy-office/blob/main/public/images/device_models.PNG" target="_blank">
        <img src="https://github.com/Rorty/tidy-office/blob/main/public/images/device_models_t.png">
      </a>
      <br />
      <p>Модели устройств</p>
    </td>
    <td align="center">
      <a href="https://github.com/Rorty/tidy-office/blob/main/public/images/from_service.PNG" target="_blank">
        <img src="https://github.com/Rorty/tidy-office/blob/main/public/images/from_service_t.png">
      </a>
      <br />
      <p>После обслуживания</p>
    </td>
    <td align="center">
      <a href="https://github.com/Rorty/tidy-office/blob/main/public/images/show.PNG" target="_blank">
        <img src="https://github.com/Rorty/tidy-office/blob/main/public/images/show_t.png">
      </a>
      <br />
      <p>Просмотр устройства</p>
    </td>
    <td align="center">
      <a href="https://github.com/Rorty/tidy-office/blob/main/public/images/to_issue.PNG" target="_blank">
        <img src="https://github.com/Rorty/tidy-office/blob/main/public/images/to_issue_t.png">
      </a>
      <br />
      <p>Выдача картриджа</p>
    </td>
  </tr>
</table>

Возможности:
- Поиск и фильтрация по типам устройств и картриджей
- Выдача картриджа и прием ранее выданного картриджа за одно действие
- История изменения состояний
- История сервисного обслуживания
- Заметки
- Итоги по изменению состояний и динамики устройств/картриджей
- Вывод этикеток для печати

## Модели
Содержит списки:
- Местонахождение - Список помещений. Поддерживается древовидная структура
- Типы устройств/картриджей - Все устройства группируются по типам например: Компьютер, Монитор, Ноутбук, Принтер, Сетевое оборудование. Установите галочку "совместимость" для принтеров. 
- Производители - Список производителей устройств и картриджей
- Модели устройств/картриджей - Список моделей.

## Устройства/картриджи
Состояния Устройств/картриджей:
- Резервные — находящиеся на складе;
- Выданные/Установленные — выданные в пользование картриджи / установленное устройство в помещении;
- Принятые/Демонтированные — принятые картриджи, например по причине израсходованного тонера / демонтированные устройства;
- Обслуживаются — отданные на сервисное обслуживание, заправка или ремонт;
- Списанные

## События
Основные события по перемещению всех объектов
## Отчеты
Несколько отчетов для аналитики

## Системные требования
- Ruby 2.7+
- Microsoft SQL Server

## Установка
1. Установить набор библиотек FreeTDS
2. Установить в корень проекта шрифты consola.ttf, consolab.ttf, consolai.ttf, consolaz.ttf для генерации этикеток
3. Создать базу данных
4. Отредактировать config/database.rb и config/config.yml
5. bundle install
6. rake db:migrate:up
7. RAILS_ENV=development puma -p 3000

## Установка контейнера
1. Установить в корень проекта шрифты consola.ttf, consolab.ttf, consolai.ttf, consolaz.ttf для генерации этикеток
2. Создать базу данных
3. Отредактировать config/database.rb и config/config.yml
4. docker-compose up -d
5. docker-compose exec web bundle exec rake db:migrate:up