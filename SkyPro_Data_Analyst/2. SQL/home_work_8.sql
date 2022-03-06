-- создаю таблицу
create temp table capitalisation (
    "Страна" text,
    "Компания" text,
    "Капитализация" integer
);

-- заполняю данными
insert into capitalisation ("Страна", "Компания", "Капитализация")
values
    ('Россия', 'Сбербанк', 79504),
    ('Россия', 'Газпром', 68012),
    ('Россия', 'Яндекс', 22122),
    ('Россия', 'Татнефть', 15176),
    ('Россия', 'X5 Retail Group', 9809),
    ('США', 'Apple', 1113000),
    ('Китай', 'Alibaba', 522000),
    ('США', 'Amazon', 1000000),
    ('Саудовская Аравия', 'Saudi Aramco', 1602000),
    ('США', 'Facebook', 475000);

-- проверяю выборку
select *
from capitalisation;

-- опусташаю таблицу (приходилось делать, т.к. данные портились в результате "туда-сюда" заполнения временной таблицы данными)
truncate table capitalisation;



/* Задание 8.1
Необходимо выявить в каждой стране компанию, капитализация которой максимальна*/

SELECT c1."Страна", "Компания", "Капитализация"
  FROM capitalisation c1
       JOIN 
            (SELECT "Страна", max("Капитализация") AS max_cap
               FROM capitalisation
              GROUP BY "Страна"
            ) AS c2
            ON c2.max_cap = c1."Капитализация"
ORDER BY c1."Страна";


-- удаляю временную таблицу
drop table capitalisation;



/* Задание 8.2
Необходимо вывести самые высокие по цене объявления у тех продавцов, у которых было больше всего просмотров в декабре 2020 года
(оставляем только трех продавцов).
То есть задачка решается в два действия:
1. Выбираем трех продавцов по всем объявлениям, у которых было наибольшее количество просмотров всех объявлений.
2. Выводим для каждого продавца самое дорогое объявление — указываем ID продавца, название объявления и его цену.*/


-- число просмотром объявлений за декабрь 2020 года
create temp table count_number_of_reviews as 
    (select host_id, count(number_of_reviews) as count_number
    from airbnb_dallas.listings l 
        join airbnb_dallas.reviews r on r.listing_id = l.id
    where date_trunc('month', "date"::date) = '2020-12-01'
    group by host_id);
    
-- проверяем таблицу
select *
from count_number_of_reviews;

-- 3 продавца, у которых было больше всего просмотров в декабре 2020 года
create temp table sellers as
    (select host_id, max(count_number) as max_number_reviews
    from count_number_of_reviews cnr 
    --     join airbnb_dallas.reviews r on r.listing_id = l.id
    -- where date_trunc('month', "date"::date) = '2020-12-01'
    group by host_id
    order by 2 desc
    limit 3);


-- проверяем таблицу
select *
from sellers;

-- находим самое дорогое объявление для найденных продавцов
create temp table sellers_max_price as
    (select l.host_id, max(price) as max_price
    from airbnb_dallas.listings l
        join sellers s on s.host_id = l.host_id
    group by l.host_id
    order by max_price desc);

-- проверяем таблицу
select *
from sellers_max_price;

-- итоговая выборка - для каждого продавца самое дорогое объявление — указываем ID продавца, название объявления и его цену
select l.host_id, l.name, l.price
from sellers_max_price smp
    join airbnb_dallas.listings l on l.price = smp.max_price
        and l.host_id = smp.host_id
order by l.price desc;


-- удаляем временные таблицы
drop table count_number_of_reviews;
drop table sellers;
drop table sellers_max_price;



/* Задание 8.3
Посмотреть и сравнить, как отличается конверсия в третью покупку у учеников,
совершивших вторую покупку внутри схемы skyeng_db, в зависимости от пола*/

-- ученики, совершившие вторую покупку
create temp table sex_paid2 as
    (select student_sex, count(user_id) as count_sex_paid2
    from 
        (select s.student_sex, p.user_id, count(id_transaction) as count_paid2
        from skyeng_db.payments p
            join skyeng_db.students s on s.user_id = p.user_id
        where operation_name = 'Покупка уроков'
            and student_sex is not null
        group by s.student_sex, p.user_id
        having count(id_transaction) = 2
        ) as users_paid2
    group by student_sex);

-- смотрим таблицу
select *
from sex_paid2;


-- ученики, совершившие третью покупку
create temp table sex_paid3 as
    (select student_sex, count(user_id) as count_sex_paid3
    from 
        (select s.student_sex, p.user_id, count(id_transaction) as count_paid3
        from skyeng_db.payments p
            join skyeng_db.students s on s.user_id = p.user_id
        where operation_name = 'Покупка уроков'
            and student_sex is not null
        group by s.student_sex, p.user_id
        having count(id_transaction) = 3
        ) as users_paid3
    group by student_sex);

-- смотрим таблицу
select *
from sex_paid3;


-- итоговый запрос - конверсия в третью покупку у учеников, совершивших вторую покупку
select student_sex, (count_sex_paid3 / count_sex_paid2::numeric) as conversion3
from sex_paid2 sp2
    join sex_paid3 sp3 using(student_sex);


-- удаляем временные таблицы
drop table sex_paid2;
drop table sex_paid3;



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