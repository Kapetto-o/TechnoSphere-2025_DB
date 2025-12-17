use TechnoSphere_2025_DB
go

select name, recovery_model_desc
from sys.databases
where name = 'TechnoSphere_2025_DB';

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

-- Вносим правки для видимости differential backup
update dbo.products
set price = price * 1.05
where product_id % 100 = 0;
go

backup database TechnoSphere_2025_DB
to disk = 'C:\DataBase\TechnoSphere_2025_DB\technosphere_diff.bak'
with
    differential,
    init,
    name = 'TechnoSphere differential backup',
    stats = 10;
go

-- Симуляция потери данных:
delete from dbo.products
where product_id > 100000;

select count(*) from dbo.products;
go

-- Восстановление БД (в master)
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

-- Проверяем что всё восстановилось:
select count(*) as total_products
from dbo.products;