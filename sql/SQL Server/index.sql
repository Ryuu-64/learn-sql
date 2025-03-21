-- https://learn.microsoft.com/zh-cn/sql/relational-databases/system-dynamic-management-views/sys-dm-db-missing-index-details-transact-sql?view=sql-server-ver16
-- https://learn.microsoft.com/zh-cn/sql/relational-databases/system-dynamic-management-views/sys-dm-db-missing-index-groups-transact-sql?view=sql-server-ver16
-- https://learn.microsoft.com/zh-cn/sql/relational-databases/system-dynamic-management-views/sys-dm-db-missing-index-group-stats-transact-sql?view=sql-server-ver16

-- region 高影响缺失索引信息查询
SELECT details.statement          AS 表名,
       details.equality_columns   AS 等值列,
       details.inequality_columns AS 不等值列,
       details.included_columns   AS 包含列,
       stats.avg_user_impact      AS 平均百分比收益,
       stats.user_seeks           AS seek触发次数,
       stats.user_scans           AS scan触发次数
FROM sys.dm_db_missing_index_details details
         JOIN sys.dm_db_missing_index_groups groups ON details.index_handle = groups.index_handle
         JOIN sys.dm_db_missing_index_group_stats stats ON groups.index_group_handle = stats.group_handle
ORDER BY stats.avg_user_impact DESC;
-- endregion

-- region 查询高影响缺失索引创建语句
SELECT 'CREATE INDEX ' +
       '[idx_' + OBJECT_NAME(details.object_id) + '_' + CONVERT(VARCHAR, details.index_handle) + ']' +
       ' ON ' + details.statement +
       ' (' +
       COALESCE(details.equality_columns, '') +
       IIF(details.equality_columns IS NOT NULL AND details.inequality_columns IS NOT NULL, ',', '') +
       COALESCE(details.inequality_columns, '') +
       ')' +
       IIF(details.included_columns IS NOT NULL, ' INCLUDE (' + details.included_columns + ')', '') +
       ';'
                             AS 索引创建语句,
       stats.avg_user_impact AS 平均百分比收益,
       stats.user_seeks      AS seek触发次数,
       stats.user_scans      AS scan触发次数
FROM sys.dm_db_missing_index_details details
         JOIN sys.dm_db_missing_index_groups groups ON details.index_handle = groups.index_handle
         JOIN sys.dm_db_missing_index_group_stats stats ON groups.index_group_handle = stats.group_handle
WHERE stats.avg_user_impact > 50
ORDER BY stats.avg_user_impact DESC;
-- endregion
