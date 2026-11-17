# Результат выполнения лабораторной работы

Проверка выполнена 4 ноября 2026 года. Приложение реализует практические задания глав 1–7. Подключение к основному PostgreSQL успешно проверено после предоставления пароля пользователем; миграции применены, seeds загружены в development, тесты прошли.

## Выполнение по главам

| Глава | Результат |
| --- | --- |
| 1 | Реализован API рекрутинга: все CRUD-операции, фильтры, связанные записи, работа с резюме, прочтение и приглашение/отказ по отклику. |
| 2 | Сохранён существующий API-проект, `ActionController::API`, Puma и текущие зависимости. Frontend, авторизация, новые сервисы и гемы не добавлены. |
| 3 | Настроены три окружения PostgreSQL под `yanik_pryanik`, пароль из Rails credentials с возможностью переопределения через ENV, порт обнаруженного сервера 5433. Rails/Puma запущен и проверен. Подключение к основному кластеру успешно; миграции применены во всех трёх базах. |
| 4 | Четыре модели, шесть миграций, внешние ключи, индексы, NOT NULL, ассоциации, валидации, данные из примеров, маршруты `/v1` и вложенные вакансии компании. |
| 5 | JSON-сериализаторы на встроенных средствах Rails, обработка отсутствующей записи, неверного маршрута, параметров и JSON; четыре ресурсных контроллера. Удаление вакансии сохраняет запись с признаком удаления. |
| 6 | Выполнены запросы с ассоциациями, валидациями, созданием и удалением; подготовлена Postman Collection v2.1. Проверены все прикладные маршруты, включая PATCH, автоматизированными интеграционными тестами. |
| 7 | Отдельная миграция `companies.deleted`, метод `delete_company`, PUT `mark_deleted` и мягкий DELETE. Повторное удаление проверено; компания, её вакансии и отклики сохраняются. |

Существующая версия Rails — 7.2.4 из Gemfile.lock, совместимая с ограничением `~> 7.2.3`. Обновления зависимостей не выполнялись. Изменение Gemfile только удаляет две лишние пустые строки для прохождения существующей проверки RuboCop.

## PostgreSQL

Основной PostgreSQL 18.4 доступен на `127.0.0.1:5433`. После предоставления пароля пользователем подключение Rails и psql с ролью `yanik_pryanik` успешно проверено. При первоначальной проверке пароль передавался через окружение процесса. По запросу пользователя 14 ноября 2026 года пароль сохранён в зашифрованных Rails credentials (`database.password`), чтобы приложение запускалось без ручного ввода. Ключ `config/master.key` исключён из Git; открытый пароль в файлы проекта не записан. Переменные окружения сохраняют приоритет над credentials.

После изменения 14 ноября проверено подключение к development и выполнен `bin/rails test` без переменных `DATABASE_URL`, `API_RAILS_PG_DATABASE_PASSWORD`, `PGPASSWORD`, `PGHOST`, `PGPORT`, `PGUSER`: 41 тест, 409 проверок, 0 failures, 0 errors, 0 skips. Подключение использует пароль из credentials автоматически.

Все три базы уже существовали, принадлежали `yanik_pryanik` и не содержали таблиц в схеме public. Все шесть миграций применены к `api_rails_pg_development`, `api_rails_pg_test`, `api_rails_pg_production`. Seeds загружены только в development: 4 компании, 7 вакансий, 9 соискателей, 4 отклика. Повторный запуск seeds оставил эти количества неизменными. Production тестовыми данными не заполнялась.

`bin/rails test` выполнен на основном PostgreSQL с отдельной `api_rails_pg_test`: 41 тест, 409 проверок, 0 failures, 0 errors, 0 skips. Данные development сохранились. Пароли роли, права, pg_hba.conf и системная конфигурация не менялись; базы других проектов не изменялись.

Первоначальная HTTP-проверка выполнялась на отдельном временном кластере установленного PostgreSQL с каталогом `/tmp/api_rails_pg_lab_check/data`, Unix-сокетом и портом 55432 без TCP. Временные Puma и PostgreSQL после той проверки остановлены. Основной сервер PostgreSQL оставлен работающим.

## Результаты проверок

Автоматизированные тесты моделей и HTTP-интеграции:

```text
Run options: --seed 4563
41 runs, 409 assertions, 0 failures, 0 errors, 0 skips
```

Проверены обязательные поля и их длины, числовые и существующие внешние ID, `validates_associated`, boolean-статусы, FK/NOT NULL на уровне PostgreSQL, ассоциации, повторяемость seeds с сохранением пользовательских записей, сериализация, все CRUD-методы, фильтры true/false и их сочетания, SQL-метасимволы, вложенные маршруты и защита от доступа к чужой вакансии, резюме, прочтение/приглашение/отказ, мягкое удаление и повтор, ошибки 400/404/422. Фикстуры очищают только четыре таблицы лабораторной в отдельной test-базе; каждый тест выполняется в транзакции.

Через настоящий Puma на `127.0.0.1:3107` выполнены запросы и JavaScript-проверки подготовленной Postman Collection. Использован временный локальный скрипт на Node.js с эквивалентными assertions, без установки Newman или Postman и без регистрации внешних аккаунтов:

```text
PASS: 67 HTTP requests, 166 Postman assertions
```

Это проверка HTTP-запросов и скриптов коллекции, а не утверждение о запуске GUI Postman. Для ручной проверки импортировать JSON в Postman и запустить Collection Runner.

Дополнительные проверки:

```text
bundle check                         The Gemfile's dependencies are satisfied
bin/rails zeitwerk:check              All is good!
bin/rubocop                          45 files inspected, no offenses detected
git diff --check                     без ошибок
bundle exec brakeman --no-pager       0 errors, 1 warning (EOLRails)
```

Предупреждение Brakeman относится к сроку поддержки сохранённой версии Rails 7.2.4 в существующем Gemfile.lock. Предупреждений о SQL injection в итоговом коде нет. Версия Rails сохранена по условиям задания. Штатный `bin/brakeman` дополнительно требует сетевую проверку актуальности (`--ensure-latest`); в данном окружении эта проверка завершилась внутренней ошибкой Brakeman. Сам анализ выполнен установленным `bundle exec brakeman --no-pager`.

## Адаптация примеров методички

- Исправлены множественные `belongs_to :geeks/:jobs` на `belongs_to :geek/:job`.
- Миграции используют ActiveRecord 7.2 и `references` с внешними ключами.
- Вместо устаревших secrets и открытых паролей в Git используются Rails credentials и переменные окружения; локальный ключ расшифровки исключён из Git.
- Дополнительные гемы сериализации и сброса sequence не требуются: используются явные сериализаторы Rails и безопасные повторяемые seeds.
- `resume` остаётся text; примеры true/false в seeds заменены текстом резюме/`nil`.
- Ошибки действительно получают HTTP 400/404/422; статус не ограничивается полем JSON. Повтор мягкого удаления возвращает 200 с `deleted_already: "not_modified"`, чтобы сохранить JSON-тело, запрещённое для HTTP 304.
- Вложенный маршрут ищет вакансию внутри компании, несмотря на противоречивый пример главы 6 с чужим ID вакансии.
- Как в главе 7, помеченные записи остаются доступны в GET с флагом `deleted=true`; скрывающий `default_scope` не добавлен.
- Указание о favicon помечено в методичке «для версии 6»; к существующему Rails 7.2 API не применяется.
- Репозиторий уже создан и подключён пользователем. Git push и новые коммиты не выполнялись.

Маршруты, поля запросов и команды запуска перечислены в [README](../README.md). Коллекция: [Postman JSON](postman/api_rails_pg.postman_collection.json).

## Созданные и изменённые файлы

- `Gemfile`
- `README.md`
- `app/controllers/api/v1/applies_controller.rb`
- `app/controllers/api/v1/base_controller.rb`
- `app/controllers/api/v1/companies_controller.rb`
- `app/controllers/api/v1/geeks_controller.rb`
- `app/controllers/api/v1/jobs_controller.rb`
- `app/controllers/application_controller.rb`
- `app/models/apply.rb`
- `app/models/company.rb`
- `app/models/geek.rb`
- `app/models/job.rb`
- `app/serializers/application_serializer.rb`
- `app/serializers/apply_serializer.rb`
- `app/serializers/company_serializer.rb`
- `app/serializers/geek_serializer.rb`
- `app/serializers/job_serializer.rb`
- `config/credentials.yml.enc`
- `config/database.yml`
- `config/routes.rb`
- `db/migrate/20261104000100_create_companies.rb`
- `db/migrate/20261104000200_create_jobs.rb`
- `db/migrate/20261104000300_create_geeks.rb`
- `db/migrate/20261104000400_create_applies.rb`
- `db/migrate/20261104000500_add_deleted_to_companies.rb`
- `db/migrate/20261104000600_add_deleted_to_jobs.rb`
- `db/schema.rb`
- `db/seeds.rb`
- `docs/lab_report.md`
- `docs/postman/api_rails_pg.postman_collection.json`
- `test/fixtures/applies.yml`
- `test/fixtures/companies.yml`
- `test/fixtures/geeks.yml`
- `test/fixtures/jobs.yml`
- `test/integration/api_test.rb`
- `test/models/recruiting_test.rb`
- `test/test_helper.rb`
