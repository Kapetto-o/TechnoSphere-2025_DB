use TechnoSphere_2025_DB;
go

set nocount on;

-- 1. категории (без жёстких id)
if not exists (select 1 from dbo.categories where category_name = 'стиральные машинки')
    insert into dbo.categories (category_name, description)
    values ('стиральные машинки', 'стиральные/встраиваемые/автоматические модели');

if not exists (select 1 from dbo.categories where category_name = 'холодильники')
    insert into dbo.categories (category_name, description)
    values ('холодильники', 'холодильники и морозильные камеры');

if not exists (select 1 from dbo.categories where category_name = 'телевизоры')
    insert into dbo.categories (category_name, description)
    values ('телевизоры', 'smart-tv, led, oled и т.д.');

if not exists (select 1 from dbo.categories where category_name = 'пылесосы')
    insert into dbo.categories (category_name, description)
    values ('пылесосы', 'роботы, вертикальные, циклонные');

if not exists (select 1 from dbo.categories where category_name = 'смартфоны')
    insert into dbo.categories (category_name, description)
    values ('смартфоны', 'мобильные устройства разных ценовых категорий');

-- 2. временные таблицы брендов и моделей
if object_id('tempdb..#brands') is not null drop table #brands;
create table #brands (
    category_name nvarchar(150),
    brand nvarchar(100)
);

insert into #brands values
('стиральные машинки', 'lg'), ('стиральные машинки', 'samsung'), ('стиральные машинки', 'bosch'),
('стиральные машинки', 'haier'), ('стиральные машинки', 'beko'),

('холодильники', 'bosch'), ('холодильники', 'samsung'), ('холодильники', 'haier'),
('холодильники', 'lg'), ('холодильники', 'beko'),

('телевизоры', 'sony'), ('телевизоры', 'samsung'), ('телевизоры', 'lg'),
('телевизоры', 'hisense'), ('телевизоры', 'xiaomi'),

('пылесосы', 'dyson'), ('пылесосы', 'philips'), ('пылесосы', 'xiaomi'),
('пылесосы', 'roborock'), ('пылесосы', 'bosch'),

('смартфоны', 'samsung'), ('смартфоны', 'xiaomi'), ('смартфоны', 'apple'),
('смартфоны', 'realme'), ('смартфоны', 'oneplus'),
('смартфоны', 'huawei'), ('смартфоны', 'motorola'), ('смартфоны', 'nokia');

-------------------------------------------------

if object_id('tempdb..#models') is not null drop table #models;
create table #models (
    category_name nvarchar(150),
    model nvarchar(200)
);

insert into #models values
('стиральные машинки', 'f12a8hds'), ('стиральные машинки', 'ww60k4210'),
('стиральные машинки', 'waw28590'), ('стиральные машинки', 'eco-slim 7kg'),

('холодильники', 'kgn39vl35r'), ('холодильники', 'rb37j5000sa'),
('холодильники', 'side-by-side 600l'),

('телевизоры', 'bravia 55x85j'), ('телевизоры', 'oled c1'),
('телевизоры', 'qled q70b'),

('пылесосы', 'v15 detect'), ('пылесосы', 's7 maxv'),
('пылесосы', 'robot 2-in-1'),

('смартфоны', 'galaxy s22'), ('смартфоны', 'iphone 14'),
('смартфоны', 'redmi note 12'), ('смартфоны', 'oneplus 10t');


-- 3. генерация 120 000 товаров
;with nums as (
    select 1 as n
    union all
    select n + 1 from nums where n < 120000
)
insert into dbo.products (
    category_id,
    name,
    brand,
    price,
    description,
    is_available,
    created_at
)
select
    c.category_id,
    concat(
        case b.category_name
            when 'стиральные машинки' then 'стиральная машина '
            when 'холодильники' then 'холодильник '
            when 'телевизоры' then 'телевизор '
            when 'пылесосы' then 'пылесос '
            when 'смартфоны' then 'смартфон '
        end,
        b.brand, ' ', m.model, ' ', n
    ),
    b.brand,
    cast(
        case b.category_name
            when 'стиральные машинки' then 30000 + abs(checksum(newid())) % 70000
            when 'холодильники' then 40000 + abs(checksum(newid())) % 160000
            when 'телевизоры' then 15000 + abs(checksum(newid())) % 60000
            when 'пылесосы' then 2000  + abs(checksum(newid())) % 80000
            when 'смартфоны' then 10000 + abs(checksum(newid())) % 90000
        end
    as decimal(12,2)),
    concat(
        'модель ', m.model,
        ' от производителя ', b.brand,
        '. автоматически сгенерирован товар №', n,
        ' для нагрузочного тестирования.'
    ),
    case when abs(checksum(newid())) % 10 = 0 then 0 else 1 end,
    dateadd(day, - (abs(checksum(newid())) % 730), sysdatetime())
from nums
cross apply (select top 1 * from #brands order by newid()) b
cross apply (select top 1 * from #models where category_name = b.category_name order by newid()) m
join dbo.categories c
    on c.category_name = b.category_name
option (maxrecursion 0);
go

-- 4. проверка
select count(*) as total_products
from dbo.products;
go