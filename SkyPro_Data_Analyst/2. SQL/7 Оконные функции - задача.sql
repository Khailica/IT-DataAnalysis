-- урок 7 в виде CTE. Оконные функции.
WITH needed_users AS (
	SELECT
		user_id
	FROM
		skyeng_db.classes
	GROUP BY
		user_id
	HAVING
		count(
			CASE
				WHEN class_status = 'success' AND
					class_type = 'trial' THEN
					1
			END
		) > 0 AND
		max(class_start_datetime) < '2017-12-01'
)
, lag_classes AS (
	SELECT
		c.*
	,	class_start_datetime - coalesce(
			lag(class_start_datetime) OVER(PARTITION BY user_id ORDER BY class_start_datetime)
		,	class_start_datetime
		) AS previous_class
	FROM
		skyeng_db.classes c
	JOIN
		needed_users n
			USING(user_id)
	WHERE
		class_status = 'success'
	ORDER BY
		user_id
	,	class_start_datetime
)
, streak_classes AS (
	SELECT
		*
	,	sum(
			CASE
				WHEN previous_class > '30 days'::interval THEN
					1
				ELSE
					0
			END
		) OVER(PARTITION BY user_id ORDER BY class_start_datetime) AS streak_number
	FROM
		lag_classes
)
, streak_trial AS (
	SELECT
		*
	,	max(
			CASE
				WHEN class_type = 'trial' THEN
					class_type
			END
		) OVER(PARTITION BY user_id, streak_number) AS trial_happened
	FROM
		streak_classes
)
, user_lesson_count AS (
	SELECT
		user_id
	,	streak_number
	,	count(1) AS classes_count
	FROM
		streak_trial
	WHERE
		trial_happened IS NOT NULL
	GROUP BY
		1, 2
)
SELECT
	avg(classes_count) average_classes
,	percentile_cont(0.5) WITHIN GROUP (ORDER BY classes_count) AS median_classes
FROM
	user_lesson_count
WHERE
	classes_count <> 1;



-- урок 7 в виде подзапросов. Оконные функции. 
SELECT
	avg(classes_count) average_classes
,	percentile_cont(0.5) WITHIN GROUP (ORDER BY classes_count) AS median_classes
FROM
	(
		SELECT
			user_id
		,	streak_number
		,	count(1) AS classes_count
		FROM
			(
				SELECT
					*
				,	max(
						CASE
							WHEN class_type = 'trial' THEN
								class_type
						END
					) OVER(PARTITION BY user_id, streak_number) AS trial_happened
				FROM
					(
						SELECT
							*
						,	sum(
								CASE
									WHEN previous_class > '30 days'::interval THEN
										1
									ELSE
										0
								END
							) OVER(PARTITION BY user_id ORDER BY class_start_datetime) AS streak_number
						FROM
							(
								SELECT
									c.*
								,	class_start_datetime - coalesce(
										lag(class_start_datetime) OVER(PARTITION BY user_id ORDER BY class_start_datetime)
									,	class_start_datetime
									) AS previous_class
								FROM
									skyeng_db.classes c
								JOIN
									(
										SELECT
											user_id
										FROM
											skyeng_db.classes
										GROUP BY
											user_id
										HAVING
											count(
												CASE
													WHEN class_status = 'success' AND
														class_type = 'trial' THEN
														1
												END
											) > 0 AND
											max(class_start_datetime) < '2017-12-01'
									) AS n
										USING(user_id)
								WHERE
									class_status = 'success'
								ORDER BY
									user_id
								,	class_start_datetime
							) AS lag_classes
					) AS streak_classes
			) AS streak_trial
		WHERE
			trial_happened IS NOT NULL
		GROUP BY
			1, 2
	) AS user_lesson_count
WHERE
	classes_count <> 1;



/*
Напишите запрос, который для каждого дня посчитает с нарастающим итогом количество успешных уроков, количество уроков, которые прогуляли студенты,
и общее количество уроков. Не нужно учитывать пробные уроки
Сколько всего уроков было 13 января 2016 года?
*/

SELECT DISTINCT -- надо избавляться от использования distinct
	class_start_datetime::date
,	count(id_class) FILTER(WHERE class_status = 'success') OVER(ORDER BY class_start_datetime::date) AS cumulative_succesful_classes
,	count(id_class) FILTER(WHERE class_status = 'failed_by_student') OVER(ORDER BY class_start_datetime::date) AS cumulative_count_failed_by_student
,	count(id_class) OVER(ORDER BY class_start_datetime::date) AS cumulative_count_total
FROM
	skyeng_db.classes
WHERE
	class_type <> 'trial';



-- вариант решения от школы. Используем CTE и определение рамки окна
WITH classes_counts AS (
	SELECT
		date_trunc('day', class_start_datetime) AS class_day
	,	coalesce(class_status, 'NA') AS class_status
	,	count(id_class) AS classes
	FROM
		skyeng_db.classes
	WHERE
		class_type <> 'trial'
	GROUP BY
		1, 2
)
SELECT DISTINCT
	class_day
,	sum(
		CASE
			WHEN class_status = 'success' THEN
				classes
			ELSE
				0
		END
	) OVER(ORDER BY class_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS succesful_classes
,	sum(
		CASE
			WHEN class_status = 'failed_by_student' THEN
				classes
			ELSE
				0
		END
	) OVER(ORDER BY class_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS failed_by_student_classes
,	sum(classes) OVER(ORDER BY class_day ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_classes
FROM
	classes_counts
ORDER BY
	class_day;


TABLE skyeng_db.classes LIMIT 100;



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

WITH teacher_number AS (
	SELECT
		department
	,	id_teacher
	,	max_teaching_level
	,	city
	,	country
	,	row_number() OVER(PARTITION BY department ORDER BY id_teacher) AS id_in_dept
	FROM
		skyeng_db.teachers
)
SELECT
	*
FROM
	teacher_number
WHERE
	id_in_dept <= 10;



--решение от школы
WITH data_with_id AS (
  SELECT
    id_teacher
  , department
  , max_teaching_level
  , city
  , country
  , row_number() OVER(PARTITION BY department ORDER BY id_teacher) AS id_in_dept
  FROM
    skyeng_db.teachers
  WHERE
    department IS NOT NULL
)
SELECT
  *
FROM
  data_with_id
WHERE
  id_in_dept <= 10
ORDER BY
  department
, id_in_dept;


TABLE skyeng_db.teachers LIMIT 100;




/*Найдите распределение фильмов, вышедших в 2020 году по длине их названий.
Используйте таблицу imdb.title_basics. Год выхода фильма - startYear, название - primaryTitle.
Не забудьте использовать с этими полями двойные кавычки. Нужно сгруппировать фильмы по длине названия и посчитать их.
Напиши количество фильмов, длина названия которых равна 10*/

SELECT DISTINCT -- надо избавляться от использования distinct
  character_length("primaryTitle") AS title_lenght
, count(tconst) OVER(PARTITION BY character_length("primaryTitle")) AS count_movies
FROM
  imdb.title_basics
WHERE
  "startYear" = 2020;


-- решение школы
SELECT
  length("primaryTitle") AS title_length
, count(tconst) AS movies
FROM
  imdb.title_basics
WHERE
  "startYear" = 2020
GROUP BY
  1
ORDER BY
  1;


TABLE imdb.title_basics LIMIT 10;



/*Давайте попробуем понять, какие части фильмов выходили за какими и проставить номер части, основываясь на названиях и датах выхода фильмов.
Для начала, определим какие фильмы мы будем рассматривать:
Найдите все фильмы, которые: в названии содержат двоеточие ":", не начинаются с двоеточия, не начинаются со знака решетки (#)
Потом с помощью strpos и substring, а также - row_number создайте запрос, который вернет такие поля:
tconst, primaryTitle, часть названия до двоеточия - main_title, часть названия после двоеточия без пробела в начале - secondary_title, startYear,
порядковый номер части с разбивкой по main_title и сортировкой по startYear и tconst - part_number
Какой номер части у фильма с tconst = tt2017085 ?*/

WITH distribution AS (
	SELECT
		tconst
	,	"primaryTitle"
	,	split_part("primaryTitle", ':', 1) AS main_title -- разделяет строку по символу ':' и выдаёт 1-ый элемент
	,	btrim(substring("primaryTitle", strpos("primaryTitle", ':') + 1)) AS secondary_title
	,	"startYear"
	,	row_number() OVER(PARTITION BY split_part("primaryTitle", ':', 1) ORDER BY "startYear", tconst) AS part_number
	FROM
		imdb.title_basics
	WHERE
		"primaryTitle" LIKE '%:%' AND
		"primaryTitle" NOT IN (':%', '#%')
)
SELECT
	*
FROM
	distribution
WHERE
	tconst = 'tt2017085';



-- решение школы
SELECT
	tconst
,	substring("primaryTitle", 0, position(':' IN "primaryTitle")) main_title
,	substring("primaryTitle", position(':' IN "primaryTitle") + 2) secondary_title
,	"primaryTitle"
,	"startYear"
,	row_number() OVER(PARTITION BY substring("primaryTitle", 0, position(':' IN "primaryTitle")) ORDER BY "startYear", tconst) part_number
FROM
	imdb.title_basics
WHERE
	"primaryTitle" LIKE '%:%' AND
	"primaryTitle" NOT LIKE ':%' AND
	"primaryTitle" NOT LIKE '#%'
ORDER BY
	main_title
,	"startYear"
,	tconst;


TABLE imdb.title_basics LIMIT 100;



/*Как бы мы написали запрос, который добавил бы в каждую строку для каждого ученика количество пройденных им уроков?*/

WITH basic_table AS ( -- создаем запрос с данными об уроках
	SELECT
		user_id
	,	id_class
	,	class_start_datetime
	FROM
		skyeng_db.classes
	WHERE
		class_type <> 'trial' AND
		class_status = 'success' AND
		user_id IN (455196710, 87589504)
)
, aggregates AS ( -- считаем количество уроков для каждого ученика
	SELECT
		user_id
	,	count(id_class) AS classes_count_total
	FROM
		basic_table
	GROUP BY
		user_id
)
SELECT
	basic_table.user_id
,	basic_table.id_class
,	basic_table.class_start_datetime
,	aggregates.classes_count_total
FROM
	basic_table
JOIN
	aggregates
		ON aggregates.user_id = basic_table.user_id
ORDER BY
	user_id
,	class_start_datetime;


-- тоже самое при помощи оконной функции
SELECT
	user_id
,	id_class
,	class_start_datetime
,	count(id_class) OVER(PARTITION BY user_id) AS classes_count_total
FROM
	skyeng_db.classes
WHERE
	class_type <> 'trial' AND
	class_status = 'success' AND
	user_id IN (455196710, 87589504);


/*А теперь попробуем создать поле с порядковым номером урока для каждого ученика.*/

WITH basic_table AS ( -- создаем запрос с данными об уроках
	SELECT
		user_id
	,	id_class
	,	class_start_datetime
	FROM
		skyeng_db.classes
	WHERE
		class_type <> 'trial' AND
		class_status = 'success' AND
		user_id IN (455196710, 87589504)
)
SELECT
	b1.user_id
,	b1.id_class
,	b1.class_start_datetime
,	count(b2.id_class) AS class_number -- можно (а если индекс то и нужно) вместо count(b2.id_class) -> count(b1.class_id)
FROM
	basic_table b1
LEFT JOIN
	basic_table b2
		ON b1.user_id = b2.user_id AND
		b2.class_start_datetime <= b1.class_start_datetime
GROUP BY
	b1.user_id
,	b1.id_class
,	b1.class_start_datetime
ORDER BY
	b1.user_id
,	b1.class_start_datetime;


-- тоже самое с помощью оконной функции, причем двумя способами
SELECT
	user_id
,	id_class
,	class_start_datetime
,	count(id_class) OVER(PARTITION BY user_id ORDER BY class_start_datetime ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS row_number_with_count
,	row_number() OVER(PARTITION BY user_id ORDER BY class_start_datetime) AS row_number_with_row_number
FROM
	skyeng_db.classes
WHERE
	class_type <> 'trial' AND
	class_status = 'success' AND
	user_id IN (455196710, 87589504);
      


	  

-- как посмотреть информацию по таблицам. Пример:
CREATE TABLE article (
    article_id bigserial PRIMARY KEY,
    article_name varchar(20) NOT NULL,
    article_desc TEXT NOT NULL,
    date_added timestamp DEFAULT NULL);


 SELECT
 	c.column_name
 ,	c.data_type
 FROM
 	information_schema.table_constraints tc
 JOIN
 	information_schema.constraint_column_usage ccu
 		USING(constraint_schema, constraint_name)
 JOIN
 	information_schema.columns c
 		ON c.table_schema = tc.constraint_schema AND
 		tc.table_name = c.table_name AND
 		ccu.column_name = c.column_name
 WHERE
 	constraint_type = 'PRIMARY KEY' AND
 	tc.table_name = 'article';
	

-- информацию по первичным ключам во всей БД
SELECT
	c.column_name
,	c.data_type
,	tc.table_name
FROM
	information_schema.table_constraints tc
JOIN
	information_schema.constraint_column_usage ccu
		USING(constraint_schema, constraint_name)
JOIN
	information_schema.columns c
		ON c.table_schema = tc.constraint_schema AND
		tc.table_name = c.table_name AND
		ccu.column_name = c.column_name
WHERE
	constraint_type = 'PRIMARY KEY';

