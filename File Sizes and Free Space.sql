SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#logspace')   IS NOT NULL DROP TABLE #logspace;
IF OBJECT_ID('tempdb..#dataspace')  IS NOT NULL DROP TABLE #dataspace;

CREATE TABLE #logspace
(
    DatabaseName sysname NOT NULL,
    LogSizeMB    decimal(18,2) NOT NULL,
    LogUsedPct   decimal(9,2)  NOT NULL,
    Status       int           NOT NULL
);

CREATE TABLE #dataspace
(
    database_name sysname NOT NULL,
    data_size_mb  decimal(18,2) NOT NULL,
    data_used_mb  decimal(18,2) NOT NULL,
    data_free_mb  decimal(18,2) NOT NULL
);

-- Log: one row per database
INSERT INTO #logspace (DatabaseName, LogSizeMB, LogUsedPct, Status)
EXEC ('DBCC SQLPERF(LOGSPACE) WITH NO_INFOMSGS;');

-- Data: must run in each DB context to use FILEPROPERTY
DECLARE @db sysname;
DECLARE @sql nvarchar(max);

DECLARE dbs CURSOR FAST_FORWARD FOR
SELECT name
FROM sys.databases
WHERE state_desc = 'ONLINE'
  AND name NOT IN ('tempdb');  -- add tempdb if you want

OPEN dbs;
FETCH NEXT FROM dbs INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
    USE ' + QUOTENAME(@db) + N';

    INSERT INTO #dataspace (database_name, data_size_mb, data_used_mb, data_free_mb)
    SELECT
        DB_NAME() AS database_name,
        SUM(df.size) * 8.0 / 1024.0 AS data_size_mb,
        SUM(CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS bigint)) * 8.0 / 1024.0 AS data_used_mb,
        SUM(df.size - CAST(FILEPROPERTY(df.name, ''SpaceUsed'') AS bigint)) * 8.0 / 1024.0 AS data_free_mb
    FROM sys.database_files df
    WHERE df.type_desc = ''ROWS'';
    ';

    EXEC sys.sp_executesql @sql;

    FETCH NEXT FROM dbs INTO @db;
END

CLOSE dbs;
DEALLOCATE dbs;

-- Final: one row per database, includes free space for data + log
SELECT
    d.database_name,
    d.data_size_mb,
    d.data_used_mb,
    d.data_free_mb,
    ls.LogSizeMB AS log_size_mb,
    CAST(ls.LogSizeMB * (ls.LogUsedPct/100.0) AS decimal(18,2)) AS log_used_mb,
    CAST(ls.LogSizeMB * (1 - (ls.LogUsedPct/100.0)) AS decimal(18,2)) AS log_free_mb,
    ls.LogUsedPct AS log_used_pct
FROM #dataspace d
LEFT JOIN #logspace ls
    ON ls.DatabaseName = d.database_name
ORDER BY d.database_name;
