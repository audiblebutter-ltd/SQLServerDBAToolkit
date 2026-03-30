SELECT
    ag.name                                 AS [AG Name],
    ar.replica_server_name                  AS [Replica],
    ar.availability_mode_desc               AS [Availability Mode],
    ar.failover_mode_desc                   AS [Failover Mode],
    ars.role_desc                           AS [Role],
    ars.connected_state_desc                AS [Connected],
    ars.synchronization_health_desc         AS [Sync Health],
    ars.operational_state_desc              AS [Operational State],
    ars.recovery_health_desc                AS [Recovery Health],
    drs.synchronization_state_desc          AS [DB Sync State],
    drs.synchronization_health_desc         AS [DB Sync Health],
    drs.log_send_queue_size                 AS [Log Send Queue KB],
    drs.redo_queue_size                     AS [Redo Queue KB],
    drs.log_send_rate                       AS [Log Send Rate KB/s],
    drs.redo_rate                           AS [Redo Rate KB/s],
    drs.last_commit_time                    AS [Last Commit Time]
FROM sys.availability_groups ag
JOIN sys.availability_replicas ar
    ON ag.group_id = ar.group_id
JOIN sys.dm_hadr_availability_replica_states ars
    ON ar.replica_id = ars.replica_id
JOIN sys.dm_hadr_database_replica_states drs
    ON ar.replica_id = drs.replica_id
ORDER BY ag.name, ar.replica_server_name;
