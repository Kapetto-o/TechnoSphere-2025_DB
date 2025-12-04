use TechnoSphere_2025
go

-- товары с категорией и средней оценкой
create view vw_products_full as
select
    p.product_id,
    p.name,
    p.brand,
    p.price,
    p.is_available,
    p.created_at,
    c.category_id,
    c.category_name,
    p.average_rating,
    p.popularity
from products p
join categories c on p.category_id = c.category_id
go

-- товары по попул€рности
create view vw_top_products as
select top 100
    p.product_id,
    p.name,
    p.brand,
    p.price,
    p.popularity
from products p
order by p.popularity desc
go