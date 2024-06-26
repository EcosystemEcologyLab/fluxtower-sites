## Originall from _targets.R in SW_Biomass.##
#############################################

# # Extract data for every NEON & Ameriflux site ----------------------------
# tar_file(neon_kmz, "data/shapefiles/NEON_Field_Sites_KMZ_v18_Mar2023.kmz"),
# tar_file(neon_field_path, "data/shapefiles/Field_Sampling_Boundaries_2020/"),
# # TODO switch to tar_sf() once it exists?
# tar_target(
#   site_locs,
#   get_site_locs(neon_kmz, neon_field_path)
# ),
# tar_map(
#   values = tibble(
#     product = rlang::syms(
#       c("esa_agb", "chopping_agb", "gedi_agb", "liu_agb", "ltgnn_agb", "menlove_agb", "xu_agb")
#     )
#   ),
#   tar_target(
#     sites,
#     extract_agb_site(product, site_locs) 
#   )
# ),
# #collect, pivot wider, join to site_locs
# tar_target(
#   sites_wide_csv,
#   pivot_sites(sites_esa_agb, sites_chopping_agb, sites_gedi_agb, sites_liu_agb, 
#               sites_ltgnn_agb, sites_menlove_agb, sites_xu_agb, site_locs = site_locs),
#   format = "file"
# ),
#   