use TechnoSphere_2025_DB
go

-- Пользователи с их ролями
create or alter view vw_users_with_roles
as
select
    u.user_id,
    u.login,
    u.email,
    u.created_at,
    r.role_id,
    r.role_name
from users u
join roles r
    on r.role_id = u.role_id;
go

-- Полный каталог товаров с категориями
create or alter view vw_products_full
as
select
    p.product_id,
    p.name,
    p.brand,
    p.price,
    p.description,
    p.is_available,
    p.created_at,
    p.popularity,
    c.category_id,
    c.category_name
from products p
join categories c
    on c.category_id = p.category_id;
go

-- Характеристики товаров в читаемом виде
create or alter view vw_product_specifications
as
select
    ps.product_id,
    st.specification_type_id,
    st.name as specification_name,
    ps.value
from product_specifications ps
join specification_types st
    on st.specification_type_id = ps.specification_type_id;
go

-- Избранные товары пользователей
create or alter view vw_favorites
as
select
    f.user_id,
    u.login,
    f.product_id,
    p.name as product_name,
    p.brand,
    p.price,
    f.created_at
from favorites f
join users u
    on u.user_id = f.user_id
join products p
    on p.product_id = f.product_id;
go

-- Корзина пользователя с итоговой стоимостью позиции
create or alter view vw_basket_items
as
select
    bi.basket_item_id,
    bi.user_id,
    u.login,
    bi.product_id,
    p.name as product_name,
    p.brand,
    bi.quantity,
    p.price,
    bi.quantity * p.price as item_total,
    bi.added_at
from basket_items bi
join users u
    on u.user_id = bi.user_id
join products p
    on p.product_id = bi.product_id;
go

-- Заказы с пользователями и статусами
create or alter view vw_orders
as
select
    o.order_id,
    o.user_id,
    u.login,
    o.status_id,
    s.status_name,
    o.created_at,
    o.updated_at,
    o.total_price,
    o.shipping_address
from orders o
join users u
    on u.user_id = o.user_id
join order_statuses s
    on s.status_id = o.status_id;
go

-- Состав заказов
create or alter view vw_order_items
as
select
    oi.order_item_id,
    oi.order_id,
    oi.product_id,
    p.name as product_name,
    p.brand,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price as item_total
from order_items oi
join products p
    on p.product_id = oi.product_id;
go

create or alter view vw_orders_full
as
select
    o.order_id,
    u.login,
    s.status_name,
    o.created_at,
    o.updated_at,
    o.total_price,
    p.name as product_name,
    p.brand,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price as item_total
from orders o
join users u
    on u.user_id = o.user_id
join order_statuses s
    on s.status_id = o.status_id
join order_items oi
    on oi.order_id = o.order_id
join products p
    on p.product_id = oi.product_id;
go

-- Упрощённое представление под поиск
create or alter view vw_products_for_search
as
select
    product_id,
    name,
    brand,
    price,
    category_name
from vw_products_full;
go