/*1. При помощи SQL найти даты в которые:
    1.1. Был выдан кредит с минимальной суммой
    1.2. Был выдан кредит с максимальной суммой*/

-- даты в которые был выдан кредит с минимальной суммой
select date_credit
  from sql_group_task_step_1.credit_info
 where credit_value = (select min(credit_value) from sql_group_task_step_1.credit_info)
 order by date_credit;

-- даты в которые был выдан кредит с максимальной суммойт
select date_credit
  from sql_group_task_step_1.credit_info
 where credit_value = (select max(credit_value) from sql_group_task_step_1.credit_info)
 order by date_credit;

-- все записи из таблицы
select *
  from sql_group_task_step_1.credit_info;



/* 3. Оценить тренд по выдаваемым кредитам: растет ли “закредитованность” клиентов банка?*/


-- сумма кредита в день, скользящее среднее по неделе и по месяцу для исключения влияния
-- суточных (недельных, месячных) колебаний и для оценки тренда
with CTE as
    (select date_trunc('day', date_credit::date) as date_credit_day,
        sum(credit_value) as credit_value_day
    from sql_group_task_step_1.credit_info
    group by date_credit_day
    ) -- сумма кредита в день
select date_credit_day, credit_value_day,
    avg(credit_value_day) over(order by date_credit_day rows between 3 preceding and 3 following) as moving_average_7,
    avg(credit_value_day) over(order by date_credit_day rows between 15 preceding and 15 following) as moving_average_31
from CTE
order by date_credit_day;