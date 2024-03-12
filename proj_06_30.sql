SELECT TOP 10 *
FROM [18-23_cleanups]

-- we need to dedupe, rename zone to county, ensure all within CA USA, split gps into two
-- columns, rename cols, standardize group names, then go from there.

SELECT COUNT(DISTINCT [Cleanup ID]) AS cleanups,
COUNT(*) AS total
FROM [18-23_cleanups]

-- changing col names via design view

-- sanity check

SELECT TOP 10 *
FROM [18-23_cleanups]

-- checking to see if all within CA

SELECT *
FROM [18-23_cleanups]
WHERE state != 'California, USA'

-- looks good
-- checking distinct zones

SELECT DISTINCT(zone) AS zones
FROM [18-23_cleanups]
ORDER BY zones

-- we've got a null in our distincts

SELECT *
FROM [18-23_cleanups]
WHERE zone IS NULL

-- several nulls but we have gps to fix this, one null is just the 'total' row, which we'll get rid of eventually
-- only one null zone is underwater, should still fall within a ca county line

-- first we're gonna split gps into lat and lon

SELECT TOP 10 gps
FROM [18-23_cleanups]

-- confirmed that lat is first followed by lon

ALTER TABLE [18-23_cleanups]
	ADD lat FLOAT,
	lon FLOAT

-- inputing values

UPDATE [18-23_cleanups]
SET lat = CAST(SUBSTRING(gps, 1, CHARINDEX(', ', gps) - 1) AS FLOAT),
    lon = CAST(SUBSTRING(gps, CHARINDEX(', ', gps) + 2, LEN(gps)) AS FLOAT)

-- sanity check

SELECT  TOP 10 lat, lon
FROM [18-23_cleanups]

-- finding the null we want (the total row)

SELECT *
FROM [18-23_cleanups]
WHERE zone IS NULL
AND state IS NULL
AND cleanup_id IS NULL

-- deleting it

DELETE FROM [18-23_cleanups]
WHERE zone IS NULL
AND state IS NULL
AND cleanup_id IS NULL

-- inspecting plastic cols

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'dbo'
    AND TABLE_NAME = '18-23_cleanups'
    AND UPPER(COLUMN_NAME) LIKE '%PLASTIC%'

-- 14 plastic cols as follows:

--------------------------------------------------------------------------------------------
--| grocery_bags_plastic                | other_bags_plastic      | bev_bottles_plastic    |
--| bottle_caps_plastic                 | cups_plates_plastic     | food_container_plastic |
--| lids_plastic                        | straws/stirrers_plastic | utens_plastic          |
--| other_plastic_bottles_ie_oil_bleach | other_plastic_waste     | plastic_o_foam_pcs     |
--| other_plastic_foam_pckg             | plastic_pcs             |                        |
--------------------------------------------------------------------------------------------

-- sanity check

SELECT plastic_pcs,
total_items_collected
FROM [18-23_cleanups]

-- inputting data for missing zones
-- finding nulls

SELECT *
FROM [18-23_cleanups]
WHERE zone IS NULL

-- observing how the data should look

SELECT TOP 10 zone, state, country
FROM [18-23_cleanups]

-- zone example: Orange County, CA, USA
-- state example: California, USA
-- country example: United States

-- Update data for multiple rows and columns

UPDATE [18-23_cleanups]
SET 
    zone = CASE WHEN cleanup_id = 55102 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 68979 THEN 'Orange County, CA, USA' 
				WHEN cleanup_id = 56556 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 57646 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 50427 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 51112 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 58334 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 58618 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 71968 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 62456 THEN 'Orange County, CA, USA'
				WHEN cleanup_id = 62457 THEN 'Orange County, CA, USA'
				ELSE zone END, -- all of these gps coords are from the San Diego Creek Trail in Irvine, CA
    country = CASE WHEN cleanup_id = 55102 THEN 'United States' 
				   WHEN cleanup_id = 68979 THEN 'United States' -- bit redundant here, but who doesn't like clean data
				   WHEN cleanup_id = 56556 THEN 'United States'
				   WHEN cleanup_id = 57646 THEN 'United States'
				   WHEN cleanup_id = 50427 THEN 'United States'
				   WHEN cleanup_id = 51112 THEN 'United States'
				   WHEN cleanup_id = 58334 THEN 'United States'
				   WHEN cleanup_id = 58618 THEN 'United States'
				   WHEN cleanup_id = 71968 THEN 'United States'
				   WHEN cleanup_id = 62456 THEN 'United States'
				   WHEN cleanup_id = 62457 THEN 'United States'
				   ELSE country END
WHERE cleanup_id IN (55102, 68979, 56556, 57646, 50427, 51112, 58334, 58618, 71968, 62456, 62457)

-- sanity check

SELECT *
FROM [18-23_cleanups]
WHERE zone IS NULL
OR country IS NULL

-- see some with missing country, but no missing zones
-- just to be sure

SELECT *
FROM [18-23_cleanups]
WHERE zone IS NULL

-- looks good

UPDATE [18-23_cleanups]
SET 
		country = CASE WHEN country IS NULL THEN 'United States' ELSE country END

-- sanity check

SELECT DISTINCT(country)
FROM [18-23_cleanups]

-- all good

-- adding regions based on county lines

-- Southern Border:            San Diego, Imperial
-- Southern California:        Ventura, Los Angeles, San Bernardino, Orange, Riverside
-- Central Coast:              San Benito, Monterey, San Luis Obispo, Santa Barbara
-- San Joaquin Valley:         San Joaquin, Stanislaus, Merced, Madera, Fresno, Kings, Tulare, Kern
-- Central Sierra:             Inyo, Mono, Mariposa, Alpine, Tuolumne, Calaveras, Amador
-- Bay Area:                   Santa Cruz, Santa Clara, Alameda, San Mateo, San Francisco, Contra Costa, Marin, Solano, Napa, Sonoma
-- Greater Sacramento:         Sacramento, Yolo, Placer, El Dorado, Sutter, Yuba
-- Northern Sacramento Valley: Colusa, Butte, Glenn, Tehama, Shasta
-- Northern California:        Nevada, Sierra, Plumas, Lassen, Modoc, Siskiyou, Del Norte, Humboldt, Trinity, Lake, Mendocino

-- sanity check

SELECT DISTINCT(zone)
FROM [18-23_cleanups]

-- adding region col

ALTER TABLE [18-23_cleanups]
    ADD regions AS (CASE 
                        WHEN zone IN('San Diego County, CA, USA', 'Imperial County, CA, USA') THEN 'Southern Border'
                        WHEN zone IN('Ventura County, CA, USA', 'Los Angeles County, CA, USA', 'San Bernardino County, CA, USA', 'Orange County, CA, USA', 'Riverside County, CA, USA') THEN 'Southern California'
                        WHEN zone IN('San Benito County, CA, USA', 'Monterey County, CA, USA', 'San Luis Obispo County, CA, USA', 'Santa Barbara County, CA, USA', 'Cayucos, CA 93430, USA') THEN 'Central Coast'
                        WHEN zone IN('San Joaquin County, CA, USA', 'Stanislaus County, CA, USA', 'Merced County, CA, USA', 'Madera County, CA, USA', 'Fresno County, CA, USA', 'Kings County, CA, USA', 'Tulare County, CA, USA', 'Kern County, CA, USA') THEN 'San Joaquin Valley'
                        WHEN zone IN('Inyo County, CA, USA', 'Mono County, CA, USA', 'Mariposa County, CA, USA', 'Alpine County, CA, USA', 'Tuolumne County, CA, USA', 'Calaveras County, CA, USA', 'Amador County, CA, USA') THEN 'Central Sierra'
                        WHEN zone IN('San Francisco County, San Francisco, CA, USA', 'Santa Cruz County, CA, USA', 'Santa Clara County, CA, USA', 'Alameda County, CA, USA', 'San Mateo County, CA, USA', 'San Francisco County, CA, USA', 'Contra Costa County, CA, USA', 'Marin County, CA, USA', 'Solano County, CA, USA', 'Napa County, CA, USA', 'Sonoma County, CA, USA') THEN 'Bay Area'
						WHEN zone IN('Sacramento County, CA, USA', 'Yolo County, CA, USA', 'Placer County, CA, USA', 'El Dorado County, CA, USA', 'Sutter County, CA, USA', 'Yuba County, CA, USA') THEN 'Greater Sacramento'
						WHEN zone IN('Colusa County, CA, USA', 'Butte County, CA, USA', 'Glenn County, CA, USA', 'Tehama County, CA, USA', 'Shasta County, CA, USA') THEN 'Northern Sacramento Valley'
						WHEN zone IN('Nevada County, CA, USA', 'Sierra County, CA, USA', 'Plumas County, CA, USA', 'Lassen County, CA, USA', 'Modoc County, CA, USA', 'Siskiyou County, CA, USA', 'Del Norte County, CA, USA', 'Humboldt County, CA, USA', 'Trinity County, CA, USA', 'Lake County, CA, USA', 'Mendocino County, CA, USA') THEN 'Northern California'
                        ELSE 'Invalid'
                     END)

-- sanity check

SELECT DISTINCT(regions)
FROM [18-23_cleanups]

-- eda

SELECT DISTINCT(zone) AS area,
SUM(total_items_collected) AS total_trash
FROM [18-23_cleanups]
GROUP BY zone
ORDER BY total_trash DESC

-- q1: what are the monthly or seasonal variations in the number of beach cleanup events? (chart)

WITH totals AS 
(
SELECT MONTH(date) AS mnth,
SUM(total_items_collected) OVER (
PARTITION BY YEAR(date)
ORDER BY MONTH(date)) AS monthly_total,
COUNT(DISTINCT cleanup_id) AS total_cleanups,
YEAR(date) AS yr
FROM [18-23_cleanups]
GROUP BY MONTH(date), date, total_items_collected, cleanup_id
)

SELECT mnth,
yr,
SUM(total_cleanups) AS total_cleanups,
monthly_total
FROM totals
GROUP BY monthly_total, total_cleanups, mnth, yr
ORDER BY yr, mnth

-- q2: are there specific months or seasons when certain types of trash are more prevalent? (chart)
-- q3: can we identify any long-term trends or patterns in the frequency of cleanup efforts over the timeframe? (see chart)

WITH totals AS 
(
SELECT MONTH(date) AS mnth,
SUM(CAST(foam_pcs AS FLOAT)) OVER (
PARTITION BY YEAR(date)
ORDER BY MONTH(date)) AS foam_total,
SUM(plastic_pcs) OVER (
PARTITION BY YEAR(date)
ORDER BY MONTH(date)) AS plastic_total,
SUM(CAST(glass_pcs AS FLOAT)) OVER (
PARTITION BY YEAR(date)
ORDER BY MONTH(date)) AS glass_total,
YEAR(date) AS yr
FROM [18-23_cleanups]
GROUP BY MONTH(date), YEAR(date), foam_pcs, plastic_pcs, glass_pcs
)

SELECT mnth,
yr,
foam_total, plastic_total, glass_total
FROM totals
GROUP BY mnth, yr, foam_total, plastic_total, glass_total
ORDER BY yr, mnth

-- odd, let's look into it

SELECT plastic_pcs, glass_pcs, foam_pcs
FROM [18-23_cleanups]
WHERE YEAR(date) = 2023

-- no records exist for total foam/plastic/glass pcs for year 2023
-- might just have to use 5 years of data to keep things consistent in terms of totals

-- total trash by season

WITH mnths AS
(
SELECT CASE WHEN MONTH(date) IN(12,1,2) THEN 'Winter'
			WHEN MONTH(date) IN(3,4,5) THEN 'Spring'
			WHEN MONTH(date) IN(6,7,8) THEN 'Summer'
			WHEN MONTH(date) IN(9,10,11) THEN 'Fall' END AS season,
SUM(total_items_collected) AS total_trash
FROM [18-23_cleanups]
GROUP BY MONTH(date)
)

SELECT season,
SUM(total_trash) AS total_trash
FROM mnths
GROUP BY season
ORDER BY total_trash DESC

-- avg trash by season

WITH mnths AS
(
SELECT CASE WHEN MONTH(date) IN(12,1,2) THEN 'Winter'
			WHEN MONTH(date) IN(3,4,5) THEN 'Spring'
			WHEN MONTH(date) IN(6,7,8) THEN 'Summer'
			WHEN MONTH(date) IN(9,10,11) THEN 'Fall' END AS season,
SUM(total_items_collected) AS total_trash
FROM [18-23_cleanups]
WHERE total_items_collected IS NOT NULL
GROUP BY date
)

SELECT season,
ROUND((AVG(total_trash)),2) AS avg_trash_by_season
FROM mnths
GROUP BY season
ORDER BY avg_trash_by_season DESC

-- testing to find nulls in total_items_collected

SELECT total_items_collected
FROM [18-23_cleanups]
WHERE YEAR(date) = 2023

-- q4: which beaches/regions have the highest/lowest recorded frequency of cleanup efforts?

SELECT TOP 5
COUNT(DISTINCT cleanup_id) AS cleanup_count,
zone
FROM [18-23_cleanups]
GROUP BY zone
ORDER BY cleanup_count DESC

-- lowest
-- cayucos is a city so we'll skip it in our results

SELECT
COUNT(DISTINCT cleanup_id) AS cleanup_count,
zone
FROM [18-23_cleanups]
GROUP BY zone
ORDER BY cleanup_count ASC
OFFSET 1 ROW

-- q8: are there orgs that consistently perform well in terms of the amount of trash collected or the number of cleanup events?

SELECT DISTINCT(group_name) AS grp,
COUNT(DISTINCT cleanup_id) AS cleanups
FROM [18-23_cleanups]
WHERE group_name NOT IN('1','2','No group name')
AND group_name IS NOT NULL
GROUP BY group_name
ORDER BY cleanups DESC

-- by amts of trash

SELECT DISTINCT(group_name) AS grp,
SUM(total_items_collected) AS total_trash
FROM [18-23_cleanups]
WHERE group_name NOT IN ('1','2','No group name')
AND group_name IS NOT NULL
AND YEAR(date) != 2023
GROUP BY group_name
ORDER BY total_trash DESC

-- now lets do this by a yearly ranking (top 5 performers for both criteria by year)

-- tba

CREATE VIEW yearly_totals AS 
(
SELECT YEAR(date),
SUM(CAST(number_of_bags AS FLOAT)) AS number_of_bags,
SUM(grocery_bags_plastic) AS grocery_bags_plastic,
SUM(CAST(other_bags_plastic AS FLOAT)) AS other_bags_plastic,
SUM(bev_bottles_glass) AS bev_bottles_glass,
SUM(bev_bottles_plastic) AS bev_bottles_plastic,
SUM(bev_cans) AS bev_cans,
SUM(CAST([bev sachets/pouches] AS FLOAT)) AS [bev_sachets/pouches],
SUM(CAST(bottle_caps_metal AS FLOAT)) AS bottle_caps_metal,
SUM(bottle_caps_plastic) AS bottle_caps_plastic,
SUM(cig_butts) AS cig_butts,
SUM(CAST(cups_plates_foam AS FLOAT)) AS cups_plates_foam,
SUM(CAST(cups_plates_paper AS FLOAT)) AS cups_plates_paper,
SUM(cups_plates_plastic) AS cups_plates_plastic,
SUM(food_container_foam) AS food_container_foam,
SUM(food_container_plastic) AS food_container_plastic,
SUM(food_wrappers) AS food_wrappers,
SUM(lids_plastic) AS lids_plastic,
SUM([straws/stirrers_plastic]) AS [straws/stirrers_plastic],
SUM(utens_plastic) AS utens_plastic,
SUM(CAST(lines_nets_traps_ropes_etc AS FLOAT)) AS lines_nets_traps_ropes_etc,
SUM(CAST(foam_dock_pcs AS FLOAT)) AS foam_dock_pcs,
SUM(CAST(appliances AS FLOAT)) AS appliances,
SUM(CAST(construction_materials AS FLOAT)) AS construction_materials,
SUM(CAST(tires AS FLOAT)) AS tires,
SUM(CAST(six_pack_holders AS FLOAT)) AS six_pack_holders,
SUM(CAST(foam_packaging AS FLOAT)) AS foam_packaging,
SUM(CAST(other_plastic_bottles_ie_oil_bleach AS FLOAT)) AS other_plastic_bottles_ie_oil_bleach,
SUM(CAST(strapping_bands AS FLOAT)) AS strapping_bands,
SUM(balloons) AS balloons,
SUM(CAST(clothing AS FLOAT)) AS clothing,
SUM(CAST(ecigs AS FLOAT)) AS ecigs,
SUM(CAST(electronic_waste AS FLOAT)) AS electionic_waste,
SUM(CAST(footwear AS FLOAT)) AS footwear,
SUM(CAST(paper_bags AS FLOAT)) AS paper_bags,
SUM(CAST(tobacco_prods AS FLOAT)) AS tobacco_prods,
SUM(toys) AS toys,
SUM(CAST(other_plastic_waste AS FLOAT)) AS other_plastic_waste,
SUM(CAST(other_waste_metal_paper_etc AS FLOAT)) AS other_waste_paper_metal_etc,
SUM(CAST(condoms AS FLOAT)) AS condoms,
SUM(CAST(cotton_swabs AS FLOAT)) AS cotton_swabs,
SUM(CAST(diapers AS FLOAT)) AS diapers,
SUM(CAST(gloves_masks AS FLOAT)) AS gloves_masks,
SUM(CAST(syringes AS FLOAT)) AS syringes,
SUM(CAST(tampons_and_applicators AS FLOAT)) AS tampons_and_applicators,
SUM(CAST(plastic_o_foam_pcs AS FLOAT)) AS plastic_o_foam_pcs,
SUM(CAST(fishing_boys_pots_traps AS FLOAT)) AS fishing_boys_pots_traps,
SUM(CAST(fishing_nets_and_pieces AS FLOAT)) AS fishing_nets_and_pieces,
SUM(CAST([fishing_line_1yd/m_1piece] AS FLOAT)) AS fishing_line,
SUM(CAST([rope_1yd/m_1piece] AS FLOAT)) AS rope,
SUM(fishing_gear_clean_swell) AS fishing_gear_clean_swell,
SUM(CAST(other_plastic_foam_pckg AS FLOAT)) AS other_plastic_foam_pckg,
SUM(CAST(tobacco_pckg_wrap AS FLOAT)) AS tobacco_pckg_wrap,
SUM(other_pckg_clean_swell) AS other_pckg_clean_swell,
SUM(CAST(cigar_tips AS FLOAT)) AS cigar_tips,
SUM(CAST(cig_lighters AS FLOAT)) AS cig_lighters,
SUM(CAST(fireworks AS FLOAT)) AS fireworks,
SUM(other_trash_clean_swell) AS other_trash_clean_swell,
SUM(CAST(other_tobacco_pckg_lighter_etc AS FLOAT)) AS other_tobacco_pckg_lighter_etc,
SUM(person_hygiene_clean_swell) AS personal_hygiene_clean_swell,
SUM(CAST(foam_pcs AS FLOAT)) AS foam_pcs,
SUM(CAST(glass_pcs AS FLOAT)) AS glass_pcs,
SUM(plastic_pcs) AS plastic_pcs,
SUM(total_items_collected) AS total_items
FROM [18-23_cleanups]
GROUP BY YEAR(date)
)

-- possibly create another by month, group, region, etc as sums or avgs

SELECT TOP 10 *
FROM [18-23_cleanups]

-- testing to retrieve geodata

SELECT geography::STPointFromText('POINT(' + CAST([Longitude location of institution (HD2019)] AS VARCHAR(20)) + ' ' + CAST([Latitude location of institution (HD2019)] AS VARCHAR(20)) + ')', 4326)
FROM [cal_colleges]

-- adding geo col to cal_colleges

ALTER TABLE cal_colleges
	ADD [geolocation] GEOGRAPHY

-- inserting data into geo col (colleges)

UPDATE cal_colleges
SET [geolocation] = geography::STPointFromText('POINT(' + CAST([Longitude location of institution (HD2019)] AS VARCHAR(20)) + ' ' + CAST([Latitude location of institution (HD2019)] AS VARCHAR(20)) + ')', 4326)
GO

-- adding geo col to cleanups

ALTER TABLE [18-23_cleanups]
	ADD [geolocation] GEOGRAPHY
	GO

-- testing to retrieve geodata

SELECT geography::STPointFromText('POINT(' + CAST([lon] AS VARCHAR(20)) + ' ' + CAST([lat] AS VARCHAR(20)) + ')', 4326)
FROM [18-23_cleanups]

-- inserting data into geo (cleanups)

UPDATE [18-23_cleanups]
SET [geolocation] = geography::STPointFromText('POINT(' + CAST([lon] AS VARCHAR(20)) + ' ' + CAST([lat] AS VARCHAR(20)) + ')', 4326)
GO

-- sanity check

SELECT TOP 1000 cl.geolocation, c.geolocation
FROM [18-23_cleanups] cl, [cal_colleges] c

-- testing to find shortest distance between the tables

CREATE VIEW coll_distances AS
(
SELECT
cl.[zone],
cl.cleanup_id,
cl.date,
cl.group_name,
uc.Title,
uc.Type,
cl.geolocation.STDistance(uc.geolocation) AS distance_to_nearest_college
FROM [18-23_cleanups] cl
CROSS APPLY (
    SELECT TOP 1
        Title,
        Type,
        geolocation
    FROM
        cal_colleges uc
    ORDER BY
        cl.geolocation.STDistance(uc.geolocation)
) uc
)

-- sanity checks

SELECT TOP 10 *
FROM [18-23_cleanups]

--

SELECT TOP 10 *
FROM coll_distances

--

SELECT COUNT(*) AS total
FROM coll_distances

-- count distinct cleanups by group and distance in miles from nearest college

CREATE VIEW group_distances AS
(
SELECT
COUNT(DISTINCT cleanup_id) AS cleanups,
group_name,
ROUND((MIN(distance_to_nearest_college) / 1609.344),2) AS min_dist_miles,
Title
FROM coll_distances
WHERE group_name IS NOT NULL
-- AND group_name NOT IN('1','2') (optional)
GROUP BY group_name, Title
-- ORDER BY COUNT(DISTINCT cleanup_id) DESC
)

-- sanity check

SELECT TOP 10 *
FROM group_distances

-- q5: are there any correlations between the frequency of cleanups by group/zone and proximity to univerisities?

-- correlation testing (let cleanups = y and distance = x)

SELECT 
(AVG(min_dist_miles * cleanups) - (AVG(min_dist_miles) * AVG(cleanups))) /  --continued
(StDevP(min_dist_miles) * StDevP(cleanups)) as pearson_coefficient,
(AVG(min_dist_miles * cleanups) - (AVG(min_dist_miles) * AVG(cleanups))) as numerator,
(StDevP(min_dist_miles) * StDevP(cleanups))  as denominator
FROM group_distances
GO

-- pearson coefficient of 0.005... virtually no correlation

-- double checking in excel gives us -0.02... virtually no correlation

-- lets try again with zones

CREATE VIEW zone_distances AS
(
SELECT
COUNT(DISTINCT cleanup_id) AS cleanups,
zone,
ROUND((MIN(distance_to_nearest_college) / 1609.344),2) AS min_dist_miles,
Title
FROM coll_distances
GROUP BY zone, Title
)

-- correlation check

SELECT 
(AVG(min_dist_miles * cleanups) - (AVG(min_dist_miles) * AVG(cleanups))) /  --continued
(StDevP(min_dist_miles) * StDevP(cleanups)) as pearson_coefficient,
(AVG(min_dist_miles * cleanups) - (AVG(min_dist_miles) * AVG(cleanups))) as numerator,
(StDevP(min_dist_miles) * StDevP(cleanups))  as denominator
FROM zone_distances
GO

-- p coefficient of -0.19, let's confirm with excel
-- excel tells us -0.193450219 p coefficient w correl function

-- q7: what is the distribution of cleanup efforts among different orgs across the timeframe?

SELECT COUNT(DISTINCT cleanup_id) AS cleanups,
group_name,
YEAR(date) AS yr
FROM [18-23_cleanups]
GROUP BY group_name, YEAR(date)
ORDER BY yr

-- save as a view, then possibly view on chart as sum or top n performers across timeframe

-- q6: do certain areas consistently have a higher prevalence of certain types of trash?

-- test to get percentage dist

SELECT ROUND(((bev_cans / total_items) * 100), 2) AS bev_cans_pct,
yr
FROM yearly_totals
GROUP BY yr, bev_cans, total_items
ORDER BY yr ASC

-- gonna need to paste the old view and modify it to get the table we want
-- thankfully we already typed most of it

CREATE VIEW zone_yearly_totals AS 
(
SELECT year(date) AS yr,
zone,
SUM(CAST(number_of_bags AS FLOAT)) AS number_of_bags,
SUM(grocery_bags_plastic) AS grocery_bags_plastic,
SUM(CAST(other_bags_plastic AS FLOAT)) AS other_bags_plastic,
SUM(bev_bottles_glass) AS bev_bottles_glass,
SUM(bev_bottles_plastic) AS bev_bottles_plastic,
SUM(bev_cans) AS bev_cans,
SUM(CAST([bev sachets/pouches] AS FLOAT)) AS [bev_sachets/pouches],
SUM(CAST(bottle_caps_metal AS FLOAT)) AS bottle_caps_metal,
SUM(bottle_caps_plastic) AS bottle_caps_plastic,
SUM(cig_butts) AS cig_butts,
SUM(CAST(cups_plates_foam AS FLOAT)) AS cups_plates_foam,
SUM(CAST(cups_plates_paper AS FLOAT)) AS cups_plates_paper,
SUM(cups_plates_plastic) AS cups_plates_plastic,
SUM(food_container_foam) AS food_container_foam,
SUM(food_container_plastic) AS food_container_plastic,
SUM(food_wrappers) AS food_wrappers,
SUM(lids_plastic) AS lids_plastic,
SUM([straws/stirrers_plastic]) AS [straws/stirrers_plastic],
SUM(utens_plastic) AS utens_plastic,
SUM(CAST(lines_nets_traps_ropes_etc AS FLOAT)) AS lines_nets_traps_ropes_etc,
SUM(CAST(foam_dock_pcs AS FLOAT)) AS foam_dock_pcs,
SUM(CAST(appliances AS FLOAT)) AS appliances,
SUM(CAST(construction_materials AS FLOAT)) AS construction_materials,
SUM(CAST(tires AS FLOAT)) AS tires,
SUM(CAST(six_pack_holders AS FLOAT)) AS six_pack_holders,
SUM(CAST(foam_packaging AS FLOAT)) AS foam_packaging,
SUM(CAST(other_plastic_bottles_ie_oil_bleach AS FLOAT)) AS other_plastic_bottles_ie_oil_bleach,
SUM(CAST(strapping_bands AS FLOAT)) AS strapping_bands,
SUM(balloons) AS balloons,
SUM(CAST(clothing AS FLOAT)) AS clothing,
SUM(CAST(ecigs AS FLOAT)) AS ecigs,
SUM(CAST(electronic_waste AS FLOAT)) AS electionic_waste,
SUM(CAST(footwear AS FLOAT)) AS footwear,
SUM(CAST(paper_bags AS FLOAT)) AS paper_bags,
SUM(CAST(tobacco_prods AS FLOAT)) AS tobacco_prods,
SUM(toys) AS toys,
SUM(CAST(other_plastic_waste AS FLOAT)) AS other_plastic_waste,
SUM(CAST(other_waste_metal_paper_etc AS FLOAT)) AS other_waste_paper_metal_etc,
SUM(CAST(condoms AS FLOAT)) AS condoms,
SUM(CAST(cotton_swabs AS FLOAT)) AS cotton_swabs,
SUM(CAST(diapers AS FLOAT)) AS diapers,
SUM(CAST(gloves_masks AS FLOAT)) AS gloves_masks,
SUM(CAST(syringes AS FLOAT)) AS syringes,
SUM(CAST(tampons_and_applicators AS FLOAT)) AS tampons_and_applicators,
SUM(CAST(plastic_o_foam_pcs AS FLOAT)) AS plastic_o_foam_pcs,
SUM(CAST(fishing_boys_pots_traps AS FLOAT)) AS fishing_boys_pots_traps,
SUM(CAST(fishing_nets_and_pieces AS FLOAT)) AS fishing_nets_and_pieces,
SUM(CAST([fishing_line_1yd/m_1piece] AS FLOAT)) AS fishing_line,
SUM(CAST([rope_1yd/m_1piece] AS FLOAT)) AS rope,
SUM(fishing_gear_clean_swell) AS fishing_gear_clean_swell,
SUM(CAST(other_plastic_foam_pckg AS FLOAT)) AS other_plastic_foam_pckg,
SUM(CAST(tobacco_pckg_wrap AS FLOAT)) AS tobacco_pckg_wrap,
SUM(other_pckg_clean_swell) AS other_pckg_clean_swell,
SUM(CAST(cigar_tips AS FLOAT)) AS cigar_tips,
SUM(CAST(cig_lighters AS FLOAT)) AS cig_lighters,
SUM(CAST(fireworks AS FLOAT)) AS fireworks,
SUM(other_trash_clean_swell) AS other_trash_clean_swell,
SUM(CAST(other_tobacco_pckg_lighter_etc AS FLOAT)) AS other_tobacco_pckg_lighter_etc,
SUM(person_hygiene_clean_swell) AS personal_hygiene_clean_swell,
SUM(CAST(foam_pcs AS FLOAT)) AS foam_pcs,
SUM(CAST(glass_pcs AS FLOAT)) AS glass_pcs,
SUM(plastic_pcs) AS plastic_pcs,
SUM(total_items_collected) AS total_items
FROM [18-23_cleanups]
GROUP BY YEAR(date), zone
)

-- sanity check

SELECT TOP 10 *
FROM zone_yearly_totals

-- testing

SELECT yr,
zone,
MAX(ROUND((GREATEST(number_of_bags, grocery_bags_plastic, other_bags_plastic,
					bev_bottles_glass, bev_bottles_plastic, bev_cans,
					[bev_sachets/pouches], bottle_caps_metal, bev_bottles_plastic,
					cig_butts, cups_plates_foam, cups_plates_paper,
					cups_plates_plastic, food_container_foam, food_container_plastic,
					food_wrappers, lids_plastic, [straws/stirrers_plastic],
					utens_plastic, lines_nets_traps_ropes_etc, foam_dock_pcs,
					appliances, construction_materials, tires,
					six_pack_holders, foam_packaging, other_plastic_bottles_ie_oil_bleach,
					strapping_bands, balloons, clothing,
					ecigs, electionic_waste, footwear,
					paper_bags, tobacco_prods, toys,
					other_plastic_waste, other_waste_paper_metal_etc, condoms,
					cotton_swabs, diapers, gloves_masks,
					syringes, tampons_and_applicators, plastic_o_foam_pcs,
					fishing_boys_pots_traps, fishing_nets_and_pieces, fishing_line,
					rope, fishing_gear_clean_swell, other_plastic_foam_pckg, 
					tobacco_pckg_wrap, other_pckg_clean_swell, cigar_tips,
					cig_lighters, fireworks, other_trash_clean_swell, other_tobacco_pckg_lighter_etc,
					personal_hygiene_clean_swell) / total_items) * 100, 2)) AS max_trash_composition_pct
FROM zone_yearly_totals
GROUP BY yr, zone
ORDER BY yr ASC, max_trash_composition_pct DESC

-- finding composition answer

WITH trash_comp AS (
    SELECT
        yr,
        zone,
        TRASH_TYPE,
        MAX(ROUND((TRASH_TYPE_VALUE / total_items) * 100, 2)) AS max_trash_composition_pct,
        ROW_NUMBER() OVER (PARTITION BY yr, zone ORDER BY TRASH_TYPE_VALUE DESC) AS rn
    FROM zone_yearly_totals
    UNPIVOT (
        TRASH_TYPE_VALUE FOR TRASH_TYPE IN (
            number_of_bags, grocery_bags_plastic, other_bags_plastic,
            bev_bottles_glass, bev_bottles_plastic, bev_cans,
            [bev_sachets/pouches], bottle_caps_metal,
            cig_butts, cups_plates_foam, cups_plates_paper,
            cups_plates_plastic, food_container_foam, food_container_plastic,
            food_wrappers, lids_plastic, [straws/stirrers_plastic],
            utens_plastic, lines_nets_traps_ropes_etc, foam_dock_pcs,
            appliances, construction_materials, tires,
            six_pack_holders, foam_packaging, other_plastic_bottles_ie_oil_bleach,
            strapping_bands, balloons, clothing,
            ecigs, electionic_waste, footwear,
            paper_bags, tobacco_prods, toys,
            other_plastic_waste, other_waste_paper_metal_etc, condoms,
            cotton_swabs, diapers, gloves_masks,
            syringes, tampons_and_applicators, plastic_o_foam_pcs,
            fishing_boys_pots_traps, fishing_nets_and_pieces, fishing_line,
            rope, fishing_gear_clean_swell, other_plastic_foam_pckg, 
            tobacco_pckg_wrap, other_pckg_clean_swell, cigar_tips,
            cig_lighters, fireworks, other_trash_clean_swell, other_tobacco_pckg_lighter_etc,
            personal_hygiene_clean_swell)
    ) AS unpivoted
    GROUP BY yr, zone, TRASH_TYPE, TRASH_TYPE_VALUE, total_items
)

SELECT
    yr,
    zone,
    TRASH_TYPE,
    max_trash_composition_pct
FROM trash_comp
WHERE rn = 1
AND max_trash_composition_pct IS NOT NULL
ORDER BY yr ASC, max_trash_composition_pct DESC

-- q9: what are the most common types of trash collected during beach cleanups?

WITH trash_comp AS (
    SELECT
        yr,
        zone,
        TRASH_TYPE,
        MAX(ROUND((TRASH_TYPE_VALUE / total_items) * 100, 2)) AS max_trash_composition_pct,
        ROW_NUMBER() OVER (PARTITION BY yr, zone ORDER BY TRASH_TYPE_VALUE DESC) AS rn
    FROM zone_yearly_totals
    UNPIVOT (
        TRASH_TYPE_VALUE FOR TRASH_TYPE IN (
            number_of_bags, grocery_bags_plastic, other_bags_plastic,
            bev_bottles_glass, bev_bottles_plastic, bev_cans,
            [bev_sachets/pouches], bottle_caps_metal,
            cig_butts, cups_plates_foam, cups_plates_paper,
            cups_plates_plastic, food_container_foam, food_container_plastic,
            food_wrappers, lids_plastic, [straws/stirrers_plastic],
            utens_plastic, lines_nets_traps_ropes_etc, foam_dock_pcs,
            appliances, construction_materials, tires,
            six_pack_holders, foam_packaging, other_plastic_bottles_ie_oil_bleach,
            strapping_bands, balloons, clothing,
            ecigs, electionic_waste, footwear,
            paper_bags, tobacco_prods, toys,
            other_plastic_waste, other_waste_paper_metal_etc, condoms,
            cotton_swabs, diapers, gloves_masks,
            syringes, tampons_and_applicators, plastic_o_foam_pcs,
            fishing_boys_pots_traps, fishing_nets_and_pieces, fishing_line,
            rope, fishing_gear_clean_swell, other_plastic_foam_pckg, 
            tobacco_pckg_wrap, other_pckg_clean_swell, cigar_tips,
            cig_lighters, fireworks, other_trash_clean_swell, other_tobacco_pckg_lighter_etc,
            personal_hygiene_clean_swell)
    ) AS unpivoted
    GROUP BY yr, zone, TRASH_TYPE, TRASH_TYPE_VALUE, total_items
),

actual_totals AS
(
SELECT
    yr,
    TRASH_TYPE,
    max_trash_composition_pct
FROM trash_comp
WHERE rn = 1
AND max_trash_composition_pct IS NOT NULL
)

SELECT yr,
TRASH_TYPE,
SUM(max_trash_composition_pct) AS total_comp
FROM actual_totals
GROUP BY yr, TRASH_TYPE
ORDER BY yr ASC, total_comp DESC

-- q10: are there any changes in the composition of litter over the years? (percent of total dist)
-- using LA (and possibly two other examples) as examples so theres not 7000 rows

WITH zone_types AS 
(
SELECT yr,
zone,
TRASH_TYPE,
(ROUND((TRASH_TYPE_VALUE / total_items) * 100, 2)) AS trash_composition_pct,
ROW_NUMBER() OVER (PARTITION BY yr, zone ORDER BY TRASH_TYPE_VALUE DESC) AS rn
FROM zone_yearly_totals
    UNPIVOT (
        TRASH_TYPE_VALUE FOR TRASH_TYPE IN (
            number_of_bags, grocery_bags_plastic, other_bags_plastic,
            bev_bottles_glass, bev_bottles_plastic, bev_cans,
            [bev_sachets/pouches], bottle_caps_metal,
            cig_butts, cups_plates_foam, cups_plates_paper,
            cups_plates_plastic, food_container_foam, food_container_plastic,
            food_wrappers, lids_plastic, [straws/stirrers_plastic],
            utens_plastic, lines_nets_traps_ropes_etc, foam_dock_pcs,
            appliances, construction_materials, tires,
            six_pack_holders, foam_packaging, other_plastic_bottles_ie_oil_bleach,
            strapping_bands, balloons, clothing,
            ecigs, electionic_waste, footwear,
            paper_bags, tobacco_prods, toys,
            other_plastic_waste, other_waste_paper_metal_etc, condoms,
            cotton_swabs, diapers, gloves_masks,
            syringes, tampons_and_applicators, plastic_o_foam_pcs,
            fishing_boys_pots_traps, fishing_nets_and_pieces, fishing_line,
            rope, fishing_gear_clean_swell, other_plastic_foam_pckg, 
            tobacco_pckg_wrap, other_pckg_clean_swell, cigar_tips,
            cig_lighters, fireworks, other_trash_clean_swell, other_tobacco_pckg_lighter_etc,
            personal_hygiene_clean_swell)
    ) AS unpivoted
GROUP BY yr, zone, TRASH_TYPE, TRASH_TYPE_VALUE, total_items
)

SELECT yr,
zone,
TRASH_TYPE AS largest_reported_trash_type,
CONCAT(trash_composition_pct,'%') AS percent_of_all_trash
FROM zone_types
WHERE zone IN('Los Angeles County, CA, USA',
			  'Monterey County, CA, USA',
			  'San Luis Obispo County, CA, USA')
AND rn = 1
ORDER BY zone ASC, yr ASC

-- view for tableau

CREATE VIEW monthly_group_totals AS 
(
SELECT date,
zone,
group_name,
SUM(CAST(number_of_bags AS FLOAT)) AS number_of_bags,
SUM(grocery_bags_plastic) AS grocery_bags_plastic,
SUM(CAST(other_bags_plastic AS FLOAT)) AS other_bags_plastic,
SUM(bev_bottles_glass) AS bev_bottles_glass,
SUM(bev_bottles_plastic) AS bev_bottles_plastic,
SUM(bev_cans) AS bev_cans,
SUM(CAST([bev sachets/pouches] AS FLOAT)) AS [bev_sachets/pouches],
SUM(CAST(bottle_caps_metal AS FLOAT)) AS bottle_caps_metal,
SUM(bottle_caps_plastic) AS bottle_caps_plastic,
SUM(cig_butts) AS cig_butts,
SUM(CAST(cups_plates_foam AS FLOAT)) AS cups_plates_foam,
SUM(CAST(cups_plates_paper AS FLOAT)) AS cups_plates_paper,
SUM(cups_plates_plastic) AS cups_plates_plastic,
SUM(food_container_foam) AS food_container_foam,
SUM(food_container_plastic) AS food_container_plastic,
SUM(food_wrappers) AS food_wrappers,
SUM(lids_plastic) AS lids_plastic,
SUM([straws/stirrers_plastic]) AS [straws/stirrers_plastic],
SUM(utens_plastic) AS utens_plastic,
SUM(CAST(lines_nets_traps_ropes_etc AS FLOAT)) AS lines_nets_traps_ropes_etc,
SUM(CAST(foam_dock_pcs AS FLOAT)) AS foam_dock_pcs,
SUM(CAST(appliances AS FLOAT)) AS appliances,
SUM(CAST(construction_materials AS FLOAT)) AS construction_materials,
SUM(CAST(tires AS FLOAT)) AS tires,
SUM(CAST(six_pack_holders AS FLOAT)) AS six_pack_holders,
SUM(CAST(foam_packaging AS FLOAT)) AS foam_packaging,
SUM(CAST(other_plastic_bottles_ie_oil_bleach AS FLOAT)) AS other_plastic_bottles_ie_oil_bleach,
SUM(CAST(strapping_bands AS FLOAT)) AS strapping_bands,
SUM(balloons) AS balloons,
SUM(CAST(clothing AS FLOAT)) AS clothing,
SUM(CAST(ecigs AS FLOAT)) AS ecigs,
SUM(CAST(electronic_waste AS FLOAT)) AS electionic_waste,
SUM(CAST(footwear AS FLOAT)) AS footwear,
SUM(CAST(paper_bags AS FLOAT)) AS paper_bags,
SUM(CAST(tobacco_prods AS FLOAT)) AS tobacco_prods,
SUM(toys) AS toys,
SUM(CAST(other_plastic_waste AS FLOAT)) AS other_plastic_waste,
SUM(CAST(other_waste_metal_paper_etc AS FLOAT)) AS other_waste_paper_metal_etc,
SUM(CAST(condoms AS FLOAT)) AS condoms,
SUM(CAST(cotton_swabs AS FLOAT)) AS cotton_swabs,
SUM(CAST(diapers AS FLOAT)) AS diapers,
SUM(CAST(gloves_masks AS FLOAT)) AS gloves_masks,
SUM(CAST(syringes AS FLOAT)) AS syringes,
SUM(CAST(tampons_and_applicators AS FLOAT)) AS tampons_and_applicators,
SUM(CAST(plastic_o_foam_pcs AS FLOAT)) AS plastic_o_foam_pcs,
SUM(CAST(fishing_boys_pots_traps AS FLOAT)) AS fishing_boys_pots_traps,
SUM(CAST(fishing_nets_and_pieces AS FLOAT)) AS fishing_nets_and_pieces,
SUM(CAST([fishing_line_1yd/m_1piece] AS FLOAT)) AS fishing_line,
SUM(CAST([rope_1yd/m_1piece] AS FLOAT)) AS rope,
SUM(fishing_gear_clean_swell) AS fishing_gear_clean_swell,
SUM(CAST(other_plastic_foam_pckg AS FLOAT)) AS other_plastic_foam_pckg,
SUM(CAST(tobacco_pckg_wrap AS FLOAT)) AS tobacco_pckg_wrap,
SUM(other_pckg_clean_swell) AS other_pckg_clean_swell,
SUM(CAST(cigar_tips AS FLOAT)) AS cigar_tips,
SUM(CAST(cig_lighters AS FLOAT)) AS cig_lighters,
SUM(CAST(fireworks AS FLOAT)) AS fireworks,
SUM(other_trash_clean_swell) AS other_trash_clean_swell,
SUM(CAST(other_tobacco_pckg_lighter_etc AS FLOAT)) AS other_tobacco_pckg_lighter_etc,
SUM(person_hygiene_clean_swell) AS personal_hygiene_clean_swell,
SUM(CAST(foam_pcs AS FLOAT)) AS foam_pcs,
SUM(CAST(glass_pcs AS FLOAT)) AS glass_pcs,
SUM(plastic_pcs) AS plastic_pcs,
SUM(total_items_collected) AS total_items
FROM cleanups$
GROUP BY date, zone, group_name
)

-- unpivoting the data to aid in visualization within tableau

SELECT
    date,
    zone,
    group_name,
	cleanup_id,
	gps,
	lat,
	lon,
	regions,
    Variable,
    Value
FROM
    cleanups$
UNPIVOT
(
    Value FOR Variable IN (
        number_of_bags,
        grocery_bags_plastic,
        other_bags_plastic,
        bev_bottles_glass,
        bev_bottles_plastic,
        bev_cans,
        [bev sachets/pouches],
        bottle_caps_metal,
        bottle_caps_plastic,
        cig_butts,
        cups_plates_foam,
        cups_plates_paper,
        cups_plates_plastic,
        food_container_foam,
        food_container_plastic,
        food_wrappers,
        lids_plastic,
        [straws/stirrers_plastic],
        utens_plastic,
        lines_nets_traps_ropes_etc,
        foam_dock_pcs,
        appliances,
        construction_materials,
        tires,
        six_pack_holders,
        foam_packaging,
        other_plastic_bottles_ie_oil_bleach,
        strapping_bands,
        balloons,
        clothing,
        ecigs,
        electronic_waste,
        footwear,
        paper_bags,
        tobacco_prods,
        toys,
        other_plastic_waste,
        other_waste_metal_paper_etc,
        condoms,
        cotton_swabs,
        diapers,
        gloves_masks,
        syringes,
        tampons_and_applicators,
        plastic_o_foam_pcs,
        fishing_boys_pots_traps,
        fishing_nets_and_pieces,
        [fishing_line_1yd/m_1piece],
        [rope_1yd/m_1piece],
        fishing_gear_clean_swell,
        other_plastic_foam_pckg,
        tobacco_pckg_wrap,
        other_pckg_clean_swell,
        cigar_tips,
        cig_lighters,
        fireworks,
        other_trash_clean_swell,
        other_tobacco_pckg_lighter_etc,
        person_hygiene_clean_swell,
        foam_pcs,
        glass_pcs,
        plastic_pcs,
        total_items_collected
    )
) AS UnpivotedData;
