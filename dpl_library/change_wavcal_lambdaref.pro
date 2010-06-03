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
;+
function change_wavcal_lambdaref, wavcal, lambdaout

szw=size(wavcal)
wavcalout=dblarr(szw[1],szw[2],szw[3])
  for ii=0,szw[1]-1 do begin
    for jj=0,szw[2]-1 do begin
        d2=(lambdaout-wavcal[ii,jj,2])/wavcal[ii,jj,3]
        wavcalout[ii,jj,0]=d2*cos(wavcal[ii,jj,4])+wavcal[ii,jj,0]
        wavcalout[ii,jj,1]=d2*sin(wavcal[ii,jj,4])+wavcal[ii,jj,1]
        wavcalout[ii,jj,2]=lambdaout
        wavcalout[ii,jj,3]=wavcal[ii,jj,3]
        wavcalout[ii,jj,4]=wavcal[ii,jj,4]
  endfor
  endfor      
 return, wavcalout 
end