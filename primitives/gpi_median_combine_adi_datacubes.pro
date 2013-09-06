;+
; NAME: gpi_median_combine_adi_datacubes
;
; PIPELINE PRIMITIVE DESCRIPTION: Median Combine ADI datacubes
;     Median all ADI datacubes
;
;
; INPUTS: data-cube
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;  INPUTS:
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE COMMENT: Median combine all residual datacubes after an ADI (or LOCI) speckle suppression.
; PIPELINE ORDER: 4.5
; PIPELINE NEWTYPE: SpectralScience
;
; EXAMPLE: 
;  <module name="gpi_medianADI"  Save="1" gpitv="1" />
; HISTORY:
;    Jerome Maire :- multiwavelength 2008-08
;    JM: adapted for GPI-pip
;   2009-09-17 JM: added DRF parameters
;   2010-10-19 JM: split HISTORY keyword if necessary
;   2013-07-16 MP: Rename for consistency
;-

Function gpi_median_combine_adi_datacubes, DataSet, Modules, Backbone
primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

;;if all ADI residuals have been processed into datacubes then start median ADI processing...
if numfile  eq ((dataset.validframecount)-1) then begin
  ;thisModuleIndex = drpModuleIndexFromCallSequence(Modules, functionName) ;module# to get data proc options from user choice
  thisModuleIndex = Backbone->GetCurrentModuleIndex()
  dimcub=(size(*(dataset.currframe[0])))
  
  ;get the list of ADI residuals
  flist=strarr((dataset.validframecount))
  for ii=0, ((dataset.validframecount)-1) do begin
    ;fn=*((dataset.frames)[ii])
    ;fname=file_break(fn,/NO_EXT)
    flist[ii]=dataset.outputFileNames[ii] ;Modules[0].OutputDir+path_sep()+fname+suffix+'.fits'
  endfor
  fits_info, dataset.outputFileNames[0],n_ext=n_ext, /silent
  if dimcub[0] eq 2 then begin
        immed=dblarr(dimcub[1],dimcub[2]) 
            ;for il=0,CommonWavVect[2]-1 do begin
            ;fait la mediane de toutes les images
              ;immed[*,*,il]=gpi_medfits(flist,dimcub,dimcub,gz=gz,lam=il,/silent)
              immed[*,*]=gpi_medfits(dataset.outputFileNames[0:(dataset.validframecount)-1],dimcub[1],dimcub[2],gz=gz,lam=-1,/silent,exten=n_ext)
              ;update_progressbar2ADI,Modules,thisModuleIndex,CommonWavVect[2], il ,'working...' 
            ;endfor
endif else begin
        immed=dblarr(dimcub[1],dimcub[2],dimcub[3])
            for il=0,dimcub[3]-1 do begin
                ;okay, the following line is strange, but it bugs if passing directly the for index
                compt=il
            ;fait la mediane de toutes les images
              ;immed[*,*,il]=gpi_medfits(flist,dimcub,dimcub,gz=gz,lam=il,/silent)
              immed[*,*,il]=gpi_medfits(dataset.outputFileNames[0:(dataset.validframecount)-1],dimcub[1],dimcub[2],gz=gz,lam=compt,/silent,exten=n_ext)
              ;update_progressbar2ADI,Modules,thisModuleIndex,CommonWavVect[2], il ,'working...' 
            endfor
endelse
  ;create header ;todo:change according with accumulate_images
  ;fits_info, dataset.outputFileNames[0], n_ext=n_ext
  ;header=headfits(dataset.outputFileNames[0],/silent)
  for ii=0, ((dataset.validframecount)-1) do $
   backbone->set_keyword,'HISTORY','Med. combin. of '+dataset.outputFileNames[ii],ext_num=0
  ;sxaddparlarge,header,'HISTORY','Med. combin. of '+dataset.outputFileNames[ii]
  
   ;*(dataset.headers[numfile])=header
   ; put the datacube in the dataset.currframe output structure:
    *(dataset.currframe[0])=immed

    
  ;create filename for median ADI datacube
  suffix=suffix+'-resadi'
 ; filenm=Modules[thisModuleIndex].OutputDir+path_sep()+strmid(fname,0,STRLEN(fname)-2)+suffix+'.fits'



  ;save median ADI datacube
thisModuleIndex = Backbone->GetCurrentModuleIndex()

@__end_primitive
;    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
;      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
;      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display)
;      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;    endif else begin
;      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
;          gpitvms, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv), head=header
;    endelse

    
 
endif

return, ok
end
