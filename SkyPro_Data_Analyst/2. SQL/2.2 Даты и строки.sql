


=========== тип данных Дата =========

-- явное ппеобразование типов
select '2012-08-31 01:00:00'::timestamp;
select cast('2012-08-31 01:00:00' as timestamp);

-- генерация последовательности дней
select GENERATE_SERIES('2012-10-01'::date, '2012-10-31', '1 day')

-- возвращает день в месяце
select extract(day from timestamp '2012-08-31')

-- subtracting
SELECT timestamp '2012-09-02 00:00:00' - timestamp '2012-08-31 01:00:00'; -- 1 day 23:00:00

-- выводит поле интервала по дню
SELECT date_part ('day', timestamp '2012-09-02 00:00:00' - timestamp '2012-08-31 01:00:00'); -- 1.0

-- или в стандартном исполнении
SELECT CAST ('2012-09-02 00:00:00' AS timestamp) - CAST ('2012-08-31 01:00:00' AS timestamp); -- 1 day 23:00:00

-- неявное преобразование типов
SELECT age('2012-09-02 00:00:00', '2012-08-31 01:00:00'); -- 1 day 23:00:00

-- epoch — общее количество секунд в интервале для значений interval 
SELECT EXTRACT(epoch FROM age('2012-09-02 00:00:00', '2012-08-31 01:00:00')); 


/*
 * timestamp - timestamp → interval
 * timestamp - interval → timestamp
 * 
 * date_part ( text, timestamp ) → double precision
 * date_part ( text, interval ) → double precision
 * 
 * date_trunc ( text, timestamp ) → timestamp
 * date_trunc ( text, interval ) → interval
 * 
 * extract ( field from timestamp ) → numeric
 * extract ( field from interval ) → numeric
 */

SELECT pg_typeof(timestamp '2012-12-01' + INTERVAL '1 month'); -- timestamp without time zone
SELECT pg_typeof((timestamp '2012-12-01' + INTERVAL '1 month') - timestamp '2012-12-01'); -- INTERVAL


-- количество дней в месяце
SELECT EXTRACT (MONTH FROM
	   					generate_series('2012-01-01'::timestamp, '2012-12-01'::timestamp , '1 month')
	   					+ '1 month'::INTERVAL - '1 day'::INTERVAL
	  		   ) AS month,
	   EXTRACT ( DAY FROM 
	   					generate_series('2012-01-01', '2012-12-01' , INTERVAL '1 month')
	   					+ INTERVAL '1 month' - INTERVAL '1 day' -- тип резльтата NUMERIC
	  		    ) AS lenght;
	  		   	  		  	  		   

-- 2 вариант и на выходе другой тип второго атрибута
select 	extract(month from cal.month) as month,
	(cal.month + interval '1 month') - cal.month as length -- тип INTERVAL
	from
	(
		select generate_series(timestamp '2012-01-01', timestamp '2012-12-01', interval '1 month') as month
	) cal
order by month;


-- количество оставшихся дней в месяце
-- date_trunc('month') округлить до месяца + 1 месяц - заданную дату = interval
SELECT date_trunc ( 'month', timestamp '2012-02-11') + INTERVAL '1 month' - timestamp '2012-02-11'

-- 2 способ
select (date_trunc('month',ts.testts) + interval '1 month') 
		- date_trunc('day', ts.testts) as remaining
	from (select timestamp '2012-02-11 01:00:00' as testts) t
	
	
	
================== тип данных Строка ====================

-- найти вхождение символов ( и )
select memid, telephone from cd.members where telephone ~ '[()]'; -- любой символ внутри скобок []
select memid, telephone from cd.members where telephone similar to '%[()]%';

