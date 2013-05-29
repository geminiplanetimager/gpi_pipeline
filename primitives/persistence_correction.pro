;+
; NAME: Persistence Removal
; PIPELINE PRIMITIVE DESCRIPTION: Persistence removal of previous images
;
; The removal of persistence from previous non-saturated images
; incorporates a model developed for Hubble Space Telescopes Wide
; Field Camera 3 (WFC3,
; www.stsci.edu/hst/wfc3/ins_performance/persistence). 
; Persistence is proportional to the intensity of the illuminating
; source, and is observed to fade exponentially with time. The 
; parameters of the mathematical model for the persistence, found
; in the pipeline's configuration directory were determined
; during integration and test at UCSC.
;
; This primitive searches for all files in the raw data directory
; taken within 600 seconds (10 min) of the beginning of the exposure
; of interest. It then calculates the persistence from each image and
; subtracts it from the frame. 
;
; Ideally, this program should be run after the destriping algorithm
; as readnoise does not induce persistence.
;
; At this time, the persistence is removed at the 40% level due to
; inaccuracies in the model.
;
; INPUTS: Raw or destriped 2D image
;
; OUTPUTS: 2D image corrected persistence of previous non-saturated images
;
; PIPELINE COMMENT: Determines/Removes persistence of previous images
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ORDER: 1.3
; PIPELINE NEWTYPE: ALL
; PIPELINE TYPE: ALL
; PIPELINE SEQUENCE: 3-
;
; HISTORY:
;
;       Wed May 22 15:11:10 2013, LAB <LAB@localhost.localdomain>
;
;		
;   2013-05-14 PI: Started

;-
function persistence_correction, DataSet, Modules, Backbone
primitive_version= '$Id$'  ; get version from subversion to store in header history
@__start_primitive

 	if tag_exist( Modules[thisModuleIndex], "remove_microphonics") then remove_microphonics=Modules[thisModuleIndex].remove_microphonics else remove_microphonics='yes'

; determine when the image of interest started
UTSTART=backbone->get_keyword('UTSTART')
; convert it to seconds
time_str=UTSTART
UTSTART_sec=float(strmid(time_str,0,2))*3600+$ ; UTEND in seconds
                float(strmid(time_str,3,2))*60+$
                float(strmid(time_str,6,2))
; look for previous images 
        filetypes = '*.{fts,fits}'
    searchpattern = dataset.inputdir + path_sep() + filetypes
    current_files =FILE_SEARCH(searchpattern,/FOLD_CASE, count=count)

; only want to consider images in the last X seconds
; but need time stamps - must be a better way to do this!
time0=systime(1,/seconds)
UTEND_arr=strarr(N_ELEMENTS(current_files))
for f=0, N_ELEMENTS(current_files)-1 do begin
   tmp_hdr=headfits(current_files[f],ext=0)
   ; incase there is some header issue or it grabbed some weird file
   if string(tmp_hdr[0]) eq '-1' then continue
   time_str=sxpar(tmp_hdr,'UTEND')
   ; incase there is no UTEND keyword
   if string(time_str[0]) eq '0' then continue
   ; put UTEND in seconds
   UTEND_arr[f]=float(strmid(time_str,0,2))*3600+$ ; UTEND in seconds
                float(strmid(time_str,3,2))*60+$
                   float(strmid(time_str,6,2))
endfor
; marked skipped files as nan
ind=where(UTEND_arr eq '')
if ind[0] ne -1 then UTEND_arr[ind]=!values.f_nan

; want the time difference between the start of the current exposure
; and the last read of the previous exposure.
UTEND_arr-=UTSTART_sec
print,systime(1,/seconds)-time0 ,'seconds'

; find all files that are within 600 seconds of this image
ind=where(UTEND_arr lt 0 and UTEND_arr gt -600)
; determine if correction is necessary
if ind[0] eq -1 then begin
   backbone->set_keyword, "HISTORY", "No persistence correction applied, no previous files found"
   message,/info, "No persistence correction applied, no previous files found"
   return, ok
endif

; apply correction
; load persistence params for model
persis_params=readfits(gpi_get_directory('GPI_DRP_CONFIG_DIR')+path_sep()+'persistence_model_parameters.fits')
persis=fltarr(2048,2048)
for f=0, N_ELEMENTS(ind)-1 do begin
   ; skip if the file is itself
   if current_files[ind[f]] eq filename then continue 
   im=mrdfits(current_files[ind[f]],1,tmp_hdr)
   ; get gain and itime
   gain=sxpar(tmp_hdr,'SYSGAIN')
   itime=sxpar(tmp_hdr,'ITIME')
; input must be in electrons, time in seconds
; we care about how many electrons were on the detector between
; resets, not the reads. time between resets and reads is 1.45479 seconds
   tmp_model=persistence_model(im*gain/itime*(itime+2*1.45479),abs(UTEND_arr[ind[f]]-1.45479),persis_params)
   ; values in im that were negative created nan's in the image, set the
; nans's to zero
   bad_ind=where(finite(tmp_model) eq 0)
   if bad_ind[0] ne -1 then tmp_model[bad_ind]=0
   persis+=tmp_model
endfor

;get exposure time of the image of interest
itime=backbone->get_keyword('ITIME')
; and now subtract the persistence (in ADU)
im=*(dataset.currframe[0])
;*(dataset.currframe[0])=im-persis*itime/gain

; for testing purposes
if 0 eq 1 then begin
   loadct,0
   window,1,retain=2
   tvdl,subarr(im,400,[250,1350]),-50,50
   
   window,2,retain=2
   tvdl,subarr(im-persis/gain,400,[250,1350]),-50,50
   stop
endif

backbone->set_keyword, "HISTORY", "Applied persistence correction using the previous "+strcompress(string(N_ELEMENTS(ind)),/remove_all)+'frames',ext_num=0


if tag_exist( Modules[thisModuleIndex], "Save_persis") && ( Modules[thisModuleIndex].Save_persis eq 1 ) then b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, '-persis', display=display,savedata=persis,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile])

suffix = '-nopersis'
@__end_primitive

end
