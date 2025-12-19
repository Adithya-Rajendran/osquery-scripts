SELECT 
    name, version, 'deb' as type 
FROM 
    deb_packages 
UNION 
SELECT 
    name, version, 'rpm' as type 
FROM 
    rpm_packages;
