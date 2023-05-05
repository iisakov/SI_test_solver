--history
--issue_key – уникальный ключ задачи
--status – статус задачи
--minutes_in_status – количество минут, которое задача находилась в статусе
--previous_status – предыдущий статус задачи
--started_at – время создания статуса задачи, unix миллисекунды 
--ended_at – время перехода задачи в другой статус, unix миллисекунды 

--SQL 1
--Напишите запрос, который выведет, сколько времени в среднем задачи каждой группы находятся в статусе “Open” 
--Условия:
--Под группой подразумевается первый символ в ключе задачи. Например, для ключа “C-40460” группой будет “C”
--Задача может переходить в один и тот же статус несколько раз.
--Переведите время в часы с округлением до двух знаков после запятой.

-- Класическое решение
SELECT
	substr(issue_key,0,instr(issue_key, '-')),
	round(sum(h.minutes_in_status)/60.00, 2)
FROM  history h
group by substr(issue_key,0,instr(issue_key, '-'))


--SQL 2 
--Напишите запрос, который выведет ключ задачи, последний статус и его время создания для задач, которые открыты на данный момент времени.
--Условия:
--Открытыми считаются задачи, у которых последний статус в момент времени не “Closed” и не “Resolved”
--Задача может переходить в один и тот же статус несколько раз.
--Оформите запрос таким образом, чтобы, изменив дату, его можно было использовать для поиска открытых задач в любой момент времени в прошлом
--Переведите время в текстовое представление

-- Классическое решение
WITH c_date as (
	select DATETIME('2020-10-10') cd -- Изменение даты ищет открытые задачи на дату
)
select
	t.issue_key,
	min_started_at "min",
	h2.status 
from (
SELECT 
	h.issue_key,
	max(DATETIME(h.started_at/1000, 'unixepoch')) max_started_at,
	min(DATETIME(h.started_at/1000, 'unixepoch')) min_started_at
FROM history h 
where DATETIME(h.started_at/1000, 'unixepoch') <= (select cd from c_date)
group by issue_key
HAVING 
	(GROUP_concat(status) not like '%Closed%' and GROUP_concat(status) not like '%Resolved%') 
and max(DATETIME(h.started_at/1000, 'unixepoch')) <= (select cd from c_date)
) t
LEFT join history h2 on DATETIME(h2.started_at/1000, 'unixepoch') = max_started_at;


-- Решение с сторонними библиотеками
select load_extension('/home/iisakov/Загрузки/sqlean/regexp.so');
select load_extension('/home/iisakov/Загрузки/sqlean/define.so');
select define('normalize_date', 'DATETIME(?/1000, ''unixepoch'')');
WITH c_date as (
	select DATETIME('2020-10-10') cd -- Изменение даты ищет открытые задачи на дату
)
select
	t.issue_key,
	min_started_at "min",
	h2.status 
from (
SELECT 
	h.issue_key,
	max(normalize_date(h.started_at)) max_started_at,
	min(normalize_date(h.started_at)) min_started_at
FROM history h 
where normalize_date(h.started_at) <= (select cd from c_date)
group by issue_key
HAVING 
	(GROUP_concat(status) not REGEXP 'Closed|Resolved') 
and max(normalize_date(h.started_at)) <= (select cd from c_date)
) t
LEFT join history h2 on normalize_date(h2.started_at) = max_started_at;
select define_free();
