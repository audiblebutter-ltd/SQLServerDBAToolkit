```sql
SELECT
    j.name                                      AS [Job Name],
    CASE j.enabled WHEN 1 THEN 'Yes' ELSE 'No' END
                                                AS [Enabled],
    ja.start_execution_date                     AS [Last Start],
    ja.stop_execution_date                      AS [Last Stop],
    DATEDIFF(
        SECOND,
        ja.start_execution_date,
        ja.stop_execution_date
    )                                           AS [Duration (sec)],
    CASE jh.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'In Progress'
        ELSE    'Unknown'
    END                                         AS [Last Run Status],
    jh.message                                  AS [Last Message],
    CASE
        WHEN js.next_run_date = 0 THEN NULL
        ELSE CAST(
            CAST(js.next_run_date AS CHAR(8))
            + ' '
            + STUFF(STUFF(RIGHT('000000' + CAST(js.next_run_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':')
            AS DATETIME
        )
    END                                         AS [Next Scheduled Run]
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobactivity ja
    ON j.job_id      = ja.job_id
    AND ja.session_id = (
        SELECT MAX(session_id) FROM msdb.dbo.syssessions
    )
LEFT JOIN msdb.dbo.sysjobhistory jh
    ON j.job_id      = jh.job_id
    AND jh.instance_id = (
        SELECT MAX(instance_id)
        FROM msdb.dbo.sysjobhistory
        WHERE job_id = j.job_id
          AND step_id = 0
    )
LEFT JOIN msdb.dbo.sysjobschedules jjs
    ON j.job_id      = jjs.job_id
LEFT JOIN msdb.dbo.sysschedules js
    ON jjs.schedule_id = js.schedule_id
ORDER BY
    CASE jh.run_status WHEN 0 THEN 0 ELSE 1 END,
    j.name;