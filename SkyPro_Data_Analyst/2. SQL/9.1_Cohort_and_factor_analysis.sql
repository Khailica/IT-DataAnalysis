/* Когортный анализ */


-- Retention учеников в успешные занятия (долю учеников, которые вернулись)
with students_firth_month as -- Выделим первый месяц, когда у учеников были успешные занятия
    (select user_id, date_trunc('month', min(class_start_datetime))::date first_month
    from skyeng_db.classes
    where class_status = 'success'
    group by 1 
    ),
students_months as -- Найдем все месяцы, в которых у учеников были успешные занятия
    (select distinct user_id, date_trunc('month', class_start_datetime)::date mon
    from skyeng_db.classes
    where class_status = 'success'
    order by 1 
    ),
returned as -- выделим месяцы, в которые ученик возвращался на платформу
    (select f.first_month
        , date_part('year', m.mon)*12 + date_part('month', m.mon) - 
            (date_part('year', f.first_month)*12 + date_part('month', f.first_month)) mon_diff
        , count(m.user_id) users_count
    from students_firth_month f 
        join students_months m on f.user_id = m.user_id
    group by 1, 2
    )
select first_month, mon_diff 
    , users_count::float/max(users_count) over(partition by first_month)*100 retention
from returned
where first_month < '2017-01-01' 
    and mon_diff <= 12 
order by first_month, mon_diff


/* Факторный анализ 
Составить модель выручки с зависимостью от количества платящих и от средней выручки.
произвести факторный анализ выручки в июле и авгуте 2016 года в зависимости от этих параметров.
Объяснить, что больше повлияло на рост*/


with revenue_monthly as
    (select date_trunc('month', transaction_datetime)::date::text pay_month
        , sum(payment_amount) revenue
        , count(distinct user_id) paying_users
        , sum(payment_amount)::float/count(distinct user_id) arppu
    from skyeng_db.payments
    where id_transaction is not null 
        and status_name = 'success'
        and date_part('year', transaction_datetime) = 2016
        and date_part('month', transaction_datetime) in (7, 8)
    group by 1 
    )
select * -- Найдем выручку в июле и августе
from revenue_monthly
union all .
select 'diff' -- Выясним, какая из переменных больше всего повлияла на рост общей выручки за месяц
    , max(case when pay_month = '2016-08-01' then revenue end) - max(case when pay_month = '2016-07-01' then revenue end) revenue_diff
    , max(case when pay_month = '2016-08-01' then paying_users end) - max(case when pay_month = '2016-07-01' then paying_users end) paying_users_diff
    , max(case when pay_month = '2016-08-01' then arppu end) - max(case when pay_month = '2016-07-01' then arppu end) paying_users_diff
from revenue_monthly
union all
select 'diff_explain' -- Поймем, что больше всего повлияло на выручку: рост платящих пользователей или рост выручки на платящих пользователей
    , max(case when pay_month = '2016-08-01' then revenue end) - max(case when pay_month = '2016-07-01' then revenue end)
    , (max(case when pay_month = '2016-08-01' then paying_users end) - max(case when pay_month = '2016-07-01' then paying_users end)) *
        max(case when pay_month = '2016-07-01' then arppu end) paying_users_explain
    , (max(case when pay_month = '2016-08-01' then arppu end) - max(case when pay_month = '2016-07-01' then arppu end)) *
        max(case when pay_month = '2016-08-01' then paying_users end) arppu_explain
from revenue_monthly


