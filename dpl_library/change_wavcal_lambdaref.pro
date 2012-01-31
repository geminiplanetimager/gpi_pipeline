;+
; NAME: change_wavcal_lambdaref
; PIPELINE FUNCTION DESCRIPTION: change the wavcal datacube 
;    according to the new lambdaout
;
;
;
; KEYWORDS:
; OUTPUTS:
;
;
; HISTORY:
;   created: Jerome Maire 2009-06
;   2010-07-16 JM: added quadratic case
;   2012-01-31 JM: change for vertical orientation of IFS real spectra 
;+
function change_wavcal_lambdaref, wavcal, lambdaout

szw=size(wavcal)
wavcalout=dblarr(szw[1],szw[2],szw[3])
  for ii=0,szw[1]-1 do begin
  for jj=0,szw[2]-1 do begin
        if szw[3] eq 5 then  begin
          d2=(lambdaout-wavcal[ii,jj,2])/wavcal[ii,jj,3]  ; linear relation of dispersion
          wavcalout[ii,jj,0]=-d2*cos(wavcal[ii,jj,4])+wavcal[ii,jj,0]
          wavcalout[ii,jj,1]=d2*sin(wavcal[ii,jj,4])+wavcal[ii,jj,1]
          endif
        if szw[3] eq 7 then  begin
          d2=wavcal[ii,jj,3]+wavcal[ii,jj,4]*(lambdaout) + wavcal[ii,jj,5]*((lambdaout)^2.) ; quadratic relation of dispersion
          wavcalout[ii,jj,0]=-d2*cos(wavcal[ii,jj,6])+wavcal[ii,jj,0]
          wavcalout[ii,jj,1]=d2*sin(wavcal[ii,jj,6])+wavcal[ii,jj,1] 
          endif                  
  endfor
  endfor  
          wavcalout[*,*,2]=lambdaout
          wavcalout[*,*,3]=wavcal[*,*,3]
          wavcalout[*,*,4]=wavcal[*,*,4]
          if szw[3] eq 7 then  begin
            wavcalout[*,*,5]=wavcal[*,*,5]
            wavcalout[*,*,6]=wavcal[*,*,6]
          endif
 return, wavcalout 
end