;+
; NAME: create microphonics model
; PIPELINE PRIMITIVE DESCRIPTION: Create a microphonics noise model.
;
;  Create a microphonics noise model in Fourier space.
;
; INPUTS:  several dark frames
; OUTPUTS: microphonics model in Fourier space, saved as a calibration file
;
; PIPELINE COMMENT: Create a microphonics noise model in Fourier space.
; PIPELINE ARGUMENT: Name="Gauss_Interp" Type="int" Range="[0,1]" Default="0" Desc="1: Interpolate each peak by a 2d gaussian, 0: don't interpolate"
; PIPELINE ARGUMENT: Name="Combining_Method" Type="string" Range="ADD|MEDIAN" Default="ADD" Desc="Method to combine the Fourier transforms of the microphonics (ADD|MEDIAN)"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.01
; PIPELINE TYPE: CAL-SPEC
; PIPELINE NEWTYPE: Calibration
; PIPELINE SEQUENCE: 22-
;
; HISTORY:
;    Jean-Baptiste Ruffio 2013-05
;-
function create_microphonics_model, DataSet, Modules, Backbone
primitive_version= '$Id: create_microphonics_model.pro 1501 2013-04-29 21:24:26Z jruffio $' ; get version from subversion to store in header history
@__start_primitive

 if tag_exist( Modules[thisModuleIndex], "Gauss_Interp") then Gauss_Interp=float(Modules[thisModuleIndex].Gauss_Interp) else Gauss_Interp=0
 if tag_exist( Modules[thisModuleIndex], "Combining_Method") then Combining_Method=string(Modules[thisModuleIndex].Combining_Method) else Combining_Method='ADD'
 
  nfiles=dataset.validframecount

  ; Load the first file so we can figure out their size, etc. 
  im0 = accumulate_getimage(dataset, 0, hdr,hdrext=hdrext)
  sz = [0, backbone->get_keyword('NAXIS1',ext_num=1), backbone->get_keyword('NAXIS2',ext_num=1)]
  imtab = dblarr(sz[1], sz[2], nfiles)

  itimes = fltarr(nfiles)
  ; read in all the images
  for i=0,nfiles-1 do begin
    imtab[*,*,i] =  accumulate_getimage(dataset,i,hdr, hdrext=hdrext)
    itimes[i] = sxpar(hdrext, 'ITIME')
    ; verify all input files have the same exp time?
    if itimes[i] ne itimes[0] then return, error('FAILURE ('+functionName+"): Exposure times are inconsistent. First file was "+strc(itimes[0])+" s, but file "+strc(i)+" is not.")
  endfor

  ; now combine them to create the model.
  if nfiles gt 1 then begin
  
    backbone->set_keyword, 'HISTORY', functionname+":   Combining n="+strc(nfiles)+' files using method='+Combining_Method,ext_num=0
    backbone->Log, "  Combining n="+strc(nfiles)+' files using method='+Combining_Method
    backbone->set_keyword, 'DRPNFILE', nfiles, "# of files combined to produce this output file"
    
    Fimtab = complexarr(sz[1], sz[2], nfiles)
    for i=0,nfiles-1 do begin
      ;shift for centering the Fourier image to gather the three peaks
      Fimtab[*,*,i] = shift(fft(imtab[*,*,i]),1024,1024)
    endfor

    ;get the aera with the three peaks of the microphonics noise
    abs_peaks_Fimtab = abs(Fimtab[1004:1046, 1190:1210, *])
    
    ;combine all the frames
    case Combining_Method of
    'MEDIAN': begin 
      combined_abs_peaks_Fimtab=median(abs_peaks_Fimtab,/DOUBLE,DIMENSION=3) 
    end
    'ADD': begin
      combined_abs_peaks_Fimtab=total(abs_peaks_Fimtab,/DOUBLE,3)
    end
    else: begin
      return, error('FAILURE ('+functionName+"): Invalid combination method '"+Combining_Method+"' in call to create_microphonics_model.")
    endelse
    endcase
    
  endif else begin
    backbone->set_keyword, 'HISTORY', functionname+":   Only 1 file supplied, so nothing to combine.",ext_num=0
    message,/info, "Only one frame supplied - can't really combine it with anything..."
    ;the next line is hard to read but it does exactly the same as the lines before
    combined_abs_peaks_Fimtab = abs((shift(fft(imtab[*,*,0]),1024,1024))[1004:1046, 1190:1210])
  endelse
   
   ;interpolate each pek with a 2d gaussian if asked
   if Gauss_Interp eq 1 then begin
      ;isolate the peaks
      peakleft = combined_abs_peaks_Fimtab[0:11, *]
      peakmiddle = combined_abs_peaks_Fimtab[12:31, *]
      peakright = combined_abs_peaks_Fimtab[32:42, *]
      
      peakleft_gauss = gauss2dfit(peakleft, para_left)
      peakmiddle_gauss = gauss2dfit(peakmiddle, para_middle)
      peakright_gauss = gauss2dfit(peakright, para_right)
      ;remove the constant term
      peakleft_gauss = peakleft_gauss - para_left[0]
      peakmiddle_gauss = peakmiddle_gauss - para_middle[0]
      peakright_gauss = peakright_gauss - para_right[0]
      
      combined_abs_peaks_Fimtab = [peakleft_gauss,peakmiddle_gauss,peakright_gauss]
   endif else begin
      ;remove the constant term
      combined_abs_peaks_Fimtab = combined_abs_peaks_Fimtab - median([combined_abs_peaks_Fimtab[*,0],combined_abs_peaks_Fimtab[*,20]])
   endelse
      
   ;build the model
   micro_noise_model = fltarr(sz[1], sz[2])
   micro_noise_model[1004:1046, 1190:1210] = combined_abs_peaks_Fimtab
   micro_noise_model = shift(micro_noise_model, -1024, -1024)
   ;build the symetric in Fourier space because the image is real
   micro_noise_model += reverse(reverse(micro_noise_model, 2),1)
   
   ;normalize the model
   micro_noise_model_normalized = micro_noise_model/sqrt(total(micro_noise_model^2))

  ;----- store the output into the backbone datastruct
  *(dataset.currframe)=micro_noise_model_normalized
  dataset.validframecount=1
    backbone->set_keyword, "FILETYPE", "Micro Model", /savecomment
    backbone->set_keyword, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
  suffix = '-microModel'

@__end_primitive
end