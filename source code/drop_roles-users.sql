use TechnoSphere_2025;
go

if exists (select * from sys.database_principals where name = 'admin_user')
begin
    exec sp_droprolemember 'admin_role', 'admin_user';
end

if exists (select * from sys.database_principals where name = 'app_user')
begin
    exec sp_droprolemember 'user_role', 'app_user';
end

if exists (select * from sys.database_principals where name = 'admin_user')
    drop user admin_user;

if exists (select * from sys.database_principals where name = 'app_user')
    drop user app_user;

if exists (select * from sys.database_principals where name = 'admin_role' and type = 'r')
    drop role admin_role;

if exists (select * from sys.database_principals where name = 'user_role' and type = 'r')
    drop role user_role;

use master;

if exists (select * from sys.server_principals where name = 'tech_admin')
    drop login tech_admin;

if exists (select * from sys.server_principals where name = 'tech_user')
    drop login tech_user;