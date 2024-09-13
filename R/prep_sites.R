prep_sites <- function(sites, modis) {
  sites |> 
    #add modis tile
    add_modis(modis) |> 
    #calculate ffp_radius
    dplyr::mutate(ffp_radius = calc_ffp_radius(
      zm = ZM_F,
      wind_speed = avg_WS,
      friction_velocity = avg_ustar
    )) |>
    #fill in NAs with median
    dplyr::mutate(
      ffp_radius = ifelse(is.na(ffp_radius), median(ffp_radius, na.rm = TRUE), ffp_radius)
    )
}

# prep_sites(ffp_inputs, modis)
