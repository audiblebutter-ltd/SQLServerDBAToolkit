SELECT 
		DB_NAME(database_id) AS database_name, 
		name AS logical_name,
		type_desc, 
		physical_name, 
		size8/1024.0 AS size_mb,
		CAST(FILEPROPERTY(name,‘SpaceUsed’) AS bigint)8/1024.0 AS used_mb,
		(size - CAST(FILEPROPERTY(name,‘SpaceUsed’) AS bigint))*8/1024.0 AS free_mb 
		FROM sys.master_files 
	ORDER BY 
			database_name, 
			type_desc,
			logical_name