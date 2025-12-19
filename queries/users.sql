SELECT 
    username, uid, gid, shell 
FROM 
    users 
WHERE 
    shell NOT LIKE '%/nologin' AND shell NOT LIKE '%/false';
