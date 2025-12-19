SELECT 
    os.name, os.version, k.version AS kernel_version, si.cpu_physical_cores, si.physical_memory 
FROM 
    os_version os, kernel_info k, system_info si;
