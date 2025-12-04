use TechnoSphere_2025
go

if exists (select * from sys.triggers where name = 'trg_product_reviews_after_change')
    drop trigger trg_product_reviews_after_change;

if exists (select * from sys.triggers where name = 'trg_order_items_after_change')
    drop trigger trg_order_items_after_change;