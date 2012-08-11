;+
; NAME: testsatspotloc001
; PIPELINE PRIMITIVE DESCRIPTION: Test the satellite spot locations
;
; INPUTS: 
;
;
; KEYWORDS:
; 
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Test the satellite  spot locations
; PIPELINE ARGUMENT: Name="suffix" Type="string"  Default="-satspotloc" Desc="Enter suffix of figure name"
; PIPELINE ARGUMENT: Name="title" Type="string" Default="" Desc="Enter figure title"
; PIPELINE ORDER: 2.52
; PIPELINE TYPE: ALL-SPEC 
; PIPELINE SEQUENCE: 
;
; HISTORY:
;   Jerome Maire 2011-02-16
;- 

function testsatspotloc001, DataSet, Modules, Backbone
primitive_version= '$Id: testsatspotloc001.pro 11 2011-02-11 10:22:03 maire $' ; get version from subversion to store in header history
@__start_primitive
mydevice = !D.NAME
cubef3D=*(dataset.currframe[0])

   ; hdr= *(dataset.headers)[numfile]
    filter = gpi_simplify_keyword_value(backbone->get_keyword('IFSFILT', count=ct))
   ; if cc eq 0 then filter=SXPAR( hdr, 'IFSFILT',cc)
        ;get the common wavelength vector
            ;error handle if extractcube not used before
            if  (strlen(filter) eq 0)  then $
            return, error('FAILURE ('+functionName+'): filter not defined. Use extractcube module before.')        
        cwv=get_cwv(filter)
        CommonWavVect=cwv.CommonWavVect
        lambda=cwv.lambda
        lambdamin=CommonWavVect[0]
        lambdamax=CommonWavVect[1]
;SPOTWAVE=sxpar( *(dataset.headers[numfile]), 'SPOTWAVE',  COUNT=cc4)
SPOTWAVE=backbone->get_keyword('SPOTWAVE', count=cc4)
  
    spotloc=fltarr(5,2) ;1+ due for PSF center 
          spotloc[0,0]=backbone->get_keyword('PSFCENTX');sxpar( *(dataset.headers[numfile]),"PSFCENTX")
          spotloc[0,1]=backbone->get_keyword('PSFCENTY');sxpar( *(dataset.headers[numfile]),"PSFCENTY")      
        for ii=1,(size(spotloc))[1]-1 do begin
          spotloc[ii,0]=backbone->get_keyword("SPOT"+strc(ii)+'x') ;sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'x')
          spotloc[ii,1]=backbone->get_keyword("SPOT"+strc(ii)+'y') ;sxpar( *(dataset.headers[numfile]),"SPOT"+strc(ii)+'y')
        endfor  
        
maxaper=3.
centroidaper=2.  
deducedpos=fltarr(CommonWavVect[2],2,5)
distance=fltarr(CommonWavVect[2],5)
centroidspotloc=fltarr(CommonWavVect[2],2,5)
      for spot=1,4 do begin
        for i=0,CommonWavVect[2]-1 do begin
            ;;extrapolate sat -spot at a given wavelength
            pos2=calc_satloc(spotloc[spot,0],spotloc[spot,1],spotloc[0,*],SPOTWAVE,lambda[i])
            deducedpos[i,0,spot]=pos2[0]
            deducedpos[i,1,spot]=pos2[1]
            ;;measure centroids
            pos3=calc_centroid_spots( pos2[0],pos2[1],cubef3D[*,*,i], maxaper, centroidaper)
            centroidspotloc[i,0,spot]=pos3[0]
            centroidspotloc[i,1,spot]=pos3[1]
            ;;measure distance between extrapolated values and true centroids
            distance[i,spot]=sqrt((pos3[1]-pos2[1])^2.+(pos3[0]-pos2[0])^2.)
        endfor
      endfor  

thisLetter = "155B
greekLetter = '!9' + String(thisLetter) + '!X'
thisModuleIndex = Backbone->GetCurrentModuleIndex()
;figtitle=(Modules[thisModuleIndex].title)
openps,gpi_get_directory('GPI_REDUCED_DATA_DIR')+path_sep()+'test03_'+filter+'.ps', xsize=14, ysize=27 ;, ysize=10, xsize=15
  !P.MULTI = [0, 3, 4, 0, 0] 
for spot=1,4 do begin
  plot, lambda, deducedpos[*,0,spot],ytitle='X-Loc[mlens]', xtitle='Wavelength (' + greekLetter + 'm)',$
   xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0, charsize=1.,yrange=[min(deducedpos[*,0,spot]),max(deducedpos[*,0,spot])],title='Spot #'+strc(spot)+' '+filter+'-band'
   oplot,lambda, centroidspotloc[*,0,spot],linestyle=1
   legend,['Extrap. X-loc.','Centroids'],linestyle=[0,1], charsize=1.
   plot, lambda, deducedpos[*,1,spot],ytitle='Y-Loc[mlens]', xtitle='Wavelength (' + greekLetter + 'm)',$
   xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0, charsize=1.,yrange=[min(deducedpos[*,1,spot]),max(deducedpos[*,1,spot])],title='Spot #'+strc(spot)+' '+filter+'-band'
   oplot,lambda, centroidspotloc[*,1,spot],linestyle=1
   legend,['Extrap. Y-loc.','Centroids'],linestyle=[0,1], charsize=1.
  plot, lambda, distance[*,spot],ytitle='Dist.centroid-extrap.[mlens]', xtitle='Wavelength (' + greekLetter + 'm)',$
   xrange=[lambda[0],lambda[n_elements(lambda)-1]],linestyle=0, charsize=1. ,yrange=[min(distance[*,spot]),max(distance[*,spot])],title='Spot #'+strc(spot)+' '+filter+'-band'
  legend,['max. dist. [mlens]:'+strc(max(distance[*,spot]),format='(g5.2)')],linestyle=[0], charsize=1.
endfor
closeps
  SET_PLOT, mydevice ;set_plot,'win'

return, ok
 end
