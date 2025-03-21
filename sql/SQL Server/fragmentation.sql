-- https://learn.microsoft.com/zh-cn/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-physical-stats-transact-sql?view=sql-server-ver16

-- region 查询碎片化率
SELECT DB_NAME(stats.database_id)         AS 数据库名称,
       OBJECT_NAME(stats.object_id)       AS 表名称,
       indexes.name                       AS 索引名称,
       stats.index_type_desc              AS 索引类型,
       stats.avg_fragmentation_in_percent AS 平均碎片百分比,
       stats.page_count                   AS 分页数
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') stats
         INNER JOIN
     sys.indexes indexes ON stats.object_id = indexes.object_id AND stats.index_id = indexes.index_id
WHERE stats.avg_fragmentation_in_percent > 0
ORDER BY stats.avg_fragmentation_in_percent DESC;
-- endregion
