pro obridgeabort,oBridge

sproc=size(oBridge)
nbproc=sproc[1]

for i=0,nbproc-1 do begin
 oBridge[i]->abort
endfor


end
