use TechnoSphere_2025
go

-- добавление товара admin
create procedure proc_add_product
    @category_id int,
    @name nvarchar(300),
    @brand nvarchar(150),
    @price decimal(12,2),
    @description nvarchar(max) = null,
    @is_available bit = 1
as
begin
    set nocount on;
    insert into products (category_id, name, brand, price, description, is_available)
    values (@category_id, @name, @brand, @price, @description, @is_available)

    select scope_identity() as product_id
end
go

-- обновление товара admin
create procedure proc_update_product
    @product_id bigint,
    @category_id int = null,
    @name nvarchar(300) = null,
    @brand nvarchar(150) = null,
    @price decimal(12,2) = null,
    @description nvarchar(max) = null,
    @is_available bit = null
as
begin
    set nocount on;
    update products
    set
        category_id = coalesce(@category_id, category_id),
        name = coalesce(@name, name),
        brand = coalesce(@brand, brand),
        price = coalesce(@price, price),
        description = coalesce(@description, description),
        is_available = coalesce(@is_available, is_available)
    where product_id = @product_id
end
go

-- удаление товара admin
create procedure proc_delete_product
    @product_id bigint
as
begin
    set nocount on;
    delete from products where product_id = @product_id
end
go

-- добавление в избранное
create procedure proc_add_favorite
    @user_id int,
    @product_id bigint
as
begin
    set nocount on;
    if not exists (select 1 from favorites where user_id = @user_id and product_id = @product_id)
        insert into favorites (user_id, product_id) values (@user_id, @product_id)
end
go

-- удаление из избранного
create procedure proc_remove_favorite
    @user_id int,
    @product_id bigint
as
begin
    set nocount on;
    delete from favorites where user_id = @user_id and product_id = @product_id
end
go

-- добавление в корзину (увеличиваем quantity если есть)
create procedure proc_add_to_basket
    @user_id int,
    @product_id bigint,
    @quantity int
as
begin
    set nocount on;
    begin transaction
    if exists (select 1 from basket_items where user_id = @user_id and product_id = @product_id)
        update basket_items set quantity = quantity + @quantity where user_id = @user_id and product_id = @product_id
    else
        insert into basket_items (user_id, product_id, quantity) values (@user_id, @product_id, @quantity)
    commit transaction
end
go

-- удаление из корзины или уменьшение количества
create procedure proc_remove_from_basket
    @user_id int,
    @product_id bigint,
    @quantity int = null  -- null => удалить полностью
as
begin
    set nocount on;
    if @quantity is null
        delete from basket_items where user_id = @user_id and product_id = @product_id
    else
    begin
        update basket_items
        set quantity = quantity - @quantity
        where user_id = @user_id and product_id = @product_id

        delete from basket_items where user_id = @user_id and product_id = @product_id and quantity <= 0
    end
end
go

-- создание заказа из корзины
create procedure proc_create_order_from_basket
    @user_id int,
    @shipping_address nvarchar(1000) = null
as
begin
    set nocount on;
    begin transaction

    -- создаём заказ
    insert into orders (user_id, shipping_address)
    values (@user_id, @shipping_address)

    declare @order_id bigint = scope_identity()

    -- переносим позиции
    insert into order_items (order_id, product_id, quantity, unit_price)
    select @order_id, b.product_id, b.quantity, p.price
    from basket_items b
    join products p on p.product_id = b.product_id
    where b.user_id = @user_id

    -- удаляем позиции корзины
    delete from basket_items where user_id = @user_id

    -- пересчёт total_price будет выполнен триггером (order_items after insert)
    commit transaction

    select @order_id as order_id
end
go

-- изменение статуса заказа (бизнес-правила: после delivered нельзя изменить)
create procedure proc_change_order_status
    @order_id bigint,
    @new_status_id tinyint
as
begin
    set nocount on;
    declare @current_status nvarchar(100)
    select @current_status = status_name
    from orders o
    join order_statuses s on o.status_id = s.status_id
    where o.order_id = @order_id

    if @current_status = 'delivered'
        raiserror('заказ с статусом delivered не может быть изменён', 16, 1)

    update orders set status_id = @new_status_id, updated_at = sysdatetime() where order_id = @order_id
end
go

-- поиск товаров (фильтрация/сортировка) - возвращает постранично
create procedure proc_search_products
    @category_id int = null,
    @brand nvarchar(150) = null,
    @min_price decimal(12,2) = null,
    @max_price decimal(12,2) = null,
    @search_text nvarchar(400) = null,
    @sort_by nvarchar(50) = 'price', -- price, popularity, created_at
    @sort_dir nvarchar(4) = 'asc', -- asc/desc
    @page int = 1,
    @page_size int = 20
as
begin
    set nocount on;

    declare @sql nvarchar(max) = N'
    select
        p.product_id, p.name, p.brand, p.price, p.is_available, p.created_at, p.average_rating, p.popularity, c.category_name
    from products p
    join categories c on p.category_id = c.category_id
    where 1 = 1
    '

    if @category_id is not null set @sql += N' and p.category_id = @category_id'
    if @brand is not null set @sql += N' and p.brand = @brand'
    if @min_price is not null set @sql += N' and p.price >= @min_price'
    if @max_price is not null set @sql += N' and p.price <= @max_price'
    if @search_text is not null set @sql += N' and (p.name like ''%'' + @search_text + ''%'' or p.description like ''%'' + @search_text + ''%'')'

    set @sql += N' order by ' + case when @sort_by = 'price' then 'p.price' when @sort_by = 'popularity' then 'p.popularity' else 'p.created_at' end
    set @sql += case when lower(@sort_dir) = 'desc' then ' desc' else ' asc' end
    set @sql += N' offset ' + cast((@page - 1) * @page_size as nvarchar(20)) + N' rows fetch next ' + cast(@page_size as nvarchar(20)) + N' rows only'

    exec sp_executesql @sql,
        N'@category_id int, @brand nvarchar(150), @min_price decimal(12,2), @max_price decimal(12,2), @search_text nvarchar(400)',
        @category_id = @category_id, @brand = @brand, @min_price = @min_price, @max_price = @max_price, @search_text = @search_text
end
go

-- экспорт товара в json по id
if exists (select 1 from sys.objects where object_id = object_id('proc_export_product_json') and type = 'p')
    drop procedure proc_export_product_json;
go

create procedure proc_export_product_json
    @product_id bigint
as
begin
    set nocount on;

    select
        p.product_id,
        p.name,
        p.brand,
        p.price,
        p.description,
        p.is_available,
        c.category_name as category,
        (
            select
                ps.specification_type_id as id,
                st.name as type_name,
                ps.value
            from product_specifications ps
            join specification_types st on ps.specification_type_id = st.specification_type_id
            where ps.product_id = p.product_id
            for json path
        ) as specifications,
        (
            select
                pr.review_id,
                pr.user_id,
                pr.rating,
                pr.comment,
                pr.created_at
            from product_reviews pr
            where pr.product_id = p.product_id
            for json path
        ) as reviews
    from products p
    join categories c on p.category_id = c.category_id
    where p.product_id = @product_id
    for json path, without_array_wrapper;
end
go

-- импорт массива товаров из json (пример формата: [{...}, {...}])
create procedure proc_import_products_from_json
    @json nvarchar(max)
as
begin
    set nocount on;
    -- разобрать массив json на строки и вставить в products; расширяй по необходимости
    declare @tbl table (
        name nvarchar(300),
        brand nvarchar(150),
        price decimal(12,2),
        description nvarchar(max),
        category_name nvarchar(150),
        is_available bit
    )

    insert into @tbl (name, brand, price, description, category_name, is_available)
    select j.name, j.brand, j.price, j.description, j.category, j.is_available
    from openjson(@json)
    with (
        name nvarchar(300),
        brand nvarchar(150),
        price decimal(12,2),
        description nvarchar(max),
        category nvarchar(150),
        is_available bit
    ) as j

    -- вставка категорий, если нет
    insert into categories (category_name)
    select distinct t.category_name
    from @tbl t
    where not exists (select 1 from categories c where c.category_name = t.category_name)

    -- вставка продуктов (связь по категории)
    insert into products (category_id, name, brand, price, description, is_available)
    select c.category_id, t.name, t.brand, t.price, t.description, coalesce(t.is_available, 1)
    from @tbl t
    join categories c on c.category_name = t.category_name
end
go