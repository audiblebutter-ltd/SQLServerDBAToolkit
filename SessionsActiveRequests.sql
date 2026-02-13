SELECT 
		r.session_id, 
		s.login_name, 
		s.host_name, 
		s.program_name,
		DB_NAME(r.database_id) AS database_name, 
		r.status, 
		r.command,
		r.cpu_time, 
		r.total_elapsed_time, 
		r.reads, 
		r.writes, 
		r.logical_reads,
		r.wait_type, 
		r.wait_time, 
		r.last_wait_type, 
		r.blocking_session_id,
		r.percent_complete, 
		r.start_time, 
		SUBSTRING(t.text,
					(r.statement_start_offset/2)+1, 
					((CASE r.statement_end_offset WHEN -1
						THEN DATALENGTH(t.text) ELSE r.statement_end_offset 
						END 
					r.statement_start_offset)/2)+1) AS running_statement, 
					t.text AS batch_text 
			FROM sys.dm_exec_requests r 
				JOIN sys.dm_exec_sessions s ON s.session_id = r.session_id 
				OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t 
			WHERE s.is_user_process = 1 
		ORDER
BY r.total_elapsed_time DESC;
