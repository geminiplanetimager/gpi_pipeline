; by Jerome Maire
function findcommonbasename, list


length=strlen(list[0])

cc=1
while (total(strmatch(list,strmid(list[0],0,cc)+'*')) eq n_elements(list)) do cc+=1
print, strmid(list[0],0,cc-1)

return, strmid(list[0],0,cc-1)
end
