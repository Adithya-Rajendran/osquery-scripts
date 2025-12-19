SELECT
	pos.local_port,
	pos.remote_address,
	pos.remote_port,
	p.name AS process
FROM
	process_open_sockets pos
	JOIN processes p ON pos.pid = p.pid
WHERE
	pos.remote_port > 0
	AND pos.state = 'ESTABLISHED';
