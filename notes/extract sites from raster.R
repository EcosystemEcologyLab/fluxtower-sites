library(fs)
library(sf)
library(terra)
library(readr)
library(exactextractr)
library(units)
library(tidyr)
library(dplyr)

# file_path <- "/Volumes/moore/AGB_cleaned/liu/liu_1993-2012.tif"
file_path <- "/Volumes/moore/AGB_cleaned/esa_cci/esa.cci_N40W110_2010.2017-2020.tif"

#read in raster with terra
raster <- rast(file_path)

#read in sites csv
sites_df <- 
  read_csv("fluxtower_locations.csv") 

#conver to sf object
sites_sf <- 
  sites_df |> 
  st_as_sf(coords = c("lon", "lat")) |> 
  st_set_crs("WGS84") |> 
  st_transform(crs(raster))


#get raster boundaries
raster_bbox <- st_bbox(raster) |>
  st_as_sfc() |> #needs to be sfc object
  st_set_crs(crs(raster)) #needs to have CRS set

sites_buffer <-
  sites_sf |> 
  #filter sites to only those within raster boundaries
  st_intersection(raster_bbox) %>% 
  #create circle polygons with buffer in meters
  st_buffer(dist = set_units(.$buffer_radius_m, "m")) |> 
  #add column with folder name on snow
  mutate(product = path_file(path_dir(file_path)))

# extract total AGB from each site
df <- exact_extract(raster, sites_buffer, fun = "sum", append_cols = TRUE, force_df = TRUE)

# tidy data
df |> 
  pivot_longer(
    starts_with("sum."),
    names_to = "year",
    names_prefix = "sum.",
    values_to = "agb"
  )
