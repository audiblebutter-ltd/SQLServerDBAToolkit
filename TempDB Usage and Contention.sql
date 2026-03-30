-- =============================================
-- Part 1: TempDB space usage by session
-- =============================================
SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    (tsu.user_objects_alloc_page_count
        - tsu.user_objects_dealloc_page_count) * 8 / 1024
                                                AS [User Objects MB],
    (tsu.internal_objects_alloc_page_count
        - tsu.internal_objects_dealloc_page_count) * 8 / 1024
                                                AS [Internal Objects MB],
    r.status,
    r.command,
    SUBSTRING(
        t.text,
        (r.statement_start_offset / 2) + 1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(t.text)
            ELSE r.statement_end_offset
          END - r.statement_start_offset) / 2) + 1
    )                                           AS [Current Statement]
FROM sys.dm_db_session_space_usage tsu
JOIN sys.dm_exec_sessions s
    ON tsu.session_id = s.session_id
LEFT JOIN sys.dm_exec_requests r
    ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE (tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) > 0
  AND s.session_id > 50
ORDER BY
    (tsu.user_objects_alloc_page_count - tsu.user_objects_dealloc_page_count)
  + (tsu.internal_objects_alloc_page_count - tsu.internal_objects_dealloc_page_count)
  DESC;

-- =============================================
-- Part 2: TempDB file I/O stall (contention)
-- =============================================
SELECT
    vfs.file_id,
    mf.physical_name,
    vfs.io_stall_read_ms                        AS [Read Stall ms],
    vfs.io_stall_write_ms                       AS [Write Stall ms],
    vfs.io_stall                                AS [Total Stall ms],
    vfs.io_stall / NULLIF(vfs.num_of_reads + vfs.num_of_writes, 0)
                                                AS [Avg Stall ms per IO]
FROM sys.dm_io_virtual_file_stats(2, NULL) vfs
JOIN sys.master_files mf
    ON vfs.database_id = mf.database_id
    AND vfs.file_id    = mf.file_id
ORDER BY vfs.io_stall DESC;

-- =============================================
-- Part 3: TempDB file layout
-- =============================================
SELECT
    file_id,
    name,
    physical_name,
    ROUND(size * 8.0 / 1024, 2)                AS [Size MB],
    CASE is_percent_growth
        WHEN 1 THEN CAST(growth AS VARCHAR) + '%'
        ELSE CAST(growth * 8 / 1024 AS VARCHAR) + ' MB'
    END                                         AS [Auto Growth],
    max_size
FROM tempdb.sys.database_files
ORDER BY file_id;