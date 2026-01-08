use TechnoSphere_2025_DB
go

-- триггер пересчЄта orders.total_price
create or alter trigger trg_order_items_recalc_total
on order_items
after insert, update, delete
as
begin
    set nocount on;

    update o
    set
        o.total_price = isnull(t.total, 0),
        o.updated_at = sysdatetime()
    from orders o
    join (
        select
            oi.order_id,
            sum(oi.quantity * oi.unit_price) as total
        from order_items oi
        where oi.order_id in (
            select order_id from inserted
            union
            select order_id from deleted
        )
        group by oi.order_id
    ) t
        on t.order_id = o.order_id;
end;
go

-- триггер увеличени€ попул€рности товара
create or alter trigger trg_order_items_increase_popularity
on order_items
after insert
as
begin
    set nocount on;

    update p
    set p.popularity = p.popularity + i.qty
    from products p
    join (
        select product_id, sum(quantity) as qty
        from inserted
        group by product_id
    ) i
        on i.product_id = p.product_id;
end;
go

-- триггер контрол€ доступности товара при добавлении в корзину
create or alter trigger trg_basket_items_check_availability
on basket_items
instead of insert
as
begin
    set nocount on;

    if exists (
        select 1
        from inserted i
        join products p
            on p.product_id = i.product_id
        where p.is_available = 0
    )
    begin
        raiserror (N'нельз€ добавить в корзину недоступный товар', 16, 1);
        rollback transaction;
        return;
    end;

    insert into basket_items (user_id, product_id, quantity, added_at)
    select
        user_id,
        product_id,
        quantity,
        added_at
    from inserted;
end;
go

-- триггер запрета отрицательного остатка корзины
create or alter trigger trg_basket_items_quantity_check
on basket_items
after update
as
begin
    set nocount on;

    if exists (
        select 1
        from inserted
        where quantity <= 0
    )
    begin
        raiserror (N'количество товара в корзине должно быть больше нул€', 16, 1);
        rollback transaction;
    end;
end;
go

-- триггер автоматической установки даты обновлени€ заказа
create or alter trigger trg_orders_set_updated_at
on orders
after update
as
begin
    set nocount on;

    update o
    set o.updated_at = sysdatetime()
    from orders o
    join inserted i
        on i.order_id = o.order_id;
end;
go

-- триггер пересчЄта orders.total_price
create or alter trigger trg_order_items_recalc_total
on order_items
after insert, update, delete
as
begin
    set nocount on;

    update o
    set
        o.total_price = isnull(t.total, 0),
        o.updated_at = sysdatetime()
    from orders o
    join (
        select
            oi.order_id,
            sum(oi.quantity * oi.unit_price) as total
        from order_items oi
        where oi.order_id in (
            select order_id from inserted
            union
            select order_id from deleted
        )
        group by oi.order_id
    ) t
        on t.order_id = o.order_id;
end;
go

-- триггер увеличени€ попул€рности товара
create or alter trigger trg_order_items_increase_popularity
on order_items
after insert
as
begin
    set nocount on;

    update p
    set p.popularity = p.popularity + i.qty
    from products p
    join (
        select product_id, sum(quantity) as qty
        from inserted
        group by product_id
    ) i
        on i.product_id = p.product_id;
end;
go

-- триггер контрол€ доступности товара при добавлении в корзину
create or alter trigger trg_basket_items_check_availability
on basket_items
instead of insert
as
begin
    set nocount on;

    if exists (
        select 1
        from inserted i
        join products p
            on p.product_id = i.product_id
        where p.is_available = 0
    )
    begin
        raiserror (N'нельз€ добавить в корзину недоступный товар', 16, 1);
        rollback transaction;
        return;
    end;

    insert into basket_items (user_id, product_id, quantity, added_at)
    select
        user_id,
        product_id,
        quantity,
        added_at
    from inserted;
end;
go

-- триггер запрета отрицательного остатка корзины
create or alter trigger trg_basket_items_quantity_check
on basket_items
after update
as
begin
    set nocount on;

    if exists (
        select 1
        from inserted
        where quantity <= 0
    )
    begin
        raiserror (N'количество товара в корзине должно быть больше нул€', 16, 1);
        rollback transaction;
    end;
end;
go

-- триггер автоматической установки даты обновлени€ заказа
create or alter trigger trg_orders_set_updated_at
on orders
after update
as
begin
    set nocount on;

    update o
    set o.updated_at = sysdatetime()
    from orders o
    join inserted i
        on i.order_id = o.order_id;
end;
go