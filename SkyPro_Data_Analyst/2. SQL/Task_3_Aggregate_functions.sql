/* Задание 1
Получить список платформ, у которых больше 10 различных игр и общих продаж на сумму больше 50 млн долл
и на которых есть выбор шутеров, выпущенные не раньше 01.01.2010.
Важно, чтобы в отчет попала информация о производителях игр.
Увидеть среднюю выручку на одну игру и среднюю выручку на одного производителя.
Результаты в отчете нужно отсортировать по общему объему всех продаж в мире на каждой платформе
*/

SELECT
	sum(global_sales) AS total_sales
,	platform_name games
,	count(DISTINCT publisher) AS publishers
,	avg(global_sales) AS global_sales_per_game
,	sum(global_sales) / count(DISTINCT publisher) AS sales_per_publisher
FROM
	game_db
WHERE
	genre ~* 'shooter' AND
	sales_start >= '2010-01-01' AND
	publisher IS NOT NULL
GROUP BY
	platform_name
HAVING
	count(DISTINCT name) > 10 AND
	sum(global_sales) > 50
ORDER BY
	sum(global_sales) DESC
,	platform_name;


/*Задание 2
Какое количество игр выпущено в каждом жанре? Информация по экшен-играм и шутерам, а также по ролевым и приключенческим играм.
Платформеры и пазлы можно отнести к категории «другое» и считать вместе.
Жанры определите самостоятельно, уделив некоторое время изучению таблиц баз данных. 
Выведите под каждый жанр отдельный столбец, а затем в той же таблице общее количество игр,
а дальше — доли каждого жанра в общем количестве игр, тоже отдельными столбцами.
*/

SELECT
	count('выводим количество жанров 1') FILTER(WHERE genre = 'Action' OR genre = 'Shooter') AS "Action+Shooter"
,	count('выводим количество жанров 2') FILTER(WHERE genre = 'Rore-Playing' OR genre = 'Adventure') AS "Rore-Playing+Adventure"
,	count('выводим количество жанров 3') FILTER(WHERE genre NOT IN ('Rore-Playing', 'Adventure', 'Action', 'Shooter')) AS "Other"
,	count('выводим долю 1 от Total_games') FILTER(WHERE genre = 'Action' OR genre = 'Shooter') / count(name)::numeric AS part1
,	count('выводим долю 2 от Total_games') FILTER(WHERE genre = 'Rore-Playing' OR genre = 'Adventure') / count(name)::numeric AS part2
,	count('выводим долю 3 от Total_games') FILTER(WHERE genre NOT IN ('Rore-Playing', 'Adventure', 'Action', 'Shooter')) / count(name)::numeric AS part3
,	count(name) AS "Total_games"
FROM
	game_db g;