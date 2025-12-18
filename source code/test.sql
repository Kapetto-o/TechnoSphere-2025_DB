use TechnoSphere_2025_DB;
go

set nocount on;

begin try
    select
        u.user_id,
        u.login,
        r.role_name
    from dbo.users u
    join dbo.roles r
        on r.role_id = u.role_id;
end try
begin catch
    print 'ошибка при выводе ролей: ' + error_message();
end catch
go

begin try
    -- добавление
    declare @category_id int = 1;
    exec dbo.proc_add_product
        @category_id = @category_id,
        @name = 'машина',
        @brand = 'testbrand',
        @price = 9999.99,
        @description = 'добавлен для демонстрации',
        @is_available = 1;

    -- получаем id добавленного товара
    declare @test_product_id bigint;
    set @test_product_id = (select top 1 product_id
                            from dbo.products
                            where name = 'тестовый товар'
                            order by product_id desc);

    -- обновление
    exec dbo.proc_update_product
        @product_id = @test_product_id,
        @category_id = @category_id,
        @name = 'тестовый товар (обновлён)',
        @brand = 'testbrand',
        @price = 10999.99,
        @description = 'обновлённое описание',
        @is_available = 1;

    -- удаление
    exec dbo.proc_delete_product
        @product_id = @test_product_id;
end try
begin catch
    print 'ошибка управления товарами: ' + error_message();
end catch
go

-- избранное
declare @user_id int;
declare @product_id bigint;

begin try
    set @user_id = (select top 1 user_id from dbo.users);
    set @product_id = (select top 1 product_id from dbo.products);

    -- добавление
    exec dbo.proc_add_to_favorites
        @user_id = @user_id,
        @product_id = @product_id;

    select *
    from dbo.favorites
    where user_id = @user_id;

    -- удаление
    exec dbo.proc_remove_from_favorites
        @user_id = @user_id,
        @product_id = @product_id;
end try
begin catch
    print 'ошибка работы с избранным: ' + error_message();
end catch
go

-- корзина
begin try
    -- добавление в корзину
    declare @product_id int = 120001;
    declare @user_id int = 1;
    exec dbo.proc_add_to_basket
        @user_id = @user_id,
        @product_id = @product_id,
        @quantity = 2;

    -- просмотр корзины
    exec dbo.proc_get_basket
        @user_id = @user_id;

    -- удаление из корзины
    exec dbo.proc_remove_from_basket
        @user_id = @user_id,
        @product_id = @product_id;
end try
begin catch
    print 'ошибка работы с корзиной: ' + error_message();
end catch
go

-------------------------------------------------
-- 5. заказы
-------------------------------------------------
print '5. заказы';

declare @order_id bigint;

begin try
    -- снова добавляем товар в корзину для создания заказа
    exec dbo.proc_add_to_basket @user_id, @product_id, 1;

    -- создание заказа
    exec dbo.proc_create_order
        @user_id = @user_id,
        @shipping_address = 'г. тестовый, ул. демонстрационная, д. 1';

    -- получаем id последнего заказа
    set @order_id = (select top 1 order_id
                     from dbo.orders
                     where user_id = @user_id
                     order by created_at desc);

    -- просмотр заказов пользователя
    exec dbo.proc_get_user_orders
        @user_id = @user_id;

    -- изменение статуса заказа
    exec dbo.proc_update_order_status
        @order_id = @order_id,
        @status_id = 2; -- paid
end try
begin catch
    print 'ошибка работы с заказами: ' + error_message();
end catch
go

-- фильтрация товаров
begin try
    exec dbo.proc_get_products
        @category_id = @category_id;

    exec dbo.proc_get_products
        @min_price = 45000,
        @max_price = 50000;

    exec dbo.proc_get_products
        @brand = 'samsung';
end try
begin catch
    print 'ошибка фильтрации товаров: ' + error_message();
end catch
go

-- сортировка товаров
begin try
    exec dbo.proc_get_products @sort_mode = 'price';
    exec dbo.proc_get_products @sort_mode = 'popularity';
    exec dbo.proc_get_products @sort_mode = 'new';
end try
begin catch
    print 'ошибка сортировки товаров: ' + error_message();
end catch
go

-- поиск товаров
begin try
    exec dbo.proc_search_products
        @search_text = 'машина';
end try
begin catch
    print 'ошибка поиска товаров: ' + error_message();
end catch
go