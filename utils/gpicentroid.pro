FUNCTION gpicentroid, array
	compile_opt defint32, strictarr, logical_predicate

    s = Size(array, /Dimensions)
    if n_elements(s) eq 1 then return, [0,0]
    totalMass = Total(array)
    xcm = Total( Total(array, 2) * Indgen(s[0]) ) / totalMass
    ycm = Total( Total(array, 1) * Indgen(s[1]) ) / totalMass
    RETURN, [xcm, ycm]
END
