/* Задание 5.1
Сравните средние цены в трех городах на отдельные комнаты (Private room), которые сдаются минимум на 30 суток.
*/

	SELECT
		'Dallas' "CITY"
	,	avg(price) "AVG"
	FROM
		airbnb_dallas.listings
	WHERE
		room_type = 'Private room' AND
		minimum_nights >= 30
UNION
	SELECT
		'New-York'
	,	avg(price)
	FROM
		airbnb_new_york.listings
	WHERE
		room_type = 'Private room' AND
		minimum_nights >= 30
UNION
	SELECT
		'Oakland'
	,	avg(price)
	FROM
		airbnb_oakland.listings
	WHERE
		room_type = 'Private room' AND
		minimum_nights >= 30;


		
/* Задание 5.2
Сравните средние предложенные сервисом цены (adjusted_price) на Entire home/apt за три месяца весны 2021 года в Далласе, Нью-Йорке и Окленде.
*/

     SELECT
          'Dallas' "City"
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 3) "Март"
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 4) "Апрель"
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 5) "Май"
     FROM
          airbnb_dallas.listings l
     JOIN
          airbnb_dallas.calendar c
               ON c.listing_id = l.id AND
               room_type = 'Entire home/apt'
UNION
     SELECT
          'Oakland'
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 3)
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 4)
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 5)
     FROM
          airbnb_oakland.listings l
     JOIN
          airbnb_oakland.calendar c
               ON c.listing_id = l.id AND
               room_type = 'Entire home/apt'
UNION
     SELECT
          'New-York'
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 3)
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 4)
     ,    avg(replace(replace(c.adjusted_price, '$', ''), ',', '')::double precision) FILTER(WHERE date_part('month', c.date) = 5)
     FROM
          airbnb_new_york.listings l
     JOIN
          airbnb_new_york.calendar c
               ON c.listing_id = l.id AND
               room_type = 'Entire home/apt';

          

          
/* Задание 5.3
Найдите цену самого дорогого объекта для сдачи у продавца, у которого был просмотр объявления апартаментов из Бруклина (Нью-Йорк) 1 апреля 2020 года.
Нужно вывести ID продавца, имя и цену объекта. Объект может находиться в любом районе Нью-Йорка.
*/

          
-- 1 вариант:
SELECT
     host_id
,    name
,    max(price)
FROM
     airbnb_new_york.listings
GROUP BY
     host_id
,    name
HAVING
     host_id IN (
          SELECT
               l.host_id
          FROM
               airbnb_new_york.listings l
          JOIN
               airbnb_new_york.reviews r
                    ON r.listing_id = l.id AND
                    r.date = '2020-04-01'
          JOIN
               airbnb_new_york.neighbourhoods n
                    ON n.neighbourhood = l.neighbourhood AND
                    n.neighbourhood_group = 'Brooklyn'
     )
ORDER BY
     max(price) DESC
LIMIT 1;



-- 2 вариант:
SELECT
     l2.host_id
,    l2.name
,    max(l2.price)
FROM
     airbnb_new_york.listings l1
JOIN
     airbnb_new_york.reviews r
          ON r.listing_id = l1.id AND
          r.date = '2020-04-01'
JOIN
     airbnb_new_york.neighbourhoods n
          ON n.neighbourhood = l1.neighbourhood AND
          n.neighbourhood_group = 'Brooklyn'
JOIN
     airbnb_new_york.listings l2
          ON l2.host_id = l1.host_id
GROUP BY
     l2.host_id
,    l2.name
ORDER BY
     max(l2.price) DESC
LIMIT 1;