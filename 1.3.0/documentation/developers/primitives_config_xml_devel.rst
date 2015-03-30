Appendix: Primitives Configuration XML File Format and Generation
###################################################################


This page documents the contents of the ``config/gpi_pipeline_primitives.xml`` file which serves as the master index of
primitives available to the pipeline. It should essentially never be necessary to manually edit or update this file:
For developers, the IDL command  ``make_primitives_config`` will automatically regenerate this file based on 
structured information present in the doc headers of the primitives themselves.  This command is invoked as part of the
response to the user pressing the "Rescan DRP Config" button in the Status Console, so for the vast majority of cases the workflow is simply:

 1. Create a new primitive or edit an existing primitive as desired. Update the doc header comments at the top as described below. 
 2. Press "Rescan DRP Config" in the Status Console.  The ``config/gpi_pipeline_primitives.xml`` file will be updated. 
 3. Your new primitive is now available for use in the pipeline. If you have any currently open Recipe Editor windows, you'll need to select 'Reload Available Pritives' to make it read in the updated configuration file. 

The ``gpi_pipeline_primitves.xml`` file consists of a long series of <Primitive /> XML tags, contained within a single <Config /> tag. 
Here is an example of the content of a Primitive tag from that file::

 <Primitive Name="Remove Persistence from Previous Images" IDLFunc="gpi_remove_persistence_from_previous_images" Comment=" Determines/Removes persistence of previous images" Order=" 1.2" Type=" ALL">
     <Argument  Name="CalibrationFile" Type="String" CalFileType="persis" Default="AUTOMATIC" Desc="Filename of the persistence_parameter file to be read" />
     <Argument  Name="Save" Type="int" Range="[0,1]" Default="0" Desc="1: save output on disk, 0: don't save" />
     <Argument  Name="gpitv" Type="int" Range="[0,500]" Default="0" Desc="1-500: choose gpitv session for displaying output, 0: no display "  />
 </Primitive>
 

The attributes of a Primitive tag are as follows:

 * *Name*: The descriptive name for the primitive. Required. Obtained from the 'PRIMITIVE DESCRIPTION' doc header line in the IDL source code file.
 * *IDLFunc*: Name of the IDL function that implements this command. Required. Obtained from the filename itself automatically during indexing by ``make_primitives_config``. 
 * *Comment*: A longer explanatory comment. Optional. Obtained from the 'COMMENT' doc header line.
 * *Order*: A numeric order giving the suggested default order of this primitive relative to other ones.  Required. Obtained from the 'ORDER' doc header line. See :ref:`primitives` for more information. 
 * *Type*: Which subset(s) of primitives this particular primitive belongs to.  Required. Obtained from the 'TYPE' doc header line.  See :ref:`templates` for more information. 

Each primitive may contain zero or more Argument tags. The attributes of an argument tag are as follows:

 * *Name*: The string name to be used for that primitive argument. 
 * *Type*: The IDL variable type for that primitive argument. May be "string", "int", "float"
 * *Range*: An optional range limit that will apply to this argument. For numeric types, give the min and max allowed values enclosed in brackets: ``"[0,500]"`` and so on. For string types, if there are a limited set of allowed values, give those separated by a pipe (``|``) symbol: ``"MEAN|MEDIAN|SIGMACLIP"``. If the Range argument is not present, the argument's range is not constrained. 
 * *Default*: The default value for that argument. Must comply with the Type and Range constraints. Optional. 
 * *Desc*: A longer descriptive comment for the argument, which is shown in the Recipe Editor as a reference for the user. Optional. 


A "CalibrationFile" argument may also have an additional attribute:

 * *CalFileType*: The type of calibration file desired from the calibration database for this primitive. 

The CalFileType attribute if present for any argument other than CalibrationFile will simply be ignored.

