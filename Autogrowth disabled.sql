-- =============================================
-- Part 1: Backup size history (last 6 months)
-- =============================================
SELECT
    s.database_name                                 AS [Database],
    CAST(s.backup_start_date AS DATE)               AS [Backup Date],
    ROUND(s.backup_size / 1048576.0, 2)             AS [Backup Size MB],
    ROUND(s.compressed_backup_size / 1048576.0, 2)  AS [Compressed MB]
FROM msdb.dbo.backupset s
WHERE s.type = 'D'      -- Full backups only
  AND s.backup_start_date >= DATEADD(MONTH, -6, GETDATE())
ORDER BY s.database_name, s.backup_start_date;

-- =============================================
-- Part 2: Current file sizes and autogrowth
-- =============================================
SELECT
    DB_NAME(f.database_id)                          AS [Database],
    f.name                                          AS [File Name],
    f.type_desc                                     AS [File Type],
    ROUND(f.size * 8.0 / 1024, 2)                  AS [Allocated MB],
    ROUND(
        FILEPROPERTY(
            (SELECT name FROM sys.databases WHERE database_id = f.database_id),
            'SpaceUsed'
        ) * 8.0 / 1024,
        2
    )                                               AS [Used MB (approx)],
    CASE f.is_percent_growth
        WHEN 1 THEN CAST(f.growth AS VARCHAR) + '%'
        ELSE CAST(f.growth * 8 / 1024 AS VARCHAR) + ' MB'
    END                                             AS [Auto Growth Setting],
    CASE
        WHEN f.growth = 0 THEN 'WARNING: Autogrowth disabled'
        WHEN f.is_percent_growth = 0 AND f.growth * 8 / 1024 < 256
            THEN 'WARNING: Small fixed autogrowth (' + CAST(f.growth * 8 / 1024 AS VARCHAR) + ' MB)'
        ELSE 'OK'
    END                                             AS [Autogrowth Health],
    f.max_size,
    f.physical_name
FROM sys.master_files f
ORDER BY DB_NAME(f.database_id), f.type_desc;