SELECT 
    device, path, type, blocks_size * blocks_free AS free_bytes 
FROM 
    mounts 
WHERE 
    type NOT IN ('proc', 'sysfs', 'cgroup', 'tmpfs', 'devtmpfs', 'autofs', 'overlay');
