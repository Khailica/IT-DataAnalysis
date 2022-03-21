/* Задание 3
Нам нужны все столбцы из базы данных Netflix, которые попадают под условия:
- тип: фильм (Movie);
- режиссер: 5 режиссеров фильмов, указанных в списке «КиноПоиска»;
- год: не слишком старые фильмы и сериалы — это фильмы и сериалы, вышедшие не раньше 2010 года.
Важно: имена режиссеров нужно писать на английском, ведь это база Netflix. В нашей базе режиссер «Паразитов» записан как Bong Joon Ho, что незначительно отличается от версии IMDb.
*/

select  *
  from  netflix
 where  type = 'Movie'
        and director in ('Bong Joon Ho', 'Sam Mendes', 'Todd Phillips', 'Quentin Tarantino', 'Martin Scorsese')
        and release_year >= 2010;




/* Задание 4
Проверить, есть ли у Netflix фильмы, за игру в которых актеры получили «Оскар» в 2020 году.
Передать маркетологам всю имеющуюся информацию об этих фильмах.
Имена актеров и названия фильмов можно посмотреть по этой ссылке. В БД нужно проверить только наличие нужного сочетания.
*/

select  *
  from  netflix
 where  type = 'Movie'
        and (cast_names like '%Joaquin Phoenix%'
            or cast_names like '%Renée Zellweger%'
            or cast_names like '%Brad Pitt%'
            or cast_names like '%Laura Dern%');