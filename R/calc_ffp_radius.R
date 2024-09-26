#a simple function for estimating reasonable radius for the footprint of a flux tower
#from Kljun et al. 2015, equn 25, pg 3702

#zm is the sensor height above the displacement height (zm = meas_h - d); d has been assumed 2/3*canopy height
#friction velocity = ustar in flux data

calc_ffp_radius <- function(zm, wind_speed, friction_velocity){
  
  #define tower constants
  footprint_fraction = 0.80 #valid for values 0.1 to 0.9
  Kljun_param_c = 1.462 #see paper
  Kljun_param_d = 0.136 #see paper
  boundary_layer_height = 1000 #boundary layer assumed stable, so height = 1000m
  von_Karman_constant = 0.4
  
  #calculate tower radius
  ffp_radius = 
    (((-Kljun_param_c)/(log(footprint_fraction))) + Kljun_param_d) *
    zm * ((1 - (zm / boundary_layer_height))^(-1)) *
    ((wind_speed) / friction_velocity) * von_Karman_constant
  
  return(ffp_radius)
}
