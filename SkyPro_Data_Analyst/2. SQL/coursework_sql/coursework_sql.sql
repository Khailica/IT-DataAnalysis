-- посмотрим на таблицу skyeng_db.payments
-- select *
--   from skyeng_db.payments
--  order by user_id, transaction_datetime
--  limit 100;

-- посмотрим на таблицу skyeng_db.payments
-- select *
--   from skyeng_db.classes
-- -- where class_type != 'single'
--  limit 100;

/* Структура таблиц skyeng_db

payments

- `user_id`             — ID студента,
- `id_transaction`      — ID транзакции,
- `operation_name`      — название операции,
- `status_name`         — название статуса транзакции,
- `classes`             — количество уроков в транзакции,
- `payment_amount`      — сумма операции,
- `transaction_datetime`    — дата и время операции.

classes

- `user_id`                 — ID студента,
- `id_class`                — ID урока,
- `class_start_datetime`    — дата и время начала урока,
- `class_end_datetime`      — дата и время окончания урока,
- `class_removed_datetime`  — дата и время удаления данных об уроке,
- `id_teacher`              — ID преподавателя,
- `class_status`            — статус урока,
- `class_status_datetime`   — дата постановки статуса урока,
- `class_type`              — тип урока.
*/



/*
### Шаг 1
Узнаем, когда была первая транзакция для каждого студента. Начиная с этой даты, мы будем собирать его баланс уроков.
**Создадим CTE** `first_payments` с двумя полями: `user_id` и `first_payment_date` (дата первой успешной транзакции).
*/
with first_payments as (
    select user_id, min(date_trunc('day', transaction_datetime::date)) as first_payment_date
      from skyeng_db.payments
     group by user_id
    ),
/*
### Шаг 2
Соберем таблицу с датами за каждый календарный день.
Выберем все даты из таблицы `classes`, **создадим CTE** `all_dates` с полем `dt`, где будут храниться уникальные даты (безвремени) уроков.
*/
    all_dates as (
    select distinct(date_trunc('day', class_start_datetime::date)) as dt
      from skyeng_db.classes
     where date_trunc('year', class_start_datetime) = '2016-01-01'
    ),
/*
### Шаг 3
Узнаем, за какие даты имеет смысл собирать баланс для каждого студента. Для этого объединим таблицы и создадим CTE `all_dates_by_user`,
где будут храниться все даты жизни студента после того, как произошла его первая транзакция. 
**В таблице** будут такие поля: `user_id`, `dt`.
*/
    all_dates_by_user as (
    select user_id, dt
      from first_payments fp
           join all_dates ad on ad.dt >= fp.first_payment_date
    ),
/*
### Шаг 4
Найдем все изменения балансов, связанные с успешными транзакциями (id_transaction is not null  and status_name = 'success')
Выберем все транзакции из таблицы `payments`, сгруппируем их по `user_id` и дате транзакции (без времени) и найдем сумму по полю `classes`. 
**В результате** получим CTE `payments_by_dates` с полями: `user_id`, `payment_date`, `transaction_balance_change`
(сколько уроков было начислено или списано в этот день).
*/
    payments_by_dates as (
    select user_id,
           date_trunc('day', transaction_datetime) as payment_date,
           sum(classes) as transaction_balance_change
      from skyeng_db.payments
     where id_transaction is not null
           and status_name = 'success'
           and date_trunc('year', transaction_datetime) = '2016-01-01'
     group by 1, 2
    ),
/*
### Шаг 5
Найдем баланс студентов, который сформирован только транзакциями.
Для этого объединим `all_dates_by_user` и `payments_by_dates` так, чтобы совпадали даты и `user_id`.
Используем оконные выражения (функцию `sum`), чтобы найти кумулятивную сумму по полю `transaction_balance_change`
для всех строк до текущей включительно с разбивкой по `user_id` и сортировкой по `dt`. 
**В результате** получим CTE `payments_by_dates_cumsum` с полями: `user_id`, `dt`,
`transaction_balance_change` — `transaction_balance_change_cs` (кумулятивная сумма по `transaction_balance_change`).
При подсчете кумулятивной заменим пустые значения нулями.
*/
    payments_by_dates_cumsum as (
    select adu.user_id, adu.dt, transaction_balance_change,
           coalesce(sum(transaction_balance_change) over (partition by adu.user_id order by adu.dt), 0) as transaction_balance_change_cs
      from all_dates_by_user adu
           left join payments_by_dates pd
                     on pd.user_id = adu.user_id
                     and pd.payment_date = adu.dt -- оставим даты, если не было транзакций
    ),
/*
### Шаг 6
Найдем изменения балансов из-за прохождения уроков. 
Создадим CTE `classes_by_dates`, посчитав в таблице `classes` количество уроков за каждый день для каждого ученика. 
Нас не интересуют вводные уроки ('trial') и уроки со статусом, отличным от `success` и `failed_by_student`. 
**Получим результат** с такими полями: `user_id`, `class_date`, `classes` (количество пройденных в этот день уроков).
Причем `classes` мы умножим на `-1`, чтобы отразить, что `-` — это списания с баланса.
*/
    classes_by_dates as (
    select user_id,
           date_trunc('day', class_start_datetime::date) as class_date,
           count(id_class) * -1 as classes
      from skyeng_db.classes
     where class_status in ('success', 'failed_by_student')
           and class_type != 'trial'
           and date_trunc('year', class_start_datetime) = '2016-01-01'
     group by 1,2
    ),
/*
### Шаг 7
По аналогии с уже проделанным шагом для оплат создадим CTE для хранения кумулятивной суммы количества пройденных уроков. 
Для этого объединим таблицы `all_dates_by_user` и `classes_by_dates` так, чтобы совпадали даты и `user_id`.
Используем оконные выражения (функцию `sum`), чтобы найти кумулятивную сумму по полю `classes` для всех строк до текущей включительно
с разбивкой по `user_id`и сортировкой по `dt`. 
**В результате** получим CTE `classes_by_dates_dates_cumsum`с полями: `user_id`, `dt`, `classes` — `classes_cs`(кумулятивная сумма по `classes`).
При подсчете кумулятивной суммы заменим пустые значения нулями.
*/
    classes_by_dates_cumsum as (
    select adu.user_id, adu.dt, classes,
           coalesce(sum(classes) over (partition by adu.user_id order by adu.dt), 0) as classes_cs
      from all_dates_by_user adu
           left join classes_by_dates cd
                     on cd.user_id = adu.user_id
                     and cd.class_date = adu.dt -- оставляем все даты
    ),
/*
### Шаг 8
Создадим CTE `balances` с вычисленными балансами каждого студента.
Для этого объединим таблицы `payments_by_dates_cumsum` и `classes_by_dates_dates_cumsum` так,чтобы совпадали даты и `user_id`.
**Получим такие поля:**
`user_id`, `dt`, `transaction_balance_change`, `transaction_balance_change_cs`, `classes`, `classes_cs`, `balance` (`classes_cs` + `transaction_balance_change_cs`)
*/
    balances as (
    select pdc.user_id, pdc.dt, transaction_balance_change, transaction_balance_change_cs, classes, classes_cs,
           (classes_cs + transaction_balance_change_cs) as balance
      from payments_by_dates_cumsum pdc
           join classes_by_dates_cumsum cdc
                on cdc.user_id = pdc.user_id
                and cdc.dt = pdc.dt
    )
/*
### Задание 1
Выберите топ-1000 строк из CTE `balances` с сортировкой по `user_id` и `dt`. Посмотрите на изменения балансов студентов. 
Какие вопросы стоит задавать дата-инженерам и владельцам таблицы `payments`?
*/
-- select user_id, dt, transaction_balance_change, transaction_balance_change_cs, classes, classes_cs, balance
--   from balances
--  order by user_id, dt
--  limit 1000;
/*
### Шаг 9
Посмотрим, как менялось общее количество уроков на балансах студентов.
Для этого просуммируем поля `transaction_balance_change`, `transaction_balance_change_cs`, `classes`, `classes_cs`, `balance`
из CTE `balances` с группировкой и сортировкой по `dt`.
*/
select distinct dt, 
       sum (transaction_balance_change) over (partition by dt) as sum_transaction_balance_change,
       sum (transaction_balance_change_cs) over (partition by dt) as sum_transaction_balance_change_cs,
       sum (classes) over (partition by dt) as sum_classes,
       sum (classes_cs) over (partition by dt) as sum_classes_cs,
       sum (balance) over (partition by dt) as sum_balance
  from balances
 order by dt;


/*
### Задание 2
Создайте визуализацию (линейную диаграмму) итогового результата. 
Какие выводы можно сделать из получившейся визуализации?

Вывод: суммарный баланс студентов имеет тенденцию к небольшому росту за год. 
        Накапливается к весне, немного проседает за лето, вырастает в начале учебного года и уменьшается (расходуется) к концу календарного.
*/