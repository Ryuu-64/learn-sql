drop table if exists table_without_primary_key
create table table_without_primary_key
(
    id bigint
)

insert into learn_sql_server_2017.dbo.table_without_primary_key(id) values (1);
insert into learn_sql_server_2017.dbo.table_without_primary_key(id) values (2);
insert into learn_sql_server_2017.dbo.table_without_primary_key(id) values (3);
