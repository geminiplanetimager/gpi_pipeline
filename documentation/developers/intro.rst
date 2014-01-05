Introduction for New Developers
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


Best Steps for Getting Started
--------------------------------------


The GPI data pipeline is a large complex code base with a lot of legacy code. The best way to get started is probably 
to read through existing primitives and see how they operate on the data and which utility functions they make use of. Subsequent pages
describe how to create your own primitive. 

The GPI instrument team welcomes contributions of code enhancements and fixes
from members of the community. The preferred method for submitting new code is
to post to the `Gemini Data Reduction forum <http://drforum.gemini.edu>`_
for initial discussion there. Access to the subversion repository for
non-members of the GPI instrument team may be considered on a case by case
basis, particulary for anyone with a track record of useful contributions. 


Subversion Repository Organization
--------------------------------------


The subversion repository for the GPI pipeline is organized following the
common Subversion pattern of having 'trunk', 'tags', and 'branches'
subdirectories.  If you're not familiar with what each of these means, here are
some `explanatory <http://svnbook.red-bean.com/en/1.6/svn-book.html#svn.reposadmin.projects.chooselayout>`_
`references <http://stackoverflow.com/questions/16142/what-do-branch-tag-and-trunk-mean-in-subversion-repositories>`_.

There are separate 'trunk', 'tags', and 'branches' directories inside both the `pipeline` and `external` repository root directories. 

The `trunk` directory contains the main, current development of the pipeline. For most developers, this is all you will want to check out:

.. code-block:: sh
        svn checkout https://repos.seti.org/gpi/pipeline/trunk pipeline
        svn checkout https://repos.seti.org/gpi/external/trunk external


The `tags` directory contains a tagged copy of each numbered public release of the pipeline. 

Starting in early 2014, the `branches` directory contains one branch named `public`. This is the code base for public 
release of the pipeline, allowing for differences between the GPI instrument team's internal development and the code that's released. 
The main purpose for this is to separate out any new developmental/experimental code that's "not yet ready for prime time" use in production.




Terminology
-----------------

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
