# R code for extracting zonal statistics for all fluxtower sites from a single AGB product

library(fs)
library(sf)
library(terra)
library(readr)
library(exactextractr)
library(units)
library(tidyr)
library(dplyr)

#TODO This doesn't work totally as I'd expect with s2 geometry on, but I get
#errors with it off due to inability to calculate a buffer in degrees from a
#radius in meters.  I think the solution is to project to a CRS that has units
#of meters, not lat/lon maybe?
sf_use_s2(TRUE)
source("R/calc_ffp_radius.R")

# root <- "/Volumes/moore/AGB_cleaned"
root <- "d://AGB_cleaned/"

# file_path <- path(root, "liu/liu_1993-2012.tif")
file_path <- path(root, "esa_cci/esa.cci_N40W110_2010.2017-2020.tif")

#read in raster with terra
raster <- rast(file_path)

#read in sites csv
sites_df <- 
  read_csv("data/ffp_inputs.csv") 

#convert to sf object
sites_sf <- 
  sites_df |> 
  st_as_sf(coords = c("LOCATION_LONG", "LOCATION_LAT")) |> 
  st_set_crs("WGS84") |> 
  st_transform(crs(raster))

#calculate flux tower footprint
sites_sf <- 
  sites_sf |> 
  mutate(radius = calc_ffp_radius(zm = ZM_F, wind_speed = avg_WS, friction_velocity = avg_ustar)) |> 
  #remove sites with unknown footprint
  #TODO an alternative here would be to pick a default radius if one can't be calculated
  filter(!is.na(radius))


#get raster boundaries
raster_bbox <- st_bbox(raster) |>
  st_as_sfc() |> #needs to be sfc object
  st_set_crs(crs(raster)) #needs to have CRS set

sites_buffer <-
  sites_sf %>% 
  # #filter sites to only those within raster boundaries
  st_intersection(raster_bbox) %>%
  #create circle polygons with buffer in meters
  st_buffer(dist = set_units(.$radius, "m")) |> 
  #add column with folder name on snow
  mutate(product = path_file(path_dir(file_path)))

# extract total AGB from each site
df <- exact_extract(
  raster,
  sites_buffer,
  fun = "sum",
  append_cols = TRUE,
  force_df = TRUE
)

# tidy data
df_tidy <- df |> 
  pivot_longer(
    starts_with("sum."),
    names_to = "year",
    names_prefix = "sum.",
    values_to = "agb"
  )

# plot data to see if it worked
library(ggplot2)
ggplot(df_tidy, aes(x = year, y = agb, group = SITE_ID, color = SITE_ID)) +
  geom_line(alpha = 0.4) +
  geom_point(aes(size = radius), alpha = 0.4) + #not good viz, just seeing if radius matters much
  theme(legend.position = "none")
