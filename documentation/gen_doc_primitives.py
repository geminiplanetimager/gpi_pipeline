#!/usr/bin/env python
#import os, sys
import numpy as np
import matplotlib.pyplot as pl
import matplotlib
import astropy
import astropy.io.fits as fits
#import aplpy, atpy
from IPython.core.debugger import Tracer; stop = Tracer()
import logging
_log = logging.getLogger('t')

import gpi_pipeline

""" Generate documentation for primitives

Based on Dmitry's gen_doc_pages.pl perl script
Reimplemented/refactored in Python by Marshall 
in order to make use of existing parsing code for
the primitives database. 


"""



if __name__ == "__main__":
        
    logging.basicConfig(level=logging.INFO, format='%(name)-12s: %(levelname)-8s %(message)s',)

    pc = gpi_pipeline.GPIPrimitivesConfig()

    outname = "usage/primitives.rst"
    outfile = open(outname, 'w')

 

    types = ['SpectralScience','PolarimetricScience','Calibration']
    already_done = dict()

    outfile.write(".. _primitives:\n\n")
    outfile.write("Primitives, Listed by Category\n")
    outfile.write("==============================\n\n\n")

    outfile.write("""

This page documents all available pipeline primitives, currently {nprimitives} in total. 

First we list the available primitives in each mode, and below provide the detailed documentation including the
parameter arguments for each. 

Primitives each have an "**order**", which is a floating point number that defines the *default* ordering when added to a recipe. Smaller numbers come earlier in the execution sequence. You can change the order arbitrarily in the Recipe Editor of course. Notionally, orders <2 are actions on 2D files, orders between 2-4 are actions on datacubes, and orders > 4 are actions on entire observation sequences, but these are not strictly enforced.

(*Note: For simplicity, some engineering and software testing related primitives not intended for end users are not listed in the following tables.*)

""".format(nprimitives=len(pc)))

    for type_ in types:
        outfile.write(":ref:`{0}`  \n".format(type_) )

    # First, write the table of contents at the top, organized by type
    for type_ in types:

        outfile.write("\n.. _{0}:\n\n".format(type_) )

        outfile.write(type_+"\n"+"-"*len(type_)+"\n\n")

        plist = pc.ListOrderedPrimitives(type=type_, return_list=True)
        # figure out the max line length needed, for the RST table
        maxlen = 0
        for num, name in plist:
            linelen = len(":ref:`{0} <{1}>`\n".format(name, "".join(name.split())) )
            if linelen > maxlen:
                maxlen=linelen
        maxlen+=2 # some padding

        # write out table header
        outfile.write("====== "+"="*maxlen + " =\n")
        outfile.write("Order  Primitives relevant to "+type_ +"     ({0} total)\n".format(len(plist)) )        
        outfile.write("====== "+"="*maxlen + " =\n")

        # write out list
        for num, name in plist:
            outfile.write("{num:5.2f}  :ref:`{name} <{name2}>`\n".format(num=num, name=name, name2="".join(name.split())) )

        outfile.write("====== "+"="*maxlen + " =\n")
        outfile.write("\n\n")

    # now write the detailed description for ALL primitives

    outfile.write("Primitive Detailed Documentation\n")
    outfile.write("==================================\n\n\n")


    plist = pc.ListOrderedPrimitives(return_list=True)
    for num, name in plist:
        #if name in already_done.keys(): continue

        if name.strip() == "": continue
        #else:
        outfile.write(""".. index::
    single:"""+name+"\n\n")
        outfile.write(".. _{0}:\n\n".format("".join(name.split()) ) )
        p = gpi_pipeline.Primitive(pc.primitive[name])
        outfile.write(p.doc())
        #already_done[name] = True

    outfile.close()
    print "  ==>> "+outname


