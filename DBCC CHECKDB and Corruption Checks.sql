-- =============================================
-- Part 1: Last CHECKDB per database
-- =============================================
CREATE TABLE #DBCCResults (
    ParentObject    VARCHAR(255),
    [Object]        VARCHAR(255),
    Field           VARCHAR(255),
    Value           VARCHAR(255)
);

EXEC sp_MSforeachdb '
    INSERT INTO #DBCCResults
    EXEC (''DBCC DBINFO([?]) WITH TABLERESULTS, NO_INFOMSGS'')
';

SELECT
    d.name                                          AS [Database],
    r.Value                                         AS [Last DBCC CHECKDB],
    DATEDIFF(DAY, TRY_CAST(r.Value AS DATETIME), GETDATE())
                                                    AS [Days Since Last Check],
    d.state_desc                                    AS [State],
    d.recovery_model_desc                           AS [Recovery Model]
FROM sys.databases d
LEFT JOIN #DBCCResults r
    ON r.Field = 'dbi_dbccLastKnownGood'
WHERE d.database_id > 4     -- Exclude system databases
ORDER BY TRY_CAST(r.Value AS DATETIME) ASC;

DROP TABLE #DBCCResults;

-- =============================================
-- Part 2: Suspect pages log
-- =============================================
SELECT
    DB_NAME(database_id)    AS [Database],
    file_id,
    page_id,
    event_type,
    CASE event_type
        WHEN 1 THEN '823 or 824 error (hard I/O)'
        WHEN 2 THEN 'Bad checksum'
        WHEN 3 THEN 'Torn page'
        WHEN 4 THEN 'Restored - page is good'
        WHEN 5 THEN 'Repaired by DBCC'
        WHEN 7 THEN 'Deallocated by DBCC'
    END                     AS [Event Description],
    error_count,
    last_update_date
FROM msdb.dbo.suspect_pages
ORDER BY last_update_date DESC;