.. _gpi_constants:

Appendix: GPI Constants
=========================================

This appendix describes the various constants used by the pipeline and stored in the system constants file ( ``$GPI_DRP_DIR/config/pipeline_constants.txt``).

======================================  ==============================  ====================================================================================
Setting Name                            Possible Values                 Meaning
======================================  ==============================  ====================================================================================
ifs_lenslet_scale                       <float>                         Lenslet spatial scale of the IFS, in arcseconds/lenslet. Currently believed to 
                                                                        be 0.0143, close to the design value of 0.014
mems_rotation                           <float>                         The rotation of the DM (or equivalently the edges of the dark hole) with respect to 
                                                                        the satellite spots, such that the rotation of the dark hole in the processed IFS cubes 
                                                                        is given by SO3(\theta) where \theta = mean(satang) - memsrot, and satang is 
                                                                        the array of the calculated rotations of the four satellite spots.  
                                                                        This value is supplied in radians. Current empirical estimates place it at 0.01745 (1 degree).
pix_to_ripple                           <float>                         Twice the number of pixels between the image center (defined as the center of the sat 
                                                                        spots) and the MEMS ripple (i.e., twice the distance to the highest controllable 
                                                                        frequency).  Note that this is a lateral and not radial measurement (i.e., the edge 
                                                                        of the dark is located pix_to_ripple/2. away from the center in the reference frame 
                                                                        given by memsrotation). Equivalently, pix_to_ripple is equal to the radial distance 
                                                                        between waffle spots, divided by \sqrt{2}.  Theoretically, this value should be 
                                                                        given by  pix_to_ripple =  44*\lambda*1d-6/8* 180/\pi*3600/pixscl, or approximately 
                                                                        122.534 pixels for the first slice of H band (1.5121622 \mu m).  In practice, it 
                                                                        varies from this value by about 1 to 3 pixels, depending on the system state.
observatory_lat                         <float>  [-90,90]               Observatory latitude (WGS84) in decimal degrees
observatory_lon                         <float>  [-180,180]             Observatory longitude (WGS84) in decimal degrees.  Positive East
primary_diam                            <float>                         Diameter of primary mirror in meters
secondary_diam                          <float>                         Diameter of secondary mirror in meters
ifs_rotation                            <float> [0,360]                 Rotation of IFS lenslets (rotation of data cube in final frame).  Positive CCW
zero_pt_flux_Y                          <float>                         Zero point fluxes in GPI Y band (erg/cm2/s/um)
zero_pt_flux_J                          <float>                         Zero point fluxes in GPI J band (erg/cm2/s/um)
zero_pt_flux_H                          <float>                         Zero point fluxes in GPI H band (erg/cm2/s/um)
zero_pt_flux_K1                         <float>                         Zero point fluxes in GPI K1 band (erg/cm2/s/um)
zero_pt_flux_k2                         <float>                         Zero point fluxes in GPI K2 band (erg/cm2/s/um)
cen_wave_Y                              <float>                         Central wavelength of GPI Y band (microns)
cen_wave_J                              <float>                         Central wavelength of GPI J band (microns)
cen_wave_H                              <float>                         Central wavelength of GPI H band (microns)
cen_wave_K1                             <float>                         Central wavelength of GPI K1 band (microns)
cen_wave_K2                             <float>                         Central wavelength of GPI K2 band (microns)
======================================  ==============================  ====================================================================================


