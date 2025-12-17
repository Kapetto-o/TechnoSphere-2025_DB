use TechnoSphere_2025_DB;
go

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