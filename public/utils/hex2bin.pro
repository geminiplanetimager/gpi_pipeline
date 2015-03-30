function hex2bin,in,len
;;take string input in, assuming its in hex, convet to decimal,then to
;;binary, and then split into array of length len (to ensure proper
;;number of initial zero pads).

dec = ulong64(0)
reads,in,dec,format='(Z)'
bin = string(dec,format='(B+'+strtrim(len,2)+'.'+strtrim(len,2)+')')
vals = ulonarr(len)
for j=0,len-1 do vals[j] = long(strmid(bin,j,1))

return,vals

end
