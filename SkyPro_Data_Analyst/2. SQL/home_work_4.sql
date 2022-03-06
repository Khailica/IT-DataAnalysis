/* Задание 1
Нужен топ-10 картин 2020 года с самым высоким рейтингом в порядке убывания.
Пожалуйста, ограничьте выбор фильмов количеством 100 000 оценок.
Фильмы, количество оценок по которым менее 100 000, нам не интересны, так как рейтинг может быть завышен
из-за небольшого количества проголосовавших.
*/

select tb."originalTitle", r."averageRating"
  from imdb.title_basics tb
       join imdb.title_ratings r using(tconst)
 where tb."startYear" = 2020 and
       r."numVotes" > 100000 and
       tb."titleType" = 'movie'
 order by r."averageRating" desc 
 limit 10;


/* Задание 2
Было бы круто отметить 10 лучших режиссеров фильмов и сериалов (movie и tvSeries) 2020 года, у которых самый высокий средний рейтинг.
Если у режиссера выходило два фильма в 2020 году, нам нужна одна цифра — средний рейтинг по обоим фильмам. Давайте выведем данные в порядке убывания.
Условия задачи 1 (например, количество оценок) тоже учитываются!
*/

select nb."primaryName", avg(r."averageRating")
from imdb.title_basics b
 join imdb.title_ratings r on r.tconst = b.tconst and
     r."numVotes" > 100000
 join imdb.title_crew_long cl on cl.tconst = r.tconst
 left join imdb.name_basics nb on nb.nconst = cl.directors  -- взял left join, т.к. не уверен в таблице name_basics, вдруг там нет точного соответствия
where b."startYear" = 2020 and
    b."titleType" in ('movie', 'tvSeries')
group by nb."primaryName"
order by avg(r."averageRating") desc
limit 10;


/* Задание 3
Еще было бы интересно посмотреть, как просела киноиндустрия в 2020 году. Предоставьте в абсолютных цифрах количество выпущенных фильмов,
начиная с 2015 года по 2020 год включительно. Сделайте разбивку данных по годам.
*/

select b."startYear", count(b.tconst)
from imdb.title_basics b
where b."titleType" = 'movie' and 
    b."startYear" between 2015 and 2020
group by b."startYear";


/* Задание 4
Со мной поделились списками режиссеров, которые выпускали фильмы в 2018–2020 годах. Список режиссеров, выпускавших фильмы в 2018 году,
хранится в таблице imdb.directors_2018, в 2019 — imdb.directors_2019, в 2020 — imdb.directors_2020.
Было бы интересно посмотреть долю тех, кто режиссировал в 2018 году и продолжил режиссировать в 2019 году.
То есть если в 2018 году фильмы выпускали 10 человек и из их числа в 2019 году продолжило работать 3, то доля перетекания из 2018 в 2019 будет равна 30%.
Вот такой процент мне нужен относительно 2018/2019 и 2019/2020. Посмотрим, как поменялась эта доля. Думаю, в 2019/2020 она должна упасть.
Будет круто, если проверим.
*/

select  (select (count(d2.directors) / count(d1.directors)::numeric * 100)
          from imdb.directors_2018 d1
               left join imdb.directors_2019 d2 on d2.directors = d1.directors) as "2019/2018",
        (select (count(d3.directors) / count(d2.directors)::numeric * 100)
           from imdb.directors_2019 d2
                left join imdb.directors_2020 d3 on d3.directors = d2.directors) as "2020/2019";