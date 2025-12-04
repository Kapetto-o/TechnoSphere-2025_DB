use master
go


if exists (select * from sys.databases where name = 'TechnoSphere_2025')
begin
    alter database TechnoSphere_2025 set single_user with rollback immediate;
    drop database TechnoSphere_2025;
end