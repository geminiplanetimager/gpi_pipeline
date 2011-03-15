;+
; NAME: gpi_correct_distortion
; PIPELINE PRIMITIVE DESCRIPTION: Correct GPI distortion
;
;
; INPUTS: data-cube
;
;
; KEYWORDS:
;	
;
; OUTPUTS:  
;
; PIPELINE COMMENT: Correct GPI distortion
; PIPELINE ARGUMENT: Name="Save" Type="int" Range="[0,1]" Default="1" Desc="1: save output on disk, 0: don't save"
; PIPELINE ARGUMENT: Name="CalibrationFile" Type="distorcal" Default="GPI-distorcal.fits" Desc="Filename of the desired distortion calibration file to be read"
; PIPELINE ARGUMENT: Name="gpitv" Type="int" Range="[0,500]" Default="10" Desc="1-500: choose gpitv session for displaying output, 0: no display "
; PIPELINE ORDER: 2.44
; PIPELINE TYPE: ALL-SPEC
; PIPELINE SEQUENCE: 
;
; HISTORY:
; 	Originally by Jerome Maire 2009-12
;- 

function gpi_correct_distortion, DataSet, Modules, Backbone
primitive_version= '$Id: gpi_correct_distortion.pro 78 2011-01-06 18:58:45Z maire $' ; get version from subversion to store in header history

calfiletype='distor' 
@__start_primitive

  cubef3D=*(dataset.currframe[0])

nlens=(size(cubef3D))[1]
xx=findgen(nlens)#replicate(1L,nlens)
yy=replicate(1L,nlens)#findgen(nlens)

    pmd_fluxcalFrame        = ptr_new(READFITS(c_File, Headercal, /SILENT))
    parms=*pmd_fluxcalFrame
    
    parmsx=parms[0,*]
    parmsy=parms[1,*]
    
;distormodely=rotate(transpose(mydistor4(XX,YY,parmsx)),2)
;distormodelx=rotate(transpose(mydistor4(XX,YY,parmsy)),2)
distormodelx=mydistor4(XX,YY,parmsx)
distormodely=mydistor4(XX,YY,parmsy)
cubef3D2=cubef3D
cubef3D3=cubef3D


cubef3D_corrected=cubef3D
nwav=(size(cubef3D))[3]
for ii=0, nwav-1 do cubef3D2[*,*,ii]=rotate(transpose(cubef3D[*,*,ii]),2)

;for ii=0, nwav-1 do cubef3D_corrected[*,*,ii]= interpolate(cubef3D2[*,*,ii],distormodelx,distormodely)
;for ii=0, nwav-1 do cubef3D_corrected[*,*,ii]= interpolate(cubef3D2[*,*,ii],xx+distormodelx,yy+distormodely)
for hh=0,nwav-1 do cubef3D_corrected[*,*,hh,0] = warp_tri(xx+(distormodelx),yy+(distormodely),xx,yy,cubef3D2[*,*,hh,0]) ;,/quintic

for ii=0, nwav-1 do cubef3D3[*,*,ii]=rotate(transpose(cubef3D_corrected[*,*,ii]),2)
;stop

*(dataset.currframe[0])=cubef3D3

suffix+='-distor'

@__end_primitive

end
