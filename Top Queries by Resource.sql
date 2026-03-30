-- =============================================
-- Part 1: Top 25 by total CPU
-- =============================================
SELECT TOP 25
    qs.total_worker_time / 1000000.0                AS [Total CPU (sec)],
    qs.total_worker_time / qs.execution_count / 1000.0
                                                    AS [Avg CPU (ms)],
    qs.execution_count,
    qs.total_logical_reads / qs.execution_count     AS [Avg Logical Reads],
    qs.total_physical_reads / qs.execution_count    AS [Avg Physical Reads],
    qs.total_elapsed_time / qs.execution_count / 1000.0
                                                    AS [Avg Duration (ms)],
    qs.creation_time                                AS [Plan Compiled],
    DB_NAME(qt.dbid)                                AS [Database],
    SUBSTRING(
        qt.text,
        (qs.statement_start_offset / 2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset) / 2) + 1
    )                                               AS [Statement]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_worker_time DESC;

-- =============================================
-- Part 2: Top 25 by logical reads (I/O pressure)
-- =============================================
SELECT TOP 25
    qs.total_logical_reads / qs.execution_count     AS [Avg Logical Reads],
    qs.total_logical_reads                          AS [Total Logical Reads],
    qs.execution_count,
    qs.total_worker_time / qs.execution_count / 1000.0
                                                    AS [Avg CPU (ms)],
    qs.total_elapsed_time / qs.execution_count / 1000.0
                                                    AS [Avg Duration (ms)],
    DB_NAME(qt.dbid)                                AS [Database],
    SUBSTRING(
        qt.text,
        (qs.statement_start_offset / 2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset) / 2) + 1
    )                                               AS [Statement]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_logical_reads DESC;