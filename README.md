# REST API рекрутинга

Лабораторная работа по главам 1–7: компании, вакансии, соискатели и отклики. Ruby 3.3.6, PostgreSQL 18.4, Bundler 4.0.12. В существующем `Gemfile.lock` установлен Rails 7.2.4; ограничение `~> 7.2.3` сохранено. Новые гемы не добавлены.

## Подключение и запуск

Команды выполнять из корня проекта. Локальный PostgreSQL обнаружен на порту **5433**. При другой конфигурации изменить `PGHOST`/`PGPORT` в окружении. Пароль берётся из `API_RAILS_PG_DATABASE_PASSWORD` или `PGPASSWORD`; файлы с паролями не нужны. `.env` автоматически не загружается.

```bash
cd /home/yan-kovalenko/RubymineProjects/api_rails_pg
unset DATABASE_URL
export PGHOST=127.0.0.1
export PGPORT=5433
export PGUSER=yanik_pryanik
read -rsp 'Пароль PostgreSQL: ' API_RAILS_PG_DATABASE_PASSWORD
export API_RAILS_PG_DATABASE_PASSWORD
printf '\n'
bundle check
bin/rails db:create
bin/rails db:migrate db:seed
RAILS_ENV=test bin/rails db:migrate
SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails db:create
bin/rails runner 'puts ActiveRecord::Base.connection.select_value("SELECT current_database()")'
bin/rails server -b 127.0.0.1 -p 3000
```

`db:create` создаёт development/test, только если они отсутствуют. Последняя команда создания БД отдельно проверяет production; `SECRET_KEY_BASE_DUMMY` используется только для этой служебной команды. Production не заполняется тестовыми данными. Для применения схемы к production при необходимости: `SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails db:migrate`.

Роль `yanik_pryanik` должна иметь LOGIN и доступ к указанным базам; для создания отсутствующих баз требуется CREATEDB. Если у роли нет CREATEDB, администратор может создать только нужные базы с владельцем `yanik_pryanik`. Приложению не требуются права superuser или изменения других баз.

`DATABASE_URL`, если он установлен, имеет приоритет над соответствующими параметрами `database.yml`. Имена БД по умолчанию: `api_rails_pg_development`, `api_rails_pg_test`, `api_rails_pg_production`.

## Проверка

В другом терминале задать те же переменные подключения и пароль:

```bash
bin/rails test
bin/rails zeitwerk:check
bin/rubocop
bundle exec brakeman --no-pager
curl -i http://localhost:3000/v1/companies
curl -i 'http://localhost:3000/v1/jobs?name=react&place=remote'
curl -i 'http://localhost:3000/v1/applies?read=false&invited=false'
```

Тесты используют только `api_rails_pg_test`, без дополнительных баз для параллельных workers. Это отдельная тестовая БД; не назначать ей development/production через `DATABASE_URL`.

В Postman импортировать [коллекцию](docs/postman/api_rails_pg.postman_collection.json), установить `base_url=http://localhost:3000`, запустить все запросы по порядку через Collection Runner. В коллекции 67 запросов и 166 проверок. Она создаёт собственные данные и сохраняет ID из ответов. Исходные данные методички не изменяются. Созданные ею компании и вакансии остаются с `deleted=true`, соискатель и его отклики удаляются.

## Маршруты

Все пути ниже начинаются с `/v1`. Контроллеры размещены в `Api::V1`.

| Метод | Путь | Назначение |
| --- | --- | --- |
| GET, POST | `/companies`, `/jobs`, `/geeks`, `/applies` | Список / создание |
| GET, PUT, PATCH, DELETE | `/companies/:id`, `/jobs/:id`, `/geeks/:id`, `/applies/:id` | Запись / изменение / удаление |
| GET, POST | `/companies/:company_id/jobs` | Вакансии компании / создание |
| GET, PUT, PATCH, DELETE | `/companies/:company_id/jobs/:id` | Вакансия указанной компании |
| GET | `/companies/:id/geeks` | Соискатели компании без дублей |
| GET | `/companies/:id/applies` | Отклики компании |
| GET | `/jobs/:id/geeks` | Соискатели вакансии без дублей |
| GET | `/companies/:company_id/jobs/:id/geeks` | То же в рамках компании |
| GET | `/jobs/:job_id/applies` | Отклики на вакансию |
| GET | `/companies/:company_id/jobs/:job_id/applies` | Отклики на вакансию компании |
| GET | `/geeks/:geek_id/applies` | Все отклики соискателя |
| GET | `/geeks/:id/read_applies` | Прочитанные отклики соискателя |
| GET | `/geeks/:id/invited_applies` | Приглашения соискателя |
| PUT | `/geeks/:id/resume` | Добавить / изменить текст резюме; `null` убирает его |
| PUT | `/applies/:id/mark_read` | Установить `read=true` |
| PUT | `/applies/:id/invite` | Установить `invited=true` |
| PUT | `/companies/:id/mark_deleted` | Мягкое удаление компании |

`GET /up` — стандартная проверка работоспособности Rails. Неизвестные пути, включая `/`, и неподходящие HTTP-методы возвращают JSON с HTTP 404.

Фильтры списка: компании — `name`, `location`; вакансии — `name`, `place`; соискатели — `name`, `stack`; отклики — `read`, `invited`. Текстовые фильтры ищут подстроку без учёта регистра, несколько фильтров соединяются через AND; `%` и `_` воспринимаются как обычные символы. Фильтры поддержаны и в соответствующих списках связанных записей. Значения boolean: JSON `true`/`false`, строки `true`/`false`, `1`/`0`. Например, `GET /v1/applies?read=true&invited=false` возвращает прочитанные отклонённые отклики. Сброс статуса и отказ в приглашении: `PUT /v1/applies/:id` с `{"read":false}` или `{"invited":false}`.

Вложенная вакансия ищется только среди вакансий компании из URL. Чужая вакансия возвращает 404; при создании и изменении вложенной вакансии `company_id` определяется URL.

## JSON и валидации

Запросы принимают JSON с `Content-Type: application/json`, как с обёрткой (`{"job":{...}}`), так и без неё. Query-параметры из примеров методички тоже поддержаны.

```json
{"name":"JS Angular","place":"Tomsk","company_id":4}
```

Допустимые поля: компания — `name, location`; вакансия — `name, place, company_id`; соискатель — `name, stack, resume`; отклик — `job_id, geek_id, read, invited`. `id`, `deleted` и временные метки не принимаются для массового присваивания.

Обязательные строковые поля не могут быть пустыми и имеют максимальную длину 255 символов. `resume` — необязательный текст. Внешние ID должны быть положительными целыми числами и ссылаться на существующие валидные записи. Статусы отклика допускают только boolean-значения; неверные значения не преобразуются незаметно в `true`. В БД установлены NOT NULL, внешние ключи и индексы связей.

Списки возвращаются как `{"jobs":[...]}` с соответствующим именем ресурса; одиночные записи — как объект. Сериализаторы явно задают поля, включают `id`, исключают timestamps. У компаний и вакансий возвращается `deleted`.

HTTP: 200 — чтение/изменение/удаление; 201 — создание; 400 — неверный JSON, структура параметров или boolean-фильтр; 404 — отсутствующая запись/маршрут; 422 — ошибки валидации (`{"errors":{...},"status":"unprocessable_entity"}`).

## Мягкое удаление и seeds

`DELETE /v1/companies/:id` и `PUT /v1/companies/:id/mark_deleted` вызывают `Company#delete_company`, сохраняют компанию, вакансии и отклики. `DELETE /v1/jobs/:id` тоже помечает вакансию согласно главе 5. Повтор возвращает HTTP 200 и `{"deleted_company":[],"deleted_already":"not_modified"}` (для вакансии — `deleted_job`). HTTP 304 не используется, поскольку ответ содержит JSON.

По образцу главы 7 удаление только меняет флаг: записи доступны в GET и возвращаются в списках с `deleted=true`. Соискатели и отдельные отклики удаляются физически; удаление соискателя удаляет его отклики, сохраняя вакансии.

Seeds содержат 4 компании, 7 вакансий, 9 соискателей и 4 отклика из методички. Они повторяемые, без очистки таблиц, сброса sequence и фиксированных ID. Boolean-примеры `resume` преобразованы в текст резюме или `nil`, поскольку в схеме методички это поле имеет тип text. Уже существующие записи и статусы не перезаписываются.

Подробный результат проверки и список файлов: [отчёт](docs/lab_report.md).
