function array_indices_1d,array,x,y,z
sz = size(array)
if n_params() eq 3 then z=0
if sz[0] eq 3 then return, sz[2]*y+x+z*sz[3]
if sz[0] eq 2 then return, sz[2]*y+x
end