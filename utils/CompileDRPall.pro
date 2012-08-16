;;  **********   DRP compiler   **************
;; Here are the commands that will compile the DRP code 
;; and produce executables
;; Set the following directories
;; Execute all these commands directly with the IDL command line  
;; set the 3 following directories with your code and exec locations 
;; 2011-03-20: JM
dircode='E:\testsvn3\pipeline\' ; main DRP directory
dircodeg='E:\testsvn3\'  ; the directory that contains the gpitv source code directory
compildir='E:\compil\'  ;the directory that will contain the directory of executables

.compile gpi_expand_path.pro 
.compile gpi_pipeline_version.pro
;.compile gpicaldatabase__define.pro
.compile gpidrfparser__define.pro
.compile gpidrsconfigparser__define.pro
.compile gpiloadedcalfiles__define.pro
.compile gpipipelinebackbone__define.pro
.compile gpipiperun.pro
.compile gpiprogressbar__define.pro
.compile launch_drp.pro
.compile launcher__define.pro
.compile make_gpi_logfile.pro
;.compile startup_gpi_drp.pro
.compile structdataset__define.pro
.compile structmodule__define.pro
.compile automaticproc2__define
.compile autom
.compile gpi_path_relative_to_vars
directory=dircode+'gpidrfgui'
list = FILE_SEARCH(directory+path_sep()+'[A-Za-z]*.pro',count=cc)
print, list
.compile addmsg.pro
.compile confirm.pro
.compile drfgui__define.pro
.compile gpidrfgui.pro
.compile gpiparsergui.pro
.compile gpirootdir.pro
.compile makedatalogfile__define.pro
.compile parsergui__define.pro
.compile queueview__define.pro
directory=dircode+'primitives'
list = FILE_SEARCH(directory+path_sep()+'[A-Za-z]*.pro',count=cc)
print, list
.compile accumulate_images.pro
.compile addwcs.pro
.compile apply_photometric_cal.pro
.compile apply_photometric_cal_02.pro
.compile apply_photometric_cal_extented.pro
.compile apply_photometric_cal_polar.pro
.compile applydarkcorrection.pro
.compile applyrefpixcorrection.pro
.compile calc_astrometry_binaries.pro
.compile calc_astrometry_binaries_sixth_orbit_catalog.pro
.compile collapsedatacube.pro
.compile combine2dframes.pro
.compile combinedarkframes.pro
.compile control_data_quality.pro
.compile displayrawimage.pro
.compile extract.pro
.compile extract_one_spectrum.pro
.compile extract_telluric_transmission.pro
.compile extractcube.pro
.compile extractcube_withbadpix.pro
.compile extractpol.pro
.compile get_spots_locations.pro
.compile gpi_add_geminigpikeywords.pro
.compile gpi_add_missingkeyword.pro
.compile gpi_add_multimissingkeyword.pro
.compile gpi_adi_loci_multiwav.pro
.compile gpi_adisimple_multiwav.pro
.compile gpi_combine_badpixmaps.pro
.compile gpi_combine_wavcal_all.pro
.compile gpi_combine_wavcal_locations_all.pro
.compile gpi_copykeywordvalue.pro
.compile gpi_correct_distortion.pro
.compile gpi_cosmicrays.pro
.compile gpi_extract_polcal.pro
.compile gpi_extract_wavcal2.pro
.compile gpi_extract_wavcal_locations.pro
.compile gpi_find_badpixels.pro
.compile gpi_find_badpixels_from_qemap.pro
.compile gpi_find_hotbadpixels_from_dark.pro
.compile gpi_find_badpixels_from_dark
.compile gpi_medianadi.pro
.compile gpi_rotate_extended_object_with_pa.pro
.compile gpirotateimage.pro
.compile interpol_spec_oncommwavvect.pro
.compile load_instpol.pro
.compile medianframes_dark.pro
.compile pol_combine.pro
.compile pol_flat_div.pro
.compile pol_flat_norm.pro
.compile readbadpixmap.pro
.compile readwavcal.pro
.compile remove_lamp_spectrum.pro
.compile rotate_north_up.pro
.compile sat_spots_calib_from_unocc.pro
.compile sat_spots_locations.pro
.compile gpi_meas_sat_spots_locations.pro
.compile save_output.pro
.compile set_calfile_type.pro
.compile simplespectraldiff.pro
.compile simplespectraldiff_postadi.pro
.compile spectral_flat_div.pro
.compile spectral_telluric_transm_div.pro
.compile testcoordinates001.pro
.compile testdistortion001.pro
.compile testextendedobjectflux.pro
.compile testphotometry001.pro
.compile testphotometryextented001.pro
.compile testplatescale001.pro
.compile testpolcal001.pro
.compile testsatspotloc001.pro
.compile testspecklesuprsdi001.pro
.compile testspecklesuprpolar001.pro
.compile testspecklesupr001.pro
.compile teststokesparam.pro
.compile testwavcal001.pro
directory=dircode+'config'
list = FILE_SEARCH(directory+path_sep()+'[A-Za-z]*.pro',count=cc)
print, list
.compile about_message
.compile accumulate_getimage.pro
.compile array_indices_1d.pro
.compile atmos_trans_forpipeline.pro
.compile calc_debrisdisk.pro
.compile calc_satloc.pro
.compile calc_centroid_spots.pro
.compile change_wavcal_lambdaref.pro
.compile change_wavcal_lambdaref_2.pro
.compile changeres.pro
.compile closeps.pro
;.compile create_progressbar2.pro
.compile decrease_spec_res.pro
.compile diagonal_matrix.pro
.compile drp_atmos_trans.pro
.compile eanomaly.pro
.compile fftscale.pro
.compile find_pol_positions_quadrant.pro
.compile find_spectra_dispersions_quadrant.pro
.compile find_spectra_positions_quadrant.pro
.compile findcommonbasename.pro
.compile forprint2.pro
.compile fxread3d.pro
.compile gaussian.pro
.compile get_cwv.pro
.compile gpi_adi_rotat.pro
.compile gpi_finddeviants.pro
.compile gpi_medfits.pro
.compile gpidetectnewfits.pro
.compile gpi_simplify_keyword_value
.compile initgpi_default_paths.pro
.compile localizepeak.pro
;.compile localizepeak_badpix.pro
;.compile localizepeak_new.pro
.compile make_drsconfigxml.pro
.compile make_drsconfigxml_order.pro
.compile openps.pro
.compile orbit.pro
.compile pip_nbphot_trans_lowres.pro
.compile pipeline_getfilter.pro
.compile plotc
.compile profrad.pro
.compile pseudo_invert.pro
.compile pseudo_invert_reg.pro
.compile psf_gaussian.pro
.compile read6thorbitcat.pro
.compile resample.pro
.compile rot_rate2.pro
.compile save_currdata.pro
.compile sxaddparlarge.pro
.compile test_telluric.pro
;.compile update_progressbar.pro
;.compile update_progressbar2adi.pro
.compile gpiparangle.pro
.compile setenvir__define.pro

directory=dircode+'idl_library'
list = FILE_SEARCH(directory+path_sep()+'[A-Za-z]*.pro',count=cc)
print, list
.compile alogscale.pro 
.compile angarr.pro
.compile aprint.pro 
.compile asinhscl.pro
.compile bool_is_integer.pro 
.compile bool_is_string.pro
.compile centroid.pro 
.compile checkdir.pro
.compile cmcongrid.pro 
.compile cmset_op.pro
.compile comdim2.pro 
.compile CW_pdmenu_checkable.pro
.compile cw_progress.pro
.compile decomposedcolor.pro 
.compile djs_iterstat.pro
.compile error.pro 
.compile error_message.pro
.compile fftrot.pro 
.compile file_break.pro
.compile fixpix
.compile cgcolor.pro 
.compile get_cind.pro
.compile getfratio.pro 
.compile getmyname.pro
.compile gpi_expand_path.pro 
.compile hdrconcat.pro
.compile hrot2.pro 
.compile hrotate2.pro
.compile indices.pro 
.compile intersect.pro
.compile intshift.pro 
.compile make_filename.pro
.compile mpfit.pro 
.compile mpfit2dfun.pro
.compile mpfit2dpeak.pro 
.compile mpfitpeak.pro
.compile nbr2txt.pro 
.compile pickcolorname.pro 
.compile procstatus.pro
.compile remchar.pro 
.compile remcharf.pro
.compile report_success.pro 
.compile sigfig.pro
.compile statusline.pro 
.compile str2num.pro
.compile strepex.pro 
.compile strnumber.pro
.compile strreplace
.compile struct_merge.pro 
.compile struct_trimtags.pro
.compile subarr.pro 
.compile sxpararr.pro
.compile ten_string.pro 
.compile textbox.pro
.compile translate.pro 
.compile uniqvals.pro

directory=dircodeg+'gpitv'
list = FILE_SEARCH(directory+path_sep()+'[A-Za-z]*.pro',count=cc)
print, list
print, repstr(list,directory+path_sep(),'.compile ')
.compile gpitv.pro 
.compile gpitv__define.pro
.compile gpitve.pro 
.compile gpitvms.pro 
.compile gpitvms2.pro 
.compile gpitvo.pro 
.compile idlbridcalms2.pro
.compile launchgpitvsharedmemms2.pro
.compile cfitshedit__define.pro 
.compile detecloopms2.pro
.compile detectnewfits.pro 
.compile fitsget.pro 
.compile callback_searchnewfits.pro 
directory=dircodeg+'gpitv'+path_sep()+'idl_library'
list = FILE_SEARCH(directory+path_sep()+'[A-Za-z]*.pro',count=cc)
print, list
print, repstr(list,directory+path_sep(),'.compile ')
.compile avgaper.pro 
.compile cmcongrid.pro 
.compile cmps_form.pro 
.compile fftscale.pro 
.compile hreverse2.pro 
.compile hrot2.pro
.compile hrotate2.pro 
.compile mkpupil.pro 
.compile myaper.pro 
.compile scale_vector.pro 
.compile strc.pro 
.compile subarr.pro


.compile gpicaldatabase__define.pro

resolve_all, /continue


;SAVE, /ROUTINES, FILENAME = 'launch_drp.sav' 
;; create the executables
;MAKE_RT, 'launch_drp', 'E:\testsvn3\pipeline\compil', savefile='launch_drp.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32
;
;SAVE, /ROUTINES, FILENAME = 'gpipiperun.sav' 
;MAKE_RT, 'gpipiperun', 'E:\testsvn3\pipeline\compil', savefile='gpipiperun.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32
;
;SAVE, /ROUTINES, FILENAME = 'autom.sav' 
;MAKE_RT, 'autom', 'E:\testsvn3\pipeline\compil', savefile='autom.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32
;
;SAVE, /ROUTINES, FILENAME = 'gpitv.sav' 
;MAKE_RT, 'gpitv', 'E:\testsvn3\pipeline\compil', savefile='gpitv.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32


SAVE, /ROUTINES, FILENAME = compildir+'launch_drp.sav' 
; create the executables
MAKE_RT, 'launch_drp', compildir, savefile=compildir+'launch_drp.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32

SAVE, /ROUTINES, FILENAME = compildir+'gpipiperun.sav' 
MAKE_RT, 'gpipiperun', compildir, savefile=compildir+'gpipiperun.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32

SAVE, /ROUTINES, FILENAME = compildir+'autom.sav' 
MAKE_RT, 'autom', compildir, savefile=compildir+'autom.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32

SAVE, /ROUTINES, FILENAME = compildir+'gpitv.sav' 
MAKE_RT, 'gpitv', compildir, savefile=compildir+'gpitv.sav', /vm, /MACINT32, /MACPPC32, /LIN32, /WIN32

file_mkdir, compildir+'pipeline'
;;put all files in the same dir
file_copy, compildir+'launch_drp'+path_sep()+'*', compildir+'pipeline'+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'gpipiperun'+path_sep()+'*', compildir+'pipeline'+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'gpitv'+path_sep()+'*', compildir+'pipeline'+path_sep()+'', /recursive, /overwrite
file_copy, compildir+'autom'+path_sep()+'*', compildir+'pipeline'+path_sep()+'', /recursive, /overwrite

file_delete, compildir+'launch_drp', /recursive
file_delete, compildir+'gpipiperun', /recursive
file_delete, compildir+'gpitv', /recursive
file_delete, compildir+'autom', /recursive
file_delete, compildir+'launch_drp.sav'
file_delete, compildir+'gpipiperun.sav'
file_delete, compildir+'gpitv.sav'
file_delete, compildir+'autom.sav'
;;create directories structure for the DRP
file_mkdir, compildir+'pipeline'+path_sep()+'log',$
            compildir+'pipeline'+path_sep()+'dst',$
            compildir+'pipeline'+path_sep()+'dst'+path_sep()+'pickles',$
            compildir+'pipeline'+path_sep()+'drf_templates',$
            compildir+'pipeline'+path_sep()+'drf_queue',$
            compildir+'pipeline'+path_sep()+'log',$
            compildir+'pipeline'+path_sep()+'config',$
            compildir+'pipeline'+path_sep()+'config'+path_sep()+'filters'
;;copy DRF templates, etc...            
file_copy, dircode+'drf_templates'+path_sep()+'*.xml', compildir+'pipeline'+path_sep()+'drf_templates'+path_sep(),/overwrite         
file_copy, dircode+'config'+path_sep()+'*.xml', compildir+'pipeline'+path_sep()+'config'+path_sep(),/overwrite   
file_copy, dircode+'config'+path_sep()+'*.txt', compildir+'pipeline'+path_sep()+'config'+path_sep(),/overwrite           
file_copy, dircode+'config'+path_sep()+'*.dat', compildir+'pipeline'+path_sep()+'config'+path_sep(),/overwrite              
file_copy, dircode+'config'+path_sep()+'filters'+path_sep()+'*.fits', compildir+'pipeline'+path_sep()+'config'+path_sep()+'filters'+path_sep(),/overwrite
file_copy, dircode+'dst'+path_sep()+'*.dat', compildir+'pipeline'+path_sep()+'dst'+path_sep()+'',/overwrite
file_copy, dircode+'dst'+path_sep()+'pickles'+path_sep()+'*.*t', compildir+'pipeline'+path_sep()+'dst'+path_sep()+'pickles'+path_sep(),/overwrite
file_copy, dircode+'gpi.bmp',compildir+'pipeline'+path_sep(),/overwrite

;;remove non-necessary txt file
Result = FILE_SEARCH(compildir+'pipeline'+path_sep()+'*script_source.txt') 
file_delete, Result

print, 'Compilation done.'   


