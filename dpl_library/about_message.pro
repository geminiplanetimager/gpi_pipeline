function about_message

    ver=strc(gpi_pipeline_version())
    tmpstr=['GPI DRP Revision: '+ver+'  - GPI 3d Data-Reduction Package', $
              '', $
              'Copyright _,_ by the University of Montreal ' + $
               '(UdeM), Canada', $
              '', $
              'Programming (report bugs to):', $
              '  Jerome Maire (UdeM, maire@astro.umontreal.ca)', $
              '  Marshall Perrin (UCLA)', $
              '', $
              'Documentation:', $
              '  Marshall Perrin (UCLA)', $
              '  Jerome Maire (UdeM)', $
              '', $
              'This software has been tested by:', $
              '  Jeff Chilcote, Quinn Konopacky ', $
              '', $
              'Acknowledgements:', $
              '  René Doyon, Kathleen Labrie', $
              '    which have helped improve GPI DRP', $
              '  ', $
              ' ', $
              '', $
              'The project web site is:', $
              '  ', $
              '', $
              'When using this code, please cite the following paper:', $
              '  Maire J., Perrin M. D., et al SPIE 2010' + $
              '', $
              '']

return, tmpstr
end