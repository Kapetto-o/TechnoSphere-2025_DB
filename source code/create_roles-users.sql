use TechnoSphere_2025
go

create role admin_role
create role user_role

create login tech_admin with password = 'Admin1234!'
create login tech_user with password = 'User1234!'

create user admin_user for login tech_admin
create user app_user for login tech_user

exec sp_addrolemember 'admin_role', 'admin_user'
exec sp_addrolemember 'user_role', 'app_user'