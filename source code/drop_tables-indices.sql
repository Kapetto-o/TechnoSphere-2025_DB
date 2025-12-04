use TechnoSphere_2025
go

if exists (select * from sys.indexes where name = 'idx_products_category_price' and object_id = object_id('products'))
    drop index idx_products_category_price on products;

if exists (select * from sys.indexes where name = 'idx_products_brand' and object_id = object_id('products'))
    drop index idx_products_brand on products;

if exists (select * from sys.indexes where name = 'idx_products_price' and object_id = object_id('products'))
    drop index idx_products_price on products;

if exists (select * from sys.indexes where name = 'idx_products_name_fulltext' and object_id = object_id('products'))
    drop index idx_products_name_fulltext on products;

if exists (select * from sys.indexes where name = 'idx_order_items_orderid' and object_id = object_id('order_items'))
    drop index idx_order_items_orderid on order_items;

if exists (select * from sys.indexes where name = 'idx_basket_user' and object_id = object_id('basket_items'))
    drop index idx_basket_user on basket_items;

if exists (select * from sys.indexes where name = 'idx_favorites_user' and object_id = object_id('favorites'))
    drop index idx_favorites_user on favorites;

if exists (select * from sys.indexes where name = 'idx_reviews_product' and object_id = object_id('product_reviews'))
    drop index idx_reviews_product on product_reviews;

    if exists (select * from sys.objects where object_id = object_id('product_reviews') and type = 'u')
    drop table product_reviews;

if exists (select * from sys.objects where object_id = object_id('order_items') and type = 'u')
    drop table order_items;

if exists (select * from sys.objects where object_id = object_id('orders') and type = 'u')
    drop table orders;

if exists (select * from sys.objects where object_id = object_id('order_statuses') and type = 'u')
    drop table order_statuses;

if exists (select * from sys.objects where object_id = object_id('basket_items') and type = 'u')
    drop table basket_items;

if exists (select * from sys.objects where object_id = object_id('favorites') and type = 'u')
    drop table favorites;

if exists (select * from sys.objects where object_id = object_id('product_specifications') and type = 'u')
    drop table product_specifications;

if exists (select * from sys.objects where object_id = object_id('specification_types') and type = 'u')
    drop table specification_types;

if exists (select * from sys.objects where object_id = object_id('products') and type = 'u')
    drop table products;

if exists (select * from sys.objects where object_id = object_id('categories') and type = 'u')
    drop table categories;

if exists (select * from sys.objects where object_id = object_id('users') and type = 'u')
    drop table users;

if exists (select * from sys.objects where object_id = object_id('roles') and type = 'u')
    drop table roles;