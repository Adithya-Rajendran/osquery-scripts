SELECT 
    lp.port, lp.protocol, p.name AS process, p.path, p.cmdline 
FROM 
    listening_ports lp 
JOIN 
    processes p 
ON 
    lp.pid = p.pid 
WHERE 
    lp.address != '127.0.0.1';
