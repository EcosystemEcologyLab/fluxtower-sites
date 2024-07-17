#' Extract AGB totals from raster products
#' 
#' Given a tibble of sites with columns for lat, lon, tower height, wind speed,
#' and friction coef, calculate a tower footprint radius and get the total AGB
#' in that radius.
#'
#' @param sites a tibble with columns LOCATION_LAT, LOCATION_LONG, ZM_F, avg_WS,
#'   and avg_ustar
#' @param raster_path path to either a .tif file or a directory of .tif files
#'   for a tiled data product
#'
#' @return the sites tibble joined with columns for product, year, and agb_Mg
#'
#' @examples
#' extract_agb(sites, "d://AGB_cleaned/esa_cci/")
#' extract_agb(sites, "d://AGB_cleaned/menlove/menlove_2009-2019.tif")
extract_agb <- function(sites, raster_path) {
  
  if (fs::is_dir(raster_path)){ #if it's tiles, read in as a vrt
    files <- dir_ls(raster_path, glob = "*.tif")
    raster <- terra::vrt(files, set_names = TRUE)
    product_name <- fs::path_file(raster_path)
  } else if (fs::is_file(raster_path)) { #else just read it in as a SpatRaster
    raster <- terra::rast(raster_path)
    product_name <- fs::path_dir(raster_path)
  }
  
  #create weighting raster of ha/pixel
  raster_ha <- terra::cellSize(raster, unit = "ha")
  
  #validate sites input has the correct columns
  #TODO alternatively, these could all be inputs to the function if it needs to be more flexible
  stopifnot("LOCATION_LONG" %in% colnames(sites))
  stopifnot("LOCATION_LAT"  %in% colnames(sites))
  stopifnot("ZM_F"          %in% colnames(sites))
  stopifnot("avg_WS"        %in% colnames(sites))
  stopifnot("avg_ustar"     %in% colnames(sites))
  
  #convert sites tibble to sf object
  sites_sf <- 
    sites_df |> 
    sf::st_as_sf(coords = c("LOCATION_LONG", "LOCATION_LAT")) |> 
    sf::st_set_crs("WGS84") |> #I think this is safe to hard code
    #projet to whatever CRS the data product uses
    sf::st_transform(terra::crs(raster))
  
  #calculate flux tower footprint radius
  sites_sf <- 
    sites_sf |> 
    dplyr::mutate(radius = calc_ffp_radius(zm = ZM_F, wind_speed = avg_WS, friction_velocity = avg_ustar)) |> 
    #remove sites with unknown footprint
    #TODO an alternative here would be to pick a default radius if one can't be calculated
    dplyr::filter(!is.na(radius))
  
  #create polygons for flux tower footprints
  sites_buffer <-
    sites_sf %>% 
    sf::st_buffer(dist = set_units(.$radius, "m")) |> 
    #add column with folder name.  Not super flexible--only works when tifs are in folders with product name
    dplyr::mutate(product = product_name)
  
  # extract total AGB from each site
  df <- exactextractr::exact_extract(
    raster,
    sites_buffer,
    fun = "weighted_sum", #sum(Mg/ha * fraction of pixel covered * ha/pixel) = total Mg
    weights = raster_ha, #ha/pixel
    append_cols = TRUE,
    force_df = TRUE,
    stack_apply = TRUE #can be done independently for each layer to save memory
  )
  
  # tidy data
  # if there is only a single layer, the output looks a bit different so we do the tidying differently
  if(terra::nlyr(raster) == 1) {
    df_tidy <- df |> 
      dplyr::as_tibble() |> 
      dplyr::rename(agb_Mg = weighted_sum) |> 
      dplyr::mutate(year = names(raster))
  } else {
    df_tidy <- df |> 
      tidyr::pivot_longer(
        tidyr::starts_with("weighted_sum."),
        names_to = "year",
        names_prefix = "weighted_sum.", 
        values_to = "agb_Mg"
      ) |> 
      dplyr::mutate(year = year)
  }
  
  #return:
  df_tidy
  
}