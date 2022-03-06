/* Задание 2.1
Посчитать средний возраст клиентов в разрезе месяцев*/
WITH credit_info_month AS (
     SELECT id_client,
             id_credit,
             DATE_PART('month', date_credit) month_credit,
             DATE_PART ('year', date_credit) year_credit,
             credit_value,
             age,
             education education_idx
       FROM sql_group_task_step_2.credit_info
)
SELECT month_credit, AVG(age) avg_age
  FROM credit_info_month
 GROUP BY (1)
 ORDER BY (1)




/*Задание 2.2
Найти долю кредитов, выдаваемых клиентам без высшего образования.*/
WITH ed_cred_info AS (
    SELECT ci.*, ed.education_text, DATE_TRUNC ('month' , date_credit) month_credit
      FROM sql_group_task_step_2.credit_info ci 
           JOIN sql_group_task_step_2.dim_education ed ON ci.education=ed.education_idx
    ),
  cred_wot_higher_ed AS (
    SELECT COUNT (id_credit) cnt_credit_wot_higher_ed,
           SUM (credit_value) value_credit_wot_higher_ed, month_credit
      FROM ed_cred_info
     WHERE education_text!='Полное высшее'
     GROUP BY (month_credit)
    ),
  credit_monthly AS (
    SELECT COUNT (id_credit) cnt_credit_monthly,
           SUM (credit_value) value_credit_monthly, month_credit
      FROM ed_cred_info
     GROUP BY (month_credit)
)
SELECT whe.cnt_credit_wot_higher_ed::float / cm.cnt_credit_monthly share_cnt_wot_higher_monthly,
       whe.value_credit_wot_higher_ed::float / cm.value_credit_monthly share_value_wot_higher_monthly, whe.month_credit
  FROM cred_wot_higher_ed whe
       JOIN credit_monthly cm ON whe.month_credit=cm.month_credit;

-- вторая часть запроса к CTE
SELECT COUNT (  
        CASE WHEN education_text NOT IN ('Полное высшее', 'Неоконченное высшее')
             THEN id_credit
         END
             )::float / COUNT(id_credit)::float*100 AS share_cnt_wot_higher, 
        SUM (
            CASE WHEN education_text NOT IN ('Полное высшее', 'Неоконченное высшее')
                 THEN credit_value
            END
            )::float / SUM(credit_value)::float*100 AS share_value_wot_higher,
        COUNT (
            CASE WHEN education_text!='Полное высшее'
                 THEN id_credit
            END
              )::float / COUNT(id_credit)::float*100 AS share_cnt_wot_finished_higher, 
        SUM (
            CASE WHEN education_text!='Полное высшее' 
                 THEN credit_value
            END
            )::float / SUM(credit_value)::float*100 AS share_value_wot_finished_higher
FROM ed_cred_info;





/* Задание 2.3
Выгрузить в Excel записи с ненулевыми значениями credit_value и датой выдачи кредита в диапазоне 15.01.2010 и 15.05.2011*/

SELECT date_credit,
        credit_value,
        id_client,
        age,
        education_text
  FROM sql_group_task_step_2.credit_info ci
       LEFT JOIN sql_group_task_step_2.dim_education de
                 ON ci.education = de.education_idx
                  AND DATE_TRUNC ('day', date_credit) BETWEEN '2010-01-15' AND '2011-05-15'
                  AND credit_value IS NOT NULL;



/*Задание 2.4
Найти средний возраст клиентов по дням и отразить на графике*/
WITH credits_of_interests AS (
     SELECT
          date_credit,
          credit_value,
          id_client,
          age,
          education_text
     FROM sql_group_task_step_2.credit_info ci
           LEFT JOIN sql_group_task_step_2.dim_education de
                       ON ci.education = de.education_idx
                       AND DATE_TRUNC ('day', date_credit) BETWEEN '2010-01-15' AND '2011-05-15'
                       AND credit_value IS NOT NULL
)
SELECT date_credit,
        AVG(age) avg_age
  FROM credits_of_interests
 GROUP BY 1;



/* Задание 2.5
Добавить столбец age_group и задать значение в соответствии с названиями групп*/
SELECT date_credit,
        DATE_TRUNC('month' , date_credit) month_cred,
        credit_value,
        id_client,
        age,
        education_text,
        (CASE
               WHEN age BETWEEN 18 AND 25 THEN '18 - 25'
               WHEN age BETWEEN 25 AND 35 THEN '25 - 35'
               WHEN age BETWEEN 35 AND 45 THEN '35 - 45'
               WHEN age BETWEEN 45 AND 60 THEN '45 - 60'
               ELSE '60'
          END) age_group
  FROM
        sql_group_task_step_2.credit_info ci
        LEFT JOIN sql_group_task_step_2.dim_education de
                     ON ci.education = de.education_idx
                     AND DATE_TRUNC ('day', date_credit) BETWEEN '2010-01-15' AND '2011-05-15'
                     AND credit_value IS NOT NULL;