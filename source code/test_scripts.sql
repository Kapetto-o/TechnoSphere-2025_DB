use TechnoSphere_2025
go

set nocount on;

-- создаём основные категории, если их ещё нет
if not exists (select 1 from categories where category_name = 'стиральные машинки')
    insert into categories (category_name, description) values ('стиральные машинки', 'стиральные/встраиваемые/автоматические модели');

if not exists (select 1 from categories where category_name = 'холодильники')
    insert into categories (category_name, description) values ('холодильники', 'холодильники и морозильные камеры');

if not exists (select 1 from categories where category_name = 'телевизоры')
    insert into categories (category_name, description) values ('телевизоры', 'smart-tv, led, oled и т.д.');

if not exists (select 1 from categories where category_name = 'пылесосы')
    insert into categories (category_name, description) values ('пылесосы', 'роботы, вертикальные, циклонные');

if not exists (select 1 from categories where category_name = 'смартфоны')
    insert into categories (category_name, description) values ('смартфоны', 'мобильные устройства разных ценовых категорий');

-- подготовка таблиц-«семян» в tempdb
if object_id('tempdb..#brands') is not null drop table #brands;
create table #brands (category_id int, brand nvarchar(100));
insert into #brands values
(1, 'lg'), (1, 'samsung'), (1, 'bosch'), (1, 'haier'), (1, 'beko'),
(2, 'bosch'), (2, 'samsung'), (2, 'haier'), (2, 'lg'), (2, 'beko'),
(3, 'sony'), (3, 'samsung'), (3, 'lg'), (3, 'hisense'), (3, 'xiaomi'),
(4, 'dyson'), (4, 'philips'), (4, 'xiaomi'), (4, 'roborock'), (4, 'bosch'),
(5, 'samsung'), (5, 'xiaomi'), (5, 'apple'), (5, 'realme'), (5, 'oneplus'),
(5, 'huawei'), (5, 'motorola'), (5, 'nokia');

if object_id('tempdb..#models') is not null drop table #models;
create table #models (category_id int, model nvarchar(200));
insert into #models values
-- стиральные машины
(1, 'f12a8hds'), (1, 'ww60k4210'), (1, 'waw28590'), (1, 'wmf-7010'), (1, 'wiug24t'),
(1, 'eco-slim 7kg'), (1, 'inverter 9kg'),
-- холодильники
(2, 'kgn39vl35r'), (2, 'rb37j5000sa'), (2, 'c2f636cfx'), (2, 'gn-h702'), (2, 'rds-415'),
(2, 'double-door 420l'), (2, 'side-by-side 600l'),
-- телевизоры
(3, 'bravia 55x85j'), (3, 'qled q70b'), (3, 'oled c1'), (3, 'u7hq'), (3, 'mi tv q1'),
(3, 'oled 65 4k'), (3, 'led 43 smart'),
-- пылесосы
(4, 'v15 detect'), (4, 'fc9558'), (4, 'dreame l10s'), (4, 's7 maxv'), (4, 'bg-625'),
(4, 'robot 2-in-1'),
-- смартфоны
(5, 'galaxy s22'), (5, 'iphone 14'), (5, 'redmi note 12'), (5, 'realme gt neo3'), (5, 'oneplus 10t'),
(5, 'p50 pro'), (5, 'nord 3');
go

-- генерация 120000 товаров
;with nums as (
    select 1 as n
    union all
    select n + 1 from nums where n < 120000
)
insert into products (category_id, name, brand, price, description, is_available, created_at)
select
    cat.category_id,
    -- читаемое имя: префикс + бренд + модель + индекс
    concat(
        case cat.category_id
            when 1 then 'стиральная машина '
            when 2 then 'холодильник '
            when 3 then 'телевизор '
            when 4 then 'пылесос '
            when 5 then 'смартфон '
            else 'товар '
        end,
        b.brand, ' ', m.model, ' ', cast(n as nvarchar(20))
    ) as name,
    b.brand,
    -- цена
    cast(
        case cat.category_id
            when 1 then 30000 + (abs(checksum(newid())) % 70000) * 1.0 / 100 -- 300..999
            when 2 then 40000 + (abs(checksum(newid())) % 160000) * 1.0 / 100 -- 400..2000
            when 3 then 15000 + (abs(checksum(newid())) % 600000) * 1.0 / 100 -- 150..7500
            when 4 then 2000 + (abs(checksum(newid())) % 80000) * 1.0 / 100 -- 20..1000
            when 5 then 10000 + (abs(checksum(newid())) % 900000) * 1.0 / 100 -- 100..10000
            else 1000 + (abs(checksum(newid())) % 100000) * 1.0 / 100
        end
    as decimal(12,2)) as price,
    -- описание
    concat('модель ', m.model, ' от производителя ', b.brand, '. автоматически сгенерирован для нагрузочного тестирования №', n, 
           '. характеристики примерные, цена указана для тестирования фильтров и сортировок.') as description,
    -- доступность: ~90% в наличии
    case when abs(checksum(newid())) % 10 = 0 then 0 else 1 end as is_available,
    -- дата добавления: в пределах последних 2 лет
    dateadd(day, - (abs(checksum(newid())) % 730), sysdatetime()) as created_at
from nums
cross apply (
    -- случайный бренд/категория из #brands
    select top 1 * from #brands order by newid()
) b
cross apply (
    -- случайная модель, но подберём модель из той же категории, если есть - иначе любая
    select top 1 * from #models where category_id = b.category_id order by newid()
) m
cross apply (
    -- соответствующая категория
    select top 1 category_id from #brands where brand = b.brand
) cat
option (maxrecursion 0);
go

-- быстрое подтверждение количества добавленных записей
select count(*) as total_products from products;
go