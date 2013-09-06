

Terminology
==================

There are some vocabulary items that you should be familiar with if you're
going to hack on pipeline internals. These in part reflect usage in the Keck
OSIRIS data pipeline, from which the core architecture of the GPI pipeline was
originally derived. 


**DRF**
        "Data Reduction File" = an XML file containing a series of reduction
        steps and their options.  Generally referred to as a "Recipe" or "Recipe file"
        for GPI and in general Gemini usage, but pipeline internals in many places
        still uses the DRF vocabulary.

**module**
        Likewise, the legacy OSIRIS term for an individual reduction task, 
        generally called a "primitive" in GPI/Gemini contexts. 

All end-user-facing code (including all GUIs etc) should use the
recipe/primitive nomenclature that is standard for Gemini, while internal code is allowed to still use the
Keck legacy terms (but can be updated to use the Gemini vocabulary, at developers'
convenience)
