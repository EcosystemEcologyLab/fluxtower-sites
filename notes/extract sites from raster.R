# R code for extracting zonal statistics for all fluxtower sites from a single AGB product

library(fs)
library(sf)
library(terra)
library(readr)
library(exactextractr)
library(units)
library(tidyr)
library(dplyr)

sf_use_s2(TRUE)
source("R/calc_ffp_radius.R")

# root <- "/Volumes/moore/AGB_cleaned"
root <- "d://AGB_cleaned/"

# file_path <- path(root, "liu/liu_1993-2012.tif")
# file_path <- path(root, "xu/xu_2000-2029.tif")
file_path <- dir_ls(path(root, "esa_cci"), glob = "*.tif")


#read in raster with terra
if (length(file_path) == 1){
  raster <- rast(file_path)
} else { #if it's tiles, read in as a vrt
  raster <- vrt(file_path, set_names = TRUE)
}

#create weighting raster of ha/pixel
raster_ha <- cellSize(raster, unit = "ha")

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

#TODO: Could be good to do some data validation here
hist(sites_sf$radius)

sites_buffer <-
  sites_sf %>% 
  #create circle polygons with buffer in meters
  st_buffer(dist = set_units(.$radius, "m")) |> 
  #add column with folder name on snow
  mutate(product = unique(path_file(path_dir(file_path))))

# extract total AGB from each site
df <- exact_extract(
  raster,
  sites_buffer,
  fun = "weighted_sum", #sum(Mg/ha * fraction of pixel covered * ha/pixel) = total Mg
  weights = raster_ha, #ha/pixel
  append_cols = TRUE,
  force_df = TRUE,
  stack_apply = TRUE #can be done independently for each layer to save memory
)

# tidy data
df_tidy <- df |> 
  pivot_longer(
    starts_with("weighted_sum."),
    names_to = "year",
    names_prefix = "weighted_sum.", 
    values_to = "agb_Mg"
  ) |> 
  mutate(year = as.integer(year))

# plot data to see if it worked
library(ggplot2)
ggplot(df_tidy, aes(x = year, y = agb_Mg, group = SITE_ID, color = SITE_ID)) +
  geom_line(alpha = 0.4) +
  geom_point(aes(size = radius), alpha = 0.4) + #not good viz, just seeing if footprint radius matters much
  theme(legend.position = "none")
