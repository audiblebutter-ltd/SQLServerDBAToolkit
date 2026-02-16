SELECT 
		r.session_id, 
		r.command, 
		DB_NAME(r.database_id) AS database_name,
		r.start_time, 
		r.percent_complete, 
			DATEADD(second,
				(r.estimated_completion_time/1000)
			, GETDATE()) AS estimated_finish_time
	FROM sys.dm_exec_requests r 
		WHERE r.command IN (‘BACKUP DATABASE’,‘BACKUP LOG’,‘RESTORE DATABASE’,‘RESTORE LOG’) 
			ORDER BY
		r.start_time;