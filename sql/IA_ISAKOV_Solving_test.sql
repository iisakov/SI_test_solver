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

with t as (
SELECT 
	issue_key,
	sum(minutes_in_status) sum_minutes_in_status
FROM history h
where status = 'Open'
group by issue_key
)
select 
	substr(issue_key,0,instr(issue_key, '-')) 'Группа',
	round(avg(t.sum_minutes_in_status)/60.00, 2) 'Среднее время задачи в статутсе Open'
from t
group by substr(issue_key,0,instr(issue_key, '-'))

--SQL 2 
--Напишите запрос, который выведет ключ задачи, последний статус и его время создания для задач, которые открыты на данный момент времени.
--Условия:
--Открытыми считаются задачи, у которых последний статус в момент времени не “Closed” и не “Resolved”
--Задача может переходить в один и тот же статус несколько раз.
--Оформите запрос таким образом, чтобы, изменив дату, его можно было использовать для поиска открытых задач в любой момент времени в прошлом
--Переведите время в текстовое представление

with t as (
select 
	issue_key,
	status,
	DATETIME(started_at/1000, 'unixepoch') normal_started_at,
	row_number() over(partition by issue_key order by started_at desc) num
from history h
where DATETIME(started_at/1000, 'unixepoch') <= DATETIME('2022-08-22 12:13:58') -- <- Изменяя дату, можно менять в прошлом.
order by started_at
)
select 
	issue_key,
	status,
	normal_started_at
from t
where num = 1 and (status not in ('Closed', 'Resolved'))
order by normal_started_at
