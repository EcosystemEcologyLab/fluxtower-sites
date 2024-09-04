library(fs)
library(dplyr)
library(readr)
library(purrr)
library(exactextractr)
library(sf)
library(terra)
source("R/calc_ffp_radius.R")
source("R/extract_mean_agb.R")

#windows
snow <- "//snow.snrenet.arizona.edu/projects/moore"
#macos
# snow <- "/Volumes/moore"

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
#     raster_file = "d://AGB_cleaned/liu/liu_1993-2012.tif",
#     max_cells_in_memory = 1e+07
#   )


# Extract mean AGB for all products ---------------------------------------

#For tiled data products, there is a single .vrt file that can be opened with
#terra::vrt().  For all other products, there is a single cloud optimized
#geotiff. `extract_mean_agb()` is written to take either a .vrt or a .tif as
#input

product_dirs <- dir_ls(path(snow, "AGB_cleaned"))
vrts <- dir_ls(product_dirs, glob = "*.vrt")
single_tif <- dir_ls(product_dirs[!product_dirs %in% path_dir(vrts)], glob = "*.tif")

agb_files <- c(vrts, single_tif)

# apply extract_mean_agb to all products
#
# Warning: this is super slow.  Maybe you
# want to just do one product at a time, paralellize with furrr::future_map(),
# or use the `targets` version of this workflow by running `targets::tar_make()`

agb_list <- map(agb_files, \(.file) {
  extract_mean_agb(
    sites_df,
    lat = "LOCATION_LAT",
    lon = "LOCATION_LONG",
    radius = "ffp_radius",
    raster_file = .file,
    max_cells_in_memory = 1e+07
  )
})

# comine to a single df

agb_df <- list_rbind(agb_list)

# Write results to csv ----------------------------------------------------

write_csv(agb_df, "fluxtower_agb.csv")
