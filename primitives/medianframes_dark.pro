;+
; NAME: medianframes_dark
; PIPELINE PRIMITIVE DESCRIPTION: Calculate the median frame of dark images.
;
;
; INPUTS: 2D image from narrow band arclamp
; common needed:
;
; KEYWORDS:
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: NAXISi,FILETYPE,ISCALIB
;
; OUTPUTS:
;
; PIPELINE COMMENT: Calculate the median frame of dark images
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-dark" Desc="Enter output suffix"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 1.4
; PIPELINE TYPE: CAL-SPEC
; PIPELINE SEQUENCE: 22-

; HISTORY:
; 	 Jerome Maire 2008-10
;   2009-09-17 JM: added DRF parameters
;-
function medianframes_dark, im
common PIP

primitive_version= '$Id$' ; get version from subversion to store in header history
  getmyname, functionname
  @__start_primitive
;test if last file of listfilenames
if numfile eq n_elements(listfilenames)-1  then begin

fits_read,filename,im,h, header_only=1
im=readfits(filename,h,/silent)
naxis = sxpar( h ,'NAXIS*')
	imtab=dblarr(naxis(0),naxis(1),numfile)
		for i=1,numfile-1 do begin
		filena=listfilenames(i,*)
		imtab(*,*,i)=readfits(filena,heade,/silent)
		endfor
		if numfile gt 1 then im=median(imtab,/DOUBLE,DIMENSION=3)

		 pos=strpos(filename,'-',/REVERSE_SEARCH)
		 ;TODO header update
		 sxaddhist, functionname+":Combined darks:", h		 
		 for i=1,numfile-1 do  sxaddhist, listfilenames(i,*), h
		 sxaddpar, h, "FILETYPE", "dark", /savecomment
     sxaddpar, h, "ISCALIB", 'YES', 'This is a reduced calibration file of some type.'
		 
		; writefits,strmid(filename,0,pos+1)+suffix+'.fits',im,h
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
  if tag_exist( Modules[thisModuleIndex], "suffix") then suffix=Modules[thisModuleIndex].suffix
  
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          ;gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse

endif

return, ok
end
