# use branching to apply this to all the raster datasets and rowbind the results
extract_agb_site <- function(rast, sites) {
  site_buffer <- sites |> sf::st_buffer(1000) |> terra::vect()
  
  # zonal() is slightly faster than extract()
  site_agb <- terra::zonal(rast, site_buffer, exact = TRUE, na.rm = TRUE)
  
  out <- site_agb |> 
    rename(agb = 1) |>
    mutate(
      product = names(rast),
      site_rowid = 1:n()
      ) |> as_tibble()
  out  
}

  