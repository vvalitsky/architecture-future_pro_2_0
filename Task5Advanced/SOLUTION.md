# Задание 5 — Технологический стек, TCO и роадмап Data Mesh

Решение для компании **«Будущее 2.0»**: целевой технологический ландшафт
(**расширенный технический радар**), экономическое обоснование (**TCO-анализ**
на 3 года) и **стратегический роадмап** внедрения Data Mesh. Стек, домены и
принципы едины с остальными заданиями спринта (Yandex Cloud, событийная
платформа, Data Mesh, изоляция медицинского контура / PHI).

## Состав решения

| Файл | Содержание |
| --- | --- |
| [`tech-radar.md`](tech-radar.md) | Расширенный техрадар: технологии **и** архитектурные паттерны (Data Mesh, EDA, Self-service BI, CQRS, Outbox, ACL, Lakehouse, GitOps и др.). Кольца Adopt/Trial/Assess/Hold, 4 квадранта (Techniques/Patterns, Platforms, Tools, Languages&Frameworks), таблицы, Mermaid `quadrantChart` + `mindmap`. Легаси — в Hold |
| [`tech-radar.puml`](tech-radar.puml) | Альтернативный экспорт радара в PlantUML (`@startmindmap`): квадрант → кольцо → элементы, цветовая кодировка колец |
| [`tco-analysis.md`](tco-analysis.md) | TCO-модель current vs target по статьям (инфраструктура, лицензии, сопровождение, время аналитиков, миграция/обучение), таблицы Y1/Y2/Y3 + Y4–Y5, период окупаемости, экономия, Mermaid `xychart-beta`. Цифры иллюстративные |
| [`roadmap.md`](roadmap.md) | Роадмап Data Mesh: роли (DPO, Data Engineer, BI-аналитик, Platform Team, Governance/Steward) + RACI, 3 этапа (0–6 / 6–18 / 18–36 мес) с целями, доменами, метриками и привязкой к бизнес-целям, Mermaid `gantt` + `timeline` |
| [`SOLUTION.md`](SOLUTION.md) | Этот файл — оглавление и резюме |

## Краткое резюме

**Технический радар.** 63 элемента в 4 квадрантах (Adopt 24 / Trial 21 / Assess 8 / Hold 10). Ядро целевой платформы —
в **Adopt** (Event-Driven Architecture, Outbox, ACL, DDD, Yandex Managed Kafka/K8s/
PostgreSQL/Object Storage, Terraform, Vault, Python/Go/Java, Avro, SQL). В **Trial** —
внедряемое поэтапно (Data Mesh, Self-service BI, Lakehouse/Iceberg, CQRS, Saga,
ClickHouse/Trino, dbt, Kafka Streams/Flink, ArgoCD, OpenTelemetry). В **Assess** —
исследуемое (CDC, Reverse ETL, Feature Store, Data Fabric, DataHub, Kotlin).
В **Hold** — всё легаси и антипаттерны: **MS SQL 2008 DWH-монолит, бизнес-логика
в DWH (T-SQL), PowerBuilder, кастомный Power BI, точечные синхронные интеграции,
Apache Camel ESB, on-prem ЦОД** — с выводом по strangler fig к концу Этапа 3.

**TCO (иллюстративно).** Горизонт 3 года: Current ≈ **322 млн ₽**, Target ≈
**319 млн ₽** (паритет, включая разовую миграцию). Пик инвестиций — Y1 (+29 млн ₽).
**Окупаемость — конец Y3 (~34–36 мес)**, совпадает с завершением Этапа 3. С Y4 —
устойчивая экономия **≈74–86 млн ₽/год (≈55–60%)**; накопленная выгода к Y5 —
**≈163 млн ₽**. Ключевые драйверы экономии: замена лицензий (SQL Server/Power BI/
PowerBuilder) на open-source/managed, разгрузка эксплуатации managed-сервисами и
резкое сокращение потерь времени аналитиков за счёт self-service BI и near-real-time.

**Роадмап Data Mesh.** Три этапа, привязанные к бизнес-целям (Продукты · География ·
Данные):
- **Этап 1 (0–6):** пилот в Banking & Payments и Patient Flow; MVP платформы и
  портала; Kafka + Schema Registry + DLQ + outbox.
- **Этап 2 (6–18):** критические домены (Lending, Billing, Customer/MDM, AI
  Diagnostics, Inventory); потоковые витрины; ACL к Camel/DWH; каталог и governance.
- **Этап 3 (18–36):** все 10 доменов как data products; отказ от синхронных
  интеграций на критпути; декомиссия легаси; federated governance; выход в регионы.

Роли (DPO, Data Engineer, BI-аналитик, Platform Team, Governance/Steward)
распределены по RACI; для каждого этапа заданы цели, домены, метрики успеха.

## Соответствие каноническому стеку

- Облако: **Yandex Cloud** (Managed K8s, Object Storage, Managed PostgreSQL,
  Managed Kafka, Managed ClickHouse, DataProc, DataLens).
- Событийность: **Kafka + Schema Registry** (Avro/Protobuf) + **DLQ** + **outbox**.
- Стриминг: **Kafka Streams / Apache Flink**.
- Data Mesh: доменные **data products**, **lakehouse** (Object Storage + **Iceberg**),
  **Trino/ClickHouse**, **dbt**, каталог **DataHub/OpenMetadata**.
- Self-service BI: **DataLens/Metabase/Superset** (замена кастомного Power BI).
- Интеграции: REST/gRPC, API Gateway, **ACL** для Camel и DWH.
- IaC/DevOps: **Terraform**, **GitOps (ArgoCD)**, CI/CD.
- Безопасность: **Vault**, IAM, шифрование, маскирование, изоляция медконтура.
- **PHI-изоляция:** медкарты, истории болезни, результаты исследований **не**
  попадают в аналитическую витрину.

## Как смотреть диаграммы

Все `.md` содержат диаграммы **Mermaid** в fenced-блоках и рендерятся на GitHub:
`quadrantChart` и `mindmap` (радар), `xychart-beta` (TCO), `gantt` и `timeline`
(роадмап). Для радара дополнительно приложен экспорт **PlantUML** —
[`tech-radar.puml`](tech-radar.puml).

> Примечание по каталогам: артефакты подготовлены в `Task5/`. По условию основного
> README финальная сдача — в директории `Task5Advanced/` (скопировать содержимое
> при формировании пул-реквеста).
