#' Extract mean AGB from raster products
#' 
#' Given a tibble of sites with columns for lat, lon, and tower footprint radius
#' this extracts the mean AGB in that radius.
#'
#' @param sites a tibble 
#' @param lat character; the name of the column with latitude data
#' @param lon character; the name of the column with longitude data
#' @param radius character; the name of the column with footprint radii
#' @param radius_units character; the units that `radius` is in.
#' @param raster_dir path to a folder in AGB_cleaned/ containing a .tif or
#'   multiple .tifs (when tiled) for a AGB product
#' @param ... other arguments passed to `exactextractr::exact_extract()`
#'
#' @return the sites tibble joined with columns for product, year, and agb_Mg_ha
#'
#' @examples
#' extract_mean_agb(sites, lat = "LOCATION_LAT", lon = "LOCATION_LONG", radius = "ffp_radius", raster_dir = "d://AGB_cleaned/esa_cci/")
extract_mean_agb <- function(sites, lat, lon, radius, radius_units = "m", raster_dir, ...) {
  tifs <- fs::dir_ls(raster_dir, glob = "*.tif")
  product_name <- fs::path_file(raster_dir)
  
  if (length(tifs) > 1){ #if it's tiles, read in as a vrt
    raster <- terra::vrt(tifs, set_names = TRUE)
  } else { #else just read it in as a SpatRaster
    raster <- terra::rast(tifs)
  }
  
  #validate sites input has the correct columns
  #TODO alternatively, these could all be inputs to the function if it needs to be more flexible
  stopifnot({{ lon }}    %in% colnames(sites))
  stopifnot({{ lat }}    %in% colnames(sites))
  stopifnot({{ radius }} %in% colnames(sites))

  #convert sites tibble to sf object
  sites_sf <- 
    sites |> 
    sf::st_as_sf(coords = c(lon, lat)) |> 
    sf::st_set_crs("WGS84") |> #I think this is safe to hard code
    #projet to whatever CRS the data product uses
    sf::st_transform(terra::crs(raster))
  
  #create polygons for flux tower footprints
  radii <- sites[[{{ radius }}]]
  units(radii) <- radius_units
  sites_buffer <-
    sites_sf |> 
    sf::st_buffer(dist = radii) |> 
    #add column with folder name.  Not super flexible--only works when tifs are in folders with product name
    dplyr::mutate(product = product_name)
  
  # extract total AGB from each site
  df <- exactextractr::exact_extract(
    raster,
    sites_buffer,
    fun = "mean",
    append_cols = TRUE,
    force_df = TRUE,
    ...
  )
  
  # tidy data
  # if there is only a single layer, the output looks a bit different so we do the tidying differently
  if(terra::nlyr(raster) == 1) {
    df_tidy <- df |> 
      dplyr::as_tibble() |> 
      dplyr::rename(agb_Mg_ha = mean) |> 
      dplyr::mutate(year = names(raster))
  } else {
    df_tidy <- df |> 
      tidyr::pivot_longer(
        tidyr::starts_with("mean."),
        names_to = "year",
        names_prefix = "mean.", 
        values_to = "agb_Mg_ha"
      ) |> 
      dplyr::mutate(year = year)
  }
  
  #return:
  df_tidy
  
}