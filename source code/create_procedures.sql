use TechnoSphere_2025_DB
go

-- Добавление товара
create or alter procedure proc_add_product
    @category_id int,
    @name nvarchar(300),
    @brand nvarchar(150),
    @price decimal(12,2),
    @description nvarchar(max),
    @is_available bit = 1
as
begin
    set nocount on;

    insert into products (
        category_id, name, brand, price, description, is_available
    )
    values (
        @category_id, @name, @brand, @price, @description, @is_available
    );
end;
go

-- Обновление товара
create or alter procedure proc_update_product
    @product_id bigint,
    @category_id int,
    @name nvarchar(300),
    @brand nvarchar(150),
    @price decimal(12,2),
    @description nvarchar(max),
    @is_available bit
as
begin
    set nocount on;

    update products
    set
        category_id = @category_id,
        name = @name,
        brand = @brand,
        price = @price,
        description = @description,
        is_available = @is_available
    where product_id = @product_id;
end;
go

-- Удаление товара
create or alter procedure proc_delete_product
    @product_id bigint
as
begin
    set nocount on;

    delete from products
    where product_id = @product_id;
end;
go

-- Получение каталога с фильтрацией и сортировкой
create or alter procedure proc_get_products
    @category_id int = null,
    @brand nvarchar(150) = null,
    @min_price decimal(12,2) = null,
    @max_price decimal(12,2) = null,
    @sort_mode nvarchar(20) = 'price'
as
begin
    set nocount on;

    select
        p.product_id,
        p.name,
        p.brand,
        p.price,
        p.is_available,
        p.created_at,
        p.popularity,
        c.category_name
    from products p
    join categories c
        on c.category_id = p.category_id
    where
        (@category_id is null or p.category_id = @category_id)
        and (@brand is null or p.brand = @brand)
        and (@min_price is null or p.price >= @min_price)
        and (@max_price is null or p.price <= @max_price)
    order by
        case when @sort_mode = 'price' then p.price end,
        case when @sort_mode = 'popularity' then p.popularity end desc,
        case when @sort_mode = 'new' then p.created_at end desc;
end;
go

-- Поиск товаров
create or alter procedure proc_search_products
    @search_text nvarchar(200)
as
begin
    set nocount on;

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
        or p.brand like '%' + @search_text + '%';
end;
go

-- Добавление в избранное
create or alter procedure proc_add_to_favorites
    @user_id int,
    @product_id bigint
as
begin
    set nocount on;

    if not exists (
        select 1
        from favorites
        where user_id = @user_id
          and product_id = @product_id
    )
    begin
        insert into favorites (user_id, product_id)
        values (@user_id, @product_id);
    end;
end;
go

-- Удаление из избранного
create or alter procedure proc_remove_from_favorites
    @user_id int,
    @product_id bigint
as
begin
    set nocount on;

    delete from favorites
    where user_id = @user_id
      and product_id = @product_id;
end;
go

-- Добавление товара в корзину
create or alter procedure proc_add_to_basket
    @user_id int,
    @product_id bigint,
    @quantity int
as
begin
    set nocount on;

    if exists (
        select 1
        from basket_items
        where user_id = @user_id
          and product_id = @product_id
    )
    begin
        update basket_items
        set quantity = quantity + @quantity
        where user_id = @user_id
          and product_id = @product_id;
    end
    else
    begin
        insert into basket_items (user_id, product_id, quantity)
        values (@user_id, @product_id, @quantity);
    end;
end;
go

-- Удаление из корзины
create or alter procedure proc_remove_from_basket
    @user_id int,
    @product_id bigint
as
begin
    set nocount on;

    delete from basket_items
    where user_id = @user_id
      and product_id = @product_id;
end;
go

-- Просмотр корзины
create or alter procedure proc_get_basket
    @user_id int
as
begin
    set nocount on;

    select *
    from vw_basket_items
    where user_id = @user_id;
end;
go

-- Создание заказа
create or alter procedure proc_create_order
    @user_id int,
    @shipping_address nvarchar(1000)
as
begin
    set nocount on;

    declare @order_id bigint;

    insert into orders (user_id, status_id, shipping_address)
    values (@user_id, 1, @shipping_address);

    set @order_id = scope_identity();

    insert into order_items (order_id, product_id, quantity, unit_price)
    select
        @order_id,
        bi.product_id,
        bi.quantity,
        p.price
    from basket_items bi
    join products p
        on p.product_id = bi.product_id
    where bi.user_id = @user_id;

    delete from basket_items
    where user_id = @user_id;
end;
go

-- Изменение статуса заказа
create or alter procedure proc_update_order_status
    @order_id bigint,
    @status_id tinyint
as
begin
    set nocount on;

    update orders
    set status_id = @status_id
    where order_id = @order_id;
end;
go

-- Просмотр заказов пользователя
create or alter procedure proc_get_user_orders
    @user_id int
as
begin
    set nocount on;

    select *
    from vw_orders
    where user_id = @user_id;
end;
go

-- Экспорт
create or alter procedure dbo.proc_export_table_to_json
(
    @table_name sysname
)
as
begin
    set nocount on;

    declare @file_path nvarchar(500);
    declare @cmd nvarchar(max);
    declare @cmd_varchar varchar(8000);

    -- путь к файлу
    set @file_path = 'C:\DataBase\TechnoSphere_2025_DB\' + @table_name + '.json';

    -- формируем команду bcp
    -- !!! замени -S и -d при необходимости !!!
    set @cmd =
        'bcp "select * from dbo.' + quotename(@table_name) +
        ' for json path, include_null_values" queryout "' +
        @file_path +
        '" -S localhost -d TechnoSphere_2025 -T -w';

    set @cmd_varchar = cast(@cmd as varchar(8000));

    print 'экспортируем таблицу: ' + @table_name;
    print 'файл: ' + @file_path;

    exec xp_cmdshell @cmd_varchar;

    print 'экспорт завершён';
end;
go

-- Импорт
create or alter procedure dbo.proc_import_products_from_json
(
    @file_path nvarchar(500)
)
as
begin
    set nocount on;

    declare @json nvarchar(max);
    declare @sql nvarchar(max);

    set @sql = N'
        select @json_out = bulkcolumn
        from openrowset(
            bulk ''' + @file_path + ''',
            single_clob
        ) as j;
    ';

    exec sp_executesql @sql, N'@json_out nvarchar(max) output', @json output;

    insert into products (
        category_id,
        name,
        brand,
        price,
        description,
        is_available,
        created_at,
        popularity
    )
    select
        c.category_id,
        p.name,
        p.brand,
        p.price,
        p.description,
        p.is_available,
        isnull(p.created_at, sysdatetime()),
        isnull(p.popularity, 0)
    from openjson(@json)
    with (
        category_name nvarchar(150),
        name nvarchar(300),
        brand nvarchar(150),
        price decimal(12,2),
        description nvarchar(max),
        is_available bit,
        created_at datetime2,
        popularity int
    ) p
    join categories c
        on c.category_name = p.category_name;
end;
go