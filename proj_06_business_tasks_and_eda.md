# California Beach Cleanup Analysis
## EDA and Business Tasks

__Author__: Daniel Perez <br />
__Email__: dannypere11@gmail.com <br />
__LinkedIn__: https://www.linkedin.com/in/danielperez12/ <br />

__1.__ What are the monthly or seasonal variations in the number of beach cleanup events?

```sql
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
```
__Results:__

Limiting results to 15 of 72 rows for the sake of brevity.

mnth  |      yr    |      total_cleanups | monthly_total 
|-----------|----------|--------------|-------------|
1   |        2018    |    128     |       13322
2   |        2018    |    78      |       26908
3   |        2018    |    144     |       50857
4   |        2018    |    169     |       94026
5   |        2018    |    102     |       111605
6   |        2018    |    140     |       138766
7   |        2018    |    143     |       165552
8   |        2018    |    119     |       186244
9   |        2018    |    1544    |       673290
10  |        2018    |    145     |       764949
11  |        2018    |    106     |       786677
12  |        2018    |    94      |       809438
1   |        2019    |    118     |       21310
2   |       2019     |   93       |      46971
3   |        2019    |    148     |       66416

(insert chart here)

__2.__ Are there specific months or seasons when certain types of trash are more prevalent?

__3.__ Can we identify any long-term trends or patterns in the frequency of cleanup efforts over the timeframe?

```sql
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
```

__Results:__

Results limited to 14 of 72 rows for the sake of brevity.

mnth  | yr  | foam_total       |      plastic_total  |        glass_total
|-----|-----|-----------------|----------------------|-----------------|
1    |       2018  |      851        |            2890    |               78
2    |       2018  |      1133       |            5911    |          147
3    |       2018  |      1876       |            11193   |            489
4    |       2018  |      3221       |    20906         |         3001
5    |       2018  |      3346        |      24633      |            3297
6    |       2018  |      3763        |      32964      |            3372
7    |       2018  |      4108        |   37152         |         3756
8    |       2018  |      4480        |   39773         |         3893
9    |       2018  |      32824       |   106509        |         24459
10   |       2018   |     47741     |  129703           |      26435
11   |       2018   |     50176    |  132785            |     26730
12   |       2018   |     50372     |  138389           |      26985
1    |       2019  |      197        |  5794            |       50
2    |       2019  |      566         |       13279     |             80


__4.__ Which beaches/regions have the highest/lowest recorded frequency of cleanup efforts?

```sql
SELECT TOP 5
COUNT(DISTINCT cleanup_id) AS cleanup_count,
zone
FROM [18-23_cleanups]
GROUP BY zone
ORDER BY cleanup_count DESC
```

__Results:__

cleanup_count  | zone
|------------|--------------------------|
7442      |    San Mateo County, CA, USA
5811      |    Los Angeles County, CA, USA
3777      |    San Diego County, CA, USA
2936      |    Alameda County, CA, USA
2201      |    Orange County, CA, USA

```sql
SELECT
COUNT(DISTINCT cleanup_id) AS cleanup_count,
zone
FROM [18-23_cleanups]
GROUP BY zone
ORDER BY cleanup_count ASC
OFFSET 1 ROW
```

__Results:__

For lowest counts, we skip Cayucos (row 1) since it's technically a city.

cleanup_count  | zone
|---------------|------------------|
1     |       Lassen County, CA, USA
1     |        Sierra County, CA, USA
1     |        Trinity County, CA, USA
2     |        Yuba County, CA, USA
2     |        Kings County, CA, USA
2     |        Glenn County, CA, USA
2     |        Amador County, CA, USA
2     |        Plumas County, CA, USA
3     |        Butte County, CA, USA
3     |       Colusa County, CA, USA
3     |        Tehama County, CA, USA
3     |        Siskiyou County, CA, USA

__5.__ Is there any correlation between the frequency of cleanups and proximity to colleges?

```sql
-- group cleanup quantities in relation to proximity to college

SELECT 
(AVG(min_dist_miles * cleanups) - (AVG(min_dist_miles) * AVG(cleanups))) / 
(StDevP(min_dist_miles) * StDevP(cleanups)) as pearson_coefficient,
(AVG(min_dist_miles * cleanups) - (AVG(min_dist_miles) * AVG(cleanups))) as numerator,
(StDevP(min_dist_miles) * StDevP(cleanups))  as denominator
FROM group_distances
GO
```

__Results:__

pearson_coefficient |   numerator      |        denominator
|----------------------|---------------------|----------------------|
0.005 |   0.559   |   109.790

```sql
-- zone cleanups in relation to proximity to college

SELECT 
(AVG(min_dist_miles * cleanups) - (AVG(min_dist_miles) * AVG(cleanups))) / 
(StDevP(min_dist_miles) * StDevP(cleanups)) as pearson_coefficient,
(AVG(min_dist_miles * cleanups) - (AVG(min_dist_miles) * AVG(cleanups))) as numerator,
(StDevP(min_dist_miles) * StDevP(cleanups))  as denominator
FROM zone_distances
GO
```

__Results:__

pearson_coefficient  |  numerator       |       denominator
|----------------------|----------------------|----------------------|
-0.192  |   -1121.712  |    5814.470

__6.__ Do certain areas consistently have a higher prevalence of certain types of trash?

```sql
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
```

__Results:__

Limited to 5 rows for the sake of brevity.

yr     |     zone   |     TRASH_TYPE    |    max_trash_composition_pct
|-----------|--------------|-------------------|-------------------------|
2018 |   Tulare County, CA, USA |   food_wrappers    |          50
2018 |      Napa County, CA, USA |    cig_butts      |      43.31
2018 |   Sierra County, CA, USA  |  food_wrappers   | 33.95
2018 |       Monterey County, CA, USA  |         cig_butts  |    33.18
2018 |       Contra Costa County, CA, USA  |           cig_butts  |   32.18

__7.__ What is the distribution of cleanup efforts among different groups across the timeframe?

```sql
SELECT COUNT(DISTINCT cleanup_id) AS cleanups,
group_name,
YEAR(date) AS yr
FROM [18-23_cleanups]
GROUP BY group_name, YEAR(date)
ORDER BY yr
```

__Results:__

Limited to 9 rows for the sake of brevity.

cleanups  |  group_name |          yr
|----------|-------------|----------------|
1002    |    NULL                      |          2018
1       |    #TeamCVS                  |          2018
3       |    #TeamCVS #Coram           |          2018
1       |    #TeamPineapplePrincess    |          2018
2       |    01062018                  |          2018
19      |    1                         |          2018
2       |    1/6/2018                  |          2018
1       |    1618 NB                   |          2018
1       |    1-6-18 NB                 |          2018

__8.__ Are there groups that consistently perform well in terms of the amount of trash collected or the number of cleanup events?

```sql
-- by number of cleanups

SELECT TOP 6
DISTINCT(group_name) AS grp,
COUNT(DISTINCT cleanup_id) AS cleanups
FROM [18-23_cleanups]
WHERE group_name NOT IN('1','2','No group name') -- not relevant to the question
AND group_name IS NOT NULL
GROUP BY group_name
ORDER BY cleanups DESC
```

__Results:__

grp               |                                 cleanups
|-----------------------------|--------------------------------|
Pacific beach coalition         |                   2630
Heal the bay                    |                   524
Pacifica Beach Coalition        |                   455
Explore Ecology                 |                   380
Sea Hugger                      |                   366
Noyo Center for Marine Science  |                   356

```sql
-- by amount of trash pieces

SELECT DISTINCT(group_name) AS grp,
SUM(total_items_collected) AS total_trash
FROM [18-23_cleanups]
WHERE group_name NOT IN ('1','2','No group name')
AND group_name IS NOT NULL
AND YEAR(date) != 2023
GROUP BY group_name
ORDER BY total_trash DESC
```

__Results:__

grp          |                    total_trash
|----------------------------------|---------------|
Pacific Beach Coalition           |                 388505
Environmental Center of San Luis Obispo    |        159366
I love a clean San Diego              |             127515
Heal The Bay                        |               60305
International Shoreline Cleanup 2019     |          51881
Explore Ecology                       |             46394

__9.__ What are the most common types of trash collected during beach cleanups?

```sql
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
```

__Results:__

yr     |     TRASH_TYPE        |          total_comp
|-------|------------------------|-----------------------------------------|
2018    |    cig_butts                   |                       586.25
2018    |    food_wrappers               |                       198.7
2018    |    bev_cans                    |                       24.69
2018    |    other_trash_clean_swell     |                       16.67
2018    |    rope                        |                       15.15
2019    |    cig_butts                   |                       476.33
2019    |    other_trash_clean_swell     |                       98.22
2019    |    food_wrappers               |                       68.68
2019    |    bev_bottles_plastic         |                       30.99
2019    |    utens_plastic               |                       21.88
2019    |    food_container_plastic      |                       17.76
2020    |    cig_butts                   |                       617.88
2020    |    other_trash_clean_swell     |                       226.17
2020    |    food_wrappers               |                       70.55
2020    |    bottle_caps_metal           |                       24.14
2020    |    bev_cans                    |                       13.33
2020    |    other_pckg_clean_swell      |                       10.71
2021    |    cig_butts                   |                       582.21
2021    |    number_of_bags              |                       121.43
2021    |    food_wrappers               |                       98.83
2021    |    bev_cans                    |                       80
2021    |    other_trash_clean_swell     |                       47.87
2021    |    gloves_masks                |                       36.67
2022    |    cig_butts                   |                       462.52
2022    |    plastic_o_foam_pcs          |                       211.29
2022    |    other_waste_paper_metal_etc |                       85.71
2022    |    number_of_bags              |                       85.25
2022    |    bev_cans                    |                       40.03
2022    |    other_trash_clean_swell     |                       37.72
2022    |    food_wrappers               |                       22.7
2022    |    bev_bottles_plastic         |                       21.89
2023    |    plastic_o_foam_pcs          |                       357.15
2023    |    cig_butts                   |                       356.03
2023    |    food_wrappers               |                       56.61
2023    |    other_plastic_waste         |                       42.46
2023    |    other_bags_plastic          |                       40.41
2023    |    other_waste_paper_metal_etc |                       37.82
2023    |    grocery_bags_plastic        |                       16.93
2023    |    bev_bottles_glass           |                       11.76

__10.__ Are there any changes in the composition of litter over the years? (We'll use three example cities for now.)

```sql
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
```

__Results:__

yr  |  zone  |      largest_reported_trash_type   |  percent_of_all_trash
|----|---------|-------------------------------------|----------------------|
2018   |     Los Angeles County, CA, USA   |    cig_butts    |      13.02%
2019   |     Los Angeles County, CA, USA   |    cig_butts    |     12.76%
2020   |    Los Angeles County, CA, USA    |   cig_butts    |   12.39%
2021   |     Los Angeles County, CA, USA   |   cig_butts    |   12.16%
2022   |     Los Angeles County, CA, USA   |  plastic_o_foam_pcs  |   21.39%
2023   |     Los Angeles County, CA, USA   |  plastic_o_foam_pcs  |    25.15%
2018   |     Monterey County, CA, USA      |  cig_butts    |     33.18%
2019   |     Monterey County, CA, USA      |   cig_butts   |   38.84%
2020   |     Monterey County, CA, USA      |   cig_butts    |     14.8%
2021   |    Monterey County, CA, USA    |   cig_butts   |   14.34%
2022   |     Monterey County, CA, USA   |    cig_butts  |    17.66%
2023   |     Monterey County, CA, USA    |    cig_butts  |   23.6%
2018   |     San Luis Obispo County, CA, USA  |    cig_butts |    32.09%
2019   |     San Luis Obispo County, CA, USA  |    cig_butts |    36.34%
2020   |     San Luis Obispo County, CA, USA  |    cig_butts |    19.79%
2021   |     San Luis Obispo County, CA, USA  |   cig_butts  |    22.55%
2022   |     San Luis Obispo County, CA, USA  |  food_wrappers |  14.96%
2023   |     San Luis Obispo County, CA, USA  |  plastic_o_foam_pcs |  21.63%
