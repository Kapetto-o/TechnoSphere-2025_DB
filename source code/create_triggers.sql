use TechnoSphere_2025
go

-- после вставки/обновления/удаления отзыва пересчитывается рейтинг
create trigger trg_product_reviews_after_change
on product_reviews
after insert, update, delete
as
begin
    set nocount on;

    declare @changed_product_id bigint

    ;with changed as (
        select product_id from inserted
        union
        select product_id from deleted
    )
    update p
    set average_rating = r.avg_rating
    from products p
    join (
        select product_id, cast(avg(cast(rating as float)) as decimal(3,2)) as avg_rating
        from product_reviews
        where product_id in (select product_id from changed)
        group by product_id
    ) r on p.product_id = r.product_id
end
go

-- при добавлении/удалении/обновлении товара заказа пересчитывается итогованя сумма к заказу
create trigger trg_order_items_after_change
on order_items
after insert, update, delete
as
begin
    set nocount on;

    ;with changed as (
        select order_id from inserted
        union
        select order_id from deleted
    )
    update o
    set total_price = isnull(oi.sum_price, 0),
        updated_at = sysdatetime()
    from orders o
    join (
        select order_id, sum(quantity * unit_price) as sum_price
        from order_items
        where order_id in (select order_id from changed)
        group by order_id
    ) oi on o.order_id = oi.order_id
end
go