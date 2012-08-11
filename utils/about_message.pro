function about_message

    ver=strc(gpi_pipeline_version())
    tmpstr=['GPI DRP Revision: '+ver+'  - Gemini Planet Imager Data-Reduction Pipeline', $
              '', $
              ;'Copyright _,_ by the University of Montreal ' + $
              ; '(UdeM), Canada', $
              '', $
              '--------- Programming: ---------', $
              '', $
              '  Marshall Perrin (mperrin@stsci.edu)', $
              '  Jerome Maire (maire@utoronto.ca)', $
			  '', $
			  '  Contributions from: (alphabetically)',$
			  '    Jeff Chilcote', $
			  '    Christian Marois', $
			  '    Dmitry Savransky',$
              '', $
              '--------- Documentation: ---------', $
              '', $
              '  Marshall Perrin', $
              '  Jerome Maire', $
              '', $
              '  This software has been tested by:', $
              '    Kathleen Labrie, Jeff Chilcote, Quinn Konopacky ', $
              '', $
              '-------- Acknowledgements: --------', $
              '', $
              '  Rene Doyon, Kathleen Labrie and GPI team members', $
              '    who have helped to improve the GPI DRP', $
              '  ', $
			  '  Based in part on OSIRIS pipeline by:', $
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
