use master;
go

-- логины
create login technosphere_admin
with password = 'AdminStrongPass123!';

create login technosphere_user
with password = 'UserStrongPass123!';
go


use TechnoSphere_2025_DB;
go

alter database TechnoSphere_2025_DB
set multi_user;
go

-- пользователи и роли
create user admin_user for login technosphere_admin;
create user app_user   for login technosphere_user;
go

create role TechnoSphereAdmin;
create role TechnoSphereUser;
go

alter role TechnoSphereAdmin add member admin_user;
alter role TechnoSphereUser  add member app_user;
go

-- права пользователя
grant execute on proc_register_user to TechnoSphereUser;
grant execute on proc_login_user to TechnoSphereUser;
grant execute on proc_get_products to TechnoSphereUser;
grant execute on proc_search_products to TechnoSphereUser;
grant execute on proc_get_product_by_id to TechnoSphereUser;
grant execute on proc_add_to_favorites to TechnoSphereUser;
grant execute on proc_remove_from_favorites to TechnoSphereUser;
grant execute on proc_add_to_basket to TechnoSphereUser;
grant execute on proc_remove_from_basket to TechnoSphereUser;
grant execute on proc_get_basket to TechnoSphereUser;
grant execute on proc_create_order to TechnoSphereUser;
grant execute on proc_get_user_orders to TechnoSphereUser;
grant execute on dbo.proc_get_categories to TechnoSphereUser;
grant execute on dbo.proc_get_favorites to TechnoSphereUser;
grant execute on dbo.proc_get_order_items to TechnoSphereUser;
go

deny execute on proc_add_product to TechnoSphereUser;
deny execute on proc_update_product to TechnoSphereUser;
deny execute on proc_delete_product to TechnoSphereUser;
deny execute on proc_update_order_status to TechnoSphereUser;
deny execute on proc_get_all_orders to TechnoSphereUser;
deny execute on proc_add_category to TechnoSphereUser;
deny execute on proc_update_category to TechnoSphereUser;
deny execute on proc_delete_category to TechnoSphereUser;
deny execute on proc_unblock_user to TechnoSphereUser;
deny execute on proc_delete_user to TechnoSphereUser;
deny execute on proc_export_table_to_json to TechnoSphereUser;
deny execute on proc_import_products_from_json to TechnoSphereUser;
deny execute on proc_get_all_users to TechnoSphereUser;
go

-- права администратора
grant execute on proc_add_product to TechnoSphereAdmin;
grant execute on proc_update_product to TechnoSphereAdmin;
grant execute on proc_delete_product to TechnoSphereAdmin;
grant execute on proc_update_order_status to TechnoSphereAdmin;
grant execute on proc_get_all_orders to TechnoSphereAdmin;
grant execute on proc_add_category to TechnoSphereAdmin;
grant execute on proc_update_category to TechnoSphereAdmin;
grant execute on proc_delete_category to TechnoSphereAdmin;
grant execute on proc_block_user to TechnoSphereAdmin;
grant execute on proc_unblock_user to TechnoSphereAdmin;
grant execute on proc_delete_user to TechnoSphereAdmin;
grant execute on proc_export_table_to_json to TechnoSphereAdmin;
grant execute on proc_import_products_from_json to TechnoSphereAdmin;
grant execute on dbo.proc_get_categories to TechnoSphereAdmin;
grant execute on dbo.proc_get_favorites to TechnoSphereAdmin;
grant execute on dbo.proc_get_all_users to TechnoSphereAdmin;
grant execute on dbo.proc_get_order_items to TechnoSphereAdmin;
grant execute on proc_search_products to TechnoSphereAdmin;
go