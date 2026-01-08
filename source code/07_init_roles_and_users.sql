use TechnoSphere_2025_DB;
go

set nocount on;

-- 1. роли приложения
if not exists (select 1 from roles where role_name = 'admin')
    insert into roles (role_name) values ('admin');

if not exists (select 1 from roles where role_name = 'user')
    insert into roles (role_name) values ('user');

if not exists (select 1 from roles where role_name = 'blocked')
    insert into roles (role_name) values ('blocked');
go

-- 2. администратор
if not exists (select 1 from users where login = 'admin')
begin
    insert into users (
        role_id,
        login,
        password_hash,
        email
    )
    select
        r.role_id,
        'admin',
        'HASHED_ADMIN_PASSWORD',
        'admin@technosphere.local'
    from roles r
    where r.role_name = 'admin';
end;

-- 3. обычный пользователь
if not exists (select 1 from users where login = 'user')
begin
    insert into users (
        role_id,
        login,
        password_hash,
        email
    )
    select
        r.role_id,
        'user',
        'HASHED_USER_PASSWORD',
        'user@technosphere.local'
    from roles r
    where r.role_name = 'user';
end;
go