# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)
library(fst)
library(fs)

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

targets<- list(
  #track input file for changes
  tar_target(
    name = ffp_inputs_csv,
    command = "data/ffp_inputs.csv",
    format = "file"
  ),
  #read in csv
  tar_target(
    name = ffp_inputs,
    command = read_csv(ffp_inputs_csv) |> 
      dplyr::select(-any_of(c("...1", "X")))
  ),
  #modis tiles
  tar_target(
    name = modis_file,
    command = path(snow, "shapefiles/modis_grid"),
    format = "file"
  ),
  tar_target(
    name = modis,
    command = read_sf(modis_file)
  ),
  #add radius column and modis tile
  tar_target(
    name = ffp_radii,
    command = prep_sites(ffp_inputs, modis) |>
      dplyr::group_by(modis_tile) |>
      targets::tar_group(),
    iteration = "group"
  ),
  tar_map(
    #for these rows...
    values = tibble::tribble(
      ~product,   ~file_path, #path relative to AGB_cleaned folder on Snow
      "chopping", "chopping/chopping_2000-2021.tif",
      "gedi",     "gedi/gedi_2019-2023.tif",
      "hfbs",     "hfbs/hfbs_2010.tif",
      "liu",      "liu/liu_1993-2012.tif",
      "menlove",  "menlove/menlove_2009-2019.tif",
      "xu",       "xu/xu_2000-2019.tif",
      #these are tiled data sets so only track the .vrt file
      "esa",      "esa_cci/esa_2010.2017-2020.vrt",
      "gfw",      "gfw/gfw_2000.vrt",
      "icesat",   "icesat/icesat_2020.vrt",
      "ltgnn",    "lt_gnn/lt.gnn_1990-2017.vrt",
      "nbcd",     "nbcd/nbcd_2000.vrt",
    ),
    names = product, #get target name suffix from `product` column
    
    #do these targets
    tar_target(
      name = file,
      command = path(snow, "AGB_cleaned", file_path),
      format = "file",
      description = "track product files for changes"
    ),
    tar_target(
      name = agb,
      command = extract_mean_agb(
        ffp_radii,
        lat = "LOCATION_LAT",
        lon = "LOCATION_LONG",
        radius = "ffp_radius",
        raster_file = file,
        max_cells_in_memory = 9e+06 #prevent using too much RAM
      ),
      pattern = map(ffp_radii),
      iteration = "vector"
    ),
    tar_target(
      name = agb_csv,
      command = write_agb(agb),
      format = "file_fast"
    )
  )
)
  