-- I want to get angle between motorway and otherways. I need to preserve the angle direction. 
-- this is further developed based on https://gis.stackexchange.com/questions/25126/how-to-calculate-the-angle-at-which-two-lines-intersect-in-postgis/370761#370761

-- First: get intersection points.

with intersections as (
	select ST_Intersection(a.geometry, b.geometry) as intersection,
           a.geometry as otherway_geom,
           b.geometry as motorway_geom,
           a.id as otherway_osmid,
           b.id as motorway_osmid

	from otherways a, motorways b
	where ST_Intersects(a.geometry,b.geometry)),

-- Second, create a buffer around intersection point.

    buffers AS (SELECT intersections.intersection, 
        ST_ExteriorRing (ST_Buffer(intersections.intersection, 1))AS extring,
        ST_Buffer(intersections.intersection, 1) as buffer,
        intersections.otherway_geom,
		intersections.motorway_geom,
		intersections.otherway_osmid,
		intersections.motorway_osmid
	FROM 
		intersections),

-- Third, get the end point of each line, which preserve the direction of linestring. 

    points AS(

	SELECT 
        ST_Intersection(buffers.buffer, buffers.otherway_geom) as otherway_intersected_lane, 
        ST_Intersection(buffers.buffer, buffers.motorway_geom) as motorway_intersected_lane,
        st_endpoint(ST_Intersection(buffers.buffer, buffers.otherway_geom)) as point1,
        st_endpoint(ST_Intersection(buffers.buffer, buffers.motorway_geom)) as point2,
		buffers.intersection,
		buffers.extring,
		buffers.buffer,
		buffers.otherway_geom,
		buffers.motorway_geom,
		buffers.otherway_osmid,
		buffers.motorway_osmid
	FROM 
		buffers)

-- Finally, calculate the angle!

    
    SELECT 

	st_astext(points.point1) as point1,
	st_astext(points.point2) as point2,
	st_astext(points.extring) as extring,
	st_astext(points.otherway_geom) as otherway_geom,
    st_astext(points.motorway_geom) as motorway_geom,
	abs
	(
		round
		(
			degrees
			(
				ST_Azimuth
				(
					points.point2,
					points.intersection
				)

				-

				ST_Azimuth
				(
					points.point1,
					points.intersection
				)			
			)::decimal % 180.0
			,2
		)
	)AS angle_Azimuth,   
	points.otherway_osmid AS otherway_id, 
	points.motorway_osmid AS motorway_id 
    FROM points
