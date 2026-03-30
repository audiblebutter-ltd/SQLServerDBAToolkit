-- =============================================
-- Part 1: CPU history (last 20 samples ~20 min)
-- =============================================
SELECT TOP 20
    record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int')
                                                    AS [SQL CPU %],
    record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int')
                                                    AS [System Idle %],
    100
        - record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int')
        - record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int')
                                                    AS [Other Process CPU %],
    DATEADD(
        ms,
        -1 * ((SELECT cpu_ticks / (cpu_ticks / ms_ticks) FROM sys.dm_os_sys_info) - [timestamp]),
        GETDATE()
    )                                               AS [Sample Time]
FROM (
    SELECT TOP 20
        [timestamp],
        CONVERT(xml, record) AS record
    FROM sys.dm_os_ring_buffers
    WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
      AND record LIKE '%<SystemHealth>%'
    ORDER BY [timestamp] DESC
) x
ORDER BY [Sample Time] DESC;

-- =============================================
-- Part 2: Memory state
-- =============================================
SELECT
    physical_memory_in_use_kb / 1024            AS [SQL Memory Used MB],
    page_fault_count                            AS [Page Faults],
    memory_utilization_percentage               AS [Memory Utilization %]
FROM sys.dm_os_process_memory;

SELECT
    total_physical_memory_kb / 1024             AS [Total Physical Memory MB],
    available_physical_memory_kb / 1024         AS [Available Physical Memory MB],
    system_memory_state_desc                    AS [Memory State]
FROM sys.dm_os_sys_memory;

-- =============================================
-- Part 3: Top 20 queries by memory grant
-- =============================================
SELECT TOP 20
    qs.total_worker_time / qs.execution_count   AS [Avg CPU (µs)],
    qs.total_logical_reads / qs.execution_count AS [Avg Logical Reads],
    qs.total_grant_kb                           AS [Total Memory Grant KB],
    qs.execution_count,
    DB_NAME(qt.dbid)                            AS [Database],
    SUBSTRING(
        qt.text,
        (qs.statement_start_offset / 2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset) / 2) + 1
    )                                           AS [Statement]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_grant_kb DESC;