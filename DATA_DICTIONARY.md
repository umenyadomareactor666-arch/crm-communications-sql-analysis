# Data Dictionary

## clients

| Поле | Тип | Описание |
|---|---|---|
| client_id | int | ID клиента |
| gender | varchar | Пол |
| age | int | Возраст |
| city | varchar | Город |
| segment | varchar | Клиентский сегмент |
| registration_date | date | Дата регистрации |
| is_active | boolean | Активен ли клиент |
| last_activity_at | date | Дата последней активности |

## campaigns

| Поле | Тип | Описание |
|---|---|---|
| campaign_id | int | ID кампании |
| campaign_name | varchar | Название CRM-кампании |
| channel | varchar | Канал коммуникации |
| product | varchar | Продукт |
| start_date | date | Дата старта |
| target_segments | varchar | Целевые сегменты |

## campaign_audience

| Поле | Тип | Описание |
|---|---|---|
| audience_id | int | ID записи аудитории |
| campaign_id | int | ID кампании |
| client_id | int | ID клиента |
| group_type | varchar | test или control |
| assigned_at | timestamp | Дата попадания в аудиторию |

## messages

| Поле | Тип | Описание |
|---|---|---|
| message_id | int | ID сообщения |
| campaign_id | int | ID кампании |
| client_id | int | ID клиента |
| channel | varchar | Канал |
| sent_at | timestamp | Время отправки |
| status | varchar | Статус доставки |

## message_events

| Поле | Тип | Описание |
|---|---|---|
| event_id | int | ID события |
| message_id | int | ID сообщения |
| event_type | varchar | sent, delivered, opened, clicked |
| event_at | timestamp | Время события |

## loan_applications

| Поле | Тип | Описание |
|---|---|---|
| application_id | int | ID заявки |
| client_id | int | ID клиента |
| campaign_id | int | ID кампании |
| product | varchar | Продукт |
| application_at | timestamp | Время заявки |
| status | varchar | approved или declined |
| requested_amount | numeric | Запрошенная сумма |
