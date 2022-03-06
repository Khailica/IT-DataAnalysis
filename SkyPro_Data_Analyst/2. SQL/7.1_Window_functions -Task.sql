-- урок 7 в виде CTE. Оконные функции.
with needed_users as 
    (select user_id
    from skyeng_db.classes
    group by user_id
    having count(case when class_status = 'success' and class_type = 'trial' then 1 end) > 0 
        and max(class_start_datetime) < '2017-12-01'
    ),
lag_classes as 
    (select c.*
        , class_start_datetime - coalesce(lag(class_start_datetime) over(partition by user_id order by class_start_datetime), class_start_datetime) previous_class
    from skyeng_db.classes c 
        join needed_users n using(user_id)
    where class_status = 'success'
    order by user_id, class_start_datetime
    ),
streak_classes as 
    (select *
        , sum(case when previous_class > interval '30 days' then 1 else 0 end) over(partition by user_id order by class_start_datetime) streak_number
    from lag_classes
    ),
streak_trial as 
    (select *
        , max(case when class_type = 'trial' then class_type end) over(partition by user_id, streak_number) trial_happened
    from streak_classes
    ), 
user_lesson_count as 
    (select user_id, streak_number
        , count(1) classes_count
    from streak_trial
    where trial_happened is not null
    group by 1, 2
    )
select avg(classes_count) average_classes
    , percentile_cont(0.5) within group (order by classes_count) median_classes
from user_lesson_count
where classes_count != 1;


-- урок 7 в виде подзапросов. Оконные функции. 
select avg(classes_count) average_classes
    , percentile_cont(0.5) within group (order by classes_count) median_classes
from 
    (select user_id, streak_number
        , count(1) classes_count
    from 
        (select *
            , max(case when class_type = 'trial' then class_type end) over(partition by user_id, streak_number) trial_happened
        from
            (select *
                , sum(case when previous_class > interval '30 days' then 1 else 0 end) over(partition by user_id order by class_start_datetime) streak_number
            from
                (select c.*
                        , class_start_datetime - coalesce(lag(class_start_datetime) over(partition by user_id order by class_start_datetime), class_start_datetime) previous_class
                from skyeng_db.classes c 
                    join
                        (select user_id
                        from skyeng_db.classes
                        group by user_id
                        having count(case when class_status = 'success' and class_type = 'trial' then 1 end) > 0 
                            and max(class_start_datetime) < '2017-12-01'
                        ) as n using(user_id)
                where class_status = 'success'
                order by user_id, class_start_datetime
                ) as lag_classes
            ) as streak_classes
        ) as streak_trial
    where trial_happened is not null
    group by 1, 2
    ) as user_lesson_count
where classes_count != 1;


/*
Напишите запрос, который для каждого дня посчитает с нарастающим итогом количество успешных уроков, количество уроков, которые прогуляли студенты,
и общее количество уроков. Не нужно учитывать пробные уроки
Сколько всего уроков было 13 января 2016 года?
*/

select distinct class_start_datetime::date, -- надо избавляться от использования distinct
        count(id_class) filter(where class_status = 'success') over(order by class_start_datetime::date) cumulative_succesful_classes,
        count(id_class) filter(where class_status = 'failed_by_student') over(order by class_start_datetime::date) cumulative_count_failed_by_student,
        count(id_class) over(order by class_start_datetime::date) cumulative_count_total
    from skyeng_db.classes
    where class_type != 'trial';

-- вариант решения от школы. Используем CTE и определение рамки окна
with classes_counts as 
    (select date_trunc('day', class_start_datetime) as class_day,
         coalesce(class_status, 'NA') as class_status,
         count(id_class) as classes
    from skyeng_db.classes
    where class_type != 'trial'
    group by 1, 2
    )
select distinct class_day,
     sum(case when class_status='success' then classes else 0 end) over(order by class_day rows between unbounded preceding and current row) as succesful_classes,
     sum(case when class_status='failed_by_student' then classes else 0 end) over(order by class_day rows between unbounded preceding and current row) as failed_by_student_classes,
     sum(classes) over(order by class_day rows between unbounded preceding and current row) as total_classes
from classes_counts
order by class_day;

.
select *
from skyeng_db.classes
limit 100;


/*
Напишите запрос, который позволит выбрать до 10 учителей из каждого департамента. Нужно в CTE пронумеровать учителей в разбивке по департаментам
(row_number) и в порядке возрастания id_teacher, назовем новое поле id_in_dept, и в итоговом запросе вывести всех, у кого id_in_dept<=10.
Нужно, чтобы итоговый запрос выводил такие поля
department
id_teacher
max_teaching_level
city
country
id_in_dept
Напишите id_in_dept департамента учителя, с id_teacher = 675,223.
*/

with teacher_number as
    (select department, id_teacher, max_teaching_level, city, country,
        row_number() over(partition by department order by id_teacher) as id_in_dept
    from skyeng_db.teachers
    )
select *
from teacher_number
where id_in_dept <=10;


--решение от школы
with data_with_id as
(
select id_teacher,
       department,
       max_teaching_level,
       city,
       country,
       row_number() over(partition by department order by id_teacher) as id_in_dept
from skyeng_db.teachers
where department is not null
)
select *
from data_with_id
where id_in_dept <= 10
order by department, id_in_dept;


select *
from skyeng_db.teachers
limit 100;



/*Найдите распределение фильмов, вышедших в 2020 году по длине их названий.
Используйте таблицу imdb.title_basics. Год выхода фильма - startYear, название - primaryTitle.
Не забудьте использовать с этими полями двойные кавычки. Нужно сгруппировать фильмы по длине названия и посчитать их.
Напиши количество фильмов, длина названия которых равна 10*/

select distinct character_length("primaryTitle") as title_lenght, -- надо избавляться от использования distinct 
    count(tconst) over(partition by character_length("primaryTitle")) as count_movies
from imdb.title_basics
where "startYear" = 2020;

-- решение школы
select length("primaryTitle") as title_length,
    count(tconst) as movies
from imdb.title_basics
where "startYear" = 2020
group by 1
order by 1;


select *
from imdb.title_basics
limit 10;


/*Давайте попробуем понять, какие части фильмов выходили за какими и проставить номер части, основываясь на названиях и датах выхода фильмов.
Для начала, определим какие фильмы мы будем рассматривать:
Найдите все фильмы, которые: в названии содержат двоеточие ":", не начинаются с двоеточия, не начинаются со знака решетки (#)
Потом с помощью strpos и substring, а также - row_number создайте запрос, который вернет такие поля:
tconst, primaryTitle, часть названия до двоеточия - main_title, часть названия после двоеточия без пробела в начале - secondary_title, startYear,
порядковый номер части с разбивкой по main_title и сортировкой по startYear и tconst - part_number
Какой номер части у фильма с tconst = tt2017085 ?*/

with distribution as
    (select tconst, "primaryTitle"
        , split_part("primaryTitle", ':', 1) as main_title -- разделяет строку по символу ':' и выдаёт 1-ый элемент
        , trim(substring("primaryTitle" from (strpos("primaryTitle", ':')) + 1)) as secondary_title
        , "startYear"
        , row_number() over(partition by split_part("primaryTitle", ':', 1) order by "startYear", tconst) as part_number
    from imdb.title_basics
    where "primaryTitle" like '%:%'
        and "primaryTitle" not in (':%','#%')
    )
select *
from distribution
where tconst = 'tt2017085';

-- решение школы
select tconst
    , substring("primaryTitle", 0, position(':' in "primaryTitle")) as main_title
    , substring("primaryTitle", position(':' in "primaryTitle")+2) as secondary_title
    , "primaryTitle", "startYear", row_number() over(partition by substring("primaryTitle", 0, position(':' in "primaryTitle")) order by "startYear", tconst) as part_number
from imdb.title_basics
where "primaryTitle" like '%:%' 
    and "primaryTitle" not like ':%' 
    and "primaryTitle" not like '#%'
order by main_title, "startYear", tconst;


select *
from imdb.title_basics
limit 100;


/*Как бы мы написали запрос, который добавил бы в каждую строку для каждого ученика количество пройденных им уроков?*/

with basic_table as -- создаем запрос с данными об уроках
        (select user_id,
               id_class,
               class_start_datetime
        from skyeng_db.classes
        where class_type!='trial' 
              and class_status='success' 
              and user_id in (455196710, 87589504)
        ),
    aggregates as -- считаем количество уроков для каждого ученика
        (select user_id, count(id_class) as classes_count_total
        from basic_table
        group by user_id
        )-- получаем результат
select basic_table.user_id,
       basic_table.id_class,
       basic_table.class_start_datetime,
       aggregates.classes_count_total
from basic_table
join aggregates
    on aggregates.user_id = basic_table.user_id
order by user_id, class_start_datetime;

-- тоже самое при помощи оконной функции
select user_id,
       id_class,
       class_start_datetime,
       count(id_class) over(partition by user_id) as classes_count_total
from skyeng_db.classes
where class_type!='trial' 
      and class_status='success' 
      and user_id in (455196710, 87589504);


/*А теперь попробуем создать поле с порядковым номером урока для каждого ученика.*/

with basic_table as -- создаем запрос с данными об уроках
        (select user_id,
               id_class,
               class_start_datetime
        from skyeng_db.classes
        where class_type!='trial' 
              and class_status='success' 
              and user_id in (455196710, 87589504)
        )
select b1.user_id
     , b1.id_class
     , b1.class_start_datetime
     , count(b2.id_class) as class_number -- можно (а если индекс то и нужно) вместо count(b2.id_class) -> count(b1.class_id)
from basic_table b1
left join basic_table b2
    on b1.user_id = b2.user_id
       and b2.class_start_datetime <= b1.class_start_datetime
group by b1.user_id
     , b1.id_class
     , b1.class_start_datetime
order by b1.user_id, b1.class_start_datetime;

-- тоже самое с помощью оконной функции, причем двумя способами
select user_id,
    id_class,
    class_start_datetime,
    count(id_class) over
        (partition by user_id
        order by class_start_datetime 
        rows between unbounded preceding and current row -- можно не писать, подразумевается по умолчанию
        ) as row_number_with_count,
    row_number() over
        (partition by user_id 
        order by class_start_datetime
        ) as row_number_with_row_number
from skyeng_db.classes
where class_type!='trial' 
      and class_status='success' 
      and user_id in (455196710, 87589504);
      

-- как посмотреть информацию по таблицам. Пример:
CREATE TABLE article (
    article_id bigserial PRIMARY KEY,
    article_name varchar(20) NOT NULL,
    article_desc TEXT NOT NULL,
    date_added timestamp DEFAULT NULL);

SELECT *
  FROM information_schema.columns
 WHERE table_name = 'article';

SELECT c.column_name, c.data_type
  FROM information_schema.table_constraints tc
       JOIN information_schema.constraint_column_usage AS ccu USING (constraint_schema, constraint_name)
       JOIN information_schema.columns AS c ON c.table_schema = tc.constraint_schema
            AND tc.table_name = c.table_name 
            AND ccu.column_name = c.column_name
 WHERE constraint_type = 'PRIMARY KEY' and tc.table_name = 'article';

-- информацию по первичным ключам во всей БД
SELECT c.column_name, c.data_type, tc.table_name
  FROM information_schema.table_constraints tc
       JOIN information_schema.constraint_column_usage AS ccu using(constraint_schema, constraint_name)
       JOIN information_schema."columns" AS c
            ON c.table_schema = tc.constraint_schema
            AND tc.table_name = c.table_name
            AND ccu.column_name = c.column_name
 WHERE constraint_type = 'PRIMARY KEY' 

