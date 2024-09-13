#' Add column for MODIS tile ID
#'
#' Given a data frame of points identified by a site ID, lat, and lon, match the
#' sites to a MODIS tile.
#'
#' @param sites data frame with at least columns for site ID (`id`), latitude
#'   (`lat`), and longitude (`lon`)
#' @param modis a `sf` object, eg by reading in a modis tile shapefile with
#'   `sf::read_sf()`
#' @param id character; column name of site IDs
#' @param lat character; column name of lattitudes
#' @param lon character; column name of longitudes
#'
#' @return the `sites` data frame with an additional `modis_tile` column
#' 
add_modis <- function(sites, modis, id = "SITE_ID", lat = "LOCATION_LAT", lon = "LOCATION_LONG") {
  sf_use_s2(TRUE) #only works with shperical geometry
  
  sites_sf <- sites |> 
    sf::st_as_sf(coords = c(lon, lat)) |> 
    sf::st_set_crs("WGS84")
  
  tile_df <- st_join(
    modis,
    st_transform(sites_sf, st_crs(modis)),
    left = FALSE
  ) |> 
    dplyr::as_tibble() |> 
    dplyr::mutate(modis_tile = paste0("h", h, "v", v)) |> 
    dplyr::select(all_of(id), modis_tile)
  
  dplyr::left_join(sites, tile_df)
  
}

