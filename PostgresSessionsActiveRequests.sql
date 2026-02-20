SELECT
  pid,
  usename,
  application_name,
  client_addr,
  backend_start,
  xact_start,
  query_start,
  state,
  wait_event_type,
  wait_event,
  now() - query_start AS query_age,
  left(query, 2000) AS query
FROM pg_stat_activity
WHERE pid <> pg_backend_pid()
  AND state <> 'idle'
ORDER BY query_start ASC;
