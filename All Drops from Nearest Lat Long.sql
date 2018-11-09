SET @vehicleid          = 1;
SET @distance           = 50;

SELECT
    # VEHICLE DETAILS
    dc_vehicles.location_latitude  as vehicle_latitude,
    dc_vehicles.location_longitude as vehicle_longitude,
    dc_vehicles.pallets_capacity   as vehicle_capacity,
    dc_vehicles.pallets_usage      as vehicle_usage,
    SUM(dc_vehicles.pallets_capacity - dc_vehicles.pallets_usage) as vehicle_capacity_current,
    
    
    # CUSTOMER DETAILS
    dc_drops.pallets_count        as drop_pallets_count,
    dc_customers.customerid       as customer_customerid,
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
                radians(dc_vehicles.location_latitude)
            ) * cos(
                radians(dc_drops.pickup_latitude)
            ) * cos(
                radians(dc_drops.pickup_longitude) - radians(dc_vehicles.location_longitude)
            ) + sin(
                radians(dc_vehicles.location_latitude)
            ) * sin(
                radians(dc_drops.pickup_latitude)
            )
        )
    ), 2) AS distance_calculation_driver_to_pickup,
    
    
    # DISTANCE CALCULATIONS - DRIVER to DROPOFF
    ROUND((
        6371 * acos(
            cos(
                radians(dc_vehicles.location_latitude)
            ) * cos(
                radians(dc_drops.dropoff_latitude)
            ) * cos(
                radians(dc_drops.dropoff_longitude) - radians(dc_vehicles.location_longitude)
            ) + sin(
                radians(dc_vehicles.location_latitude)
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
    
    
INNER JOIN
    dc_vehicles
    USE INDEX (idx_vehicleid)
    ON dc_vehicles.vehicleid = @vehicleid
    
    
WHERE
    # Only show drops that are within a certain distance of the 
    # vehicles GPS / Address location
    (6371 * acos(
        cos(
            radians(dc_vehicles.location_latitude)
        ) * cos(
            radians(dc_drops.pickup_latitude)
        ) * cos(
            radians(dc_drops.pickup_longitude) - radians(dc_vehicles.location_longitude)
        ) + sin(
            radians(dc_vehicles.location_latitude)
        ) * sin(
            radians(dc_drops.pickup_latitude)
        )
    )) <= @distance
    
    # Calculate how many spare pallet slots in vehicle, and 
    # if this drop is less or equal to spare space
    AND (dc_vehicles.pallets_capacity - dc_vehicles.pallets_usage) <= dc_drops.pallets_count
    
    # Check that the customers account has not been 
    # banned/deleted/disabled
    AND dc_customers.status    = 1
    
    
GROUP BY
    dc_drops.pallets_count,
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
    distance_calculation_driver_to_pickup <= @distance

ORDER BY
    distance_calculation_driver_to_pickup ASC

LIMIT
    0, 150
