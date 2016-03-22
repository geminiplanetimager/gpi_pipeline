;+
; NAME: gpi_get_pol_vector_stats
; PIPELINE PRIMITIVE DESCRIPTION: Get statistics on Polarimetry Vectors
;
; Get's a number of statistics on polarimetry vectors
; Plots histograms.
;

; INPUTS: stokesdc data-cube
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; OUTPUTS:  None
;
; PIPELINE COMMENT: Converts a stokes cube to a radial stokes cube
; PIPELINE ARGUMENT: Name="SaveHists" Type="string" Default="" Desc="Save vector histograms to filename as FITS (blank for no save, dir name for default naming, AUTO for auto full path)"
; PIPELINE ARGUMENT: Name="SavePNG" Type="string" Default="" Desc="Save plot to filename as PNG (blank for no save, dir name for default naming, AUTO for auto full path) "
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[-1,100]" Default="-1" Desc="-1 = No display; 0 = New (unused) window; else = Window number to display in."
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="2" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ARGUMENT: Name="offset" Type="float" Range="[-360.,360]" Default="0" Desc="An offset in the theta used to calculate the radial stokes - for testing"
; PIPELINE ORDER: 3.5
; PIPELINE NEWTYPE: PolarimetricScience
;
;
; HISTORY:
;   2015-05-20 MMB created
;
;-

function gpi_get_pol_vector_stats, DataSet, Modules, Backbone
  primitive_version= '$Id: gpi_smooth_cube.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history
    @__start_primitive

  ;  if ~strmatch(mode,"*wollaston*",/fold) then begin
  ;    backbone->Log, "ERROR: That's not a polarimetry file!"
  ;    return, not_ok
  ;  endif

  ctype3 = backbone->get_keyword('CTYPE3', count=ct1, indexFrame=indexFrame)

  if ~strmatch(ctype3, "STOKES*", /fold) then begin
    backbone->Log, "ERROR: That's not a stokesdc file!"
    return, not_ok
  endif

  ;Get the psf centers
  psfcentx = backbone->get_keyword('PSFCENTX', count=ct1, indexFrame=indexFrame)
  psfcenty = backbone->get_keyword('PSFCENTY', count=ct2, indexFrame=indexFrame)
  if ct1+ct2 ne 2 then begin
    return, error("Could not get PSFCENTX and PSFCENTY keywords from header. Cannot determine PSF center.")
  endif

  if tag_exist( Modules[thisModuleIndex], "SaveHists") then savehists= Modules[thisModuleIndex].SaveHists else savehists="" ; can be CUBIC or FFT
  if tag_exist( Modules[thisModuleIndex], "SavePNG") then pngsave= Modules[thisModuleIndex].SavePNG else pngsave="" ; can be CUBIC or FFT
  if tag_exist( Modules[thisModuleIndex], "Display") then display= strupcase(Modules[thisModuleIndex].Display) else display=-1 ; can be CUBIC or FFT

  ;Measure the angles.
  im=*(dataset.currframe)
  q=im[*,*,1]
  u=im[*,*,2]

  ;The actual vectors in the data
  sgn = 1
  ; Get the vector angles
  phi =  sgn* 0.5 * atan(u,q)/!dtor+float(Modules[thisModuleIndex].offset) mod 180

  ; Get the radial pol
  qr=Q*cos(2*phi)+U*sin(2*phi)
  ur=-Q*sin(2*phi)+U*cos(2*phi)

  ;Make an array of xyz values
  indices, im[*,*,0], x,y,z

  ;  hdr = *((*self.state).exthead_pter)
  hdr=*DataSet.HeadersExt[indexFrame]
  rot_ang = backbone->get_keyword('ROTANG') ;If this keyword isn't set sxpar just returns 0, which is acceptable.
  getrot, hdr, npa, cdelt, /silent
  d_PAR_ANG = - rot_ang

  ;print, "Rotating pol vectors by angle of: "+string(-d_PAR_ANG) ; To match with north rotation
  if cdelt[0] gt 0 then sgn = -1 else sgn = 1 ; To check for flip between RH and LH coordinate systems


  ;The expected values if completely tangential and circularly symmetry
  phi_expected = atan((y-psfcenty)/(x-psfcentx))/!dtor+float(Modules[thisModuleIndex].offset)+npa mod 180

  dist_circle, rad, (size(q))[1], psfcentx, psfcenty

  ;Testing this out
  ;  qr=sqrt(q^2+u^2)

  ;  med_qr=median(qr)
  ;   meanclip, qr[where(rad lt 80 and rad gt 12 and finite(qr))], me_qr, std_qr
  meanclip, ur[where(rad lt 80 and rad gt 12 and finite(qr))], me_ur, std_ur

  ;  std_qr=stddev(qr[where(rad lt 80 and rad gt 12)], /nan)
  w_good=where(rad lt 80 and rad gt 12 and qr gt 3*std_ur); and qr lt median(qr))


  ;Plot only of display > 0
  ;
  
    ;Plot the histogram of actual values
    p_hist=histogram(phi[w_good], locations=p_x ,/nan, binsize=5)
    pdiff=(phi[w_good]-phi_expected[w_good]) mod 90
    
    ;The difference from circular
    pdiff_hist=histogram(pdiff, locations=pdiff_x, /nan, binsize=5)
    ;pdiff_hist=histogram_weight(phi[w_good]-phi_expected[w_good], weight=1/(qr[w_good]/max(qr[w_good])), locations=pdiff_x, /nan)
   

    if display ge 0 then begin
      p=plot(p_x, p_hist, /stairstep, title="Raw Pol Vectors", layout=[1,2,1])
      p2=plot(pdiff_x, pdiff_hist, /stairstep, title="Difference from expected", layout=[1,2,2], /current)
    endif else begin
      p=plot(p_x, p_hist, /stairstep, title="Raw Pol Vectors", layout=[1,2,1],/buffer)
      p2=plot(pdiff_x, pdiff_hist, /stairstep, title="Difference from expected", layout=[1,2,2], /current, /buffer)
    endelse
    
    ;Save the image as a png!
    if pngsave ne '' then begin

      ;;if user set AUTO then synthesize entire path
      if strcmp(strupcase(pngsave),'AUTO') then begin
        s_OutputDir = Modules[thisModuleIndex].OutputDir
        s_OutputDir = gpi_expand_path(s_OutputDir)
        if strc(s_OutputDir) eq "" then return, error('FAILURE: supplied output directory is a blank string.')
        s_OutputDir = s_OutputDir+path_sep()+'contrast'+path_sep()

        if ~file_test(s_OutputDir,/directory, /write) then begin
          if gpi_get_setting('prompt_user_for_outputdir_creation',/bool, default=0,/silent) then $
            res =  dialog_message('The requested output directory '+s_OutputDir+' does not exist. Should it be created now?', $
            title="Nonexistent Output Directory", /question) else res='Yes'

          if res eq 'Yes' then  file_mkdir, s_OutputDir

          if ~file_test(s_OutputDir,/directory, /write) then $
            return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)
        endif
        pngsave = s_OutputDir
      endif


      ;;if this is a directory, then you want to save to it with the
      ;;default naming convention
      if file_test(pngsave,/dir) then begin
        nm = gpi_expand_path(DataSet.filenames[numfile])
        strps = strpos(nm,path_sep(),/reverse_search)
        strpe = strpos(nm,'.fits',/reverse_search)
        nm = strmid(nm,strps+1,strpe-strps-1)
        nm = gpi_expand_path(pngsave+path_sep()+nm+'_stokesdc_pol_vectors.png')
      endif else nm = pngsave

      p.Save, nm
      print, "Histograms image saved to ",nm
    endif

  cd, "./", current=old_Dir
  print, "Working directory: "+old_dir
  ;;save radial contrast as fits
  if savehists ne '' then begin
    ;;if user set AUTO then synthesize entire path
    if strcmp(strupcase(savehists),'AUTO') then begin
      s_OutputDir = Modules[thisModuleIndex].OutputDir
      s_OutputDir = gpi_expand_path(s_OutputDir)
      if strc(s_OutputDir) eq "" then return, error('FAILURE: supplied output directory is a blank string.')
      s_OutputDir = s_OutputDir+path_sep()+'contrast'+path_sep()

      if ~file_test(s_OutputDir,/directory, /write) then begin
        if gpi_get_setting('prompt_user_for_outputdir_creation',/bool, default=0,/silent) then $
          res =  dialog_message('The requested output directory '+s_OutputDir+' does not exist. Should it be created now?', $
          title="Nonexistent Output Directory", /question) else res='Yes'

        if res eq 'Yes' then  file_mkdir, s_OutputDir

        if ~file_test(s_OutputDir,/directory, /write) then $
          return, error("FAILURE: Directory "+s_OutputDir+" does not exist or is not writeable.",/alert)
      endif
      savehists = s_OutputDir
    endif

    ;;if this is a directory, then you want to save to it with the
    ;;default naming convention
    if file_test(savehists,/dir) then begin
      nm = gpi_expand_path(DataSet.filenames[numfile])
      strps = strpos(nm,path_sep(),/reverse_search)
      strpe = strpos(nm,'.fits',/reverse_search)
      nm = strmid(nm,strps+1,strpe-strps-1)
      nm = gpi_expand_path(savehists+path_sep()+nm+'stokesdc_pol_vector_hist.fits')
    endif else nm = savehists

    out1 = dblarr(n_elements(p_x),2)+!values.d_nan
    out1[*,0] = p_x
    out1[*,1] = p_hist

    out2 = dblarr(n_elements(p_x),2)+!values.d_nan
    out2[*,0] = pdiff_x
    out2[*,1] = pdiff_hist

;    tmp = intarr((dim)[2])
;    tmp[inds] = 1
;    slices = string(strtrim(tmp,2),format='('+strtrim(n_elements(tmp),2)+'(A))')

    mkhdr,hdr,out1
    ;      sxaddpar,hdr,'SLICES',slices,'Cube slices used.'
    ;      sxaddpar,hdr,'YUNITS',(['Std Dev','Median','Mean'])[],'Contrast units'

    writefits,nm, out1, hdr
    writefits,nm, out2, /append

    print, "Histograms output to ", nm
  endif else print, "Not saving the histograms to fits"

  @__end_primitive
end
