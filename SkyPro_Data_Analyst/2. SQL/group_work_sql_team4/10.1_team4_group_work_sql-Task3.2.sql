/*посчитать количество выданных в январе 2011 года кредитов в разрезе типа кредита (автокредит, ипотека, потребительский)*/

SELECT credit_type,
       CASE
            WHEN credit_type = 'Автокредит' THEN count(id_credit)
            WHEN credit_type = 'Ипотека' THEN count(id_credit)
            WHEN credit_type = 'Потребительский' THEN count(id_credit)
       END count_credit
  FROM sql_group_task_step_3.credit_info
 WHERE date_trunc('month', date_credit) = '2011-01-01'
 GROUP BY credit_type;