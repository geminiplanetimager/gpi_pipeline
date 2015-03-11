;+
; NAME: gpi_remove_persistence_from_previous_images
; PIPELINE PRIMITIVE DESCRIPTION: Remove Persistence from Previous Images
;
;   The removal of persistence from previous non-saturated images
;   incorporates a model developed for Hubble Space Telescopes Wide
;   Field Camera 3 (WFC3,
;   www.stsci.edu/hst/wfc3/ins_performance/persistence). 
;   Persistence is proportional to the intensity of the illuminating
;   source, and is observed to fade exponentially with time. The 
;   parameters of the mathematical model for the persistence, found
;   in the pipeline's configuration directory were determined
;   during integration and test at UCSC.
;
;   This primitive searches for all files in the raw data directory
;   taken within 600 seconds (10 min) of the beginning of the exposure
;   of interest. It then calculates the persistence from each image,
;   using the maximum of the stack, and subtracts it from the
;   frame. Note that if the detector is exposed to light, but no
;   exposures are being taken, persistence will still build up on the
;   detector that cannot be subtracted.  
;
;   Ideally, this program should be run after the destriping algorithm
;   as readnoise does not induce persistence. However, due to limitation
;   that a pipeline primitive cannot call another primitive, this has
;   not been implemented. Future developement will involve moving the
;   destriping algorithm into a idl function, and then calling the
;   function from the destriping primitive. This will enable the ability
;   for this primitive to destripe the previous images. The user should
;   note that the destriping is at a level that is low enough to not
;   leave a significant persistence, so this detail will not
;   significantly affect science data.
;
;   At this time, the persistence is removed at the ~75% level due to
;   inaccuracies in the model caused by an insufficient time sampling of
;   the initial falloff and readnoise. A new dataset will be taken prior to shipping,
;   and new model parameters will be derived prior to commissioning.
;
;	WARNING: Persistence removal does not (yet) work with COADDED images!
;
;	The manual_dt keyword allows the user to manually offset the UTEND keyword in 
;	the image that is taken in closest time to the image being reduced 
;	(and therefore probably the dominent persisting image). This is 
;	important because sometimes when changing modes or exposure times quickly, 
;	the CAL exit shutter can remain open so light will continue hitting the
;	detector past the UTEND time. Users should note that this is generally
;	occurs only for polarimetry snapshots after long spectral sequences
;	(taken in the same band).
;
; INPUTS: Raw or destriped 2D image
; OUTPUTS: 2D image corrected for persistence of previous non-saturated images
;
; Requires the persistence_model_parameters.fits calibration file.
;
;
; PIPELINE COMMENT: Determines/Removes persistence of previous images
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="String" CalFileType="persis" Default="AUTOMATIC" Desc="Filename of the persistence_parameter file to be read"
; PIPELINE ARGUMENT: Name="manual_dt" Type="float" Range="[0,600]" Default="0" Desc="Manual offset for time (in seconds) since last persisting file - see help for details"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display " 
; PIPELINE ORDER: 1.2
; PIPELINE CATEGORY: ALL
;
; HISTORY:
;
;   Wed May 22 15:11:10 2013, LAB <LAB@localhost.localdomain>
;   2013-05-14 PI: Started
;   2013-12-16 MP: CalibrationFile argument syntax update. 
;-
function gpi_remove_persistence_from_previous_images, DataSet, Modules, Backbone
primitive_version= '$Id$'  ; get version from subversion to store in header history
calfiletype = 'persis'
@__start_primitive

if tag_exist( Modules[thisModuleIndex], "manual_dt") then manual_dt=float(Modules[thisModuleIndex].manual_dt) else manual_dt=0


; check if the image is coadded
ncoadds=backbone->get_keyword('COADDS0')

;if ncoadds ne 1 then return, error('No persistence correction can (currently) be applied to images with coadds')

if ncoadds ne 1 then message, /info, 'WARNING - IMAGE HAS COADDS code will not output a perfect correction (assuming the persistence model is perfect)'


; determine when the image of interest started
; the UTSTART keyword is actually not a good keyword to use as the start of the image
; depends on the clocking, and not on this keyword
UTSTART=backbone->get_keyword('UTEND')
; convert it to seconds
time_str=UTSTART
UTSTART_sec=float(strmid(time_str,0,2))*3600+$ 
                float(strmid(time_str,3,2))*60+$
                float(strmid(time_str,6,2))
; now determine start time
ITIME=backbone->get_keyword('ITIME')
; must subtract integration time and one clock cycle
; detector goes reset-read-itime-read-writefile
UTSTART_sec=UTSTART_sec-float(itime)-1.45479   ; so this is the time of the reset!

; the coadds fix should be here!

; so this is just a REALLY DIRTY HACK
; assumes each image is itime + 2 reads 
UTSTART_sec-= ((float(itime)+2*1.45479)*(ncoadds-1))

; look for previous images 
filetypes = '*.{fts,fits}'
searchpattern = dataset.inputdir + path_sep() + filetypes
current_files =FILE_SEARCH(searchpattern,/FOLD_CASE, count=count)

; only want to consider images in the last 600 seconds
; but need time stamps - must be a better way to do this!
; the current method reads the headers of every file in the directory.
time0=systime(1,/seconds)
UTEND_arr=strarr(N_ELEMENTS(current_files))
for f=0, N_ELEMENTS(current_files)-1 do begin
    ; check to make sure its actually a fits file with 2 extensions
    fits_info,current_files[f],n_ext=n_ext,/silent
    if n_ext[0] eq -1 then continue

    tmp_hdr=headfits(current_files[f],ext=0)
    ; incase there is some header issue or it grabbed some weird file
    if string(tmp_hdr[0]) eq '-1' then continue
    time_str=sxpar(tmp_hdr,'UTEND')
 	; incase there is no UTEND keyword
    if string(time_str[0]) eq 0 then continue
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
;print,systime(1,/seconds)-time0 ,'seconds'

; find all files that are within 600 seconds of this image
ind=where(UTEND_arr lt 0 and UTEND_arr gt -600)
; determine if correction is necessary
if ind[0] eq -1 then begin
    backbone->set_keyword, "HISTORY", "No persistence correction applied, no images taken within 600s are found in the same directory"
    message,/info, "No persistence correction applied, no images taken within 600s are found in the same directory"
    return, ok
endif

; manually adjust UTEND for last file if desired
if keyword_set(manual_dt) then begin
    ; adjust the most recent UTEND time (which is now a delta time since the current exposure) to the user defined value
    junk=min(abs(UTEND_arr[ind]),min_ind,/nan)
    message,/info,"Forcing the manual time offset between science image and "+strc(current_files[ind[min_ind]])
    UTEND_arr[ind[min_ind]]=-abs(manual_dt)
endif

; apply correction
; load persistence params for model
persis_params = gpi_readfits(c_File,header=Header)
persis=fltarr(2048,2048)
tmp_model=fltarr(2048,2048)
for f=0, N_ELEMENTS(ind)-1 do begin
    ; skip if the file is itself
    if current_files[ind[f]] eq filename then continue 
    im=mrdfits(current_files[ind[f]],1,tmp_hdr,/silent)
    ; get gain and itime
    gain=sxpar(tmp_hdr,'SYSGAIN')
    itime=sxpar(tmp_hdr,'ITIME')
    ; input must be in electrons, time in seconds
    ; we care about how many electrons were on the detector between
    ; resets, not the reads. time between resets and reads is 1.45479
    ; seconds
    ; for the amount of time since exposure to stimulus
    
    ; regarding the amount of time since stimulus, we actually want the
    ; time since the stimulus, plus an amount of time such that the
    ; persistence function at that time corresponds to the average
    ; persistence  over the exposure time
    
    ; Unfortunately, the time that signifies the rate is not necessarily in
    ; the middle, but is dependent upon the exponent, one can determine
    ; this time using the following equation
    
    ; this is derived from (t2-t1)*P(tx)=integral(P(t)*dt) evaluated from
    ; t1 to t2, where P(t)=N*(t/1000)^(-a), where a is the exponential decline
    
    ; t1 is the time of the first read, t2 the last read
    ; so T1=UTSTART+0.964(reset time?)+clock_time
    
    T1 =abs(UTEND_arr[ind[f]])	; UTEND (time of last read of the loaded persisting 
    							; file since the RESET for this science image)
    
    T2=T1+itime
    gamma=median(persis_params[*,*,4])
    ; this is the average persistence over a time interval
    tx= 1000.0d0*([1000/(1.0-gamma)* [ (t2/1000)^(1.0-gamma) - ((t1/1000)^(1.0-gamma))]/(t2-t1)])^(-1d0/gamma)
    
    tmp_model=persistence_model(im*gain/itime*(itime+2*1.454790),tx[0],persis_params)
    


	; ##################################
	; this begins the new UTR treatment
	; ##################################

	; note that nreads will have itime/1.45 +1 
	nreads = float(gpi_simplify_keyword_value(backbone->get_keyword('GROUPS0', count=c)))

	gamma=median(persis_params[*,*,4])
	utr_arr=fltarr(2048,2048,nreads)
	utr_arr0=utr_arr
	for r=0, Nreads-1 do begin
		; so at read 1 - we need to know the time since last exposure (utend), and the time
		; note that there is an annoy index issue here, read 1 is actually r=0 
		T2=T1+(1.454790*(r+1))

		; the correct time such that the persistence when you do tx*dt is correct
		; instead of integrating - so this is in seconds
		tx=1000.0d0*([1000/(1.0-gamma)* [ (t2/1000)^(1.0-gamma) - ((t1/1000)^(1.0-gamma))]/(t2-t1)])^(-1d0/gamma)
		; this is the average persistence over a time interval between t1 and t2 that gives
		tmp_model=persistence_model(im*gain/itime*((r+1)*1.454790),tx[0],persis_params)
	; replace the value if it's bigger for the frame
	; note that the utr_arr is in ELECTRONS
		if r eq 0 then utr_arr[*,*,r]=tmp_model*1.454790 else utr_arr[*,*,r]=(utr_arr[*,*,r-1]+tmp_model*1.454790)>utr_arr[*,*,r]
	
	endfor

;	 ###################
; this is the original C? script that was translated...
    ; Calculate the UTR with weights
    ;    #For this document, weights are how much the frame is multipied times. The "weigted effect" of any individual
    ;    ## group becomes W{i} / W{total}. This is done to correspond to the C# code for easier understanding.
    ;    w_total = 0
    ;    result = numpy.zeros((2048,2048))
    ;    #Make sure the array is a numpy.array
    ;    #if type(image_array) != numpy.array:
    ;    #    image_array = numpy.array(image_array)
    ;    #Calculate the total weights
    ;    for i in range(0,len(image_array)):
    ;        w_total += (i*(len(image_array)-i))
    ;    #Calculate a group, then multipy by the weight for that frame / total weight
    ;    for i in range(1,len(image_array)):
    ;        if destripe == True:
    ;            raise Excpetion("Not Implimented")
    ;            result += refHorizonDeStripe(refVertChanMedian(image_array[i] - image_array[i-1])*(i*(len(image_array)-i)))/w_total*(len(image_array)-1)
    ;        else:
    ;            result += (image_array[i] - image_array[i-1])*(i*(len(image_array)-i))/w_total*(len(image_array)-1)
    ;	    return refVertChanMedian(result)
    
    ; #################
    

	; new way finds the rates for every read - then subtracts the mean rate from the rate in the image
	;dtime=findgen(round(itime/1.45479))*1.45479
	;tmp_model=persistence_model(im*gain/itime*(itime+2*1.45479), dtime+T1, persis_params)
	;stop
	if N_ELEMENTS(tmp_model) eq 1 then stop,'model failure at line 146'
	   ; values in im that were negative created nan's in the image, set the
		; nans's to zero
	bad_ind=where(finite(tmp_model) eq 0)
	if bad_ind[0] ne -1 then tmp_model[bad_ind]=0
	; want to take whatever file gives the most persistence
	
	persis=temporary(persis)>tmp_model
endfor ; end loop over files

;get exposure time of the image of interest
itime=backbone->get_keyword('ITIME')
; and now subtract the persistence (in ADU)
im=*(dataset.currframe[0])


; Calculate the UTR with weights of the persistence
; note that because the UTR calculation is linear, it can be considered as a linear set
; of equations 
; utr(flux+persitance) = utr(flux) + utr(persistence)
; so we just have to calculate the utr(persistence) and subtract it


; the following piece of code is translated from a python code from Jeff Chilcote which
; is based after the C# code in the detector software
; so pretty much a triple translation... 

final_rate_arr=fltarr(2048,2048)

total_weight=0.0
for r=1,nreads-1 do total_weight+= (r * (nreads - r) )	

; so now calculate what the persistence rate would be over the image
; note that this is in electrons/read (or something per read) 
for r=1, nreads-1 do begin
	; the weight for each read is
	; r*(len(image_array)-r)
	weight=(r * (nreads - r) )	
	final_rate_arr+=(utr_arr[*,*,r]-utr_arr[*,*,r-1])*weight/total_weight
endfor

; to get the image, we must multiply the final_rate by the itime
utr_determined_persistence=final_rate_arr*(nreads-1) ; IN ELECTRONS
; convert to ADU
utr_determined_persistence/=gain

; model might have nans in it, so replace them with zeros
bind=where(finite(utr_determined_persistence) eq 0,count)
if count gt 0 then utr_determined_persistence[bind]=0.0
new_image=im-utr_determined_persistence
; for testing purposes
if 0 eq 1 then begin
   loadct,0
   window,1,retain=2,xsize=600,ysize=600
   imdisp,subarr(im,400,[1100,1100]),range=[-10,100]
   
	determined_persistence=persis*itime/gain
   window,2,retain=2,xsize=600,ysize=600

   imdisp,subarr(im-utr_determined_persistence,400,[1100,1100]),range=[-10,100]
   stop
endif



;*(dataset.currframe[0])=im-persis*itime/gain

*(dataset.currframe[0])=im-utr_determined_persistence



backbone->set_keyword, "HISTORY", "Applied persistence correction using the previous "+strcompress(string(N_ELEMENTS(ind)),/remove_all)+'frames',ext_num=0


if tag_exist( Modules[thisModuleIndex], "Save_persis") && ( Modules[thisModuleIndex].Save_persis eq 1 ) then b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, '-persis', display=display,savedata=persis,saveheader=*dataset.headersExt[numfile], savePHU=*dataset.headersPHU[numfile])

suffix = '-nopersis'
@__end_primitive

end
