SELECT 
		r.session_id, 
		r.blocking_session_id, 
		DB_NAME(r.database_id) AS database_name, 
		r.status, 
		r.wait_type, 
		r.wait_time, 
		r.total_elapsed_time
	FROM sys.dm_exec_requests r 
		WHERE r.blocking_session_id <> 0 
		ORDER BY
			r.wait_time DESC;