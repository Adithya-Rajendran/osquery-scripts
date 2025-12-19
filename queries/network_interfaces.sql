SELECT 
    id.interface, id.mtu, id.mac, ia.address, ia.mask 
FROM 
    interface_details id 
JOIN 
    interface_addresses ia 
ON 
    id.interface = ia.interface 
WHERE 
    ia.address NOT LIKE '127.%' AND ia.address NOT LIKE '%:%';
