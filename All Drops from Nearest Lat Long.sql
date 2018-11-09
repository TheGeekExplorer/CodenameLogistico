SET @latitude  = 52.310484;
SET @longitude = -0.681849;
SET @vehicle_capacity = 3;
SET @vehicle_chilled = 0;
SET @vehicle_perishable = 0;
SET @vehicle_fragile = 0;


SELECT
    
    # CUSTOMER DETAILS
    dc_customers.customerid,
    dc_customers.business_name    as customer_business_name,
    dc_customers.address_house_no as business_address_house_no,
    dc_customers.address_street   as business_address_street,
    dc_customers.address_town     as business_address_town,
    dc_customers.address_county   as business_address_county,
    dc_customers.address_postcode as business_address_postcode,
    
    # DROP PICKUP/DROPOFF COORDS
    dc_drops.pickup_latitude,
    dc_drops.pickup_longitude,
    dc_drops.dropoff_latitude,
    dc_drops.dropoff_longitude,
    
    
    # DISTANCE CALCULATIONS - DRIVER to PICKUP
    ROUND((
        6371 * acos(
            cos(
                radians(@latitude)
            ) * cos(
                radians(dc_drops.pickup_latitude)
            ) * cos(
                radians(dc_drops.pickup_longitude) - radians(@longitude)
            ) + sin(
                radians(@latitude)
            ) * sin(
                radians(dc_drops.pickup_latitude)
            )
        )
    ), 2) AS distance_calculation_driver_to_pickup,
    
    
    # DISTANCE CALCULATIONS - DRIVER to DROPOFF
    ROUND((
        6371 * acos(
            cos(
                radians(@latitude)
            ) * cos(
                radians(dc_drops.dropoff_latitude)
            ) * cos(
                radians(dc_drops.dropoff_longitude) - radians(@longitude)
            ) + sin(
                radians(@latitude)
            ) * sin(
                radians(dc_drops.dropoff_latitude)
            )
        )
    ), 2) AS distance_calculation_driver_to_dropoff,
    
    
    # DISTANCE CALCULATIONS - PICKUP to DROPOFF
    ROUND((
        6371 * acos(
            cos(
                radians(dc_drops.pickup_latitude)
            ) * cos(
                radians(dc_drops.dropoff_latitude)
            ) * cos(
                radians(dc_drops.dropoff_longitude) - radians(dc_drops.pickup_longitude)
            ) + sin(
                radians(dc_drops.pickup_latitude)
            ) * sin(
                radians(dc_drops.dropoff_latitude)
            )
        )
    ), 2) AS distance_calculation_pickup_to_dropoff,
    
    
    # DROP PICKUP ADDRESS
    dc_drops.pickup_house_no,
    dc_drops.pickup_street,
    dc_drops.pickup_town,
    dc_drops.pickup_county,
    dc_drops.pickup_postcode,
    
    # DROP DROPOFF ADDRESS
    dc_drops.dropoff_house_no,
    dc_drops.dropoff_street,
    dc_drops.dropoff_town,
    dc_drops.dropoff_county,
    dc_drops.dropoff_postcode,
    
    # PICKUP/DROPOFF TIME FROM/TO
    dc_drops.pickup_time_from,
    dc_drops.pickup_time_to,
    dc_drops.dropoff_time_from,
    dc_drops.dropoff_time_to,

    # PICKUP/DROPOFF DATE FROM/TO
    dc_drops.pickup_date_from,
    dc_drops.pickup_date_to,
    dc_drops.dropoff_date_from,
    dc_drops.dropoff_date_to,
    
    # CONDITIONS
    dc_drops.fragile,
    dc_drops.perishable,
    dc_drops.chilled
    
    
FROM
    dc_drops
    
    
USE INDEX
    (idx_pallets_count, idx_fragile, idx_perishable, idx_chilled)
    
    
INNER JOIN
    dc_customers
    USE INDEX (idx_customerid)
    ON dc_drops.customerid = dc_customers.customerid
    
    
WHERE
    dc_drops.pallets_count <= @vehicle_capacity
    AND dc_drops.chilled    = @vehicle_chilled
    AND dc_drops.perishable = @vehicle_perishable
    AND dc_drops.fragile    = @vehicle_fragile
    AND dc_customers.status = 1
    
    
GROUP BY
    dc_customers.customerid,
    dc_customers.business_name,
    dc_customers.address_house_no,
    dc_customers.address_street,
    dc_customers.address_town,
    dc_customers.address_county,
    dc_customers.address_postcode,
    
    # PICKUP/DROPOFF COORDS
    dc_drops.pickup_latitude,
    dc_drops.pickup_longitude,
    dc_drops.dropoff_latitude,
    dc_drops.dropoff_longitude,
    
    # PICKUP ADDRESS
    dc_drops.pickup_house_no,
    dc_drops.pickup_street,
    dc_drops.pickup_town,
    dc_drops.pickup_county,
    dc_drops.pickup_postcode,
    
    # DROPOFF ADDRESS
    dc_drops.dropoff_house_no,
    dc_drops.dropoff_street,
    dc_drops.dropoff_town,
    dc_drops.dropoff_county,
    dc_drops.dropoff_postcode,
    
    # PICKUP/DROPOFF TIME FROM/TO
    dc_drops.pickup_time_from,
    dc_drops.pickup_time_to,
    dc_drops.dropoff_time_from,
    dc_drops.dropoff_time_to,

    # PICKUP/DROPOFF DATE FROM/TO
    dc_drops.pickup_date_from,
    dc_drops.pickup_date_to,
    dc_drops.dropoff_date_from,
    dc_drops.dropoff_date_to,
    
    # CONDITIONS
    dc_drops.fragile,
    dc_drops.perishable,
    dc_drops.chilled

HAVING
    distance_calculation_driver_to_pickup <= 50

ORDER BY
    distance_calculation_driver_to_pickup ASC

LIMIT
    0, 150
