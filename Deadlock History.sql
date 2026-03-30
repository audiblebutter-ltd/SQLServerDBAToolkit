WITH DeadlockData AS (
    SELECT
        xdr.value('@timestamp', 'datetime2')        AS [Deadlock Time],
        xdr.query('.')                              AS [Deadlock Graph]
    FROM (
        SELECT CAST(target_data AS XML) AS target_data
        FROM sys.dm_xe_session_targets t
        JOIN sys.dm_xe_sessions s
            ON t.event_session_address = s.address
        WHERE s.name        = 'system_health'
          AND t.target_name = 'ring_buffer'
    ) AS data
    CROSS APPLY target_data.nodes(
        '//RingBufferTarget/event[@name="xml_deadlock_report"]'
    ) AS xEventData(xdr)
)
SELECT
    [Deadlock Time],
    [Deadlock Graph].value(
        '(//victim-list/victimProcess/@id)[1]',     'varchar(50)'
    )                                               AS [Victim Process],
    [Deadlock Graph].value(
        '(//process-list/process/@spid)[1]',        'int'
    )                                               AS [Spid 1],
    [Deadlock Graph].value(
        '(//process-list/process/@spid)[2]',        'int'
    )                                               AS [Spid 2],
    [Deadlock Graph].value(
        '(//process-list/process/@clientapp)[1]',   'varchar(100)'
    )                                               AS [Client App 1],
    [Deadlock Graph].value(
        '(//process-list/process/@hostname)[1]',    'varchar(100)'
    )                                               AS [Host 1],
    [Deadlock Graph].value(
        '(//process-list/process/executionStack/frame/@procname)[1]', 'varchar(200)'
    )                                               AS [Proc 1],
    [Deadlock Graph]
FROM DeadlockData
ORDER BY [Deadlock Time] DESC;