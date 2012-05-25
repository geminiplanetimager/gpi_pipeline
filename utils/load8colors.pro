pro load8colors,colors=colors

if !d.name eq 'WIN' then device,decomposed=0
colors=strarr(13)
tvlct,   0,   0,   0, 0 & colors[0]='BACKGROUND'
tvlct,   0,   0,   0, 1 & colors[1]='BLACK'
if (!d.name eq 'X' or !d.name eq 'WIN') then tvlct, 255, 255, 255, 1 & colors[1]='WHITE'
tvlct, 255,   0,   0, 2 & colors[2]='RED'
tvlct,   0,   0, 255, 3 & colors[3]='BLUE'
tvlct,   0, 255,   0, 4 & colors[4]='GREEN'
tvlct, 255, 255,   0, 5 & colors[5]='YELLOW'
tvlct,   0, 255, 255, 6 & colors[6]='TURQUOISE'
tvlct,  80,   0, 100, 7 & colors[7]='PURPLE'
tvlct, 255, 127,   0, 8 & colors[8]='ORANGE'
tvlct, 200, 100, 100, 9 & colors[9]='SALMON'
tvlct,  10, 255, 150, 10 & colors[10]='AZUR'
tvlct, 255,  65, 130, 11 & colors[11]='PINK'
tvlct, 200, 195, 135, 12 & colors[12]='BEIGE'

end
