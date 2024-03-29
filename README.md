# California Beach Cleanups

__Author__: Daniel Perez <br />
__Email__: dannypere11@gmail.com <br />
__LinkedIn__: https://www.linkedin.com/in/danielperez12/ <br />

## Introduction
A TSQL analysis of trash pickup efforts within California beaches and related counties from 2018 to 2023. From the business tasks, we'll gather insights that we can use to guide our recommendations.

* [Business Tasks and EDA](https://github.com/danny814/California-Beach-Cleanups/blob/main/proj_06_business_tasks_and_eda.md)
* [Full TSQL File](https://github.com/danny814/California-Beach-Cleanups/blob/main/proj_06_30.sql)
* [Tableau Visualization](https://public.tableau.com/app/profile/danny.perez/viz/CaliforniaBeachCleanups/Dashboard)
* [Analysis-Based Recommendations](https://github.com/danny814/California-Beach-Cleanups/blob/main/proj_06_recs.md)

![Screenshot 2024-03-11 212148](https://github.com/danny814/California-Beach-Cleanups/assets/139296999/fb7d1ea5-903f-4855-aa8e-e8d7d2ed91eb)


## Data Used
Two datasets were used for this project:

* __18-23_cleanups.csv__: Data collected from the "Detailed Reports" option on TIDES for the state of California from 2018 to 2023. Note that a large part of 2023 data is missing.
* __cal_colleges.csv__: Geolocation data for California college campuses collected from the National Center for Education Statistics.

The data can be found at the following sites:

* [California Public Colleges and Universities Geodata](https://storymaps.arcgis.com/stories/3e441e82209a4a28a1591a73cb0c18b7?play=true&speed=medium)
* [TIDES: Trash Information and Data for Education and Solutions](https://www.coastalcleanupdata.org/reports)

## Table Schema

![drawSQL-image-export-2024-03-13](https://github.com/danny814/California-Beach-Cleanups/assets/139296999/43f513d1-1d08-48d8-aefd-a95a432cc894)
