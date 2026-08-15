# Каталог доменных событий — «Будущее 2.0»

Каталог фиксирует **доменные события** целевой событийной платформы: имя
(бизнес-имя и технический тип), **контекст-источник**, **семантику**,
**подписчиков** и **минимальный контракт payload**. Всего в каталоге **30
событий** по всем доменам.

Технические типы событий именуются в прошедшем времени (`PascalCase`), топики
Kafka — по схеме `<домен>.<агрегат>.<событие>.v<major>`.

---

## Стандартный конверт события (event envelope)

Каждое событие несёт общий конверт (обязателен для всех типов) + доменный
payload. Ниже эти общие поля не повторяются в таблице — указаны только
**ключевые доменные атрибуты**.

| Поле конверта | Тип | Назначение |
| --- | --- | --- |
| `eventId` | UUID | Уникальный идентификатор события (ключ идемпотентности у потребителя) |
| `eventType` | string | Тип события, напр. `CreditContractCreated` |
| `occurredAt` | timestamp (UTC) | Момент возникновения факта |
| `aggregateId` | UUID | Идентификатор агрегата-источника |
| `aggregateType` | string | Тип агрегата (напр. `CreditContract`) |
| `version` | int | Мажорная версия схемы события |
| `correlationId` | UUID | Сквозная трассировка бизнес-процесса (саги) |
| `causationId` | UUID | Идентификатор события/команды-причины |
| `producer` | string | Домен-источник |

---

## Каталог событий

### Patient Flow

| Событие (бизнес-имя) | Технический тип | Источник | Семантика | Подписчики | Ключевые поля payload |
| --- | --- | --- | --- | --- | --- |
| Зарегистрирован новый пациент | `PatientRegistered` | Patient Flow | Создан новый пациент в системе | MDM, Billing, Data Platform | `patientId`, `fullNameRef`, `contactRef`, `consentId`, `clinicId` |
| Приём запланирован | `AppointmentScheduled` | Patient Flow | Пациент записан в слот врача | Notifications, HR, Data Platform | `appointmentId`, `patientId`, `doctorId`, `slotStart`, `serviceCode` |
| Визит завершён | `VisitCompleted` | Patient Flow | Приём состоялся и закрыт | Billing, EHR, Inventory, Data Platform | `appointmentId`, `patientId`, `doctorId`, `servicesRendered[]`, `completedAt` |

### Medical Records / EHR

| Событие (бизнес-имя) | Технический тип | Источник | Семантика | Подписчики | Ключевые поля payload |
| --- | --- | --- | --- | --- | --- |
| Эпизод открыт | `EhrEpisodeOpened` | EHR | Открыт клинический эпизод по визиту | AI Diagnostics | `episodeId`, `patientId`, `appointmentId` |
| Исследование назначено | `StudyOrdered` | EHR | Врач назначил инструментальное исследование | AI Diagnostics | `studyId`, `episodeId`, `modality`, `orderedBy` |
| Снимок загружен | `StudyImageUploaded` | EHR | Снимок помещён в Object Storage | AI Diagnostics | `studyId`, `imageRef` (S3), `modality`, `checksum` |

> События EHR циркулируют **только в медицинском контуре** и **не попадают** в
> Data Platform.

### AI Diagnostics

| Событие (бизнес-имя) | Технический тип | Источник | Семантика | Подписчики | Ключевые поля payload |
| --- | --- | --- | --- | --- | --- |
| Инференс завершён | `InferenceCompleted` | AI Diagnostics | Модель отработала на снимке | AI Diagnostics (политика заключения) | `inferenceJobId`, `studyId`, `modelVersion`, `confidence`, `resultRef` |
| Пройдено исследование ИИ | `AiStudyCompleted` | AI Diagnostics | Сформировано ИИ-заключение по исследованию | EHR, Notifications, Billing | `aiFindingId`, `studyId`, `patientId`, `modelVersion`, `confidence`, `summaryRef` |
| Заключение ИИ подтверждено | `AiFindingConfirmed` | AI Diagnostics | Врач подтвердил/скорректировал ИИ-заключение | EHR, Notifications | `aiFindingId`, `confirmedBy`, `agreement` (bool) |

> `AiStudyCompleted` содержит **ссылки** (`summaryRef`), а не сам PHI-контент; в
> аналитику не публикуется.

### Banking & Payments

| Событие (бизнес-имя) | Технический тип | Источник | Семантика | Подписчики | Ключевые поля payload |
| --- | --- | --- | --- | --- | --- |
| Счёт открыт | `AccountOpened` | Banking & Payments | Клиенту открыт банковский счёт | Lending, MDM, Data Platform | `accountId`, `customerId`, `currency`, `openedAt` |
| Платёж инициирован | `PaymentInitiated` | Banking & Payments | Создан платёж, ожидает проведения | Compliance, Data Platform | `paymentId`, `accountId`, `amount`, `currency`, `idempotencyKey` |
| Платёж проведён | `PaymentCaptured` | Banking & Payments | Средства успешно списаны/зачислены | Billing, Lending, Notifications, Data Platform | `paymentId`, `accountId`, `amount`, `capturedAt`, `externalRef` |
| Платёж отклонён | `PaymentDeclined` | Banking & Payments | Платёж не прошёл | Billing, Notifications | `paymentId`, `reasonCode`, `declinedAt` |
| Проводка проведена | `LedgerEntryPosted` | Banking & Payments | Двойная запись в реестре | Data Platform | `entryId`, `accountId`, `debit`, `credit`, `postedAt` |

### Lending / Credit

| Событие (бизнес-имя) | Технический тип | Источник | Семантика | Подписчики | Ключевые поля payload |
| --- | --- | --- | --- | --- | --- |
| Заявка на кредит подана | `LoanApplicationSubmitted` | Lending | Клиент подал заявку | Lending (скоринг), Compliance | `applicationId`, `customerId`, `amount`, `term`, `productCode` |
| Скоринг выполнен | `CreditScoringCompleted` | Lending | Рассчитан скоринговый балл | Lending (решение), Data Platform | `applicationId`, `score`, `riskGrade`, `bureauRef` |
| Решение по кредиту принято | `CreditDecisionMade` | Lending | Заявка одобрена/отклонена | Notifications, Data Platform | `applicationId`, `decision`, `approvedAmountLimit`, `rate` |
| **Создан кредитный договор** | `CreditContractCreated` | Lending | Оформлен кредитный договор | Banking & Payments, Notifications, Data Platform | `contractId`, `customerId`, `amount`, `rate`, `scheduleRef`, `signedAt` |
| Транш выдан | `LoanTrancheDisbursed` | Lending | Средства перечислены на счёт | Banking & Payments, Notifications | `contractId`, `trancheId`, `amount`, `accountId` |

### Billing

| Событие (бизнес-имя) | Технический тип | Источник | Семантика | Подписчики | Ключевые поля payload |
| --- | --- | --- | --- | --- | --- |
| Счёт сформирован | `InvoiceCreated` | Billing | По визиту создан счёт | Billing (страховка), Data Platform | `invoiceId`, `patientId`, `appointmentId`, `lineItems[]`, `grossAmount` |
| Страховой расчёт выполнен | `InsuranceCalculated` | Billing | Рассчитано страховое покрытие | Billing (выставление) | `invoiceId`, `coverageAmount`, `insurerRef` |
| Счёт выставлен | `InvoiceIssued` | Billing | Счёт готов к оплате | Banking & Payments, Notifications | `invoiceId`, `netAmount`, `dueDate` |
| Счёт оплачен | `InvoicePaid` | Billing | Счёт полностью оплачен | Patient Flow, Data Platform | `invoiceId`, `paymentId`, `paidAmount`, `paidAt` |

### Inventory / Supply Chain

| Событие (бизнес-имя) | Технический тип | Источник | Семантика | Подписчики | Ключевые поля payload |
| --- | --- | --- | --- | --- | --- |
| Запасы списаны | `StockConsumed` | Inventory | Расходники списаны по приёму | Data Platform | `stockItemId`, `appointmentId`, `quantity`, `batchId` |
| Запасы ниже порога | `StockBelowThreshold` | Inventory | Остаток пересёк минимальный порог | Inventory (заказ), Notifications | `stockItemId`, `currentQty`, `threshold` |
| Заказ поставщику создан | `PurchaseOrderCreated` | Inventory | Автозаказ на пополнение | Notifications, Data Platform | `purchaseOrderId`, `supplierId`, `items[]`, `expectedAt` |

### Customer / Identity / MDM, Compliance, Notifications, Data Platform

| Событие (бизнес-имя) | Технический тип | Источник | Семантика | Подписчики | Ключевые поля payload |
| --- | --- | --- | --- | --- | --- |
| Профиль клиента создан | `CustomerProfileCreated` | MDM | Сформирован golden record | Banking, Lending, Billing | `customerId`, `patientId`, `partyType`, `mergedFrom[]` |
| Согласие обновлено | `ConsentUpdated` | Compliance / MDM | Изменён статус согласия на обработку ПДн | Все домены-обработчики ПДн | `consentId`, `customerId`, `scope`, `status`, `effectiveAt` |
| Уведомление доставлено | `NotificationDelivered` | Notifications | Сообщение доставлено получателю | Data Platform | `notificationId`, `channel`, `recipientRef`, `deliveredAt` |
| Data product опубликован | `DataProductPublished` | Data Platform | Опубликована новая версия data product | Каталог данных, потребители | `dataProductId`, `schemaVersion`, `owner`, `sla` |

---

## Пример полного контракта (Avro): «Создан кредитный договор»

```json
{
  "type": "record",
  "name": "CreditContractCreated",
  "namespace": "ru.future20.lending.credit.v1",
  "doc": "Оформлен кредитный договор по одобренной заявке",
  "fields": [
    { "name": "eventId",       "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "eventType",     "type": "string", "default": "CreditContractCreated" },
    { "name": "occurredAt",    "type": { "type": "long", "logicalType": "timestamp-millis" } },
    { "name": "aggregateId",   "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "aggregateType", "type": "string", "default": "CreditContract" },
    { "name": "version",       "type": "int", "default": 1 },
    { "name": "correlationId", "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "causationId",   "type": ["null", { "type": "string", "logicalType": "uuid" }], "default": null },
    { "name": "producer",      "type": "string", "default": "lending" },
    { "name": "contractId",    "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "customerId",    "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "amount",        "type": { "type": "bytes", "logicalType": "decimal", "precision": 18, "scale": 2 } },
    { "name": "currency",      "type": "string", "default": "RUB" },
    { "name": "rate",          "type": "double" },
    { "name": "termMonths",    "type": "int" },
    { "name": "scheduleRef",   "type": "string" },
    { "name": "signedAt",      "type": { "type": "long", "logicalType": "timestamp-millis" } }
  ]
}
```

## Пример полного контракта (Avro): «Зарегистрирован новый пациент»

```json
{
  "type": "record",
  "name": "PatientRegistered",
  "namespace": "ru.future20.patientflow.registration.v1",
  "doc": "В системе зарегистрирован новый пациент",
  "fields": [
    { "name": "eventId",       "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "eventType",     "type": "string", "default": "PatientRegistered" },
    { "name": "occurredAt",    "type": { "type": "long", "logicalType": "timestamp-millis" } },
    { "name": "aggregateId",   "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "aggregateType", "type": "string", "default": "Patient" },
    { "name": "version",       "type": "int", "default": 1 },
    { "name": "correlationId", "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "causationId",   "type": ["null", { "type": "string", "logicalType": "uuid" }], "default": null },
    { "name": "producer",      "type": "string", "default": "patient-flow" },
    { "name": "patientId",     "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "clinicId",      "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "consentId",     "type": { "type": "string", "logicalType": "uuid" } },
    { "name": "fullNameRef",   "type": "string", "doc": "Токен-ссылка на ПДн в защищённом хранилище (не открытый текст)" },
    { "name": "contactRef",    "type": "string", "doc": "Токен-ссылка на контактные данные" }
  ]
}
```

> **PII/PHI в событиях.** Персональные данные не передаются открытым текстом:
> в payload идут **токен-ссылки** (`fullNameRef`, `contactRef`, `summaryRef`),
> а разыменование выполняется потребителем при наличии согласия и прав
> (проверка через Compliance & Security).

---

## Конвенции работы с событиями

### Схемы и версионирование

- **Schema Registry** (Avro/Protobuf) — единый источник правды по контрактам;
  публикация схемы обязательна перед выпуском продюсера.
- **Совместимость** — `BACKWARD`/`FULL` для эволюции без остановки потребителей:
  новые поля только опциональные (с `default`), удаление обязательных полей
  запрещено.
- **Версионирование** — мажорная версия в имени топика (`...v1`, `...v2`);
  несовместимые изменения = новый топик и параллельная работа до миграции
  потребителей.

### Доставка и надёжность

- **Outbox pattern** — событие пишется в outbox-таблицу атомарно с изменением
  агрегата; релей (Debezium/коннектор) публикует в Kafka. Исключает потерю и
  «фантомные» события.
- **At-least-once** — гарантия доставки Kafka; дубликаты возможны.
- **Идемпотентность** — потребители дедуплицируют по `eventId` (или бизнес-ключу
  вроде `idempotencyKey` для платежей); обработчики идемпотентны.
- **Порядок** — партиционирование по `aggregateId` сохраняет порядок событий
  одного агрегата.

### Обработка ошибок

- **Retry с backoff** — временные ошибки повторяются с экспоненциальной паузой.
- **DLQ (Dead Letter Queue)** — «отравленные» сообщения после N ретраев уходят в
  DLQ-топик с сохранением исходного конверта и причины; оттуда — ручной/полу-
  автоматический разбор.
- **Наблюдаемость** — трассировка по `correlationId`/`causationId`
  (OpenTelemetry), метрики лагов консюмеров (Prometheus/Grafana).

### Безопасность

- Изоляция медицинского контура: события EHR/AI не выходят в общий кластер
  аналитики; PII/PHI — только по токен-ссылкам; шифрование в транзите и покое,
  контроль доступа к топикам через IAM/ACL Kafka.
