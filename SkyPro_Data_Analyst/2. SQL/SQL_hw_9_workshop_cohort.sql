
/*
Таблица classes
В этой таблице мы промаркируем когорты и вычислим время их жизни.
Возьмем за основу структуру базовой таблицы (skyeng_db.classes), просто добавим два столбца (cohort и LT month).
*/

with classes as (  
    select *,
           date_trunc('month', min(class_start_datetime) over (partition by user_id)) as cohort,
           extract ('month' from (age(date_trunc ('month', class_start_datetime), date_trunc('month', min(class_start_datetime) over (partition by user_id)))))  
            + ( extract ('year' from (age(date_trunc ('month', class_start_datetime), date_trunc('month', min(class_start_datetime) over (partition by user_id))))) ) * 12 as LT_month
      from skyeng_db.classes
     where class_status in ('success', 'failed_by_students') and class_type in ('single', 'regular') 
     order by user_id, class_start_datetime
),

/*
Таблица cohort_sizes
Здесь мы должны посчитать кол-во людей в каждой когорте.
Эта таблица небольшая, кол-во строчек равняется кол-ву когорт.
Когорты дальше июня нас не интересуют!
*/

    cohort_sizes as (
        select cohort, count (distinct user_id) as cgrt_size
          from classes
         where cohort <= '2016-06-01'
         group by 1
),

/*
Таблица cohort_chrs
Тут мы посчитаем кол-во занятий и активных студентов в каждой когорте в разрезе месяцев жизни.
У каждой когорты будет несколько пережитых месяцев (начиная с 0).
В каждом месяце жизни нас интересует число проведенных уроков и число активных студентов.
Когорты дальше июня нас не интересуют!
*/

    cohort_chrs as (
        select cohort,
               LT_month,
               count (user_id) as lessons_act,
               count (distinct user_id) as students_act
          from classes
         where cohort <= '2016-06-01'
         group by 1,2
         order by 1,2
),

/*
Таблица cohort_life
Здесь добавим к предыдущей таблице (cohort_chrs) таблицу с размерами (cohort_sizes)
Там мы найдем:
- долю активных студентов относительно изначальной когорты;
- сколько пришлось занятий в каждой когороте каждого месяца её жизни;
-сколько в среднем пришлось занятий на одного студента в каждой когороте каждого месяца жизни;
- сколько в среднем пришлось занятий на одного активного студента в каждой когороте каждого месяца жизни.
В каждом месяце жизни нас интересует число проведенных уроков и число активных студентов
Когорты дальше июня нас не интересуют!

*/
    cohort_life as (
        select cohort_chrs.*,
               cohort_sizes.cgrt_size,
               students_act::float / cgrt_size*100 as percent_active,
               lessons_act::float / cgrt_size as lessons_in_each_kohort,
               lessons_act::float / students_act as avg_lessons_on_each
          from cohort_chrs
               join cohort_sizes on cohort_chrs.cohort = cohort_sizes.cohort
  )
  
  --------------------------------------------------- Графический блок ---------------------------------------------------
/*
График "Уроки на 1 студента".
Иллюстрирует активность студентов (classes_per_student) в течение времени жизни каждой когорты (lt_month)
*/

-- select cohort,
--       lt_month,
--       lessons_in_each_kohort
--   from cohort_life;

/*
График "Вымирание когорты".
Иллюстрирует изменение доли активных студентов относительно изначального размера когорты (share_active) в течение времени её жизни (lt_month)
*/

-- select cohort,
--       lt_month,
--       percent_active 
--   from cohort_life;

/*
График "Уроки на 1 активного студента".
Иллюстрирует активность студентов (classes_per_active_student) в течение времени жизни когорты (lt_month)
*/

-- select cohort,
--       lt_month,
--       avg_lessons_on_each
--   from cohort_life;

/*
График "Уроков на студента когорты, кумулятивно".
Иллюстрирует активность студентов во времени в каждой когорте.
Для того чтобы построить этот график нам нужно создать промежуточную таблицу.
*/

select cohort,
       lt_month,
       sum (lessons_in_each_kohort) over (partition by cohort order by lt_month) kummul_summa_lessons
  from cohort_life;


/*
Таблица classes_per_cohort_student
Здесь посмотрим как меняется число уроков на одного студента (classes_per_student) в течение времени его жизни (lt_month)
*/

/*Строим сам график*/