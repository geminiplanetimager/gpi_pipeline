;+
; NAME: gpi_make_pol_ql_image
; PIPELINE PRIMITIVE DESCRIPTION: Make Quicklook Pol Image
; Makes a summary png to for quick look purposes 
; Designed to go on the GPIES WEB THINGIE
; The final image shows Q,U,P and Q_r, U_r and a plot of the stokes vectors
; INPUTS: stokesdc data-cube
;
; GEM/GPI KEYWORDS:
; DRP KEYWORDS: HISTORY
; OUTPUTS:  None
;
; PIPELINE COMMENT: Converts a stokes cube to a radial stokes cube
; PIPELINE ARGUMENT: Name="SavePNG" Type="string" Default="" Desc="Save plot to filename as PNG (blank for no save, dir name for default naming, AUTO for auto full path) "
; PIPELINE ARGUMENT: Name="Display" Type="int" Range="[-1,100]" Default="-1" Desc="-1 = No display; 0 = New (unused) window; else = Window number to display in."
; PIPELINE ORDER: 5.5
; PIPELINE NEWTYPE: PolarimetricScience
;
; HISTORY:
;   2015-05-20 MMB created
;-

function gpi_make_pol_ql_image, DataSet, Modules, Backbone
  primitive_version= '$Id: gpi_smooth_cube.pro 2878 2014-04-29 04:11:51Z mperrin $' ; get version from subversion to store in header history
    @__start_primitive

  ;Check for wollaston
;    if ~strmatch(mode,"*wollaston*",/fold) then begin
;      backbone->Log, "ERROR: That's not a polarimetry file!"
;      return, not_ok
;    endif

  ;Check to see if it's a stokesdc file
  ctype3 = backbone->get_keyword('CTYPE3', count=ct1, indexFrame=indexFrame)
  if ~strmatch(ctype3, "STOKES*", /fold) then begin
    backbone->Log, "ERROR: That's not a stokesdc file!"
    return, not_ok
  endif

  ;;
  ; This first part gets a histogram of the pol vectors (it calculates q_r and u_r in the mean time)
  ;;
  
  ;Get the psf centers
  psfcentx = backbone->get_keyword('PSFCENTX', count=ct1, indexFrame=indexFrame)
  psfcenty = backbone->get_keyword('PSFCENTY', count=ct2, indexFrame=indexFrame)
  if ct1+ct2 ne 2 then begin
    return, error("Could not get PSFCENTX and PSFCENTY keywords from header. Cannot determine PSF center.")
  endif

  if tag_exist( Modules[thisModuleIndex], "SavePNG") then pngsave= Modules[thisModuleIndex].SavePNG else pngsave="" ; can be CUBIC or FFT
  if tag_exist( Modules[thisModuleIndex], "Display") then display= strupcase(Modules[thisModuleIndex].Display) else display=-1 ; can be CUBIC or FFT

  ;Measure the angles.
  im=*(dataset.currframe)
  q=im[*,*,1]
  u=im[*,*,2]

  ;The actual vectors in the data
  sgn = 1
  ; Get the vector angles
  phi =  sgn* 0.5 * atan(u,q)/!dtor mod 180

  ; Get the radial pol
  indices, im[*,*,0], x,y,z
  phi_r=atan((y-psfcenty)/(x-psfcentx))
  qr=Q*cos(2*phi_r)+U*sin(2*phi_r)
  ur=-Q*sin(2*phi_r)+U*cos(2*phi_r)

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
  phi_expected = atan((y-psfcenty)/(x-psfcentx))/!dtor+npa mod 180

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
  
  ;This is based on the autoscale logic from GPITV
  nhigh = 2
  nlow = 2
  ;Get the autoscale parameters for q (use the same for U)
  med = median(q,/DOUBLE)
  sz=size(q)
  sig = stddev((double(q))[sz[1]/2-sz[1]/5:sz[1]/2+sz[1]/5,sz[2]/2-sz[2]/5:sz[2]/2+sz[2]/5],/NAN) ;limit area of stddev to remove edge effects occuring when flat-fielding
  q_max = (med + (nhigh * sig)) < max(q,/nan)
  q_min = (med - (nlow * sig))  > min(q,/nan)
  
  ;Get the autoscale parameters for q_r (use the same for U_r)
;  nhigh = 1
;  nlow = 2
;  med = median(qr,/DOUBLE)
;  sz=size(qr)
;  sig = stddev((double(qr))[sz[1]/2-sz[1]/5:sz[1]/2+sz[1]/5,sz[2]/2-sz[2]/5:sz[2]/2+sz[2]/5],/NAN) ;limit area of stddev to remove edge effects occuring when flat-fielding
;  
;  meanclip, qr, med, sig
;  q_rmax = (med + (nhigh * sig)) < max(qr,/nan)
;  q_rmin = (med - (nlow * sig))  > min(qr,/nan)
  
  nfiles=backbone->get_keyword('DRPNFILES')
 
  
  if display ge 0 then begin
    p_q=image(q, layout=[3,2,1], title="Stokes Q", rgb_table=1, max_value=q_max, min_value=q_min)
    p_u=image(u, layout=[3,2,2], /current, title="Stokes U", rgb_table=1, max_value=q_max, min_value=q_min)
    p_p=image(sqrt(q^2+u^2),layout=[3,2,3], /current , title="Polarized Intensity", rgb_table=1, min_value=q_min, max_value=q_max)
    p_qr=image(qr, layout=[3,2,4], /current, title="Q_r", rgb_table=1, min_value=q_min, max_value=q_max)
    p_ur=image(ur, layout=[3,2,5], /current, title="U_r", rgb_table=1, min_value=q_min, max_value=q_max)
    p2=plot(pdiff_x, pdiff_hist, /stairstep, title="Vector offset from !C centrosymmetry", layout=[3,2,6], /current, rgb_table=1)
    title=text(0.05,0.95, "Target Name: "+backbone->get_keyword('OBJECT'), /normal, alignment=0.0)
    title=text(0.05,0.05, "Last Processed File: "+strmid(dataset.filenames[0],0,14),/normal, alignment=0.0)
    title=text(0.9,0.95, "Number of Files: "+string(nfiles) ,/normal, alignment=1.0)
    title=text(0.05, 0.5, "TESTING", color='Red', font_size=40, alignment=0.0, /normal) 
  endif else begin
    p_q=image(q, layout=[3,2,1], title="Stokes Q", rgb_table=1, max_value=q_max, min_value=q_min, /buffer)
  endelse
  
  p_u=image(u, layout=[3,2,2], /current, title="Stokes U", rgb_table=1, max_value=q_max, min_value=q_min)
  p_p=image(sqrt(q^2+u^2),layout=[3,2,3], /current , title="Polarized Intensity", rgb_table=1, min_value=q_min, max_value=q_max)
  p_qr=image(qr, layout=[3,2,4], /current, title="Q_r", rgb_table=1, min_value=q_min, max_value=q_max)
  p_ur=image(ur, layout=[3,2,5], /current, title="U_r", rgb_table=1, min_value=q_min, max_value=q_max)
  p2=plot(pdiff_x, pdiff_hist, /stairstep, title="Vector offset from !C centrosymmetry", layout=[3,2,6], /current, rgb_table=1)
  title=text(0.05,0.95, "Target Name: "+backbone->get_keyword('OBJECT'), /normal, alignment=0.0)
  title=text(0.05,0.05, "Last Processed File: "+strmid(dataset.filenames[0],0,14) ,/normal, alignment=0.0)
  title=text(0.9,0.95, "Number of Files: "+string(nfiles) ,/normal, alignment=1.0)
  title=text(0.05, 0.5, "TESTING", color='Red', font_size=40, alignment=0.0, /normal)
 
  ;Save the image as a png!
  print, pngsave
  
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
    ;Where did this code come from? 
    if file_test(pngsave,/dir) then begin
      nm = gpi_expand_path(DataSet.filenames[numfile])
      strps = strpos(nm,path_sep(),/reverse_search)
      strpe = strpos(nm,'.fits',/reverse_search)
      nm = strmid(nm,strps+1,strpe-strps-1)
      nm = gpi_expand_path(pngsave+path_sep()+nm+'_stokesdc_pol_vectors.png')
    endif else nm = pngsave

    p_q.Save, nm
    print, "Quicklook image saved to ",nm
  endif

  @__end_primitive
end
