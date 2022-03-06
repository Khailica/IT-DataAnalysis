-- первоначальный запрос
explain (analyze) -- cost=6622.16..6622.66
with teachers_cost as (
        select distinct id_teacher,
               case when language_group = 'rus' then 900 else 1500 end as class_cost
          from skyeng_db.teachers
),
    class_data as (
        select distinct user_id, class_start_datetime, class_end_datetime, id_teacher,
               id_class, class_status, class_type
         from skyeng_db.classes
)
select date_trunc('month', class_start_datetime) as class_month,
       sum(class_cost) as total_classes_cost,
       count(id_class) as classes_count,
       sum(class_cost)::float / count(id_class) as avg_cost
  from class_data
       left join teachers_cost on teachers_cost.id_teacher = class_data.id_teacher
 where class_status in ('success', 'failed_by_teacher') -- урок списан с баланса
       and class_start_datetime >= '2016-01-01'::timestamp
       and class_start_datetime < '2017-01-01'::timestamp -- в 2016 году
       and class_type != 'trial' -- не вводный урок
 group by 1
 order by 1;


/*уберём совершенно не нужный distinct в двух местах,
два условия на 2016 года изменим на одно,
индекс по class_start_datetime перестанет использоваться
(думаю функция date_trunc по полю с индексом, не предназначенном для этого замедляла работу),
вместо этого будет происходить простое сканирование таблицы,
left join не нужен, будет inner join,
заменим условие date_trunc на текстовый like для 2016 года, причем '2016' будет стоять в начале строки для поиска*/

--EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON) -- для использования на сайте https://tatiyants.com/pev/
explain (analyze) -- cost=2428.02..2435.50
with teachers_cost as (
        select id_teacher, 
               case when language_group = 'rus' then 900 else 1500 end as class_cost
          from skyeng_db.teachers
),
    class_data as (
        select user_id, class_start_datetime, class_end_datetime, id_teacher, 
               id_class, class_status, class_type
         from skyeng_db.classes
)
select date_trunc('month', class_start_datetime) as class_month,
       sum(class_cost) as total_classes_cost,
       count(id_class) as classes_count,
       sum(class_cost)::float / count(id_class) as avg_cost
  from class_data
       join teachers_cost on teachers_cost.id_teacher = class_data.id_teacher
 where class_status in ('success', 'failed_by_teacher')
       and class_start_datetime::text like '2016%'
       and class_type != 'trial'
 group by 1
 order by 1;