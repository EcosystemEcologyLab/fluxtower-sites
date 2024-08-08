library(fs)
library(dplyr)
library(readr)
library(purrr)
library(exactextractr)
library(sf)
library(terra)
source("R/calc_ffp_radius.R")
source("R/extract_mean_agb.R")


# Read in fluxtower site data ---------------------------------------------

sites_df <-
  read_csv("data/ffp_inputs.csv") |>
  #Calculate footprint radius
  mutate(ffp_radius = calc_ffp_radius(
    zm = ZM_F,
    wind_speed = avg_WS,
    friction_velocity = avg_ustar
  )) |>
  #fill in NAs with median
  mutate(ffp_radius = ifelse(is.na(ffp_radius), median(ffp_radius, na.rm = TRUE), ffp_radius))


# Extract mean AGB for a single product -----------------------------------

# fluxtower_agb_liu <-
#   extract_mean_agb(
#     sites_df,
#     lat = "LOCATION_LAT",
#     lon = "LOCATION_LONG",
#     radius = "ffp_radius",
#     raster_dir = "d://AGB_cleaned/liu/",
#     max_cells_in_memory = 1e+07
#   )


# Extract mean AGB for all products ---------------------------------------

# root <- "d://AGB_cleaned/"
root <- "/Volumes/moore/AGB_cleaned/"

product_dirs <- dir_ls(root)

# apply extract_mean_agb to all products
# Warning: this is super slow.  Maybe you want to just do one product at a time?

agb_list <- map(product_dirs, \(.dir) {
  extract_mean_agb(
    sites_df,
    lat = "LOCATION_LAT",
    lon = "LOCATION_LONG",
    radius = "ffp_radius",
    raster_dir = .dir,
    max_cells_in_memory = 1e+07
  )
})

# comine to a single df

agb_df <- list_rbind(agb_list)

# Write results to csv ----------------------------------------------------

write_csv(agb_df, "fluxtower_agb.csv")
