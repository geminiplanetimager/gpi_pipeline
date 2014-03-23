.. _primitives:

Primitives, Listed by Category
==============================




This page documents all available pipeline primitives, currently 131 in total. 

First we list the available primitives in each mode, and below provide the detailed documentation including the
parameter arguments for each. 

Primitives each have an "**order**", which is a floating point number that defines the *default* ordering when added to a recipe. Smaller numbers come earlier in the execution sequence. You can change the order arbitrarily in the Recipe Editor of course. Notionally, orders <2 are actions on 2D files, orders between 2-4 are actions on datacubes, and orders > 4 are actions on entire observation sequences, but these are not strictly enforced.

(*Note: For simplicity, some engineering and software testing related primitives not intended for end users are not listed in the following tables.*)

:ref:`SpectralScience`  
:ref:`PolarimetricScience`  
:ref:`Calibration`  

.. _SpectralScience:

SpectralScience
---------------

