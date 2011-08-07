;+
; NAME: gpi_medfits
;     Median datacubes
;
;
; INPUTS: data-cube
; common needed:
;
; KEYWORDS:
; OUTPUTS:
;  INPUTS:

; EXAMPLE: 
;  
; HISTORY:
;    Jerome Maire :- 2008-08
;    JM: 2009-04 adapted for GPI-pip
;    2009-06-22 JM: fix a bug with fxread ->fxread3d 

function gpi_medfits,fnames,dim1,dim2,rns=rns,nlist=nlist,dir=dir,gz=gz,$
                 exten_no=exten_no,silent=silent,nzero=nzero,hdr=h,even=even,lam=lam

;Calcule et retourne l'image mediane de plusieurs fichiers fits.
;
;prefix: prefixe des noms de fichiers
;tlist: liste des numeros de fichiers, scalaire de type string
;       format '1-10,12,15-18'
;suffix=suffix: suffixe des noms de fichier, i.e., entre le "####" et
;               le ".fits"
;rns=rns: "Read'N Skip", integer array de dimension 2.
;         De la liste indiquee par tlist, lit sequentiellement rns[0]
;         fichiers et saute rns[1] fichiers
;nlist=array des numeros de fichiers sur lesquels faire la mediane
;      peut remplacer tlist
;dir=repertoire
;/gz: pour fichiers compresses avec gzip
;exten_no=exten_no: extension fits a lire
;nzero=nzero: nombre de chiffres dans le compteur numerique de fichiers
;/silent: pas d'affichage

nfiles=n_elements(fnames)
if ~keyword_set(lam) then lam=0

if dim1*dim2*nfiles gt 5.e7 then split=1 else split=0
;if keyword_set(exten_no) then split=0

;get all slice in one cube ;On charge tout dans un seul cube
if split eq 0 then begin
    if ~keyword_set(silent) then print,'Mediane directe du cube de ('+$
      strtrim(dim1,2)+'x'+strtrim(dim2,2)+'x'+strtrim(nfiles,2)+')'
    cube=fltarr(dim1,dim2,nfiles,/nozero)
    if (keyword_set(lam)) && (lam eq -1) then begin
      for n=0,nfiles-1 do cube[*,*,n]=readfits(fnames[n],exten_no=exten_no,/silent)
    endif else begin
      for n=0,nfiles-1 do cube[*,*,n]=readfits(fnames[n],NSLICE=lam,exten_no=exten_no,/silent)
    endelse
    if nfiles eq 1 then return,cube[*,*,0]
    return,median(cube,dimension=3,even=even)
endif

;if too many images for memory, consider several slices ;On fait plusieurs tranches

;output image  ;image qui contiendra l'image de sortie
out = fltarr(dim1,dim2)

;how many slice to have slice with less than 5.e7 pixels ;determine pas pour que les tranches ne contienne pas plus de 5.e7 pixels
;pas=pas sur la deuxieme dimension
pas=ceil(dim2/(dim1*dim2*nfiles/5.e7))
nslice=ceil(float(dim2)/pas)

if ~keyword_set(silent) then print,'Proceed '+strtrim(nslice,2)+' slices in datacube of size ('+$
  strtrim(dim1,2)+'x'+strtrim(dim2,2)+'x'+strtrim(nfiles,2)+')'
t = systime(1)

time=dblarr(nslice)
tmp = fltarr(dim1,pas,nfiles)
for n=0,nslice-1 do begin
    time[n]=systime(1)
    debut = n*pas ;position of the beginning of the Nth slice ;on calcule la position du début de la Nieme tranche
    fin = (n+1)*pas-1 ;position of the end of the Nth slice ;on calcule la position de la fin de la Nieme tranche

    ;if ~silent, display the # of the current slice; si ~silent, affiche a quelle tranche on en est rendu
    if ~keyword_set(silent) then print,'slice '+strtrim(n+1,2)+'/'+strtrim(nslice,2)+'-> ('+$
      strtrim(dim1,2)+'x'+strtrim(fin-debut+1,2)+'x'+strtrim(nfiles,2)+') ... '+strtrim(systime(1)-time[0],2)+' s'+$
      ' (time left: '+strtrim( (systime(1)-time[(n-5)>0])/(5<n)*(nslice-n) ,2)+' s)'

    if n eq (nslice-1) then begin
        fin = dim2-1
        tmp=fltarr(dim1,fin-debut+1,nfiles)
    endif

    for i = 0,nfiles-1 do begin
        fxread3d,fnames[i],data,hdr,-1,-1,debut,fin, nslice=lam, exten=exten_no
        tmp[*,*,i] = data[*,*]
    endfor

    out[*,debut:fin] = median(tmp,dimension=3,even=even)
endfor
print,'median calc. time: '+strtrim((systime(1)-time[0]),2)+' s'

return,out
end
