/* Задание 7.1
Посчитайте, сколько оплат успешно приходит каждый день. Вычислите скользящее среднее с окном 7 и 31 день так,
чтобы текущая строка была в середине диапазона.
Добавьте еще поле с кумулятивной суммой (нарастающим итогом) количества оплат.
Оплаты
    - Успешные, status_name равно success.
    - Тип оплаты «Покупка уроков» или «Начисление корпоративному клиенту».*/

with payments_per_day as
    (select distinct date_trunc('day', transaction_datetime::date) as payment_date
        , count(id_transaction) over(partition by date_trunc('day', transaction_datetime::date)) as count_payments
        , count(id_transaction) over(order by date_trunc('day', transaction_datetime::date)) as comulative_count_payments
    from skyeng_db.payments
    where status_name = 'success' 
        and operation_name in ('Покупка уроков', 'Начисление корпоративному клиенту')
    )
select *
    , avg(count_payments) over(order by payment_date rows between 3 preceding and 3 following) as moving_average_7
    , avg(count_payments) over(order by payment_date rows between 15 preceding and 15 following) as moving_average_31
from payments_per_day;



/* Задание 7.2
Напишите запрос, который позволит увидеть такие данные:
    - ID пользователя,
    - сумма оплаты,
    - дата оплаты,
    - ID транзакции,
    - номер оплаты для пользователя с сортировкой по дате оплаты,
    - номер оплаты для пользователя в текущем месяце,
    - общая сумма платежей каждого пользователя в текущем месяце,
    - дата предыдущей оплаты,
    - дата следующей оплаты.
**Оплаты:**
    - Успешные, status_name равно success.
    - Тип оплаты «Покупка уроков» или «Начисление корпоративному клиенту».*/

select user_id
    , payment_amount
    , date_trunc('day', transaction_datetime::date) as payment_date
    , id_transaction
    , row_number() over
            (partition by user_id
            order by date_trunc('day', transaction_datetime::date)
            ) as number_payment_day
    , row_number() over
            (partition by user_id, date_trunc('month', transaction_datetime::date)
            order by date_trunc('day', transaction_datetime::date)
            ) as number_payment_month
    , sum(payment_amount) over
            (partition by user_id, date_trunc('month', transaction_datetime::date)
            ) as total_payments_month
    , lag(date_trunc('day', transaction_datetime::date)) over
            (partition by user_id
            order by date_trunc('day', transaction_datetime::date)
            ) as lag_date_payment
    , lead(date_trunc('day', transaction_datetime::date)) over
            (partition by user_id
            order by date_trunc('day', transaction_datetime::date)
            ) as lead_date_payment
from skyeng_db.payments
where status_name = 'success' 
    and operation_name in ('Покупка уроков', 'Начисление корпоративному клиенту');
