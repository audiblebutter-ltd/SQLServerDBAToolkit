-- =============================================
-- Part 1: Log usage and reuse wait per database
-- =============================================
SELECT
    d.name                                  AS [Database],
    d.recovery_model_desc                   AS [Recovery Model],
    d.log_reuse_wait_desc                   AS [Log Reuse Wait],
    ROUND(ls.cntr_value * 8.0 / 1024, 2)   AS [Log Size MB],
    ROUND(lu.cntr_value * 8.0 / 1024, 2)   AS [Log Used MB],
    ROUND(
        CAST(lu.cntr_value AS FLOAT)
        / NULLIF(ls.cntr_value, 0) * 100,
        2
    )                                       AS [Log Used %]
FROM sys.databases d
JOIN sys.dm_os_performance_counters ls
    ON ls.instance_name = d.name
    AND ls.counter_name = 'Log File(s) Size (KB)'
    AND ls.object_name  LIKE '%Databases%'
JOIN sys.dm_os_performance_counters lu
    ON lu.instance_name = d.name
    AND lu.counter_name = 'Log File(s) Used Size (KB)'
    AND lu.object_name  LIKE '%Databases%'
ORDER BY [Log Used %] DESC;

-- =============================================
-- Part 2: VLF counts per database (SQL Server 2016+)
-- =============================================
CREATE TABLE #VLFInfo (
    DatabaseName    SYSNAME,
    VLFCount        INT
);

EXEC sp_MSforeachdb N'
    USE [?];
    INSERT INTO #VLFInfo (DatabaseName, VLFCount)
    SELECT DB_NAME(), COUNT(*)
    FROM sys.dm_db_log_info(DB_ID());
';

SELECT
    DatabaseName,
    VLFCount,
    CASE
        WHEN VLFCount > 1000 THEN 'CRITICAL - shrink log and regrow in one step'
        WHEN VLFCount > 500  THEN 'WARNING - monitor, plan remediation'
        ELSE 'OK'
    END                 AS [VLF Health]
FROM #VLFInfo
ORDER BY VLFCount DESC;

DROP TABLE #VLFInfo;