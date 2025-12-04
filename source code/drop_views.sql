use TechnoSphere_2025
go

if exists (select * from sys.views where object_id = object_id('vw_products_full'))
    drop view vw_products_full;

if exists (select * from sys.views where object_id = object_id('vw_top_products'))
    drop view vw_top_products;