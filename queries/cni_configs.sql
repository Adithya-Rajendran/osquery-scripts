SELECT 
    path, filename, size, mtime 
FROM 
    file 
WHERE 
    directory = '/etc/cni/net.d/';
