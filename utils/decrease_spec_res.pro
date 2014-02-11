; Decrease spectral res
; by Jerome Maire

function decrease_spec_res, lambda, nphot,spotloc
common PIP
;repDST=getenv('GPI_IFS_DIR')+path_sep()+'dst'+path_sep()
repDST=gpi_get_directory('DST')
psfmlens = readfits(repDST+'ifu_microlens_psf'+strcompress(filter,/rem)+'.fits')
szpsf=size(psfmlens) & dimpsf=szpsf[1]

nlambda=n_elements(lambda)
  cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect        
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
nlambdapsf=37.
lambdapsf=fltarr(nlambdapsf)
  ;for i=0,n_elements(lambdapsf)-1 do lambdapsf[i]=lambda[0]+(lambda[nlambdapsf-1]-lambda[0])/(2.*nlambdapsf)+double(i)*(lambda[nlambdapsf-1]-lambda[0])/nlambdapsf
 for i=0,n_elements(lambdapsf)-1 do lambdapsf[i]=lambdamin+double(i)*(lambdamax-lambdamin)/(nlambdapsf-1.)


pas=5.
nbspot=(size(spotloc))[1]-1
print, 'nbspot=',nbspot
psfmlens2=fltarr(szpsf[1],szpsf[2],nlambdapsf)
dx2L=fltarr(nbspot,nlambdapsf)
dy2L=fltarr(nbspot,nlambdapsf)
spec=fltarr(nlambda,nbspot)
window,10

for i=0,nbspot-1 do begin
      for nla=0,nlambdapsf-1 do begin
        wavcalref=change_wavcal_lambdaref( wavcal, lambdapsf[nla])
        dx2L[i,nla]=(wavcalref)[spotloc[i+1,0],spotloc[i+1,1],0]
        dy2L[i,nla]=(wavcalref)[spotloc[i+1,0],spotloc[i+1,1],1]
        ; si all-zem, determination good psfmlens (subpixel shift; subpixel sampling=pas*pas for each wavel. )
        psflmens2_tmp=psfmlens(*,*,(nla*pas*pas+pas*( round( (dx2L(i,nla)-floor(dx2L(i,nla))) * pas) mod pas) + (round( (dy2L(i,nla)-floor(dy2L(i,nla))) * pas) mod pas))<924)
        ;shift spatial x-y (integer part) following the zem pos (no translate function, just coordinates game..)
        ;if (nla eq 18) && ((round( (dx2L(i,nla)-floor(dx2L(i,nla))) * pas) ne 2)|| (round( (dy2L(i,nla)-floor(dy2L(i,nla))) * pas) ne 2)) then print, round( (dx2L(i,nla)-floor(dx2L(i,nla))) * pas),round( (dy2L(i,nla)-floor(dy2L(i,nla))) * pas)
        ;stop

        ;if nla gt 0 then begin
          xshift=floor(dx2L(i,nla))-floor(dx2L(i,0))
          yshift=floor(dy2L(i,nla))-floor(dy2L(i,0))
        
        if (dx2L(i,nla)-floor(dx2L(i,nla))) ge 1.-0.5*(1./float(pas)) then xshift+=1
        if (dy2L(i,nla)-floor(dy2L(i,nla))) ge 1.-0.5*(1./float(pas)) then yshift+=1
        
          psfmlens2[0,0,nla]=SHIFT(psflmens2_tmp,xshift,yshift)
        ;endif else psfmlens2(0,0,nla) = psflmens2_tmp
        ;si
      endfor
      
      psfmlens4=reform(psfmlens2,szpsf[1]*szpsf[2],nlambdapsf)
      spectrum=reform(psfmlens4#reform(nphot),dimpsf,dimpsf)
      

      spect=(total(spectrum,2))[(dimpsf-1)/2:(dimpsf-1)/2+xshift]
      dx=findgen(xshift+1) + replicate(float(floor(reform(dx2L[i,0]))),xshift+1)
      lambint= INTERPOL( lambdapsf, reform(dx2L[i,*]), dx)
      spec[*,i] = (float(n_elements(lambint))/float(n_elements(lambda)))*INTERPOL( spect, lambint, lambda )
      if i eq 0 then plot, lambda, spec[*,i] else oplot, lambda, spec[*,i]
      
 endfor     
 if (size(spec))[0] eq 1 then specmean=spec else $
 specmean=(1./float(nbspot))*total(spec,2)
 oplot,lambda, specmean, linestyle=1
 return, specmean
 end
