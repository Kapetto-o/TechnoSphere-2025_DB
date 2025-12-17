use TechnoSphere_2025_DB
go

-- Получение названия роли пользователя
create or alter function fn_get_user_role_name (
    @user_id int
)
returns nvarchar(50)
as
begin
    declare @role_name nvarchar(50);

    select @role_name = r.role_name
    from users u
    join roles r
        on r.role_id = u.role_id
    where u.user_id = @user_id;

    return @role_name;
end;
go

-- Проверка доступности товара
create or alter function fn_is_product_available (
    @product_id bigint
)
returns bit
as
begin
    declare @is_available bit;

    select @is_available = is_available
    from products
    where product_id = @product_id;

    return isnull(@is_available, 0);
end;
go

-- Подсчёт итоговой стоимости заказа
create or alter function fn_get_order_total_price (
    @order_id bigint
)
returns decimal(14,2)
as
begin
    declare @total decimal(14,2);

    select @total = sum(oi.quantity * oi.unit_price)
    from order_items oi
    where oi.order_id = @order_id;

    return isnull(@total, 0);
end;
go

-- Корзина конкретного пользователя
create or alter function fn_get_user_basket (
    @user_id int
)
returns table
as
return
(
    select
        bi.basket_item_id,
        bi.product_id,
        p.name as product_name,
        p.brand,
        bi.quantity,
        p.price,
        bi.quantity * p.price as item_total
    from basket_items bi
    join products p
        on p.product_id = bi.product_id
    where bi.user_id = @user_id
);
go

-- Избранные товары пользователя
create or alter function fn_get_user_favorites (
    @user_id int
)
returns table
as
return
(
    select
        f.product_id,
        p.name as product_name,
        p.brand,
        p.price,
        f.created_at
    from favorites f
    join products p
        on p.product_id = f.product_id
    where f.user_id = @user_id
);
go

-- Поиск товаров по названию и бренду
create or alter function fn_search_products (
    @search_text nvarchar(200)
)
returns table
as
return
(
    select
        p.product_id,
        p.name,
        p.brand,
        p.price,
        c.category_name
    from products p
    join categories c
        on c.category_id = p.category_id
    where
        p.name like '%' + @search_text + '%'
        or p.brand like '%' + @search_text + '%'
);
go

-- История заказов пользователя
create or alter function fn_get_orders_by_user (
    @user_id int
)
returns table
as
return
(
    select
        o.order_id,
        o.created_at,
        o.updated_at,
        s.status_name,
        o.total_price,
        o.shipping_address
    from orders o
    join order_statuses s
        on s.status_id = o.status_id
    where o.user_id = @user_id
);
go