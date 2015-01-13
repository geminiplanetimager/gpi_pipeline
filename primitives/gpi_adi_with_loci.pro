;+
; NAME: gpi_adi_with_loci
; PIPELINE PRIMITIVE DESCRIPTION: ADI with LOCI
; 		ADI algorithm based on Lafreniere et al. 2007.
;
;
; Code currently only offers the use of positive and negative coefficients.
;
;
; INPUTS: data-cube 
;
; KEYWORDS:
; GEM/GPI KEYWORDS:COADDS,CRFOLLOW,DEC,EXPTIME,HA,PAR_ANG
; DRP KEYWORDS: HISTORY,PSFCENTX,PSFCENTY
;
;
; PIPELINE COMMENT: Implements the LOCI ADI algorithm (Lafreniere et al. 2007)
; PIPELINE ARGUMENT: Name="nfwhm" Type="float" Range="[0,20]" Default="1.5" Desc="number of FWHM to calculate the minimal distance for reference calculation"
; PIPELINE ARGUMENT: Name="coeff_type" Type="int" Range="[0,1]" Default="0" Desc="0: positive and negative 1: positive only Coefficients in LOCI algorithm"
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 4.11
; PIPELINE CATEGORY: SpectralScience
;
; HISTORY:
; 	 Jerome Maire :- multiwavelength 2008-08
;   JM: adapted for GPI-pip
;   2009-09-17 JM: added DRF parameters
;   2010-04-26 JM: verify how many spectral channels to process and adapt LOCI for that, 
;                so we can use LOCI on collapsed datacubes or SDI outputs
;   2013-07-17 MP: Rename for consistency
;   2013-08-07 ds: idl2 compiler compatible, added start_primitive
;-

function gpi_adi_with_loci, DataSet, Modules, Backbone

primitive_version= '$Id$' ; get version from subversion to store in header history
@__start_primitive

if tag_exist( Modules[thisModuleIndex], "coeff_type") eq 1 then coeff_type=long(Modules[thisModuleIndex].coeff_type) else coeff_type=0

;;if all images have been processed into datacubes then start ADI processing...
if numfile  eq ((dataset.validframecount)-1) then begin

  nfiles=dataset.validframecount

  ;;get PA angles of images for final ADI processing
  paall=dblarr(dataset.validframecount)
  haall=dblarr(dataset.validframecount)
  for n=0,dataset.validframecount-1 do begin
    ;header=*(dataset.headers[n])
    haall[n]=double(ten_string(backbone->get_keyword('HA', indexFrame=n)))
    paall[n]=double(backbone->get_keyword('AVPARANG', indexFrame=n ,count=ct))
    ;Now using AVPARANG instead of PAR_ANG
    lat = ten_string('-30 14 26.700') ; Gemini South
    dec=double(backbone->get_keyword('DEC'))
    if ct eq 0 then paall[n]=parangle(haall[n],dec,lat)
  endfor
  
 ; paall=paall[1:n_elements(paall)-1] ;remove the first unused element;
  dtmean=mean((abs(paall-shift(paall,-1)))[0:nfiles-2])*!dtor ;calculate the PA distance between acquisitions
  
  ;;get some parameters of datacubes, could have been already defined before; ToDo:check if already defined and remove this piece of code..
  dimcub=(size(*(dataset.currframe[0])))[1]  ;
  xc=dimcub/2 & yc=dimcub/2
   filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
        ;get the common wavelength vector
            ;error handle if extractcube not used before
    if (strlen(filter) eq 0)  then $
        return, error('FAILURE ('+functionName+'): Datacube or filter not defined. Use extractcube module before.')        
    cwv=get_cwv(filter)
    CommonWavVect=cwv.CommonWavVect
    lambda=cwv.lambda
    lambdamin=CommonWavVect[0]
    lambdamax=CommonWavVect[1]
 


  subsuffix='-loci'

  listfilenames=strarr(nfiles)
  for i=0, nfiles-1 do listfilenames[i]=dataset.filenames[i]

  tmp=dataset.outputFileNames[0]
  tmpdir=gpi_expand_path(Modules[thisModuleIndex].OutputDir+path_sep())  ;strmid(tmp,0,strpos(tmp,path_sep(), /REVERSE_SEARCH)+1)

  nlist=strarr(nfiles)


  prefix=strmid(tmp,strpos(tmp,path_sep(), /REVERSE_SEARCH)+1,strpos(tmp,'_', /REVERSE_SEARCH)-strpos(tmp,path_sep(), /REVERSE_SEARCH))

  for ii=0,nfiles-1 do begin
	  tmp=dataset.outputFileNames[ii]
    num=strpos(tmp,prefix)+STRLEN(prefix)
    nlist[ii]=double(strmid(tmp,num,2))
  endfor
  nlist=indgen(nfiles)
  fnames=dataset.outputFileNames[0:nfiles-1];listfilenames  ;tmpdir+nbr2txt(nlist,4)+suffix+'.fits' ;+ext

  ;rayon minimum a considerer 
  rmin=0
  rmax=dimcub/2

  drsub0=5.
  na=200.
  geom=1.

  ;calculation of radius
  if n_elements(drsub0 eq 1) then begin
    nrsub=ceil((rmax-rmin)/drsub0)
    rsub=findgen(nrsub)*drsub0+rmin
    drsub=replicate(drsub0,nrsub)
  endif else begin
    nrsub=0
    r=rmin
    rsub=dblarr(1000)
    drsub=dblarr(1000)
    while r lt rmax do begin
        dr=((0.5+atan((r-drsub0[2])/drsub0[3])/!pi)*(drsub0[1]-drsub0[0])+drsub0[0])
        rsub[nrsub]=r
        drsub[nrsub]=dr
        r+=dr
        nrsub+=1
    endwhile
    rsub=rsub[0:nrsub-1] & drsub=drsub[0:nrsub-1]
  endelse
  drsub=drsub<(rmax-rsub)


  ;array des distances
  distarray=shift(dist(dimcub),dimcub/2,dimcub/2)
  ;array des angles
  ang=(angarr(dimcub)+2.*!pi) mod (2.*!pi)

      
        
      
      ;we want ADI for datacubes, i.e. several specral channels but also for 
      ;other type of data: collapsed datacubes, single spectral channel ADI, ADI after SDI,etc...
      ; so we have to verify the dimension of ADI inputs hereafter:
      imtemp=accumulate_getimage( dataset, 0)
      szinput=size(imtemp)
      if (szinput[0] eq 2) then lambda=(lambdamax+lambdamax)/2.
  
;      if (szinput[0] eq 2) then im=dblarr(szinput[1], szinput[2]) $
;                            else im=dblarr(szinput[1], szinput[2], szinput[3])



  for il=0, n_elements(lambda)-1 do begin
    print,'LOCI Wavelength '+strtrim(il+1,2)+'/'+strtrim(n_elements(lambda),2)
    nfwhm=float(Modules[thisModuleIndex].nfwhm) ;get the user-defined minimal distance for the subtraction
    Dtel=gpi_get_constant('primary_diam',default=7.7701d0)
    fwhm=0.98*(1.e-6*lambda[il]/Dtel)*(180.*3600./!dpi)/0.014

    ;estimate the largest optimisation radius needed
    rimmax=0.
    for ir=0,nrsub-1 do begin
      r=rsub[ir]
      if n_elements(na) eq 1 then area=na*!pi*(fwhm/2.)^2 $
      else area=((0.5+atan((r-na[2])/na[3])/!pi)*(na[1]-na[0])+na[0])*!pi*(fwhm/2.)^2
      ;largeur de l'anneau d'optimisation desiree
      dropt=sqrt(geom*area)
      nt=round((2*!pi*(r+dropt/2.)*dropt)/area)>1
      dropt=sqrt(r^2+(nt*area)/!pi)-r
      rimmax>=r+dropt
    endfor
    rimmax<=1.2*dimcub/2

    ;cut images with annuli 5pixels width; decoupe en anneaux de 5 pixels de large
    ;and save annuli with same radius for all images in a file; et sauvegarde les anneaux de meme rayon pour toutes les images ds un fichier
    drim=5.
    nrim=ceil((rimmax-rmin)/drim)
    rim=findgen(nrim)*drim+rmin

    ;get indices of pixels included in each annulus ;determine les indices des pixels inclus dans chaque anneau
    ;with drim pixels and save on disk ; de drim pixels et les sauve sur disque
    for ir=0,nrim-1 do begin
      ri=rim[ir] & rf=ri+drim
      ia=where(distarray lt rf and distarray ge ri)
      openw,funit,tmpdir+'indices_a'+nbr2txt(ir,3)+'.dat',/get_lun
      writeu,funit,ia
      free_lun,funit
    endfor


    ;cut images with annuli and place nfiles annuli with same radius in the same file 
    ;decoupe les images en anneaux et place les nfiles anneaux de meme rayon dans un meme fichier
    el=dblarr(nfiles) & az=dblarr(nfiles)
    dec=dblarr(nfiles) & decdeg=dblarr(nfiles)
    dtpose=dblarr(nfiles)
    noise_im=dblarr(nrim,nfiles)
    for n=0,n_elements(listfilenames)-1 do begin
      exptime=double(backbone->get_keyword('ITIME', indexFrame=n,/silent))
      coadds=double(backbone->get_keyword('COADDS', indexFrame=n))
      ;exptime=double(SXPAR( header, 'EXPTIME'))
      ;coadds=double(SXPAR( header, 'COADDS'))
      fn=listfilenames[n]
      ;fn=Modules[0].OutputDir+path_sep()+strmid(fn,1+strpos(fn,path_sep(),/REVERSE_SEARCH ),STRPOS(fn,'.fits')-strpos(fn,path_sep(),/REVERSE_SEARCH )-1)+suffix+'.fits'
      ;im=readfits(fn,header,NSLICE=il,/silent)
      if (size(lambda))[0] eq 0 then im=(accumulate_getimage( dataset, n)) $
                                else im=(accumulate_getimage( dataset, n))[*,*,il]
      
      
      norma=0
      if norma then begin
        ;++normalize the image with the noise radial profile ;normalise l'image par son profil radial de bruit
        profrad,abs(im),2.,p2d=pr
        im/=pr
        writefits,tmpdir+'noise_'+nbr2txt(nlist[n],4)+'.fits',pr,/compress
      endif

      for ir=0,nrim-1 do begin
        ia=read_binary(tmpdir+'indices_a'+nbr2txt(ir,3)+'.dat',data_type=3)
        if ia[0] eq -1 then continue
        openw,funit,tmpdir+'values_a'+nbr2txt(ir,3)+'.dat',/get_lun,append=(n gt 0)
        writeu,funit,im[ia]
        free_lun,funit
        ;calculate noise in this annulus ;calcule le bruit dans cet anneau
        noise_im[ir,n]=median(abs(im[ia]-median(im[ia])))/0.6745
    	endfor

      dec[n]=double(backbone->get_keyword('DEC'))*!dtor
      
      decdeg[n]=dec[n]*!radeg
      dtpose[n]=abs(rot_rate2(haall[n],decdeg[n],ten_string('-30 14 26.700')))*exptime*coadds*!radeg
    endfor

	  ;CRPA	Current Cass Rotator Position Angle
    ;CRFOLLOW	Cass Rotator follow mode (yes/no)
    
    cassrotonoff=(backbone->get_keyword('CRFOLLOW')) ;SXPAR( header, 'CRFOLLOW')
		if ~STRMATCH(cassrotonoff,'yes',/fold) && ~STRMATCH(cassrotonoff,'0') && ~STRMATCH(cassrotonoff,'') && ~STRMATCH(cassrotonoff,'') then begin

			;get keyword parallax, etc..
			;HA	Telescope hour angle
;			hourangle=double(backbone->get_keyword('HA', indexFrame=n)) ; SXPAR( header, 'HA')
;			decl=double(backbone->get_keyword('DEC')) ;SXPAR( header, 'DEC')
;			GS=1
;			if GS then begin
;				OLo = '-70 44 12.096'
;				OLa = '-30 14 26.700'
;			endif else begin
;			;OLo = '-155 28 06.616'
;			;OLa = '19 49 25.7016'
;			endelse

;		  lat = ten_string(OLa)
      ;ww=rot_rate2(hourangle,decl,lat)

		    ;PA=double(SXPAR( header, 'PAR_ANG'))
;		   PA=paall[n] ;double(backbone->get_keyword('PAR_ANG', count=ct))
;       lat = ten_string('-30 14 26.700') ; Gemini South
;       dec=double(backbone->get_keyword('DEC'))
;       if ct eq 0 then PA=parangle(haall[n],dec,lat)
    
      ;if n eq 0 then painit=PA
      ;	ww=PA-painit

      ;MAIN LOOP
      ;loop on all annuli, calculate ref. annulus, subtract.. ; loop sur tous les anneaux, determine anneau ref, soustrait
      iaim_loaded=-1
      for ir=0,nrsub-1 do begin
        ri=rsub[ir] & dr=drsub[ir] & r=ri+dr/2. & rf=ri+dr
        print,'LOCI Wavelength '+strtrim(il+1,2)+'/'+strtrim(n_elements(lambda),2),' Annulus '+strtrim(ir+1,2)+'/'+strtrim(nrsub,2)+' with radius '+$
        string(r,format='(f5.1)')+$
        ' [>='+string(ri,format='(f5.1)')+', <'+string(rf,format='(f5.1)')+']...'

        ;area of the region at this radius; aire de region a ce rayon
        if n_elements(na) eq 1 then area=na*!pi*(fwhm/2.)^2 $
        else area=((0.5+atan((r-na[2])/na[3])/!pi)*(na[1]-na[0])+na[0])*!pi*(fwhm/2.)^2

        ;width of the optimisation annulus chosen ;largeur de l'anneau d'optimisation desiree
        dropt=sqrt(geom*area)

        if dropt lt dr then begin
          print,'dropt < drsub !!!'
          print,'dropt: ',dropt
          print,'drsub: ',dr
          stop
        endif

        ;***get the optimisation region for this annulus to subtract***
        ;***determine la region d'optimisation pour cet anneau a soustraire***
        ; for the subtracted region at the beginning of reg_optimisation
        ;pour region soustraite au debut de reg_optimisation
        if 1 then begin
          r1opt=ri
          ;number of annulus section ;nombre de section d'anneau
          nt=round((2*!pi*(r1opt+dropt/2.)*dropt)/area)>1

          ;dropt for annuli with nt sections of exact area ;dropt pour anneaux avec nt sections d'aire exacte
          dropt=sqrt(r1opt^2+(nt*area)/!pi)-r1opt
          r2opt=r1opt+dropt

          if r2opt gt rim[nrim-1]+drim then begin
            r2opt=rim[nrim-1]+drim
            dropt=r2opt-r1opt
            nt=round((2*!pi*(r1opt+dropt/2.)*dropt)/area)>1
          endif
        endif
        ;for subtracted region at the center of reg_optimisation ;pour region soustraite au centre de reg_optimisation
        if 0 then begin
          ;number of annulus section ;nombre de section d'anneau
          nt=round((2*!pi*r*dropt)/area)>1

          ;for optimisation annulus centered on r ;pour anneau d'optimisation centre sur r
          ;dr_opt for sections with exact area ;dr_opt pour sections avec aire exacte
          dropt=(area*nt)/(2.*!pi*r)
          r1opt=r-dropt/2.
          r2opt=r+dropt/2.

          if r1opt lt rmin then begin
            r1opt=rmin
            dropt=sqrt(geom*area)
            nt=round((2*!pi*(r1opt+dropt/2.)*dropt)/area)>1
            r2opt=sqrt((area*nt)/!pi+r1opt^2)
            dropt=r2opt-r1opt
          endif
          if r2opt gt rim[nrim-1]+drim then begin
            r2opt=rim[nrim-1]+drim
            dropt=sqrt(geom*area)
            nt=round((2*!pi*(r2opt-dropt/2.)*dropt)/area)>1
            r1opt=sqrt(r2opt^2-(area*nt)/!pi)
            dropt=r2opt-r1opt
          endif
        endif

        ;find annuli of image to load on memory ;determine quels anneaux d'image a charger en memoire
        i1aim=floor((r1opt-rmin)/drim)
        i2aim=floor((r2opt-rmin)/drim)
        if i2aim eq nrim then i2aim-=1
        if rim[i2aim] eq r2opt then i2aim-=1
        iaim=indgen(i2aim-i1aim+1)+i1aim

        ;remove annuli not needed; enleve les anneaux qui ne sont plus necessaire
        if ir gt 0 then begin
          irm=where(distarray[ia] lt rim[i1aim] or distarray[ia] ge rim[i2aim]+drim,crm,complement=ikp)
          if crm gt 0 then remove,irm,ia
          if crm gt 0 then annuli=annuli[ikp,*]
        endif

        ;load missing annuli ;charge les anneaux qui manquent
        iaim_2load=intersect(iaim,intersect(iaim,iaim_loaded,/xor_flag),c2load)
        for k=0,c2load-1 do begin
          ia_tmp=read_binary(tmpdir+'indices_a'+nbr2txt(iaim_2load[k],3)+'.dat',data_type=3)
          annuli_tmp=read_binary(tmpdir+'values_a'+nbr2txt(iaim_2load[k],3)+'.dat',data_type=4)
          annuli_tmp=reform(annuli_tmp,n_elements(ia_tmp),nfiles)
          if ir+k eq 0 then ia=ia_tmp else ia=[ia,ia_tmp]
          if ir+k eq 0 then annuli=annuli_tmp else annuli=[annuli,annuli_tmp]
        endfor


        ia_tmp=0 & annuli_tmp=0
        ;keep in memory the list of loaded annuli ;garde en memoire la liste des anneaux charges
        iaim_loaded=iaim
        ;indices of pixels in the optimisation annulus ;indice des pixels dans l'anneau d'optimisation
        iaopt=where(distarray[ia] ge r1opt and distarray[ia] lt r2opt)

        ;angle of annulus section ;angle des sections d'anneau
        dt=2.*!pi/nt

        ;loop on angular section ;loop sur les sections angulaires
        for it=0,nt-1 do begin
          ;indices of pixels included in this section (optimisation region) ;indices des pixels inclus dans cette section, i.e. la region d'optimisation
          iopt=where(ang[ia[iaopt]] ge it*dt and ang[ia[iaopt]] lt (it+1)*dt)
          npix=n_elements(iopt)
          if npix lt 25 then continue
          iopt=iaopt[iopt]

          ;load optimization region in memory ;charge les regions d'optimization en memoire
          optreg=annuli[iopt,*]

          ;indices of pixels to subtract ;indices des pixels a soustraire
          isub=where(distarray[ia[iopt]] ge ri and distarray[ia[iopt]] lt rf)
          if n_elements(isub) lt 5 then continue
          isub=iopt[isub]

          ;remove from optimisation region pixels with Nan or deviant points ;enleve de region opt les pixels ou il y a un NAN ou point tres deviant dans au moins un anneau
          z=finite(optreg)
          z<=(abs(optreg/noise_im[floor((distarray[ia[iopt]]-rim[0])/drim)#replicate(1,90)]) lt 15.)
          ;for a given pixel [i,*], look for deviant points ; pour un pixel donne [i,*], regarde si dans une image ce pixel est deviant
          igood=where(min(z,dim=2),cgood)
          if cgood lt 15 then continue
          optreg=optreg[igood,*]
          iopt=iopt[igood]

          ;note indices to subtract for image reconstruction ;on note les indices a soustraire pour construire les images ulterieurement
          openw,lunit,tmpdir+'indices_images.dat',/get_lun,append=(ir+it gt 0)
          writeu,lunit,ia[isub]
          free_lun,lunit

          ;construct matrix of the linear system to resolve ;construit grosse matrice du systeme lineaire a resoudre
          aa=optreg##transpose(optreg)

          ;loop on all images and subtract..;loop sur toutes les images et fait les diff
          for n=0,nfiles-1 do begin
            ;angular separation of all images with respect of the image #n ;separation angulaire de toutes les images par rapport a image n
            dpa=abs(paall-paall[n])

            ;check if images are sufficiently shifted ;determine images suffisament decalees pour la soustraction
            indim=where(dpa gt (nfwhm*fwhm/ri*!radeg+dtpose[n]),c1)
            igood=where(finite(annuli[isub,n]) eq 1,c2)
            if c1 eq 0 or c2 lt 5 then begin
                diff=dblarr(n_elements(isub))+!values.f_nan
            endif else begin
                ;matrix of the linear system to resolve ;matrice du systeme lineaire a resoudre
                a=(aa[indim,*])[*,indim]
                ;vector b of the linear system to resolve ;vecteur b du systeme lineaire a resoudre
                b=aa[indim,n]
							if coeff_type eq 0 then begin
              ;----------------------------
              ;POSITIVE/NEGATIVE COEFFICIENTS
                ;resolve the system ;resoud le systeme
                if n_elements(a) ne 1 then $
                c=invert(a,/double)#b else $
                c=0.
              ;----------------------------
							endif else begin
							;	return, error('FAILURE ('+functionName+'): Could not use only positive coefficients, code not yet implemented. Set use_pos_neg_coeff_flag equal to 1') 
              ;----------------------------
              ;POSITIVE COEFFICIENTS
              svect=size(a)
              dim=svect[1]
              dim2=dim
              c=fltarr(dim)
              if n_elements(a) ne 1 then begin
               indx=fltarr(dim+1)
               w=fltarr(dim)
               mode=1
               rnorm=1
               nnls,a,dim,dim2,b,c,rnorm,w,indx,mode
              endif
              ;----------------------------
							endelse

                ;construct the reference ;construit la reference
                ref=dblarr(n_elements(isub))
                for k=0,c1-1 do ref[igood]+=c[k]*annuli[isub[igood],indim[k]]

                ;subtract ;fait la difference
                diff=annuli[isub,n]-ref
                diff-=median(diff,/even)
            endelse
           ; stop
            ;save the difference on disk, append values of this annulus into the file of this image
            ;enregistre la difference sur disque, ajoute (append) les valeurs de cet
            ;anneau au fichier binaire de cette image
            openw,lunit,tmpdir+prefix+nbr2txt(nlist[n],4)+'_tmp.dat',/get_lun,append=(ir+it gt 0)
            writeu,lunit,float(diff)
            free_lun,lunit
          endfor;fic
      endfor;section
    endfor;ann

    ;delete .dat files of annuli ;efface les fichiers .dat des anneaux
    file_delete,file_search(tmpdir,'indices_a*.dat')
    file_delete,file_search(tmpdir,'values_a*.dat')


    ;read indices of subtracted pixels ;lecture des indices des pixels soustraits
    ind=read_binary(tmpdir+'indices_images.dat',data_type=3)
    ;delete the temp. file of indices ;efface le fichier temporaire d'indices
    file_delete,tmpdir+'indices_images.dat'

    ;reconstruc and rotate images ;reconstruit et tourne les images
    for n=0,nfiles-1 do begin
      print,'Image '+strtrim(n+1,2)+'/'+strtrim(nfiles,2)+': '+fnames[n]+'...'
      ;reconstruct image ;reconstruit l'image
      print,' reconstruction...'

      im=make_array(dimcub,dimcub,type=4,value=!values.f_nan)
      im[ind]=read_binary(tmpdir+prefix+nbr2txt(nlist[n],4)+'_tmp.dat',data_type=4)
      
      ;delete temp. file ; efface le fichier temporaire
      file_delete,tmpdir+prefix+nbr2txt(nlist[n],4)+'_tmp.dat'

      if norma then begin
        ;++multiply by the noise radial profile ;multiplie par le profil radial de bruit
        pr=readfits(tmpdir+'noise_'+nbr2txt(nlist[n],4)+'.fits', /silent)
        im*=pr
        file_delete,tmpdir+'noise_'+nbr2txt(nlist[n],4)+'.fits'
      endif

      ;obtient le header
      fn=dataset.outputFileNames[n];listfilenames(n)
      ;fn=Modules[0].OutputDir+path_sep()+strmid(fn,1+strpos(fn,path_sep(),/REVERSE_SEARCH ),STRPOS(fn,'.fits')-strpos(fn,path_sep(),/REVERSE_SEARCH )-1)+suffix+'.fits'
      fits_info,fn,N_ext=n_ext, /silent
      h=headfits(fn,exten=n_ext, /silent)
      hphu=headfits(fn,exten=0, /silent)

      ;rotation pour ramener sur la premiere image
      print,' rotation...'
      theta=(paall[n]-paall[0])
      
      ;if n ne 0 then im=gpi_adi_rotat(im,theta,missing=!values.f_nan,hdr=h)
            x0=double(backbone->get_keyword('PSFCENTX',count=ccx,/silent)) ;float(SXPAR( *(dataset.headers[n]), 'PSFCENTX',count=ccx))
            y0=double(backbone->get_keyword('PSFCENTY',count=ccy,/silent)) ;float(SXPAR( *(dataset.headers[n]), 'PSFCENTY',count=ccy))
            if (ccx eq 0) || (ccy eq 0) || ~finite(x0) || ~finite(y0) then begin           
              if n ne 0 then im=gpi_adi_rotat(im,theta,missing=!values.f_nan,hdr=h) ;(do not rotate first image)
            endif else begin
              if n ne 0 then im=gpi_adi_rotat(im,theta,x0,y0,missing=!values.f_nan,hdr=h) ;(do not rotate first image)
            endelse  
            *(dataset.headersExt[n])=h
      ;save the difference ;enregistre la difference
      suffix1=suffix+'-loci'+strcompress(string(il),/REMOVE_ALL)
      fname=tmpdir+prefix+nbr2txt(nlist[n],4)+suffix1+'.fits'
      ;if il eq 0 then begin
;        sxaddparlarge,*(dataset.headersPHU[n]),'HISTORY',functionname+": LOCI done"
;        sxaddhist,'Une rotation de '+strc(theta,format='(f7.3)')+$
;        ' degres a ensuite ete appliquee.',h
          backbone->set_keyword,'HISTORY',functionname+": LOCI done",ext_num=0,indexFrame=n
          backbone->set_keyword,'HISTORY','ADI derotation '+strc(theta,format='(f7.2)')+$
        ' degrees applied.',ext_num=0,indexFrame=n
          backbone->set_keyword,'ADIROTAT',strc(theta,format='(f7.2)'),"Applied ADI FOV derotation [degrees]",ext_num=0,indexFrame=n
      ;endif

          mwrfits, 0, fname, *DataSet.HeadersPHU[n], /create, /silent
          hext=*DataSet.HeadersExt[n] & sxdelpar,hext,'NAXIS3'
          mwrfits, im, fname, hext, /silent
      ;writefits,fname,im,h,/compress
    endfor

    endif ;cass
   ; update_progressbar,Modules,thisModuleIndex,n_elements(lambda), il ,'working...',/adi    
  endfor; wav

; dirty suffix hack that is currently necessary since the suffix seems to get changed here for some reason...
  suffix0=suffix+'-loci'
  imt=dblarr(dimcub,dimcub,n_elements(lambda))
  for n=0,nfiles-1 do begin
    for il=0,n_elements(lambda)-1 do begin
      imt[*,*,il]=readfits(tmpdir+prefix+nbr2txt(nlist[n],4)+suffix0+strcompress(string(il),/REMOVE_ALL)+'.fits',/SILENT,exten=n_ext, header)
      file_delete, tmpdir+prefix+nbr2txt(nlist[n],4)+suffix0+strcompress(string(il),/REMOVE_ALL)+'.fits'
    endfor
suffix=suffix0 
      *(dataset.currframe[0])=imt
    ;  *(dataset.headers[n])=header
;    if ( Modules[thisModuleIndex].Save eq 1 ) then begin
;        numfile=n
;       b_Stat = save_currdata ( DataSet,  $
;                            Modules[thisModuleIndex].OutputDir, suffix,  display=fix(Modules[thisModuleIndex].gpitv) )
;       if ( b_Stat ne OK ) then $
;          return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
;    endif
thisModuleIndex = Backbone->GetCurrentModuleIndex()
    if tag_exist( Modules[thisModuleIndex], "Save") && ( Modules[thisModuleIndex].Save eq 1 ) then begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") then display=fix(Modules[thisModuleIndex].gpitv) else display=0 
      b_Stat = save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display=display,level2=n+1)
      if ( b_Stat ne OK ) then  return, error ('FAILURE ('+functionName+'): Failed to save dataset.')
    endif else begin
      if tag_exist( Modules[thisModuleIndex], "gpitv") && ( fix(Modules[thisModuleIndex].gpitv) ne 0 ) then $
          ;gpitvms, double(*DataSet.currFrame[0]), ses=fix(Modules[thisModuleIndex].gpitv),head=*(dataset.headers)[numfile]
          Backbone_comm->gpitv, double(*DataSet.currFrame), ses=fix(Modules[thisModuleIndex].gpitv)
    endelse

    
  ;writefits,tmpdir+prefix+nbr2txt(nlist[n],4)+suffix+'.fits',imt
  endfor
endif   ;;last image


return, ok
end
