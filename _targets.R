# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

# Set target options:
tar_option_set(
  packages = c("readr", "dplyr", "fs", "sf", "exactextractr", "terra"), # Packages that your targets need for their tasks.
  # format = "qs", # Optionally set the default storage format. qs is fast.
  #
  # Pipelines that take a long time to run may benefit from
  # optional distributed computing. To use this capability
  # in tar_make(), supply a {crew} controller
  # as discussed at https://books.ropensci.org/targets/crew.html.
  # Choose a controller that suits your needs. For example, the following
  # sets a controller that scales up to a maximum of two workers
  # which run as local R processes. Each worker launches when there is work
  # to do and exits if 60 seconds pass with no tasks to run.
  #
  controller = crew::crew_controller_local(workers = 2, seconds_idle = 60)
)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# tar_source("other_functions.R") # Source other scripts as needed.


# Mount point for Snow network drive
# snow <- "/Volumes/Projects/moore/"
# snow <- "/Volumes/moore/"
snow <- "//snow.snrenet.arizona.edu/projects/moore"

# Replace the target list below with your own:
list(
  #track input file for changes
  tar_target(
    name = ffp_inputs_csv,
    command = "data/ffp_inputs.csv",
    format = "file"
  ),
  #read in csv
  tar_target(
    name = ffp_inputs,
    command = read_csv(ffp_inputs_csv)
  ),
  
  #add radius column
  tar_target(
    name = ffp_radii,
    command = ffp_inputs |> 
      mutate(ffp_radius = calc_ffp_radius(
        zm = ZM_F,
        wind_speed = avg_WS,
        friction_velocity = avg_ustar
      )) |>
      #fill in NAs with median
      mutate(ffp_radius = ifelse(is.na(ffp_radius), median(ffp_radius, na.rm = TRUE), ffp_radius))
  ),
  tar_target(
    name = products,
    command = dir_ls(path(snow, "AGB_cleaned")),
    format = "file_fast"
  ),
  tar_target(
    name = agb,
    command = extract_mean_agb(
      ffp_radii,
      lat = "LOCATION_LAT",
      lon = "LOCATION_LONG",
      radius = "ffp_radius",
      raster_dir = products,
      max_cells_in_memory = 1e+07 #prevent using too much RAM
    ),
    pattern = map(products) #do this for every value of the `products` target (i.e. every dir in AGB_cleaned)
  )
  
)
