SET @latitude  = 52.310484;
SET @longitude = -0.681849;

SELECT
    dc_coords.coords_latitude,
    dc_coords.coords_longitude,
    
    ROUND((
		6371 * acos(
			cos(
				radians(@latitude)
			) * cos(
				radians(dc_coords.coords_latitude)
			) * cos(
				radians(dc_coords.coords_longitude) - radians(@longitude)
			) + sin(
				radians(@latitude)
			) * sin(
				radians(dc_coords.coords_latitude)
			)
		)
	), 2) AS distance_in_kilometers,
    
	dc_customers.customerid,
	dc_customers.business_name,
    dc_customers.address_house_no,
    dc_customers.address_street,
	dc_customers.address_town,
    dc_customers.address_county,
    dc_customers.address_postcode


FROM
	dc_coords

USE INDEX
	(idx_latitude, idx_longitude)

INNER JOIN
	dc_customers
    USE INDEX (idx_coordsid)
    ON dc_coords.coordsid = dc_customers.address_coordsid

WHERE
	dc_customers.status = 1

GROUP BY
    dc_coords.coords_latitude,
    dc_coords.coords_longitude,
    dc_customers.customerid

HAVING
	distance_in_kilometers <= 50

ORDER BY
	distance_in_kilometers ASC

LIMIT
	0, 150