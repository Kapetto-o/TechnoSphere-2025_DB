use TechnoSphere_2025_DB;
go

--------------------------------------------
--1. РЕЗЕРВНОЕ КОПИРОВАНИЕ И ВОССТАНОВЛЕНИЕ
--------------------------------------------
-- Резервное копирование
alter database TechnoSphere_2025_DB
set recovery full;
go

backup database TechnoSphere_2025_DB
to disk = 'C:\DataBase\TechnoSphere_2025_DB\technosphere_full.bak'
with
    init,
    name = 'TechnoSphere full backup',
    stats = 10;
go

backup database TechnoSphere_2025_DB
to disk = 'C:\DataBase\TechnoSphere_2025_DB\technosphere_diff.bak'
with
    differential,
    init,
    name = 'TechnoSphere differential backup',
    stats = 10;
go

-- Восстановление
use master;
go

alter database TechnoSphere_2025_DB
set single_user
with rollback immediate;
go

restore database TechnoSphere_2025_DB
from disk = 'C:\DataBase\TechnoSphere_2025_DB\technosphere_full.bak'
with
    replace,
    norecovery;
go

restore database TechnoSphere_2025_DB
from disk = 'C:\DataBase\TechnoSphere_2025_DB\technosphere_diff.bak'
with
    recovery;
go

alter database TechnoSphere_2025_DB
set multi_user;
go

use TechnoSphere_2025_DB;
go
---------------------------
--2. ЭКСПОРТ И ИМПОРТ JSON
---------------------------
-- Экспорт
exec dbo.proc_export_table_to_json
    @table_name = 'products';
go

-- Удаление товаров
delete from products;
go

select count(*) as products_after_delete from products;
go

-- Импорт
exec dbo.proc_import_products_from_json
    @file_path = 'C:\DataBase\TechnoSphere_2025_DB\products.json';
go

select count(*) as products_after_import from products;
go

------------------
--3. ПОЛЬЗОВАТЕЛЬ
------------------
-- Регистрация
exec dbo.proc_register_user
    @login = 'test_user',
    @email = 'test_user@mail.com',
    @password = 'User123!';
go

-- Авторизация
exec dbo.proc_login_user
    @login = 'test_user',
    @password = 'User123!';
go

-- Просмотр всего каталога
exec dbo.proc_get_products;
go

-- Просмотр категорий
exec dbo.proc_get_categories;

-- Фильтрация
exec dbo.proc_get_products
    @category_id = 1;
go

exec dbo.proc_get_products
    @brand = 'lg';
go

exec dbo.proc_get_products
    @min_price = 20000,
    @max_price = 60000;
go

-- Сортировка
exec dbo.proc_get_products
    @sort_mode = 'price';
go

exec dbo.proc_get_products
    @sort_mode = 'popularity';
go

exec dbo.proc_get_products
    @sort_mode = 'new';
go

-- Поиск товаров
exec dbo.proc_search_products
    @search_text = 'смартфон samsung galaxy s22 108040';
go

-- Выбор определённого товара
exec dbo.proc_get_product_by_id
    @product_id = 1680096;
go

-- Добавить \ Удалить товар в избранное
exec dbo.proc_add_to_favorites
    @user_id = 3,
    @product_id = 1745499;
go

exec dbo.proc_get_favorites
    @user_id = 3;
go

exec dbo.proc_remove_from_favorites
    @user_id = 3,
    @product_id = 1772924;
go

-- Добавить \ Удалить товар в корзину
exec dbo.proc_add_to_basket
    @user_id = 3,
    @product_id = 1745499,
    @quantity = 1;
go

exec dbo.proc_get_basket
    @user_id = 3;
go

exec dbo.proc_remove_from_basket
    @user_id = 3,
    @product_id = 1772924;
go

-- Оформление заказа
exec dbo.proc_create_order
    @user_id = 3,
    @shipping_address = 'г. Минск, ул. Панченко, д. 1';
go

-- Просмотреть все заказы пользователя
exec dbo.proc_get_user_orders
    @user_id = 3;
go

-------------------
--4. АДМИНИСТРАТОР
-------------------
-- Авторизация
exec dbo.proc_login_user
    @login = 'admin',
    @password = 'AdminStrongPass123!';
go

-- Добавление нового товара
exec dbo.proc_add_product
    @category_id = 1,
    @name = 'тестовый товар',
    @brand = 'brend',
    @price = 55555.55,
    @description = 'добавлен сегодня',
    @is_available = 1;
go

-- Поиск товара
exec dbo.proc_search_products
    @search_text = 'тестовый товар';
go

-- Обновление товара
exec dbo.proc_update_product
    @product_id = 1800001,
    @category_id = 1,
    @name = 'обновлённый тестовый товар',
    @brand = 'brend',
    @price = 60000,
    @description = 'обновление',
    @is_available = 1;
go

-- Поиск товара
exec dbo.proc_search_products
    @search_text = 'обновлённый тестовый товар';
go

-- Удаление товара
exec dbo.proc_delete_product
    @product_id = 1800001;
go

-- Поиск товара
exec dbo.proc_search_products
    @search_text = 'обновлённый тестовый товар';
go

-- Просмотр заказов и обновление статуса
exec dbo.proc_get_all_orders;
go

exec dbo.proc_update_order_status
    @order_id = 1,
    @status_id = 2;
go

-- Добавление \ Удаление категорий
exec dbo.proc_add_category
    @category_name = 'ноутбуки',
    @description = 'портативные компьютеры';
go

exec dbo.proc_get_categories;
go

exec dbo.proc_update_category
    @category_id = 6,
    @category_name = 'ноутбуки новые',
    @description = 'обновлено';
go

-- Блокировка \ Разблокировка \ Удаление пользователя
exec dbo.proc_get_all_users;

exec dbo.proc_block_user
    @user_id = 3;
go

exec dbo.proc_unblock_user
    @user_id = 3;
go

exec dbo.proc_delete_user
    @user_id = 3;
go