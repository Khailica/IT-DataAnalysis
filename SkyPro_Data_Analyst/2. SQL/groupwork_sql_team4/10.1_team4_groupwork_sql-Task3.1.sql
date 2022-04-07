/*посчитать отношение кредита к сумме всех денежных средств клиентов в банке в разрезе месяцев. Что вы можете сказать на основании этих данных?*/

/*select *
from sql_group_task_step_3.credit_info 
order by id_client
limit 100;*/

/*т.к. нам неизвесто, какой остаток по кредиту остаётся у каждого клиента в последующие месяцы после его оформления,
будем считать, что кредит гасится единым платежом в дату фактического погашения или по истечении кредитного периода,
а до тех пор сумма кредита числится за клиентом ежемесячно. 
Так же будет считать, что депозит тоже числится за клиентом весь кредитный период.*/

-- 1 вариант с рекурсией
WITH RECURSIVE r AS (
     -- стартовая часть
     SELECT 
            id_client,
            credit_value,
            bks,
            date_trunc('month', date_credit) AS x
       FROM sql_group_task_step_3.credit_info
            UNION 
     -- рекурсивная часть
     SELECT
            r.id_client,
            ci.credit_value,
            ci.bks,
            x + INTERVAL '1 month' AS x
       FROM r
            JOIN sql_group_task_step_3.credit_info ci on ci.id_client = r.id_client
      WHERE 
            (case when date_closing_fact is not null 
                then x < date_trunc('month', date_closing_fact) 
                else x < date_trunc('month',date_credit) + make_interval(months => credit_period) -- когда отсутствует значение в поле date_closing_fact
            end)
)
SELECT
       r.x as "month",
       sum(r.credit_value) AS sum_credit,
       sum(r.bks) AS sum_depozit,
       sum(r.credit_value)::NUMERIC / NULLIF(sum(r.bks), 0) AS ratio
  FROM r
 GROUP BY r.x
 ORDER BY r.x;



/*2 вариант, но в нём нельзя употрепить условный оператор CASE (т.к. возвращаются множественные значения)
и учесть отсутствие значений в поле date_closing_fact, поэтому дату фактического закрытия кредита не учитываем*/
WITH CTE AS (
    SELECT
           id_client,
           generate_series(date_trunc('month', date_credit), (date_trunc('month', date_credit) + make_interval(months => credit_period)), INTERVAL '1 month') AS "month"
      FROM sql_group_task_step_3.credit_info
)
SELECT
       CTE."month",
       sum(credit_value) AS sum_credit,
       sum(bks) AS sum_depozit,
       sum(credit_value)::NUMERIC / NULLIF(sum(r.bks), 0) AS ratio
  FROM CTE
       JOIN sql_group_task_step_3.credit_info ci
            ON ci.id_client = CTE.id_client
 GROUP BY CTE."month"
 ORDER BY CTE."month";