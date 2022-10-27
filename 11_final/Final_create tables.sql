--задать схему для работы
SET search_path TO bookings;


--удаление таблиц
drop table if exists fact_flights;
drop table if exists rej_flights;
DROP TABLE IF EXISTS dim_calendar;
drop table if exists dim_airports;
drop table if exists rej_airports;
drop table if exists dim_aircrafts;
drop table if exists rej_aircrafts;
drop table if exists dim_tariff;
drop table if exists rej_ticket_flights;
drop table if exists dim_passengers;
drop table if exists rej_tickets;


-- создание таблицы измерений - дата (как в лекции)
CREATE TABLE dim_calendar
AS
WITH dates AS (
    SELECT dd::date AS dt
    FROM generate_series
            ('2010-01-01'::timestamp
            , '2030-01-01'::timestamp
            , '1 day'::interval) dd
)
SELECT
    to_char(dt, 'YYYYMMDD')::int AS id,
    dt AS date,
    to_char(dt, 'YYYY-MM-DD') AS ansi_date,
    date_part('isodow', dt)::int AS day,
    date_part('week', dt)::int AS week_number,
    date_part('month', dt)::int AS month,
    date_part('isoyear', dt)::int AS year,
    (date_part('isodow', dt)::smallint BETWEEN 1 AND 5)::int AS week_day,
    (to_char(dt, 'YYYYMMDD')::int IN (
        20130101,
        20130102,
        20130103,
        20130104,
        20130105,
        20130106,
        20130107,
        20130108,
        20130223,
        20130308,
        20130310,
        20130501,
        20130502,
        20130503,
        20130509,
        20130510,
        20130612,
        20131104,
        20140101,
        20140102,
        20140103,
        20140104,
        20140105,
        20140106,
        20140107,
        20140108,
        20140223,
        20140308,
        20140310,
        20140501,
        20140502,
        20140509,
        20140612,
        20140613,
        20141103,
        20141104,
        20150101,
        20150102,
        20150103,
        20150104,
        20150105,
        20150106,
        20150107,
        20150108,
        20150109,
        20150223,
        20150308,
        20150309,
        20150501,
        20150504,
        20150509,
        20150511,
        20150612,
        20151104,
        20160101,
        20160102,
        20160103,
        20160104,
        20160105,
        20160106,
        20160107,
        20160108,
        20160222,
        20160223,
        20160307,
        20160308,
        20160501,
        20160502,
        20160503,
        20160509,
        20160612,
        20160613,
        20161104,
        20170101,
        20170102,
        20170103,
        20170104,
        20170105,
        20170106,
        20170107,
        20170108,
        20170223,
        20170224,
        20170308,
        20170501,
        20170508,
        20170509,
        20170612,
        20171104,
        20171106,
        20180101,
        20180102,
        20180103,
        20180104,
        20180105,
        20180106,
        20180107,
        20180108,
        20180223,
        20180308,
        20180309,
        20180430,
        20180501,
        20180502,
        20180509,
        20180611,
        20180612,
        20181104,
        20181105,
        20181231,
        20190101,
        20190102,
        20190103,
        20190104,
        20190105,
        20190106,
        20190107,
        20190108,
        20190223,
        20190308,
        20190501,
        20190502,
        20190503,
        20190509,
        20190510,
        20190612,
        20191104,
        20200101, 20200102, 20200103, 20200106, 20200107, 20200108,
       20200224, 20200309, 20200501, 20200504, 20200505, 20200511,
       20200612, 20201104))::int AS holiday
FROM dates
ORDER BY dt;

ALTER TABLE dim_calendar ADD PRIMARY KEY (id);


-- создание таблицы измерений - аэропорты
create table if not exists dim_airports (
    id serial not null primary key,
    airport_code char(3),
    airport_name varchar(100),
    city varchar(100),
    longitude double precision,
    latitude double precision,
    timezone varchar(50)
);
create table if not exists rej_airports (
    airport_code char(3),
    airport_name varchar(100),
    city varchar(100),
    longitude double precision,
    latitude double precision,
    timezone varchar(50),
    date_added timestamp default CURRENT_TIMESTAMP
);


-- создание таблицы измерений - самолеты
create table if not exists dim_aircrafts (
    id serial not null primary key,
    aircraft_code char(3),
    model varchar(100),
    range integer
);
create table if not exists rej_aircrafts (
    aircraft_code char(3),
    model varchar(100),
    range integer,
    error varchar(100),
    date_added timestamp default CURRENT_TIMESTAMP
);


-- создание таблицы измерений - тарифы
create table if not exists dim_tariff (
    id serial not null primary key,
    tariff varchar(100) unique
);
create table if not exists rej_ticket_flights
(
    ticket_no char(13),
    flight_id integer,
    fare_conditions varchar(10),
    amount numeric(10, 2),
    error varchar(100),
    date_added timestamp default CURRENT_TIMESTAMP
);


-- создание таблицы измерений - пассажиры
create table if not exists dim_passengers (
    id serial not null primary key,
    passenger_code varchar(20),
    name varchar(100),
    contact_data jsonb
);
create table if not exists rej_tickets
(
    ticket_no char(13),
    book_ref char(6),
    passenger_id varchar(20),
    passenger_name text,
    contact_data jsonb,
    error varchar(100),
    date_added timestamp default CURRENT_TIMESTAMP
);


--создание таблицы фактов - перелеты
create table if not exists fact_flights (
    passenger int not null references dim_passengers(id),
    departure_date int not null references dim_calendar(id),
    departure_time time,
    arrival_date int not null references dim_calendar(id),
    arrival_time time,
    departure_delay bigint,
    arrival_delay bigint,
    aircraft_code int not null references dim_aircrafts(id),
    departure_airport int not null references dim_airports(id),
    arrival_airport int not null references dim_airports(id),
    tariff int not null references dim_tariff(id),
    cost float4
);
create table if not exists rej_flights
(
    flight_id           integer,
    flight_no           char(6),
    scheduled_departure timestamp with time zone,
    scheduled_arrival   timestamp with time zone,
    departure_airport   char(3),
    arrival_airport     char(3),
    status              varchar(20),
    aircraft_code       char(3),
    actual_departure    timestamp with time zone,
    actual_arrival      timestamp with time zone,
    error varchar(100),
    date_added timestamp default CURRENT_TIMESTAMP
);