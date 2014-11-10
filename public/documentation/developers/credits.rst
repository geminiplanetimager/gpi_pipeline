
.. _sw-credits:

Credits for the GPI Pipeline Software Development
#############################################################

.. note::
        This listing of credits is incomplete.  Suggestions and improvements welcome. Consult the
        svn repository history or the :ref:`release-notes` for the full details of who did what when.

The GPI Data Analysis Team
----------------------------

Pipeline architecture design, initial algorithms development, core structure, GUI frameworks, and many primitives by **Jerome Maire** and **Marshall Perrin**.  



**Patrick Ingraham** developed many of the primitives, led major aspects of IFS calibration and testing, and extensively contributed to analyses and documentation.
**Dmitry Savransky** made major contributions to pipeline primitives, infrastructure, and GPItv.

**Zack Draper** developed improved datacube extraction routines and tools for fitting flexure using microlens PSFs.
**Mike Fitzgerald** contributed some improvements to gpitv and polarimetric extraction.
**Christian Marois** contributed to improving PSF subtraction algorithms and contrast measurement code. 
**Max Millar-Blanchaer** contributed extensively to polarization mode primitives and GPItv polarization support, and with 
**Abhijith Rajan** found and fixed a few bugs.
**Jean-Baptiste "JB" Ruffio** vanquished many bugs, enhanced the destriping and microphonics removal primitives, and wrote portions of the documentation.
**Naru Sarakuni** extensively supported integration and test, and contributed improvements to GPItv.
**Jason Wang** contributed to satellite spot fitting, improved the installation system, and contributed improvements to GPItv.
**Schuyler Wolff** developed and tested the PSF-fitting wavelength calibration algorithm, improved the Data Parser, made other pipeline improvements, and contributed significantly to this documentation.

**Jeff Chilcote** provided guidance on detector operations and calibrations. 
**Alexandra Greenbaum** is leading development of nonredundant aperture masking interferometry algorithms applied to GPI, and also contributed to this documentation.
**Tyler Barker** implemented the KLIP algorithm, under guidance from Dmitry.
**Steven Beckwith** analyzed detector testing data to assess optimal readout modes. 
**Quinn Konopacky** developed the distortion correction primitive along with Jerome.
**Franck Marchis** oversees the computer infrastructure at the SETI Institute hosting software repositories and documentation, and supervised visiting student JB Ruffio.
**Laurent Pueyo** contributed to data analyses and algorithms development. 
**Sloane Wiktorowicz** worked with Max to calibrate the instrumental polarization.
Some utility functions used in the pipeline are by **Mathilde Bealieau**, **David Lafreniere**, **Jean-Francois Lavigne**, and **Lisa Poyneer**.


Contributions to data analyses and public data releases have been made by many additional memebrs of the GPI Data Analysis team, including **Rob de Rosa**,  **Jennifer Patience**, **Sandrine Thomas** and **Kim Ward-Duong**.



**Rene Doyon** was subsystem PI for the GPI DRP as part of the GPI project, and provided top-level guidance in overall pipeline design. 
**James Graham** developed core algorithm concepts for the polarization reduction, which were subsequently implemented by Marshall and enhanced by Max. 
**Bruce Macintosh** maintained overall coherence of the GPI project wavefront. 

From Gemini, **Stephen Goodsell** kept the project on track. **Carlos Quiroz** and **Fredrik Rantakyro** supported 
the Gemini Data System, including establishment of interfaces and extensive implementation and testing.
**Pascale Hibon**  helped with testing of the pipeline and operations at Gemini.
**Kathleen Labrie** provided valuable input from Gemini's perspective during software reviews. 



Other Acknowledgements
------------------------


The GPI pipeline software architecture was inspired by, and portions of the backbone
code re-used from, **the Keck OSIRIS pipeline**.  The OSIRIS pipeline was developed
by James Larkin, Shelley Wright, Jason Weiss, Mike McElwain, Marshall Perrin,
Christof Iserlohe, Alfred Krabbe, Tom Gasaway, and Tommer Wizanski. 


The Recipe Editor  was inspired by the OSIRIS ODRFGUI, orginally written in Java by Jason Weiss.  Jerome Maire and Marshall Perrin reimplemented it in a modified form in IDL, with improvements since contributed by several team members.

GPItv is based on `atv by Aaron Barth et al.
<http://www.physics.uci.edu/~barth/atv/>`_   The Header Viewer dialog in gpitv
is taken from the `OSIRIS Quicklook tool
<http://www2.keck.hawaii.edu/inst/osiris/tools/>`_ ``ql2``, itself derived from
the NIRC2/NIRspec quicklook. The "Browse Files" dialog is based upon code
derived from David Fanning's tool `selectimage.pro
<http://www.idlcoyote.com/programs/catalyst/source/applications/selectimage.pro>`_. 

The GPI data pipeline is
built upon an extensive foundation of other open source software from the astronomical community, including 
but not limited to the Goddard IDL Astronomy Pipeline, the JHUAPL library, Craig Markwardt's MPFIT library, 
Liam Gumley's IMDISP.PRO, and many other individual tools.  See the licenses file provided in the pipeline source code's ``external`` directory for a
complete list of all open source routines we've made use of. 

 
