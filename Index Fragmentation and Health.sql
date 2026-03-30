SELECT
    DB_NAME()                                   AS [Database],
    OBJECT_SCHEMA_NAME(ps.object_id)            AS [Schema],
    OBJECT_NAME(ps.object_id)                   AS [Table],
    i.name                                      AS [Index Name],
    i.type_desc                                 AS [Index Type],
    ps.index_id,
    ps.partition_number,
    ps.page_count,
    ROUND(ps.avg_fragmentation_in_percent, 2)   AS [Fragmentation %],
    ROUND(ps.avg_page_space_used_in_percent, 2) AS [Page Fullness %],
    ps.record_count                             AS [Row Count],
    CASE
        WHEN ps.avg_fragmentation_in_percent >= 30 THEN 'REBUILD'
        WHEN ps.avg_fragmentation_in_percent >= 10 THEN 'REORGANIZE'
        ELSE 'OK'
    END                                         AS [Recommended Action],
    'ALTER INDEX ' + QUOTENAME(i.name)
        + ' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(ps.object_id))
        + '.' + QUOTENAME(OBJECT_NAME(ps.object_id))
        + CASE
            WHEN ps.avg_fragmentation_in_percent >= 30 THEN ' REBUILD;'
            WHEN ps.avg_fragmentation_in_percent >= 10 THEN ' REORGANIZE;'
            ELSE ' -- No action needed'
          END                                   AS [Action Script]
FROM sys.dm_db_index_physical_stats(
    DB_ID(), NULL, NULL, NULL, 'LIMITED'
) ps
JOIN sys.indexes i
    ON ps.object_id = i.object_id
   AND ps.index_id  = i.index_id
WHERE ps.page_count > 1000      -- Only objects with meaningful page counts
  AND ps.index_id   > 0         -- Exclude heaps
ORDER BY ps.avg_fragmentation_in_percent DESC;