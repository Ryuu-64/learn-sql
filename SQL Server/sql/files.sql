-- https://learn.microsoft.com/zh-cn/sql/relational-databases/system-catalog-views/sys-master-files-transact-sql?view=sql-server-ver16
-- https://learn.microsoft.com/zh-cn/sql/relational-databases/system-dynamic-management-views/sys-dm-os-volume-stats-transact-sql?view=azuresqldb-current
-- https://learn.microsoft.com/zh-cn/sql/relational-databases/system-catalog-views/sys-indexes-transact-sql?view=azuresqldb-current
-- https://learn.microsoft.com/zh-cn/sql/relational-databases/system-catalog-views/sys-partitions-transact-sql?view=azuresqldb-current

-- region 查看磁盘剩余空间
SELECT files.name                        AS [名称],
       files.physical_name               AS [物理名称],
-- 0 = 行
-- 1 = 日志
-- 2 = FILESTREAM
-- 3 = 仅用于信息性目的标识。 不支持。 不保证以后的兼容性。
-- 4 = 全文（早于 SQL Server 2008（10.0.x）;在 SQL Server 2008（10.0.x）及更高版本中升级到或创建的全文目录报告文件类型 0。）
       files.type                        AS [类型],
       files.type_desc                   AS [类型描述],
       total_bytes / 1024.0 / 1024.0     AS [总空间(MB)],
       available_bytes / 1024.0 / 1024.0 AS [剩余空间(MB)]
FROM sys.master_files files
         CROSS APPLY sys.dm_os_volume_stats(files.database_id, files.file_id);
-- endregion

-- region 检查数据库文件大小，排除系统库
SELECT DB_NAME(database_id) AS [数据库名],
       name                 AS [逻辑文件名],
       size * 8.0 / 1024.0  AS [当前大小(MB)] -- size 以页为单位，一个页的大小为8KB
FROM sys.master_files
WHERE database_id > 4;
-- endregion

-- region 查询数据表及索引使用空间（按索引分开）
SELECT OBJECT_NAME(partitions.object_id)                            AS 表名称,
       indexes.name                                                 AS [索引名称],
       partitions.index_id                                          AS [索引id],     -- 0 = 堆, 1 = 聚集索引, 2 或更高 = 非聚集索引
       partitions.rows                                              AS [总行数],
       units.total_pages * 8.0 / 1024.0                             AS [总空间(MB)], -- size 以页为单位，一个页的大小为8KB
       units.used_pages * 8.0 / 1024.0                              AS [已使用空间(MB)],
       (units.used_pages * 8.0 * 1024) / NULLIF(partitions.rows, 0) AS [平均每行使用空间(B)]
FROM sys.partitions partitions
         JOIN sys.allocation_units units
              ON partitions.partition_id = units.container_id
         LEFT JOIN sys.indexes indexes
                   ON partitions.object_id = indexes.object_id
                       AND partitions.index_id = indexes.index_id
WHERE partitions.object_id = OBJECT_ID('l_gold_upd')
  AND units.type IN (1, 3);
-- endregion

-- region 查询数据表及索引使用空间（数据表和索引合并）
SELECT OBJECT_NAME(MAX(partitions.object_id))                                 AS 表名称,
       MAX(partitions.rows)                                                   AS [总行数],
       SUM(units.total_pages) * 8.0 / 1024.0                                  AS [总空间(MB)],
       SUM(units.used_pages) * 8.0 / 1024.0                                   AS [已使用空间(MB)],
       (SUM(units.used_pages) * 8.0 * 1024) / NULLIF(MAX(partitions.rows), 0) AS [平均每行使用空间(B)]
FROM sys.partitions partitions
         JOIN sys.allocation_units units
              ON partitions.partition_id = units.container_id
         LEFT JOIN sys.indexes indexes
                   ON partitions.object_id = indexes.object_id
                       AND partitions.index_id = indexes.index_id -- 关联索引名称
WHERE partitions.object_id = OBJECT_ID('l_gold_upd')
  AND units.type IN (1, 3);
-- endregion
