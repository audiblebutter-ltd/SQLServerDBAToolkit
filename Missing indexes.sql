-- =============================================
-- Part 1: Missing indexes (by benefit score)
-- =============================================
SELECT TOP 25
    DB_NAME()                                   AS [Database],
    OBJECT_SCHEMA_NAME(mid.object_id)           AS [Schema],
    OBJECT_NAME(mid.object_id)                  AS [Table],
    ROUND(
        migs.avg_total_user_cost
        * migs.avg_user_impact
        * (migs.user_seeks + migs.user_scans),
        2
    )                                           AS [Index Benefit Score],
    migs.user_seeks                             AS [Seeks],
    migs.user_scans                             AS [Scans],
    migs.last_user_seek                         AS [Last Seek],
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    'CREATE INDEX IX_' + OBJECT_NAME(mid.object_id) + '_Missing'
        + ' ON ' + mid.statement
        + ' (' + ISNULL(mid.equality_columns, '')
        + CASE
            WHEN mid.inequality_columns IS NOT NULL
             AND mid.equality_columns   IS NOT NULL THEN ','
            ELSE ''
          END
        + ISNULL(mid.inequality_columns, '') + ')'
        + ISNULL(' INCLUDE (' + mid.included_columns + ')', '')
                                                AS [Suggested CREATE INDEX]
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups mig
    ON mid.index_handle = mig.index_handle
JOIN sys.dm_db_missing_index_group_stats migs
    ON mig.index_group_handle = migs.group_handle
WHERE mid.database_id = DB_ID()
ORDER BY [Index Benefit Score] DESC;

-- =============================================
-- Part 2: Unused indexes (reads = 0, writes > 0)
-- =============================================
SELECT
    OBJECT_SCHEMA_NAME(i.object_id)             AS [Schema],
    OBJECT_NAME(i.object_id)                    AS [Table],
    i.name                                      AS [Index Name],
    i.type_desc                                 AS [Type],
    ISNULL(ius.user_seeks, 0)                   AS [Seeks],
    ISNULL(ius.user_scans, 0)                   AS [Scans],
    ISNULL(ius.user_lookups, 0)                 AS [Lookups],
    ISNULL(ius.user_updates, 0)                 AS [Writes],
    ius.last_user_update                        AS [Last Write],
    'DROP INDEX ' + QUOTENAME(i.name)
        + ' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(i.object_id))
        + '.' + QUOTENAME(OBJECT_NAME(i.object_id))
                                                AS [Drop Script]
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius
    ON i.object_id     = ius.object_id
    AND i.index_id     = ius.index_id
    AND ius.database_id = DB_ID()
WHERE i.type                                    > 0
  AND i.is_primary_key                          = 0
  AND i.is_unique_constraint                    = 0
  AND OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1
  AND ISNULL(ius.user_seeks, 0)                 = 0
  AND ISNULL(ius.user_scans, 0)                 = 0
  AND ISNULL(ius.user_lookups, 0)               = 0
ORDER BY ISNULL(ius.user_updates, 0) DESC;