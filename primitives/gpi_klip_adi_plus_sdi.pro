;+
; NAME: gpi_klip_adi_plus_sdi
; PIPELINE PRIMITIVE DESCRIPTION: KLIP algorithm ADI + SDI
;
;   This algorithm reduces PSF speckles in a datacube using the
;   KLIP algorithm and Angular Differential Imaging + Spectral
;   Differential Imaging. Based on Soummer et al., 2012.
;
;       Star location must have been previously measured using satellite spots.
;       Measure annuli out from the center of the cube and create a
;       reference set for each annuli of each slice. Apply KLIP to the
;       reference set and project the target slice onto the KL
;       transform vector. Subtract the projected image from the
;       original and repeat for all slices 
; 
; INPUTS: Multiple spectral datacubes, ADR corrected
; OUTPUTS: A reduced datacube with reduced PSF speckle halo
;
;
; PIPELINE COMMENT: Reduce speckle noise using the KLIP algorithm with ADI+SDI data
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="numthreads" Type="int" Range="[1,10000]" Default="5" Desc="Number of parallel processes to run KLIP calculation"
; PIPELINE ARGUMENT: Name="annuli" Type="int" Range="[0,100]" Default="5" Desc="Number of annuli to use"
; PIPELINE ARGUMENT: Name="subsections" Type="int" Range="[1,10]" Default="4" Desc="Number of equal area subsections to break up each annulus into"
; PIPELINE ARGUMENT: Name="prop" Type="float" Range="[0.8,1.0]" Default=".99999" Desc="Proportion of eigenvalues used to truncate KL transform vectors"
; PIPELINE ARGUMENT: Name="minsep" Type="float" Range="[0.0,250]" Default="3" Desc="Minimum separation between slices (pixels)"
; PIPELINE ARGUMENT: Name="minPA" Type="float" Range="[0.0,360]" Default="0.0" Desc="Minimum parallactic rotation (in degrees) for constructing reference PSF (good for disk targets)"
; PIPELINE ARGUMENT: Name="waveclip" Type="int" Range="[0,18]" Default="2" Desc="Number of wavelength slices at the beginning and end of each cube to ignore"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="5" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.2
; PIPELINE CATEGORY: SpectralScience
;
; HISTORY:
;        2014-05 JW modified code from Dmitry and Tyler Barker
;-

function gpi_klip_adi_plus_sdi, DataSet, Modules, Backbone
; enforce modern IDL compiler options:
compile_opt defint32, strictarr, logical_predicate

; don't edit the following line, it will be automatically updated by subversion:
primitive_version= '$Id: __template.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history

calfiletype=''   ; set this to some non-null value e.g. 'dark' if you want to load a cal file.

@__start_primitive
suffix = suffix+'-klip'		 ; set this to the desired output filename suffix


if numfile ne ((dataset.validframecount)-1) then return, OK

;; get some info about the dataset
nlam = backbone->get_keyword('NAXIS3',indexFrame=0, count=ct)
dim = [backbone->get_keyword('NAXIS1',indexFrame=0, count=ct1),backbone->get_keyword('NAXIS2',indexFrame=0, count=ct2)]
if ct+ct1+ct2 ne 3 then return, error('FAILURE ('+functionName+'): Missing NAXIS* keyword(s).')
nfiles=dataset.validframecount
band = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
if ct eq 0 then return, error('FAILURE ('+functionName+'): Missing IFSFILT keyword.')
cwv = get_cwv(band,spectralchannels=nlam)

;;get wavelength info
cwv = get_cwv(band,spectralchannels=nlam)
if size(cwv,/type) ne 8 then return,-1
lambda = cwv.lambda

;;get PA angles and satspots of all images and check that they have
;;the same number of slices
PAs = dblarr(dataset.validframecount)
locs = dblarr(2,4,nlam,nfiles)
cens = dblarr(2,nlam,nfiles)
for j = 0, nfiles - 1 do begin
	print, "getting header keywords for file", j
 PAs[j] = double(backbone->get_keyword('AVPARANG', indexFrame=j ,count=ct)) * !DtoR
 if ct eq 0 then return, error('FAILURE ('+functionName+'): Missing average parallactic angle.')
 
 if (backbone->get_keyword('NAXIS3',indexFrame=j) ne nlam) then $
	return, error('FAILURE ('+functionName+'): All cubes in dataset must have the same number of slices.')

 if ~strcmp(gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct)),band) then $
	return, error('FAILURE ('+functionName+'): All cubes in dataset must be in the same band.')

 tmp = gpi_satspots_from_header(*DataSet.HeadersExt[j])
 if n_elements(tmp) eq 1 then $
	return, error('FAILURE ('+functionName+'): Use "Measure satellite spot locations" before this primitive.') else $
	   locs[*,*,*,j] = tmp

 for k = 0,nlam-1 do cens[*,k,j] = [mean(locs[0,*,k,j]),mean(locs[1,*,k,j])]
endfor

;;get user inputs
numthreads=long(Modules[thisModuleIndex].numthreads)
annuli=long(Modules[thisModuleIndex].annuli)
minsep=double(Modules[thisModuleIndex].minsep)
prop=double(Modules[thisModuleIndex].prop)
;numbasis=double(Modules[thisModuleIndex].numbasis)
subsections=double(Modules[thisModuleIndex].subsections)
minPA=double(Modules[thisModuleIndex].minPA) * !DtoR
waveclip=double(Modules[thisModuleIndex].waveclip)

;;get the status console and number of modules
statuswindow = backbone->getstatusconsole()
nummodules = double(N_ELEMENTS(Modules))

;;get the pixel scale, telescope diam  and define conversion factors
;;and figure out IWA in pixels
pixscl = gpi_get_ifs_lenslet_scale(*DataSet.HeadersExt[numfile]) ;as/lenslet
rad2as = 180d0*3600d0/!dpi                                       ;rad->as
tel_diam = gpi_get_constant('primary_diam',default=7.7701d0)     ;m
IWA = 2.8d0 * (cwv.commonwavvect)[0]*1d-6/tel_diam*rad2as/pixscl ; 2.8 l/D (pix)
OWA = 44d0 * (cwv.commonwavvect)[0]*1d-6/tel_diam*rad2as/pixscl  ; 
waffle = OWA/2*sqrt(2)                                           ;radial location of MEMS waffle

if ceil(waffle) - floor(IWA) lt annuli*2 then $
 return,error('INPUT ERROR ('+functionName+'): Your requested annuli will be smaller than 2 pixels.')

;;figure out starting and ending points of annuli and their centers
case annuli of
 0: rads = [0,max(dim)+1]
 1: rads = [floor(IWA),ceil(waffle)]
 else: begin
	if keyword_set(eqarea) then begin
	   rads = dblarr(annuli+1)
	   rads[0] = floor(IWA)
	   rads[n_elements(rads)-1] = ceil(waffle)
	   A = !dpi*(rads[n_elements(rads)-1]^2d0 - rads[0]^2d0)
	   for j = 1,n_elements(rads)-2 do rads[j] = sqrt(A/!dpi/annuli + rads[j-1]^2d0)
	endif else rads = round(dindgen(annuli+1d0) / (annuli) * (ceil(waffle) - floor(IWA)) + floor(IWA))
 end 
endcase 
if max(rads) lt max(dim)+1 then rads = [rads,max(dim)+1]
print, rads
radcents = (rads[0:n_elements(rads)-2]+rads[1:n_elements(rads)-1])/2d0

;;get the number of pixels planet at center of each annulus moves between
;;slices
lambda_moves  = (lambda[0]/lambda - 1d0) # radcents

;;figure out total number of iterations
totiter = (n_elements(rads)-1)*nlam*nfiles

xs = reform(dindgen(dim[0]) # (dblarr(dim[1])+1d0),dim[0]*dim[1])
ys = reform((dblarr(dim[0])+1d0) # dindgen(dim[1]),dim[0]*dim[1])
imcent = (dim-1)/2.
rth = cv_coord(from_rect=transpose([[xs-imcent[0]],[ys-imcent[1]]]),/to_polar)
rs = rth[1,*]
phis = rth[0,*] ;;for later if we want to break up the images

;;allocate output
sub_im = dblarr(dim[0]*dim[1],nlam,nfiles)

;;wavelength clipping
;waveclip = 3

;;threadpool for multithreading
;;numthreads = 33
threads = ptrarr(numthreads)
for thread = 0, numthreads-1 do begin
	print, "spinning up thread", thread
	threads[thread] = ptr_new(obj_new("IDL_IDLBridge", output=''))
	(*threads[thread])->setvar, 'index', -1
endfor
nextthread = 0

;;error handling if crashes to cleanup of threads
catch, error_status
if error_status ne 0 then begin
	for thread = 0, numthreads-1 do begin
		print, "destroying thread", thread
		(*threads[thread])->abort
		obj_destroy, (*threads[thread])
	endfor
    ;;end error catching and rethrow exception
    catch, /cancel
	message, /REISSUE_LAST
;;try to perform KLIP with multiply threads
endif else begin
	;; do this by slice
	for lam = 0 + waveclip,nlam-1-waveclip do begin

		print, "Wavelength slice", lam

		R0 = dblarr(dim[0]*dim[1],nlam,nfiles)
		
		;;get all of the data aligned and scaled by wavelength
		for imnum = 0,nfiles-1 do begin
			tmp =  accumulate_getimage(dataset,imnum)
			thislocs = locs[*,*,lam,imnum]
			thislocs[0,*] -= cens[0,lam,imnum]-imcent[0]
			thislocs[1,*] -= cens[1,lam,imnum]-imcent[1]
			print, "begin align speckles and shift images for image", imnum
			;;align images first
			for wave=0,nlam-1 do begin
				tmp[*,*,wave] = interpolate(tmp[*,*,wave],xs+cens[0,lam,imnum]-imcent[0],ys+cens[1,lam,imnum]-imcent[1],cubic=-0.5)
			endfor
			;;then do speckle align
			tmp =  speckle_align(tmp, refslice=lam, band=band, locs=thislocs)
			for wave=0,nlam-1 do begin
				;;in the future let's put ADR correction in here too...
				R0[*,wave,imnum] =  tmp[*,*,wave]
			endfor
		endfor
		
		;;now that we have the images (this might be able to be moved out of the for loop)
		R0dims = size(R0,/dim)
		;;collapse the wavelength dimension, so basically have a bunch of slices
		R0 = reform(R0, dim[0]*dim[1],nlam*nfiles, /overwrite)
		;;create PA and lambda corresponding to each slice in R0
		PAs_wv = rebin(PAs, nfiles*nlam, /sample)
		lambda_files = reform(transpose(reform(rebin(lambda,nlam*nfiles,/sample),nfiles,nlam)),nlam*nfiles) ;stupid idl array duplication
		lambda_moves_file  = (lambda[0]/lambda_files - 1d0) # radcents
		waveslice_files = indgen(nfiles*nlam) mod nlam

		;;apply KLIP to each annulus
		for radcount = 0,n_elements(rads)-2 do begin
			;;break each annulus into subsections
			;;;;subsections = 4
			dphi = 2.0*!pi/subsections
			for phi_i = 0,subsections-1 do begin
				print, "starting on anuulus", radcount, "subsection", phi_i
				
				;;grad the subannuli region of each file
				;;rad range: rads[radcount]<= R <rads[radcount+1]
				meanrad = (rads[radcount]+rads[radcount+1])/2.
				radinds = where( (rs ge rads[radcount]) and (rs lt rads[radcount+1]) and (phis ge phi_i*dphi-!Pi) and (phis lt (phi_i+1)*dphi-!Pi) )
				R = R0[radinds,*] ;;ref set
				;
				;;check that you haven't just grabbed a blank annulus
				if (total(finite(R)) eq 0) then begin 
				   statuswindow->set_percent,-1,double(nfiles)/totiter*100d/nummodules,/append
				   continue
			    endif 
				;
				;;;create mean subtracted versions and get rid of NaNs
				mean_R_dim1=dblarr(N_ELEMENTS(R[0,*]))                        
				for zz=0,N_ELEMENTS(R[0,*])-1 do mean_R_dim1[zz]=mean(R[*,zz],/double,/nan)
				R_bar = R-matrix_multiply(replicate(1,n_elements(radinds),1),mean_R_dim1,/btranspose)
				naninds = where(R_bar ne R_bar,countnan)
				if countnan ne 0 then begin 
				   R_bar[naninds] = 0
				   naninds = array_indices(R_bar,naninds)
				endif
				
				;;;find covariance of all slices
				covar0 = matrix_multiply(R_bar,R_bar,/atranspose)/(n_elements(radinds)-1d0) 
				
				;;PSF subtract for each file
				for imnum = 0,nfiles-1 do begin
					print, "begin psf subtraction for image", imnum
					;;update progress as needed
					statuswindow->set_percent,-1,1d/totiter*100d/nummodules,/append

					;;figure out which images are to be used
					;;assuming a planet is in the middle of the annulus, where can we avoid self-subtraction
                    ;;place science image section +x axis
                    x_sci = meanrad
                    y_sci = 0
                    ;;calculate coordinate of center of section for each reference PSF
                    r_ref = meanrad * (lambda[lam] / lambda_files)
                    theta_ref = PAs_wv - PAs[imnum] 
                    x_ref = r_ref * cos(theta_ref)
                    y_ref = r_ref * sin(theta_ref)
                    moves = sqrt((x_sci - x_ref)^2 + (y_sci - y_ref)^2)
					;fileinds = where( (sqrt(( sqrt(2 * (1.0-cos(PAs_wv - PAs[imnum]))) * meanrad)^2 + (	lambda_moves_file[*,radcount] - lambda_moves[lam,radcount])^2 ) gt minsep) and (abs(PAs_wv - PAs[imnum]) ge minPA) and (waveslice_files ge waveclip) and (waveslice_files lt nlam-waveclip) , count)
					fileinds = where( (moves ge minsep) and (abs(PAs_wv - PAs[imnum]) ge minPA) and (waveslice_files ge waveclip) and (waveslice_files lt nlam-waveclip) , count)
					print, "Number of files for ref PSF: ", count
					if count lt 2 then begin 
						logstr = 'No reference slices available for requested motion. Skipping.'
						message,/info,logstr
						backbone->Log,logstr
						continue
					endif 

					;grab the original file
					T0 = R0[*, imnum*nlam + lam]
					;T = T0[radinds] - mean(T0[radinds],/double,/nan)
					;nanpix = where(~finite(T), num_nanpix)
					;if num_nanpix gt 0 then T[nanpix] = 0
					;;T = R_bar[*,imnum*nlam+lam]
					;;T = R[*,ref_value]
					;
					;create mean subtracted versions and get rid of NaNs
					refs = R[*,fileinds]
					
                    ;grab covariance submatrix
					covar = covar0[fileinds,*]
					covar = covar[*,fileinds]

					;;find the next free thread
					loopcount = 0
					;print, "checking thread", nextthread
					while (*threads[nextthread])->status() eq 1 do begin
						if loopcount ge numthreads then wait, 0.07*nfiles
						nextthread += 1
						nextthread = nextthread mod numthreads
						loopcount += 1
						;print, "checking thread", nextthread
					endwhile
					
					;;take the ouput of the job that just finished and write it
					print, "thread status", (*threads[nextthread])->status()
					if (*threads[nextthread])->getvar('index') ge 0 then begin
						output = (*threads[nextthread])->getvar('image')
						oldfile = (*threads[nextthread])->getvar('index')
						sub_im[radinds,lam,oldfile] = output
						(*threads[nextthread])->setvar, 'index', -1
						print, "thread finished", nextthread, oldfile
					endif
					
					;;add the new job
					print, "add job to thread", nextthread
					(*threads[nextthread])->setvar, 'image', T0[radinds]
					(*threads[nextthread])->setvar, 'refs', refs
					(*threads[nextthread])->setvar, 'prop', prop
					(*threads[nextthread])->setvar, 'index', imnum
					(*threads[nextthread])->setvar, 'covar', covar
					(*threads[nextthread])->execute, 'image = klip_math(image, refs, prop, covar=covar)', /nowait
					;print, "thread status", (*threads[nextthread])->status()
					
					;mean_R_dim1=dblarr(N_ELEMENTS(R[0,*]))                        
					;for zz=0,N_ELEMENTS(R[0,*])-1 do mean_R_dim1[zz]=mean(R[*,zz],/double,/nan)
					;R_bar = R-matrix_multiply(replicate(1,n_elements(radinds),1),mean_R_dim1,/btranspose)
					;naninds = where(R_bar ne R_bar,countnan)
					;if countnan ne 0 then begin 
					;   R[naninds] = 0
					;   R_bar[naninds] = 0
					;   naninds = array_indices(R_bar,naninds)
					;endif
					;
					;;;find covariance of all slices
					;covar = matrix_multiply(R_bar,R_bar,/atranspose)/(n_elements(radinds)-1d0) 
					;
					;;;grab covariance submatrix
					;;covar = covar0[fileinds,*]
					;;covar = covar[*,fileinds]
					;
					;;;get the eigendecomposition
					;residual = 1         ;initialize the residual
					;evals = eigenql(covar,eigenvectors=evecs,/double,residual=residual)  
					;
					;;;determines which eigenalues to truncate
					;;evals_cut = where(total(evals,/cumulative) gt prop*total(evals))
					;;K = evals_cut[0]
					;;	print, "truncating at eigenvalue", K
					;;if K eq -1 then continue
					;K = min([numbasis,(size(covar,/dim))[0]-1])
					;
					;;;creates mean subtracted and truncated KL transform vectors
					;;Z = evecs ## R_bar[*,fileinds]
					;Z = evecs ## R_bar
					;G = diag_matrix(sqrt(1d0/evals/(n_elements(radinds)-1)))
					;
					;Z_bar = G ## Z
					;Z_bar_trunc=Z_bar[*,0:K] 
					;
					;;;Project KL transform vectors and subtract from target
					;signal_step_1 = matrix_multiply(T,Z_bar_trunc,/atranspose)
					;signal_step_2 = matrix_multiply(signal_step_1,Z_bar_trunc,/btranspose)
					;Test = T - transpose(signal_step_2)
					;
					;;;restore,NANs,rotate estimate by -PA and add to output
					;;;if countnan ne 0 then Test[naninds[0,where(naninds[1,*] eq imnum)]] = !values.d_nan
					;if num_nanpix gt 0 then Test[nanpix] = !values.d_nan
					;
					;sub_im[radinds,lam,imnum] = Test
					;;if radcount eq n_elements(rads)-2 then stop
					;;final_im[*,*,lam] += rot(reform(Test,dim),PAs[imnum],/interp,cubic=-0.5)
				endfor
				print, 'waiting for the rest of the threads to finish before moving on'
				for thread = 0, numthreads-1 do begin
					;;find the next free thread
					;print, 'waiting for', thread
					while (*threads[thread])->status() eq 1 do begin
						wait, 0.1*nfiles
					endwhile
					
					print, 'checking for finished jobs', thread
					if (*threads[thread])->getvar('index') ge 0 then begin
						;;take the ouput of the job that just finished and write it
						output = (*threads[thread])->getvar('image')
						fileindex = (*threads[thread])->getvar('index')
						sub_im[radinds,lam,fileindex] = output
						(*threads[thread])->setvar, 'index', -1
						print, "thread finished", thread, fileindex
					endif
				endfor
			endfor
		endfor
	endfor 
endelse

catch, /cancel

;form datacubes again
sub_im = reform(sub_im, dim[0],dim[1],nlam,nfiles)

suffix = suffix+'-klip'

savefile =double(Modules[thisModuleIndex].Save)

for i=0,nfiles-1 do begin

	backbone->Log, "Finished KLIP'd cube: "+strc(i+1)+" of "+strc(nfiles), depth=3
	print, "Saving frame", i
	accumulate_updateimage, dataset, i, newdata = sub_im[*,*,*,i]
   	;;writefits, strtrim(string(i),2) + '_kliped.fits', sub_im[*,*,*,i]
    if savefile eq 1 then return_val = save_currdata(dataset, Modules[thisModuleIndex].OutputDir, '_klip', indexFrame=i, SaveData=sub_im[*,*,*,i])
endfor

;;cleanup
for thread = 0, numthreads-1 do begin
	;;known bug in IDL. Using more than 15 bridges simulatenously
	;;on a 64bit linux system causes IDL to hang if the bridges are
	;; not destroyed in the exact opposite order they are created
	actual_thread = numthreads-1-thread
	print, "destroying thread", actual_thread
	(*threads[actual_thread])->abort
	obj_destroy, (*threads[actual_thread])
endfor

;sub_im = final_im/nfiles
;final_im = dblarray(dim[0],dim[1],nlam)
;for filenum=0,nfiles do begin
;final_im += rot(sub_im[*,*,*,filenum], PAs[filenum],/interp,cubic=-0.5)
;endfor
;
;*(dataset.currframe) = final_im
;dataset.validframecount=1
;
;
;
;backbone->set_keyword,'HISTORY', functionname+": ADI+SDI KLIP applied.",ext_num=0
;
;;;update WCS info
;gpi_update_wcs_basic,backbone,parang=0d0,imsize=dim
;
;;;update satspot locations to new position and rotation
;flocs = locs[*,*,*,numfile]
;fcens = cens[*,*,numfile]
;for j=0,1 do for k=0,nlam-1 do flocs[j,*,k] +=  imcent[j] - fcens[j,k]
;gpi_rotate_header_satspots,backbone,PAs[numfile],flocs,imcent=imcent
;
;backbone->set_keyword, "FILETYPE", "Spectral Cube ADI+SDI KLIP"
@__end_primitive

end

  
  
