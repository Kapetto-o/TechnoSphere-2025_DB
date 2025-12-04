use master
go

create database TechnoSphere_2025
on primary (
    name = 'TechnoSphere-2025_DB',
    filename = 'D:\Programs\SQL Server 2025\MSSQL17.SQLEXPRESS\MSSQL\DATA\TechnoSphere-2025_DB.mdf',
    size = 50mb,
    filegrowth = 50mb
)
log on (
    name = 'TechnoSphere-2025_DB_LOG',
    filename = 'D:\Programs\SQL Server 2025\MSSQL17.SQLEXPRESS\MSSQL\DATA\TechnoSphere-2025_DB_LOG.ldf',
    size = 20mb,
    filegrowth = 20mb
)