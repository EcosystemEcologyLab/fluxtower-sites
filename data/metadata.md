Metadata for files in fluxtower-sites data folder

FLUXNET_YY_FAO_gez_KG.csv : contains annual averages of measurements taken at FluxNet tower sites. See data variables page for column name codes and measurement units (https://fluxnet.org/data/aboutdata/data-variables/).

Fluxnet_MD_Jun2024.txt : FluxNet metadata records as of June 2024 for all tower sites. Downloaded from fluxnet.org. See data variables page for column name codes and measurement units (https://fluxnet.org/data/aboutdata/data-variables/). Also includes IGBP, GEZ, and Koppen land classification metadata.

ffp_inputs.csv : File generated from ffp_input_vars.R in FLUXNETMetadata repository. Contains necessary values for estimating tower footprint radii, including tower codes (SITE_ID), tower location (LOCATION_LAT, LOCATION_LONG), average wind speed in m/s (avg_WS), average friction velocity in m/s (avg_ustar), canopy height in m (HEIGHTC), sensor height in m (SENSOR_HEIGHT), and sensor height above displacement height (assumed to be 2/3 canopy height) in m (ZM_F). ZM_QC is a quality flag for ZM_F: rows with values in ZM_F that have a corresponding value of 0 in ZM_QC have been gapfilled based on a simple linear model of calculated ZM_F values. 

