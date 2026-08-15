# C4 — Уровень 3. Компоненты (Components)

Детализация двух ключевых контейнеров целевой архитектуры:
1. доменный сервис **«Кредитование» (Lending / Credit)** — типовой доменный
   сервис с outbox, consumer и ACL-адаптером к легаси;
2. **Data Product «Пациентский поток»** — типовой узел Data Mesh.

Оба примера показывают канонические компоненты: API, доменную логику/агрегаты,
outbox-publisher, consumer событий и ACL-адаптер к DWH.

---

## 3.1. Доменный сервис «Кредитование» (Lending / Credit)

```mermaid
C4Component
    title Компоненты (C4 L3): доменный сервис «Кредитование»

    Person(operator, "Кредитный оператор", "Оформление и сопровождение договоров")
    Container(apigw, "API Gateway", "Envoy", "Точка входа")
    ContainerQueue(kafka, "Apache Kafka", "Managed Kafka", "Event backbone")
    ContainerDb(pg, "PostgreSQL (lending)", "Managed PostgreSQL", "БД домена + таблицы outbox")
    System_Ext(bki, "Бюро кредитных историй", "Внешний скоринг")
    Container(acl_dwh, "ACL к DWH", "Debezium/REST", "Историческая финансовая история")

    Container_Boundary(lending, "Lending / Credit service") {
        Component(api, "Credit API", "REST/gRPC", "Заявки, договоры, статусы, графики платежей")
        Component(domain, "Доменная логика / агрегаты", "DDD: Заявка, Договор, ГрафикПлатежей", "Инварианты кредитования и переходы состояний")
        Component(scoring, "Scoring-адаптер", "Клиент БКИ и скоринг-модели", "Оценка кредитоспособности")
        Component(repo, "Repository", "ORM / SQL", "Персистентность агрегатов")
        Component(outbox, "Outbox Publisher", "Transactional Outbox + relay", "Публикация событий из БД в Kafka без dual-write")
        Component(consumer, "Event Consumer", "Kafka consumer", "Реакция на события платежей и профиля клиента")
        Component(aclad, "ACL-адаптер к DWH", "Anti-Corruption Layer", "Маппинг легаси-моделей во внутренние агрегаты")
    }

    Rel(operator, apigw, "Заявка / договор", "HTTPS")
    Rel(apigw, api, "Маршрутизация", "gRPC")
    Rel(api, domain, "Команды и запросы", "in-proc")
    Rel(domain, repo, "Сохранение агрегатов", "in-proc")
    Rel(domain, scoring, "Запрос скоринга", "in-proc")
    Rel(scoring, bki, "Проверка истории", "REST")
    Rel(repo, pg, "SQL + запись в outbox", "SQL")
    Rel(outbox, pg, "Чтение outbox", "SQL")
    Rel(outbox, kafka, "Публикация событий", "Avro")
    Rel(consumer, kafka, "Подписка на события", "Avro")
    Rel(consumer, domain, "Обновление состояния", "in-proc")
    Rel(aclad, acl_dwh, "Историческая финистория", "REST")
    Rel(aclad, domain, "Нормализованные данные", "in-proc")
```

### Пояснение компонентов «Кредитование»

| Компонент | Технология | Ответственность |
| --- | --- | --- |
| Credit API | REST/gRPC | Приём команд/запросов: создание заявки, выдача договора, статусы, график. |
| Доменная логика / агрегаты | DDD-модель | Агрегаты `Заявка`, `Договор`, `ГрафикПлатежей`; инварианты и бизнес-правила. |
| Scoring-адаптер | Клиент БКИ | Обращение к внешнему бюро кредитных историй и скоринг-моделям. |
| Repository | ORM/SQL | Загрузка/сохранение агрегатов в PostgreSQL. |
| Outbox Publisher | Transactional Outbox | Публикация доменных событий (`ЗаявкаОдобрена`, `ДоговорВыдан`) — событие пишется в БД в той же транзакции, relay доставляет его в Kafka. |
| Event Consumer | Kafka consumer | Подписка на события домена платежей (`ПлатёжПроведён`) и MDM (`ПрофильОбновлён`) для обновления графика/статуса. |
| ACL-адаптер к DWH | Anti-Corruption Layer | Изолирует легаси-модель MS SQL 2008; переводит историческую финистори­ю во внутренние понятия домена. |

**Почему так.** Outbox исключает рассогласование между БД и Kafka (dual-write).
ACL не даёт легаси-модели «протечь» в доменную логику и позволяет отключить
DWH без переписывания домена. Скоринг вынесен в адаптер — внешние сбои БКИ не
ломают доменные инварианты.

---

## 3.2. Data Product «Пациентский поток» (узел Data Mesh)

```mermaid
C4Component
    title Компоненты (C4 L3): Data Product «Пациентский поток»

    Person(analyst, "Аналитик домена", "Отчёты по операциям клиник")
    ContainerQueue(kafka, "Apache Kafka", "Managed Kafka", "События Patient Flow, без PHI")
    Container(bi, "Self-service BI", "DataLens / Metabase", "Портал самообслуживания")
    Container(catalog, "Каталог данных", "DataHub / OpenMetadata", "Контракты, lineage, доступы")
    Container(vault, "IAM / маскирование", "Vault + IAM", "Политики доступа и маскирования")

    Container_Boundary(dp, "Data Product: Пациентский поток") {
        Component(ingest, "Streaming Ingest", "Flink / Kafka Streams", "Приём, дедупликация и очистка событий")
        Component(contract, "Контракт данных", "Data Contract + Avro", "Схема, SLA, семантика; фильтрация полей PHI")
        Component(model, "dbt-модели", "dbt", "Витрины: загрузка клиник, длительность визитов, no-show")
        ComponentDb(iceberg, "Iceberg-таблицы", "Object Storage + Iceberg", "Хранение data product по слоям raw/curated")
        Component(quality, "Data Quality", "Тесты dbt / Great Expectations", "Проверки качества, полноты, свежести")
        Component(serve, "Query / Serve", "Trino / ClickHouse", "Отдача данных потребителям")
    }

    Rel(kafka, ingest, "События потока (без медкарт)", "Avro")
    Rel(ingest, contract, "Валидация по контракту", "in-proc")
    Rel(contract, iceberg, "Запись сырого слоя", "Iceberg")
    Rel(model, iceberg, "Материализация витрин", "SQL")
    Rel(quality, iceberg, "Проверки качества", "SQL")
    Rel(serve, iceberg, "Чтение", "SQL")
    Rel(bi, serve, "Аналитические запросы", "SQL")
    Rel(analyst, bi, "Отчёты", "HTTPS")
    Rel(catalog, iceberg, "Метаданные / lineage", "API")
    Rel(vault, serve, "Политики доступа / маскирование", "API")
```

### Пояснение компонентов Data Product

| Компонент | Технология | Ответственность |
| --- | --- | --- |
| Streaming Ingest | Flink / Kafka Streams | Приём событий из Kafka, дедупликация, очистка, приведение к контракту. |
| Контракт данных | Data Contract + Avro | Формальная схема, SLA (свежесть/полнота), семантика; **явная фильтрация полей PHI** — медкарты и результаты исследований не попадают в продукт. |
| dbt-модели | dbt | Версионируемые трансформации: слои raw → curated, бизнес-витрины. |
| Iceberg-таблицы | Object Storage + Iceberg | ACID-хранилище data product, схемная эволюция, time travel. |
| Data Quality | Тесты dbt / Great Expectations | Автоматические проверки качества; нарушение SLA блокирует публикацию. |
| Query / Serve | Trino / ClickHouse | Точка потребления для BI-портала и других доменов. |

**Почему так.** Data Product — единица владения в Data Mesh: домен Patient Flow
сам отвечает за качество, контракт и доступность своих данных. Контракт и
фильтрация PHI гарантируют, что запрещённые к аналитике данные (медкарты,
истории болезни, результаты исследований) физически не попадают в витрину.
IAM/Vault обеспечивают доступ и маскирование в рамках прав пользователя.
