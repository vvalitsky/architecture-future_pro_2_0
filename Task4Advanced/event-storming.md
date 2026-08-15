# Event Storming — целевая событийная архитектура «Будущее 2.0»

Диаграммы построены по нотации **Event Storming**. Для каждого ключевого
потока показаны: **акторы**, **команды**, **агрегаты**, **доменные события**
(оранжевые), **политики/процессы** (реагируют на события и порождают новые
команды), **read-models** и переходы событий к **доменам-подписчикам**.

Для каждого события в разделах ниже и в каталоге [`events.md`](./events.md)
указаны **источник** и **подписчики**.

---

## Легенда (цветовая нотация)

```mermaid
flowchart LR
  classDef actor fill:#FFF176,stroke:#F9A825,color:#000;
  classDef command fill:#1E88E5,stroke:#0D47A1,color:#fff;
  classDef aggregate fill:#FFD54F,stroke:#F9A825,color:#000;
  classDef event fill:#FF9900,stroke:#B36B00,color:#000;
  classDef policy fill:#AB47BC,stroke:#6A1B9A,color:#fff;
  classDef readmodel fill:#66BB6A,stroke:#2E7D32,color:#000;
  classDef external fill:#EF5350,stroke:#B71C1C,color:#fff;

  L1["Актор"]:::actor
  L2["Команда"]:::command
  L3["Агрегат"]:::aggregate
  L4["Доменное событие"]:::event
  L5["Политика / Процесс"]:::policy
  L6["Read-model"]:::readmodel
  L7["Внешняя система / другой домен"]:::external

  L1 --> L2 --> L3 --> L4 --> L5
  L4 --> L6
  L4 --> L7
```

| Цвет | Элемент | Значение |
| --- | --- | --- |
| Жёлтый (светлый) | Актор | Кто инициирует команду (человек или система) |
| Синий | Команда | Намерение изменить состояние (imperative) |
| Жёлтый (насыщенный) | Агрегат | Граница согласованности, обрабатывает команду |
| **Оранжевый** | **Доменное событие** | Факт, произошедший в прошлом (past tense) |
| Фиолетовый | Политика / Процесс | Реакция «когда произошло X → сделать Y» |
| Зелёный | Read-model | Проекция для запросов/UI/отчётов |
| Красный | Внешняя система / другой домен | Подписчик или внешний интегратор |

---

## Поток 1. Пациентский поток (Patient Flow)

```mermaid
flowchart LR
  classDef actor fill:#FFF176,stroke:#F9A825,color:#000;
  classDef command fill:#1E88E5,stroke:#0D47A1,color:#fff;
  classDef aggregate fill:#FFD54F,stroke:#F9A825,color:#000;
  classDef event fill:#FF9900,stroke:#B36B00,color:#000;
  classDef policy fill:#AB47BC,stroke:#6A1B9A,color:#fff;
  classDef readmodel fill:#66BB6A,stroke:#2E7D32,color:#000;
  classDef external fill:#EF5350,stroke:#B71C1C,color:#fff;

  A1["Пациент"]:::actor --> C1["Зарегистрировать пациента"]:::command
  C1 --> AG1["Регистрация пациента"]:::aggregate
  AG1 --> E1["Зарегистрирован новый пациент"]:::event
  E1 --> P1["Политика: создать единый профиль"]:::policy
  P1 --> XMDM["→ MDM: Создать golden record"]:::external
  E1 --> RM1["Read-model: Карточка пациента"]:::readmodel

  A1 --> C2["Записать на приём"]:::command
  C2 --> AG2["Приём (Appointment)"]:::aggregate
  AG2 --> E2["Приём запланирован"]:::event
  E2 --> XN1["→ Notifications"]:::external
  E2 --> RM2["Read-model: Расписание врача"]:::readmodel

  A2["Врач / оператор"]:::actor --> C3["Завершить визит"]:::command
  C3 --> AG2
  AG2 --> E3["Визит завершён"]:::event
  E3 --> P2["Политика: сформировать счёт"]:::policy
  P2 --> XBIL["→ Billing: Сформировать счёт"]:::external
  E3 --> XEHR["→ EHR: обновить эпизод"]:::external
  E3 --> XINV["→ Inventory: списать расходники"]:::external
```

**Ключевые события потока:** `Зарегистрирован новый пациент` (источник Patient
Flow → подписчики MDM, Billing, Data Platform), `Приём запланирован` (→
Notifications, HR, Data Platform), `Визит завершён` (→ Billing, EHR, Inventory,
Data Platform).

---

## Поток 2. Кредитование (Lending / Credit)

```mermaid
flowchart LR
  classDef actor fill:#FFF176,stroke:#F9A825,color:#000;
  classDef command fill:#1E88E5,stroke:#0D47A1,color:#fff;
  classDef aggregate fill:#FFD54F,stroke:#F9A825,color:#000;
  classDef event fill:#FF9900,stroke:#B36B00,color:#000;
  classDef policy fill:#AB47BC,stroke:#6A1B9A,color:#fff;
  classDef readmodel fill:#66BB6A,stroke:#2E7D32,color:#000;
  classDef external fill:#EF5350,stroke:#B71C1C,color:#fff;

  A1["Клиент банка"]:::actor --> C1["Подать заявку на кредит"]:::command
  C1 --> AG1["Заявка на кредит"]:::aggregate
  AG1 --> E1["Заявка на кредит подана"]:::event
  E1 --> P1["Политика: запустить скоринг"]:::policy
  P1 --> C2["Выполнить скоринг"]:::command
  C2 --> AG2["Кредитный скоринг"]:::aggregate
  XBKI["Бюро кредитных историй (через ACL)"]:::external --> AG2
  XMDM["MDM: профиль клиента"]:::external --> AG2
  AG2 --> E2["Скоринг выполнен"]:::event
  E2 --> P2["Политика: принять решение"]:::policy
  P2 --> E3["Решение по кредиту принято"]:::event
  E3 --> P3["Политика: оформить договор"]:::policy
  P3 --> C3["Создать кредитный договор"]:::command
  C3 --> AG3["Кредитный договор"]:::aggregate
  AG3 --> E4["Создан кредитный договор"]:::event
  E4 --> XBP["→ Banking: выдать транш"]:::external
  E4 --> XN["→ Notifications: клиент"]:::external
  E4 --> XDP["→ Data Platform: витрина кредитов"]:::external
  E4 --> RM1["Read-model: График платежей"]:::readmodel
```

**Ключевые события потока:** `Заявка на кредит подана`, `Скоринг выполнен`,
`Решение по кредиту принято`, **`Создан кредитный договор`** (источник Lending
→ подписчики Banking & Payments, Notifications, Data Platform).

---

## Поток 3. Платежи (Banking & Payments)

```mermaid
flowchart LR
  classDef actor fill:#FFF176,stroke:#F9A825,color:#000;
  classDef command fill:#1E88E5,stroke:#0D47A1,color:#fff;
  classDef aggregate fill:#FFD54F,stroke:#F9A825,color:#000;
  classDef event fill:#FF9900,stroke:#B36B00,color:#000;
  classDef policy fill:#AB47BC,stroke:#6A1B9A,color:#fff;
  classDef readmodel fill:#66BB6A,stroke:#2E7D32,color:#000;
  classDef external fill:#EF5350,stroke:#B71C1C,color:#fff;

  A1["Плательщик / клиент"]:::actor --> C1["Инициировать платёж"]:::command
  XBIL["Billing: Счёт выставлен"]:::external --> C1
  C1 --> AG1["Платёж (Payment)"]:::aggregate
  AG1 --> E1["Платёж инициирован"]:::event
  E1 --> P1["Политика: провести через СБП"]:::policy
  P1 --> XSBP["СБП / НСПК (через ACL)"]:::external
  XSBP --> AG1
  AG1 --> E2["Платёж проведён"]:::event
  AG1 --> E2b["Платёж отклонён"]:::event
  E2 --> P2["Политика: провести проводку"]:::policy
  P2 --> C2["Провести проводку по счёту"]:::command
  C2 --> AG2["Счёт (Account) / Реестр"]:::aggregate
  AG2 --> E3["Проводка проведена"]:::event
  E2 --> XBIL2["→ Billing: закрыть счёт"]:::external
  E2b --> XN["→ Notifications: повторить оплату"]:::external
  E3 --> RM1["Read-model: Баланс счёта"]:::readmodel
  E3 --> XDP["→ Data Platform: финвитрина"]:::external
```

**Ключевые события потока:** `Платёж инициирован`, `Платёж проведён`, `Платёж
отклонён`, `Проводка проведена` (источник Banking & Payments → подписчики
Billing, Notifications, Data Platform, Lending для списаний по графику).

---

## Поток 4. ИИ-диагностика (AI Diagnostics) + EHR

```mermaid
flowchart LR
  classDef actor fill:#FFF176,stroke:#F9A825,color:#000;
  classDef command fill:#1E88E5,stroke:#0D47A1,color:#fff;
  classDef aggregate fill:#FFD54F,stroke:#F9A825,color:#000;
  classDef event fill:#FF9900,stroke:#B36B00,color:#000;
  classDef policy fill:#AB47BC,stroke:#6A1B9A,color:#fff;
  classDef readmodel fill:#66BB6A,stroke:#2E7D32,color:#000;
  classDef external fill:#EF5350,stroke:#B71C1C,color:#fff;

  A1["Врач"]:::actor --> C1["Направить на исследование"]:::command
  C1 --> AG1["Исследование (Study, EHR)"]:::aggregate
  AG1 --> E1["Исследование назначено"]:::event
  E1 --> P1["Политика: запустить инференс"]:::policy
  P1 --> C2["Запустить инференс модели"]:::command
  C2 --> AG2["Задача инференса (AID)"]:::aggregate
  XS3["Object Storage: снимок (DICOM)"]:::external --> AG2
  AG2 --> E2["Инференс завершён"]:::event
  E2 --> P2["Политика: сформировать заключение"]:::policy
  P2 --> E3["Пройдено исследование ИИ"]:::event
  E3 --> XEHR["→ EHR: приложить заключение к карте"]:::external
  E3 --> XN["→ Notifications: врач"]:::external
  E3 --> XBIL["→ Billing: тарифицировать ИИ-услугу"]:::external
  E3 --> RM1["Read-model: Очередь заключений врача"]:::readmodel
  E3 -.->|"НЕ идёт в аналитику — PHI"| STOP["Data Platform ✗"]:::external
```

**Ключевые события потока:** `Исследование назначено`, `Инференс завершён`,
**`Пройдено исследование ИИ`** (источник AI Diagnostics → подписчики EHR,
Notifications, Billing). **Заключения и снимки не публикуются в Data Platform**
— соблюдается изоляция PHI/врачебной тайны.

---

## Поток 5. Биллинг медуслуг (Billing) + Инвентарь

```mermaid
flowchart LR
  classDef actor fill:#FFF176,stroke:#F9A825,color:#000;
  classDef command fill:#1E88E5,stroke:#0D47A1,color:#fff;
  classDef aggregate fill:#FFD54F,stroke:#F9A825,color:#000;
  classDef event fill:#FF9900,stroke:#B36B00,color:#000;
  classDef policy fill:#AB47BC,stroke:#6A1B9A,color:#fff;
  classDef readmodel fill:#66BB6A,stroke:#2E7D32,color:#000;
  classDef external fill:#EF5350,stroke:#B71C1C,color:#fff;

  XPF["Patient Flow: Визит завершён"]:::external --> P0["Политика: сформировать счёт"]:::policy
  P0 --> C1["Сформировать счёт за услугу"]:::command
  C1 --> AG1["Счёт за услугу (Invoice)"]:::aggregate
  AG1 --> E1["Счёт сформирован"]:::event
  E1 --> P1["Политика: рассчитать страховое покрытие"]:::policy
  P1 --> C2["Рассчитать страховку"]:::command
  C2 --> AG1
  AG1 --> E2["Страховой расчёт выполнен"]:::event
  E2 --> E3["Счёт выставлен"]:::event
  E3 --> XBP["→ Banking: инициировать платёж"]:::external
  XBP2["Banking: Платёж проведён"]:::external --> P2["Политика: закрыть счёт"]:::policy
  P2 --> E4["Счёт оплачен"]:::event
  E4 --> RM1["Read-model: Дебиторка по клиникам"]:::readmodel
  E3 --> XDP["→ Data Platform: витрина выручки"]:::external

  A1["Кладовщик"]:::actor --> C3["Списать расходники"]:::command
  XPF -.->|"по факту приёма"| C3
  C3 --> AG2["Позиция склада (Stock Item)"]:::aggregate
  AG2 --> E5["Запасы списаны"]:::event
  AG2 --> E6["Запасы ниже порога"]:::event
  E6 --> P3["Политика: заказать у поставщика"]:::policy
  P3 --> C4["Создать заказ поставщику"]:::command
  C4 --> AG3["Заказ поставщику (Purchase Order)"]:::aggregate
  AG3 --> E7["Заказ поставщику создан"]:::event
  E7 --> XN["→ Notifications: снабжение"]:::external
```

**Ключевые события потоков:** `Счёт сформирован`, `Страховой расчёт выполнен`,
`Счёт выставлен`, `Счёт оплачен` (Billing); `Запасы списаны`, `Запасы ниже
порога`, `Заказ поставщику создан` (Inventory → подписчики Notifications, Data
Platform).

---

## Сводная матрица «источник → подписчики» (ключевые события)

| Доменное событие | Источник | Подписчики |
| --- | --- | --- |
| Зарегистрирован новый пациент | Patient Flow | MDM, Billing, Data Platform |
| Приём запланирован | Patient Flow | Notifications, HR, Data Platform |
| Визит завершён | Patient Flow | Billing, EHR, Inventory, Data Platform |
| Исследование назначено | EHR | AI Diagnostics |
| Пройдено исследование ИИ | AI Diagnostics | EHR, Notifications, Billing |
| Заявка на кредит подана | Lending | Lending (скоринг), Compliance |
| Скоринг выполнен | Lending | Lending (решение), Data Platform |
| Создан кредитный договор | Lending | Banking & Payments, Notifications, Data Platform |
| Платёж инициирован | Banking & Payments | СБП (ACL), Compliance |
| Платёж проведён | Banking & Payments | Billing, Lending, Notifications, Data Platform |
| Счёт выставлен | Billing | Banking & Payments, Notifications |
| Счёт оплачен | Billing | Patient Flow, Data Platform |
| Запасы ниже порога | Inventory | Inventory (заказ), Notifications |
| Заказ поставщику создан | Inventory | Notifications, Data Platform |

> Полный контракт каждого события (payload, версия, семантика) — в
> [`events.md`](./events.md); границы и инварианты агрегатов — в
> [`aggregates.md`](./aggregates.md).
