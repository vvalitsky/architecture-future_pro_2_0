# Задание 3 — Целевая архитектура (C4) и управление рисками

Решение для компании **«Будущее 2.0»**: целевая архитектура в горизонте трёх
лет по модели **C4** (контекст, контейнеры, компоненты), схема эволюции при
масштабировании, **карта рисков** и **план управления рисками**. Стек и домены
едины с остальными заданиями спринта (Yandex Cloud, событийная платформа,
Data Mesh).

## Состав решения

| Файл | Содержание |
| --- | --- |
| [`c4-context.md`](c4-context.md) | C4 L1 — системный контекст: платформа и внешние акторы (пациенты, врачи, аналитики, регуляторы, партнёры, банковские системы, легаси). Mermaid `C4Context`. |
| [`c4-container.md`](c4-container.md) | C4 L2 — контейнеры: API Gateway, доменные сервисы, Kafka + Schema Registry + DLQ + стриминг, Data Mesh (lakehouse/Iceberg, Trino/ClickHouse, dbt, каталог), self-service BI, PostgreSQL per domain, ACL-мосты, Vault/IAM, observability. Диаграмма + таблица контейнер → технология → ответственность. |
| [`c4-component.md`](c4-component.md) | C4 L3 — компоненты для «Кредитования» и Data Product «Пациентский поток»: API, доменная логика/агрегаты, outbox-publisher, consumer, ACL-адаптер к DWH. |
| [`c4-migration.md`](c4-migration.md) | Эволюция систем: до/после (AS-IS → TO-BE), новые направления (фарма, электроника, регионы), интеграция источников, отказ от легаси. Timeline + flow по 3 этапам. |
| [`risk-map.md`](risk-map.md) | Карта рисков (17 шт.): категории Архитектурные/Технологические/Организационные, вероятность × влияние, расчёт уровня, quadrant-диаграмма и матрицы. |
| [`risk-management-plan.md`](risk-management-plan.md) | Меры снижения по каждому риску; разделение на технические и управленческие; владелец, стратегия, индикаторы, привязка к этапам. |
| [`C4_Container.puml`](C4_Container.puml) | Альтернативный формат — PlantUML C4 (уровень контейнеров). |

## Краткое резюме

**Целевая архитектура** — слабосвязанная событийная платформа в Yandex Cloud.
Домены (Patient Flow, EHR, AI Diagnostics, Banking & Payments, Lending, Billing,
Staff/HR, Inventory/Supply Chain, Customer/MDM, Data Platform + кросс-доменные
Compliance и Notifications) автономны, имеют собственную БД (PostgreSQL per
domain) и общаются через события в Kafka (Schema Registry, DLQ, outbox pattern).
Аналитика построена как **Data Mesh**: доменные data products в lakehouse
(Object Storage + Iceberg), запросы через Trino/ClickHouse, трансформации dbt,
каталог DataHub/OpenMetadata, портал **self-service BI** (DataLens/Metabase)
вместо кастомного Power BI. Медкарты, истории болезни и результаты исследований
**не попадают** в аналитическую витрину (изоляция PHI на уровне контрактов и
сетевого контура).

**Легаси** (DWH на MS SQL 2008, ESB Camel, PowerBuilder, Power BI) сохраняется
только как «мост совместимости» через антикоррупционные слои (ACL) и выводится
из эксплуатации по стратегии strangler fig к концу Этапа 3.

**Масштабирование** новых бизнес-направлений (фарма, электроника), источников
данных и регионов реализуется добавлением доменов/data products и продюсеров
событий — без внесения бизнес-логики в DWH.

**Риски.** Выделено 17 рисков (11 высоких, 6 средних) в трёх категориях.
Ключевые высокие: dual-write (R01), зависимость критпути от легаси (R03),
миграция сотен ТБ (R09), утечка PHI (R02), безопасность/IAM (R11), дефицит
компетенций (R13). План управления явно разделяет риски на закрываемые
**техническими** решениями (outbox, Schema Registry, саги, CDC, Vault/mTLS,
OpenTelemetry) и **управленческими** подходами (дорожная карта вывода легаси,
change management, data ownership, комплаенс, поэтапное финансирование), с
владельцами, стратегиями (mitigate/avoid/transfer/accept), индикаторами и
привязкой к трём этапам трансформации.

## Соответствие каноническому стеку

- Облако: Yandex Cloud (Managed K8s, Object Storage, Managed PostgreSQL,
  Managed Kafka, Managed ClickHouse, DataProc, DataLens).
- Событийность: Kafka + Schema Registry (Avro/Protobuf) + DLQ + outbox.
- Стриминг: Kafka Streams / Apache Flink.
- Data Mesh: доменные data products, lakehouse (Iceberg), Trino/ClickHouse,
  dbt, каталог DataHub/OpenMetadata.
- BI: DataLens/Metabase/Superset.
- Интеграции: REST/gRPC, API Gateway, ACL для Camel и DWH.
- Безопасность: Vault, IAM, шифрование, маскирование, изоляция медконтура.
- Наблюдаемость: Prometheus, Grafana, OpenTelemetry, ELK/Loki.

## Как смотреть диаграммы

Все `.md` содержат диаграммы **Mermaid** в fenced-блоках и рендерятся прямо на
GitHub (`C4Context`, `C4Container`, `C4Component`, `timeline`, `flowchart`,
`quadrantChart`). Для контейнерного уровня дополнительно приложен эквивалент в
формате **PlantUML C4** — [`C4_Container.puml`](C4_Container.puml).
