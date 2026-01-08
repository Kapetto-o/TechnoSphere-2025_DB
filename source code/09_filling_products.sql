use TechnoSphere_2025_DB;
go

set nocount on;

-------------------------------------------------
-- 1. КАТЕГОРИИ
-------------------------------------------------
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

-------------------------------------------------
-- 2. ВРЕМЕННЫЕ ТАБЛИЦЫ
-------------------------------------------------
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

-------------------------------------------------
-- 3. ГЕНЕРАЦИЯ 120 000 ТОВАРОВ (ИСПРАВЛЕНО)
-------------------------------------------------
;with nums as (
    select 1 as n
    union all
    select n + 1
    from nums
    where n < 120000
),
cat as (
    select
        category_id,
        category_name,
        row_number() over (order by category_id) as rn
    from dbo.categories
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
        case c.category_name
            when 'стиральные машинки' then 'стиральная машина '
            when 'холодильники' then 'холодильник '
            when 'телевизоры' then 'телевизор '
            when 'пылесосы' then 'пылесос '
            when 'смартфоны' then 'смартфон '
        end,
        b.brand, ' ', m.model, ' ', nums.n
    ),
    b.brand,
    cast(
        case c.category_name
            when 'стиральные машинки' then 30000 + abs(checksum(nums.n)) % 70000
            when 'холодильники' then 40000 + abs(checksum(nums.n)) % 160000
            when 'телевизоры' then 15000 + abs(checksum(nums.n)) % 60000
            when 'пылесосы' then 2000  + abs(checksum(nums.n)) % 80000
            when 'смартфоны' then 10000 + abs(checksum(nums.n)) % 90000
        end
    as decimal(12,2)),
    concat(
        'модель ', m.model,
        ' от производителя ', b.brand,
        '. автоматически сгенерирован товар №', nums.n,
        ' для нагрузочного тестирования.'
    ),
    case when nums.n % 10 = 0 then 0 else 1 end,
    dateadd(day, - (nums.n % 730), sysdatetime())
from nums
join cat c
    on c.rn = ((nums.n - 1) % 5) + 1
cross apply (
    select top 1 *
    from #brands b2
    where b2.category_name = c.category_name
    order by checksum(nums.n)
) b
cross apply (
    select top 1 *
    from #models m2
    where m2.category_name = c.category_name
    order by checksum(nums.n, b.brand)
) m
option (maxrecursion 0);
go

-------------------------------------------------
-- 4. ПРОВЕРКА
-------------------------------------------------
select
    c.category_name,
    count(*) as product_count
from dbo.products p
join dbo.categories c on c.category_id = p.category_id
group by c.category_name
order by product_count desc;
go