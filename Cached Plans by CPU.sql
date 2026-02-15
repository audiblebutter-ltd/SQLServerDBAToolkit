SELECT TOP (25) 
		qs.total_worker_time / 1000 AS total_cpu_ms,
		qs.execution_count, 
		(qs.total_worker_time /
		NULLIF(qs.execution_count,0)) / 1000 AS avg_cpu_ms, 
		DB_NAME(st.dbid) AS database_name, 
		st.text AS sql_text 
		FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st 
		ORDER BY
			qs.total_worker_time DESC;