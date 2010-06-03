;+
; Project     : HESSI
;                  
; Name        : FILE_NAME
;               
; Purpose     : new improved BREAK_FILE that uses STREGEX and no loops
;                             
; Category    : system utility string
;               
; Syntax      : IDL> name=file_break(file,[/name,/path,/ext,/drive])
;
; Inputs:     : FILE = file names (scalar or array) 
;
; Outputs     : Name part of file (default or if /name)
;
; Keywords    : /PATH = return path part of file 
;               /EXTENSION  = return extension part of file
;               /DRIVE = return drive part [Windows or VMS only]
;               /EXPAND = expand environment variables in name
;               /NO_EXTENSION = don't include extension in returned filename
;               
; Restrictions: Needs IDL version > 5.3
;
; Side Effects: Input file names are trimmed of redundant spaces
;               
; History     : Written, 11-Nov-2002, Zarro (EER/GSFC)
;
; Contact     : dzarro@solar.stanford.edu
;-    

function file_break,file,name=name,path=path,extension=extension,drive=drive,$
                    expand=expand,no_extension=no_extension

;-- bail out if not string input

sz=size(file)
dtype=sz[n_elements(sz)-2]
if dtype ne 7 then begin
 path=''
 ext=''
 return,''
endif
nfile=n_elements(file)

if ~(keyword_set(expand)) then file=strtrim(file,2) ;JM file=chklog(file,/pre) 

no_ext=keyword_set(no_extension)

;-- construct regular expression to search for last part of string 
;   that doesn't have any delimiters. Part before name must be path.

;-- extract path (tricky when path delimiter is missing)

if keyword_set(path) or arg_present(path) then begin
 regex='^(.*)(\\|/)(.*)$'
 temp=stregex(file,regex,/ext,/sub)

;-- have to do the following checks for weird path names

 chk=where( (temp[1,*] eq '') and (temp[3,*] ne ''),count)
 if count gt 0 then temp[1,*]=temp[2,*]

 chk=where( temp[0,*] eq '',count)
 if count gt 0 then temp[3,chk]=file[chk]

 chk=where(temp[0,*] eq '/',count)
 if count gt 0 then temp[1,chk]='/'

 chk=where( stregex(temp[1,*],'\:$',/bool) ,count)
 if count gt 0 then temp[1,chk]=temp[1,chk]+'\'

 chk=where( stregex(temp[3,*],'\:$',/bool) ,count)
 if count gt 0 then temp[1,chk]=temp[3,chk]+'\'

 tpath=comdim2(temp[1,*])
 if arg_present(path) then begin
  path=tpath
  if no_ext then return,stregex(comdim2(temp[3,*]),'[^\.]*',/ext) else $
   return,comdim2(temp[3,*])
 endif else return,tpath
endif 

;-- extract extension

if keyword_set(extension) then begin
 extension=stregex(file,'\.[^\\/:)]*',/ext)
 if nfile eq 1 then extension=extension[0]
 return,extension
endif

;-- extract drive

if keyword_set(drive) then begin
 drive=stregex(file,'[^\\/]+:',/ext)
 if nfile eq 1 then drive=drive[0]
 return,drive
endif

;-- return name (includes extension but without path)

name=stregex(file,'[^\\/:]*$',/ext)
if nfile eq 1 then name=name[0]

;-- if /NO_EXT set then peel it off

if no_ext then name=stregex(name,'[^\.]*',/ext)

return,name

end

