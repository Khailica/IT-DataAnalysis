/* Задание 6.1
Распределение нагрузки
Найдите преподавателя, который провел максимальное количество уроков в 2016 году. 
Интересуют только уроки, которые были списаны с баланса, то есть успешно пройдены (`success`) или прогуляны (`failed_by_student`) студентом.
Не включайте в выборку триальные уроки.  
Важно найти полную информацию по учителю, а не только id_teacher.
*/

with cte as
    (select id_teacher, count(id_class) cc
      from skyeng_db.classes
     where class_status = 'success'
           or class_status = 'failed_by_student'
           and class_type != 'trial'
           and date_trunc('year', class_start_datetime) = '2016-01-01'
           and date_trunc('year', class_end_datetime) = '2016-01-01'
     group by id_teacher
     )
select cc count_class, t.*
  from cte
       join skyeng_db.teachers t on t.id_teacher = cte.id_teacher
 where cc = (select max(cc) from cte);


-- Жанна Домашенко
SELECT t.*, count(c.id_class) classes_in_2016
FROM skyeng_db.classes c JOIN
    skyeng_db.teachers t ON c.id_teacher = t.id_teacher
    AND c.class_type != 'trial'
    AND c.class_status IN ('success', 'failed_by_student')
    AND DATE_TRUNC('year', c.class_start_datetime) = '2016-01-01'
GROUP BY t.id_teacher
Order by count(c.id_class) desc
Limit 1;


/* Задание 6.1 вар1
Планирование нагрузки
Напишите запрос, который покажет распределение учителей по количеству проводимых в месяц уроков
(опять же - не триальных, а только успешных или прогулянных самим студентом).
Используя подзапросы, выведите распределение учителей по количеству проведенных в месяц уроков в штуках,
ориентируясь на запрос из задания 1.
*/

select cc2.cc1 count_class, t.*
  from 
       (select c.id_teacher,
               count(id_class)::numeric / (select count(distinct date_trunc('month', class_start_datetime)) from skyeng_db.classes) cc1  -- количество уроков в месяц
          from skyeng_db.classes c
               join skyeng_db.teachers t on t.id_teacher = c.id_teacher
         where class_status = 'success'
               or class_status = 'failed_by_student'
               and class_type != 'trial'
         group by c.id_teacher
        ) cc2   -- таблица id учителя и cc1 количество уроков в месяц
  join skyeng_db.teachers t on t.id_teacher = cc2.id_teacher
 order by count_class desc;


-- 2 вариант
select tmc.count_class, count(tmc.id_teacher) as count_teachers -- количество учителей, которые провели найденное количество уроков за 2016 год
  from
       (select c.id_teacher,
               date_part('month', class_start_datetime) as month_class,
               count(id_class) as count_class
          from skyeng_db.classes c
               join skyeng_db.teachers t on t.id_teacher = c.id_teacher
         where class_status in ('success', 'failed_by_student')
               and class_type != 'trial'
               and date_trunc('year', class_start_datetime) = '2016-01-01'
         group by 1, 2
       ) as tmc --распределение учителей по месяцам и количеству проведённых уроков
 group by 1;
