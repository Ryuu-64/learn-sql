-- 查询所有分区方案的基本信息 todo 需要测试
SELECT name        AS [分区方案名称],
       type_desc   AS [类型描述],
       function_id AS [关联的分区函数ID]
FROM sys.partition_schemes;
