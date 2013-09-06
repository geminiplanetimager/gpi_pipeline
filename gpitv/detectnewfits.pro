function detectnewfits, dir, listfile,list_id,button_value

chang=0

if where(strcmp(button_value,'Search most-recent fits files')) eq -1 then begin

ii=n_elements(dir)

nn=0
for i=0,ii-1 do begin ;find nb files to consider in order
	folder=dir(i)  ;to create the fitsfileslist array
	filetypes = '*.{fts,fits}'
    string3 = folder + path_sep() + filetypes
    fitsfiles =FILE_SEARCH(string3,/FOLD_CASE)
    nn=nn+(n_elements(fitsfiles))
endfor
fitsfileslist =STRARR(nn)

n=0	;list of files in fitsfileslist
for i=0,ii-1 do begin
	folder=dir(i)
	filetypes = '*.{fts,fits}'
    string3 = folder + path_sep() + filetypes
    fitsfiles =FILE_SEARCH(string3,/FOLD_CASE)
    fitsfileslist(n:n+n_elements(fitsfiles)-1) =fitsfiles
    n=n+ n_elements(fitsfiles)
endfor

; retrieve creation date
	date=dblarr(n_elements(fitsfileslist))
    for j=0,n_elements(date)-1 do begin
    Result = FILE_INFO(fitsfileslist(j) )
    date(j)=Result.ctime
    endfor
;sort files with creation date
    list2=fitsfileslist(REVERSE(sort(date)))
    list3=list2(0:n_elements(list2)-1)

;; old file list
dateold=dblarr(n_elements(listfile))
    for j=0,n_elements(listfile)-1 do begin
    Result = FILE_INFO(fitsfileslist(j) )
    dateold(j)=Result.ctime
    endfor

;;compare old and new file list
if (max(date) gt max(dateold)) || (n_elements(date) gt n_elements(dateold)) then begin
	chang=1
	listfile=list3
endif
wait,1
endif

return, chang
end