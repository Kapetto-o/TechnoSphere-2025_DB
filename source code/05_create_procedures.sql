use TechnoSphere_2025_DB
go

-- ДОБАВЛЕНИЕ ТОВАРА
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

    if @category_id is null
    begin
        raiserror ('category_id не указан', 16, 1);
        return;
    end;

    if not exists (select 1 from categories where category_id = @category_id)
    begin
        raiserror ('указанная категория не существует', 16, 1);
        return;
    end;

    if @price < 0
    begin
        raiserror ('цена не может быть отрицательной', 16, 1);
        return;
    end;

    begin try
        begin transaction;

        insert into products (
            category_id, name, brand, price, description, is_available
        )
        values (
            @category_id, @name, @brand, @price, @description, @is_available
        );

        commit transaction;
    end try
    begin catch
        if @@trancount > 0 rollback;

        declare @err nvarchar(4000) = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

-- ОБНОВЛЕНИЕ ТОВАРА
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

    if not exists (select 1 from products where product_id = @product_id)
    begin
        raiserror ('товар не найден', 16, 1);
        return;
    end;

    begin try
        begin transaction;

        update products
        set
            category_id = @category_id,
            name = @name,
            brand = @brand,
            price = @price,
            description = @description,
            is_available = @is_available
        where product_id = @product_id;

        commit transaction;
    end try
    begin catch
        if @@trancount > 0 rollback;
        declare @err nvarchar(4000) = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

-- УДАЛЕНИЕ ТОВАРА
create or alter procedure proc_delete_product
    @product_id bigint
as
begin
    set nocount on;

    if not exists (select 1 from products where product_id = @product_id)
    begin
        raiserror ('товар не найден', 16, 1);
        return;
    end;

    begin try
        delete from products where product_id = @product_id;
    end try
    begin catch
        declare @err nvarchar(4000) = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

-- ПОЛУЧЕНИЕ КАТАЛОГА
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
    join categories c on c.category_id = p.category_id
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

-- ПОИСК ТОВАРОВ
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
    join categories c on c.category_id = p.category_id
    where
        p.name like '%' + @search_text + '%'
        or p.brand like '%' + @search_text + '%';
end;
go

-- ИЗБРАННОЕ
create or alter procedure proc_add_to_favorites
    @user_id int,
    @product_id bigint
as
begin
    set nocount on;

    if not exists (select 1 from users where user_id = @user_id)
    begin
        raiserror ('пользователь не найден', 16, 1);
        return;
    end;

    if not exists (select 1 from products where product_id = @product_id)
    begin
        raiserror ('товар не найден', 16, 1);
        return;
    end;

    if not exists (
        select 1 from favorites
        where user_id = @user_id and product_id = @product_id
    )
    begin
        insert into favorites (user_id, product_id)
        values (@user_id, @product_id);
    end;
end;
go

create or alter procedure proc_remove_from_favorites
    @user_id int,
    @product_id bigint
as
begin
    delete from favorites
    where user_id = @user_id
      and product_id = @product_id;
end;
go

create or alter procedure dbo.proc_get_favorites
(
    @user_id int
)
as
begin
    set nocount on;

    -- Проверка существования пользователя
    if not exists (
        select 1
        from dbo.users
        where user_id = @user_id
    )
    begin
        raiserror (N'пользователь не существует', 16, 1);
        return;
    end;

    select
        p.product_id,
        p.name,
        p.brand,
        p.price,
        p.description,
        p.is_available,
        p.created_at,
        p.popularity,
        c.category_name,
        f.created_at as added_to_favorites_at
    from dbo.favorites f
    join dbo.products p
        on p.product_id = f.product_id
    join dbo.categories c
        on c.category_id = p.category_id
    where f.user_id = @user_id
    order by f.created_at desc;
end;
go

-- КОРЗИНА
create or alter procedure proc_add_to_basket
    @user_id int,
    @product_id bigint,
    @quantity int
as
begin
    set nocount on;

    if @quantity <= 0
    begin
        raiserror ('количество должно быть больше нуля', 16, 1);
        return;
    end;

    if exists (
    select 1
    from users u
    join roles r on r.role_id = u.role_id
    where u.user_id = @user_id
      and r.role_name = 'blocked'
    )
    begin
        raiserror (N'пользователь заблокирован', 16, 1);
        return;
    end;

    begin try
        if exists (
            select 1 from basket_items
            where user_id = @user_id and product_id = @product_id
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
    end try
    begin catch
        declare @err nvarchar(4000) = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

create or alter procedure proc_remove_from_basket
    @user_id int,
    @product_id bigint
as
begin
    if exists (
        select 1
        from users u
        join roles r on r.role_id = u.role_id
        where u.user_id = @user_id
          and r.role_name = 'blocked'
    )
    begin
        raiserror (N'пользователь заблокирован', 16, 1);
        return;
    end;

    delete from basket_items
    where user_id = @user_id
      and product_id = @product_id;
end;
go

create or alter procedure proc_get_basket
    @user_id int
as
begin
    if exists (
        select 1
        from users u
        join roles r on r.role_id = u.role_id
        where u.user_id = @user_id
          and r.role_name = 'blocked'
    )
    begin
        raiserror (N'пользователь заблокирован', 16, 1);
        return;
    end;

    select *
    from vw_basket_items
    where user_id = @user_id;
end;
go

-- ЗАКАЗЫ
create or alter procedure proc_create_order
    @user_id int,
    @shipping_address nvarchar(1000)
as
begin
    set nocount on;

    if exists (
        select 1
        from users u
        join roles r on r.role_id = u.role_id
        where u.user_id = @user_id
          and r.role_name = 'blocked'
    )
    begin
        raiserror (N'пользователь заблокирован', 16, 1);
        return;
    end;

    declare @order_id bigint;

    begin try
        begin transaction;

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
        join products p on p.product_id = bi.product_id
        where bi.user_id = @user_id;

        delete from basket_items where user_id = @user_id;

        commit transaction;
    end try
    begin catch
        if @@trancount > 0 rollback;
        declare @err nvarchar(4000) = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

create or alter procedure proc_update_order_status
    @order_id bigint,
    @status_id tinyint
as
begin
    update orders
    set status_id = @status_id
    where order_id = @order_id;
end;
go

create or alter procedure proc_get_user_orders
    @user_id int
as
begin
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
    declare @cmd_nvarchar nvarchar(max);
    declare @cmd_varchar  varchar(8000);

    if not exists (
        select 1
        from sys.tables
        where name = @table_name
          and schema_id = schema_id('dbo')
    )
    begin
        raiserror (N'указанная таблица не существует', 16, 1);
        return;
    end;

    set @file_path = N'C:\DataBase\TechnoSphere_2025_DB\' + @table_name + N'.json';

    set @cmd_nvarchar =
        N'bcp "select (select ' +
        N'    p.product_id, c.category_name, p.name, p.brand, p.price, ' +
        N'    p.description, p.is_available, p.created_at, p.popularity ' +
        N' from dbo.products p ' +
        N' join dbo.categories c on c.category_id = p.category_id ' +
        N' for json path, root(''products''), include_null_values' +
        N') as JsonData" ' +
        N'queryout "' + @file_path + N'" ' +
        N'-S Kapetto\SQLEXPRESS -d TechnoSphere_2025_DB -T -w -Yo -u';

    set @cmd_varchar = cast(@cmd_nvarchar as varchar(8000));

    exec xp_cmdshell @cmd_varchar;
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
    declare @sql  nvarchar(max);

    if @file_path is null or len(@file_path) = 0
    begin
        raiserror (N'путь к файлу не указан', 16, 1);
        return;
    end;

    begin try
        -- Чтение JSON
        set @sql = N'
            select @json_out = bulkcolumn
            from openrowset(
                bulk ''' + @file_path + ''',
                single_nclob
            ) as j;
        ';

        exec sp_executesql
            @stmt     = @sql,
            @params   = N'@json_out nvarchar(max) output',
            @json_out = @json output;

        if @json is null
        begin
            raiserror (N'файл пустой или не прочитан', 16, 1);
            return;
        end;

        ;with src as (
            select
                c.category_id,
                p.name,
                p.brand,
                p.price,
                p.description,
                p.is_available,
                isnull(p.created_at, sysdatetime()) as created_at,
                isnull(p.popularity, 0) as popularity
            from openjson(@json, '$.products')
            with (
                category_name nvarchar(150),
                name          nvarchar(300),
                brand         nvarchar(150),
                price         decimal(12,2),
                description   nvarchar(max),
                is_available  bit,
                created_at    datetime2,
                popularity    int
            ) p
            join categories c
                on c.category_name = p.category_name
        )
        merge products as tgt
        using src
            on  tgt.category_id = src.category_id
            and tgt.name = src.name
            and tgt.brand = src.brand
        when matched then
            update set
                price        = src.price,
                description  = src.description,
                is_available = src.is_available,
                popularity   = src.popularity
        when not matched then
            insert (
                category_id,
                name,
                brand,
                price,
                description,
                is_available,
                created_at,
                popularity
            )
            values (
                src.category_id,
                src.name,
                src.brand,
                src.price,
                src.description,
                src.is_available,
                src.created_at,
                src.popularity
            );

    end try
    begin catch
        declare @msg nvarchar(4000) = error_message();
        raiserror(@msg, 16, 1);
    end catch;
end;
go

-- Регистрация
create or alter procedure proc_register_user
    @login nvarchar(100),
    @email nvarchar(255),
    @password nvarchar(200)
as
begin
    set nocount on;

    if @login is null or len(@login) = 0
    begin
        raiserror (N'логин не указан', 16, 1);
        return;
    end;

    if @password is null or len(@password) < 6
    begin
        raiserror (N'пароль слишком короткий', 16, 1);
        return;
    end;

    if exists (select 1 from users where login = @login)
    begin
        raiserror (N'логин уже существует', 16, 1);
        return;
    end;

    if exists (select 1 from users where email = @email)
    begin
        raiserror (N'email уже используется', 16, 1);
        return;
    end;

    begin try
        insert into users (
            role_id,
            login,
            password_hash,
            email
        )
        values (
            (select role_id from roles where role_name = 'user'),
            @login,
            hashbytes('sha2_256', @password),
            @email
        );
    end try
    begin catch
        declare @err nvarchar(4000);
        set @err = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

-- Авторизация
create or alter procedure proc_login_user
    @login nvarchar(100),
    @password nvarchar(200)
as
begin
    set nocount on;

    if not exists (
        select 1
        from users
        where login = @login
          and password_hash = hashbytes('sha2_256', @password)
    )
    begin
        raiserror ('неверный логин или пароль', 16, 1);
        return;
    end;

    select
        u.user_id,
        u.login,
        r.role_name
    from users u
    join roles r on r.role_id = u.role_id
    where u.login = @login;
end;
go

-- Блокировка пользователя
create or alter procedure proc_block_user
    @user_id int
as
begin
    update users
    set role_id = (select role_id from roles where role_name = 'blocked')
    where user_id = @user_id;
end;
go

-- Восстановление пользователя
create or alter procedure proc_unblock_user
    @user_id int
as
begin
    update users
    set role_id = (select role_id from roles where role_name = 'user')
    where user_id = @user_id;
end;
go

-- Удаление пользователя
create or alter procedure proc_delete_user
    @user_id int
as
begin
    delete from favorites where user_id = @user_id;

    delete from basket_items where user_id = @user_id;

    delete from orders where user_id = @user_id;

    delete from users where user_id = @user_id;
end;
go

create or alter procedure proc_get_product_by_id
    @product_id bigint
as
begin
    set nocount on;

    select
        product_id,
        name,
        brand,
        price,
        description,
        is_available,
        created_at,
        popularity
    from products
    where product_id = @product_id;
end;
go

create or alter procedure proc_get_all_orders
as
begin
    set nocount on;

    select
        o.order_id,
        o.user_id,
        u.login,
        o.status_id,
        s.status_name,
        o.total_price,
        o.created_at,
        o.updated_at,
        o.shipping_address
    from orders o
    join users u
        on u.user_id = o.user_id
    join order_statuses s
        on s.status_id = o.status_id
    order by o.created_at desc;
end;
go

-- Создание категории
create or alter procedure proc_add_category
    @category_name nvarchar(150),
    @description nvarchar(500)
as
begin
    set nocount on;

    if @category_name is null or len(@category_name) = 0
    begin
        raiserror ('название категории не указано', 16, 1);
        return;
    end;

    if exists (
        select 1
        from categories
        where category_name = @category_name
    )
    begin
        raiserror ('категория с таким названием уже существует', 16, 1);
        return;
    end;

    begin try
        insert into categories (category_name, description)
        values (@category_name, @description);
    end try
    begin catch
        declare @err nvarchar(4000);
        set @err = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

-- Изменение категории
create or alter procedure proc_update_category
    @category_id int,
    @category_name nvarchar(150),
    @description nvarchar(500)
as
begin
    set nocount on;

    if not exists (
        select 1
        from categories
        where category_id = @category_id
    )
    begin
        raiserror ('категория не найдена', 16, 1);
        return;
    end;

    begin try
        update categories
        set
            category_name = @category_name,
            description = @description
        where category_id = @category_id;
    end try
    begin catch
        declare @err nvarchar(4000);
        set @err = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

-- Удаление категории
create or alter procedure proc_delete_category
    @category_id int
as
begin
    set nocount on;

    if not exists (
        select 1
        from categories
        where category_id = @category_id
    )
    begin
        raiserror ('категория не найдена', 16, 1);
        return;
    end;

    if exists (
        select 1
        from products
        where category_id = @category_id
    )
    begin
        raiserror ('нельзя удалить категорию, в которой есть товары', 16, 1);
        return;
    end;

    begin try
        delete from categories
        where category_id = @category_id;
    end try
    begin catch
        declare @err nvarchar(4000);
        set @err = error_message();
        raiserror (@err, 16, 1);
    end catch;
end;
go

create or alter procedure dbo.proc_get_categories
as
begin
    set nocount on;

    select
        category_id,
        category_name,
        description
    from categories
    order by category_name;
end;
go

create or alter procedure dbo.proc_get_all_users
as
begin
    set nocount on;

    select
        u.user_id,
        u.login,
        u.email,
        u.created_at,
        r.role_name
    from dbo.users u
    join dbo.roles r
        on r.role_id = u.role_id
    order by u.user_id;
end;
go