use TechnoSphere_2025_DB
go

-- фильтрация по категории + цена
select *
from dbo.products
where category_id = 1
  and price between 10000 and 50000;

-- сортировка по популярности
select *
from dbo.products
order by popularity desc;

-- поиск по бренду и названию
select *
from dbo.products
where name like '%galaxy%'
   or brand = 'samsung';

-- выборка всех товаров для экспорта
select *
from dbo.products;
set statistics io on;
set statistics time on;

create nonclustered index ix_products_category_price_popularity
on dbo.products (category_id, price, popularity);
create nonclustered index ix_products_popularity_desc
on dbo.products(popularity desc);