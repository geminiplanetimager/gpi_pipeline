
GPI Observing Modes
========================


The GPI instrument control software uses observing modes (FITS keyword ``OBSMODE``) to specify sets of instrument optical masks that
work together. Each obsmode consists of a unique set of 4 elements: {Filter, Apodizer, Focal plane mask, Lyot Mask}.  Obsmodes come in several basic flavors:

 * *Coronagraphic* observations, most common for GPI.
 * *Direct* observations, with no coronagraphic masks in use.
 * *Unblocked* (unocculted) observations, which use the coronagraphic Apodizer and Lyot mask but not the focal plane masks. These 
   are occasionally used, mostly for certain types of calibration observation
 * *NRM* modes for non-redundant mask interferometry
 * and a single *Dark* mode for detector calibrations. 

The defined Obsmodes are as follows. See :ref:`reference_coronagraph` for details on the individual elements. 

============ ======= ==============  =======  ==============
Obsmode      Filter    Apodizer        FPM     Lyot Mask
============ ======= ==============  =======  ==============
Y_coron         Y       APOD_Y        FPM_Y   080m12_03
J_coron         J       APOD_J        FPM_J   080m12_04
H_coron         H       APOD_H        FPM_H   080m12_04
K1_coron        K1      APOD_K1       FPM_K1  080m12_06_03
K2_coron        K2      APOD_K2       FPM_K1  080m12_07
H_starcor       H       APOD_star     FPM_H   080m12_03
H_LIWAcor       H       APOD_HL       FPM_K1  080m12_04
Y_direct        Y       CLEAR        SCIENCE  Open
J_direct        J       CLEAR        SCIENCE  Open
H_direct        H       CLEAR        SCIENCE  Open
K1_direct       K1      CLEAR        SCIENCE  Open
K2_direct       K2      CLEAR        SCIENCE  Open
Y_unblocked     Y       APOD_Y       SCIENCE  080m12_03
J_unblocked     J       APOD_J       SCIENCE  080m12_04
H_unblocked     H       APOD_H       SCIENCE  080m12_04
K1_unblocked    K1      APOD_K1      SCIENCE  080m12_06_03
K2_unblocked    K2      APOD_K1      SCIENCE  080m12_07
H_starunb       H       APOD_star    SCIENCE  080m12_03
H_LIWAunb       H       APOD_HL      SCIENCE  080m12_04
NRM_Y           Y       NRM          SCIENCE  Open
NRM_J           J       NRM          SCIENCE  Open
NRM_H           H       NRM          SCIENCE  Open
NRM_K1          K1      NRM          SCIENCE  Open
NRM_K2          K2      NRM          SCIENCE  Open
DARK            H       APOD_H       FPM_H    Blank
============ ======= ==============  =======  ==============


See also the `Gemini page on GPI observing modes <http://www.gemini.edu/sciops/instruments/gpi/default-mode>`_.
