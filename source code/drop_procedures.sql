use TechnoSphere_2025
go

if exists (select * from sys.objects where object_id = object_id('proc_add_product') and type = 'p')
    drop procedure proc_add_product;

if exists (select * from sys.objects where object_id = object_id('proc_update_product') and type = 'p')
    drop procedure proc_update_product;

if exists (select * from sys.objects where object_id = object_id('proc_delete_product') and type = 'p')
    drop procedure proc_delete_product;

if exists (select * from sys.objects where object_id = object_id('proc_add_favorite') and type = 'p')
    drop procedure proc_add_favorite;

if exists (select * from sys.objects where object_id = object_id('proc_remove_favorite') and type = 'p')
    drop procedure proc_remove_favorite;

if exists (select * from sys.objects where object_id = object_id('proc_add_to_basket') and type = 'p')
    drop procedure proc_add_to_basket;

if exists (select * from sys.objects where object_id = object_id('proc_remove_from_basket') and type = 'p')
    drop procedure proc_remove_from_basket;

if exists (select * from sys.objects where object_id = object_id('proc_create_order_from_basket') and type = 'p')
    drop procedure proc_create_order_from_basket;

if exists (select * from sys.objects where object_id = object_id('proc_change_order_status') and type = 'p')
    drop procedure proc_change_order_status;

if exists (select * from sys.objects where object_id = object_id('proc_search_products') and type = 'p')
    drop procedure proc_search_products;

if exists (select * from sys.objects where object_id = object_id('proc_export_product_json') and type = 'p')
    drop procedure proc_export_product_json;

if exists (select * from sys.objects where object_id = object_id('proc_import_products_from_json') and type = 'p')
    drop procedure proc_import_products_from_json;