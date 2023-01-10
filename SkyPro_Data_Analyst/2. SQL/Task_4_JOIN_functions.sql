/* Задание 1
Нужен топ-10 картин 2020 года с самым высоким рейтингом в порядке убывания.
Пожалуйста, ограничьте выбор фильмов количеством 100 000 оценок.
Фильмы, количество оценок по которым менее 100 000, нам не интересны, так как рейтинг может быть завышен
из-за небольшого количества проголосовавших.
*/

SELECT
	tb."originalTitle"
,	r."averageRating"
FROM
	imdb.title_basics tb
JOIN
	imdb.title_ratings r
		USING(tconst)
WHERE
	tb."startYear" = 2020 AND
	r."numVotes" > 100000 AND
	tb."titleType" = 'movie'
ORDER BY
	r."averageRating" DESC
LIMIT 10;



/* Задание 2
Было бы круто отметить 10 лучших режиссеров фильмов и сериалов (movie и tvSeries) 2020 года, у которых самый высокий средний рейтинг.
Если у режиссера выходило два фильма в 2020 году, нам нужна одна цифра — средний рейтинг по обоим фильмам. Давайте выведем данные в порядке убывания.
Условия задачи 1 (например, количество оценок) тоже учитываются!
*/

SELECT
	nb."primaryName"
,	avg(r."averageRating")
FROM
	imdb.title_basics b
JOIN
	imdb.title_ratings r
		ON r.tconst = b.tconst AND
		r."numVotes" > 100000
JOIN
	imdb.title_crew_long cl
		ON cl.tconst = r.tconst
LEFT JOIN
	imdb.name_basics nb
		ON nb.nconst = cl.directors
WHERE
	b."startYear" = 2020 AND
	b."titleType" IN ('movie', 'tvSeries')
GROUP BY
	nb."primaryName"
ORDER BY
	avg(r."averageRating") DESC
LIMIT 10;



/* Задание 3
Еще было бы интересно посмотреть, как просела киноиндустрия в 2020 году. Предоставьте в абсолютных цифрах количество выпущенных фильмов,
начиная с 2015 года по 2020 год включительно. Сделайте разбивку данных по годам.
*/

SELECT
	b."startYear"
,	count(b.tconst)
FROM
	imdb.title_basics b
WHERE
	b."titleType" = 'movie' AND
	b."startYear" BETWEEN 2015 AND 2020
GROUP BY
	b."startYear";



/* Задание 4
Со мной поделились списками режиссеров, которые выпускали фильмы в 2018–2020 годах. Список режиссеров, выпускавших фильмы в 2018 году,
хранится в таблице imdb.directors_2018, в 2019 — imdb.directors_2019, в 2020 — imdb.directors_2020.
Было бы интересно посмотреть долю тех, кто режиссировал в 2018 году и продолжил режиссировать в 2019 году.
То есть если в 2018 году фильмы выпускали 10 человек и из их числа в 2019 году продолжило работать 3, то доля перетекания из 2018 в 2019 будет равна 30%.
Вот такой процент мне нужен относительно 2018/2019 и 2019/2020. Посмотрим, как поменялась эта доля. Думаю, в 2019/2020 она должна упасть.
Будет круто, если проверим.
*/


SELECT
     (
     SELECT
          count(d2.directors) / count(d1.directors)::numeric * 100
     FROM
          imdb.directors_2018 d1
     LEFT JOIN
          imdb.directors_2019 d2
               ON d2.directors = d1.directors
     ) "2019/2018"
,    (
     SELECT
          count(d3.directors) / count(d2.directors)::numeric * 100
     FROM
          imdb.directors_2019 d2
     LEFT JOIN
          imdb.directors_2020 d3
               ON d3.directors = d2.directors
     ) "2020/2019";