function listind2comb,ind
;; given the index of a list i.e, 0, 1, 2..., find the combination in
;; an ordered sequence it corresponds to:
;; 0 -> 0,1; 1 -> 0,2; 2 -> 1 2; 3 -> 0 3; etc.

counter = 0L
tot = 0L
while ind + 1 - tot gt 0 do begin counter += 1 & tot += counter & end

return,[ind - (tot-counter),counter]
end
