/* Задание 1
Получить список платформ, у которых больше 10 различных игр и общих продаж на сумму больше 50 млн долл
и на которых есть выбор шутеров, выпущенные не раньше 01.01.2010.
Важно, чтобы в отчет попала информация о производителях игр.
Увидеть среднюю выручку на одну игру и среднюю выручку на одного производителя.
Результаты в отчете нужно отсортировать по общему объему всех продаж в мире на каждой платформе
*/

 select sum(global_sales) as total_sales,
       platform_name as games,
       count(distinct publisher) as publishers,
       avg(global_sales) as global_sales_per_game,
       sum(global_sales) / count(distinct publisher) as sales_per_publisher
  from game_db
 where genre ~* 'shooter' and
       sales_start >= '2010-01-01' and
       publisher is not null
 group by platform_name
having count(distinct name) > 10 and
       sum(global_sales) > 50
 order by sum(global_sales) desc, platform_name;


/*Задание 2
Какое количество игр выпущено в каждом жанре? Информация по экшен-играм и шутерам, а также по ролевым и приключенческим играм.
Платформеры и пазлы можно отнести к категории «другое» и считать вместе.
Жанры определите самостоятельно, уделив некоторое время изучению таблиц баз данных. 
Выведите под каждый жанр отдельный столбец, а затем в той же таблице общее количество игр,
а дальше — доли каждого жанра в общем количестве игр, тоже отдельными столбцами.
*/

 SELECT
    count('выводим количество жанров 1') FILTER (WHERE genre = 'Action' OR genre = 'Shooter') as "Action+Shooter",
    count('выводим количество жанров 2') FILTER (WHERE genre = 'Rore-Playing' OR genre = 'Adventure') as "Rore-Playing+Adventure",
    count('выводим количество жанров 3') FILTER (WHERE genre not in ('Rore-Playing', 'Adventure', 'Action', 'Shooter')) as "Other",
    count('выводим долю 1 от Total_games') FILTER (WHERE genre = 'Action' OR genre = 'Shooter') / count(name)::numeric as "part1",
    count('выводим долю 2 от Total_games') FILTER (WHERE genre = 'Rore-Playing' OR genre = 'Adventure') / count(name)::numeric as "part2",
    count('выводим долю 3 от Total_games') FILTER (WHERE genre not in ('Rore-Playing', 'Adventure', 'Action', 'Shooter')) / count(name)::numeric as "part3",
    count(name) as "Total_games"
FROM game_db g;