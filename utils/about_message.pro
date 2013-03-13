function about_message

    ver=strc(gpi_pipeline_version())
    tmpstr=['GPI DRP Revision: '+ver+'  - Gemini Planet Imager Data-Reduction Pipeline', $
              '', $
              ;'Copyright _,_ by the University of Montreal ' + $
              ; '(UdeM), Canada', $
              '', $
              '--------- Development: ---------', $
              '', $
              '  Marshall Perrin (mperrin@stsci.edu)', $
              '  Jerome Maire (maire@utoronto.ca)', $
			  '', $
			  '  Contributions from: (alphabetically)',$
			  '    Jeff Chilcote', $
			  '    Patrick Ingraham', $
              '    Quinn Konopacky ', $
			  '    Christian Marois', $
			  '    Max Millar-Blanchaer', $
			  '    Dmitry Savransky',$
			  '    Schuyler Wolff',$
			  '    Sloane Wiktorowicz',$
              '', $
              '--------- Documentation: ---------', $
              '', $
              '    Marshall Perrin', $
              '    Jerome Maire', $
			  '    Dmitry Savransky',$
              '', $
              '-------- Acknowledgements: --------', $
              '', $
              '  Rene Doyon, Kathleen Labrie, Bruce Macintosh, and ',$
		  	  '    all other GPI team members', $
              '    who have helped to improve the GPI DRP', $
              '  ', $
			  '  Some code derived from OSIRIS pipeline by:', $
			  '    James Larkin', $
			  '    Michael McElwain', $
			  '    Jason Weiss', $
			  '    Shelley Wright', $
              ' ', $
              '------------------------------', $
              ' ', $
              'The project web site is:         http://planetimager.org/', $
			  '', $
			  'See pipeline issue tracker at:   http://rm.planetimage.org', $
			  '                                 (contact Perrin for an account) ', $
              '', $
              ;'When using this code, please cite the following paper:', $
              ;'  Maire J., Perrin M. D., et al SPIE 2010' + $
              '']

return, tmpstr
end
