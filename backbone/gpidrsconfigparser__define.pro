;-----------------------------------------------------------------------------------------------------
; CLASS gpiDRSConfigParser
;
; DESCRIPTION:
;	gpiDRSConfigParser is responsible for parsing the DRSConfig.xml file, which
;	contains a list of all the possible  modules and the translations between
;	human-readable names and IDL routines. 
;
;	gpiDRSConfigParser inherits the IDL IDLffXMLSAX class, a general XML parser.  IDLffXMLSAX is
;	an event driven parser, using callback functions to handle XML elements on
;	the fly.
;
;HISTORY:
;  Directly based on OSIRIS' drpConfigParser__define.pro
;  2009-04-20 MDP: Split to new function and renamed for GPI
;  2010-10-22 JM: EXECUTE replaced by CALL_FUNCTION in startelement (for compilation)
;-----------------------------------------------------------------------------------------------------
FUNCTION gpidrsconfigparser::init, verbose=verbose, silent=silent
  retval = Self->IDLffXMLSAX::Init()

  if keyword_set(backbone) then self.verbose=verbose

  if keyword_set(verbose) then verbose=0

  return, retval

end


;------------------------------------------------------------
;
PRO gpidrsconfigparser::cleanup

	PTR_FREE, Self.Modules
	PTR_FREE, Self.Arguments
	;PTR_FREE, Self.Parms

END

;-----------------------------------------------------------------------------------------------------
; Procedure StartDocument
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  StartDocument is
;	called automatically when the parser begins parsing an XML document.
;
; ARGUMENTS:
;	None.
;
; KEYWORDS:
;	None.
;-----------------------------------------------------------------------------------------------------
PRO gpidrsconfigparser::startdocument

	IF PTR_VALID(Self.Modules) or ptr_valid(self.arguments) THEN BEGIN
		if self.verbose then PRINT, "Freeing primitive config data..."
		;PTR_FREE, Self.Parms
		PTR_FREE, Self.Arguments
		PTR_FREE, Self.Modules
	ENDIF
	Self.Modules = PTR_NEW(/ALLOCATE_HEAP)
	;Self.Parms = PTR_NEW(/ALLOCATE_HEAP)
	Self.Arguments = PTR_NEW(/ALLOCATE_HEAP)

	; ----------------------- TO DO: Validate the file -------------------


END

PRO gpidrsconfigparser::enddocument

	self.valid_config_read=1

END

;-----------------------------------------------------------------------------------------------------
; Procedure StartElement
;
; DESCRIPTION:
; 	This procedure is inherited from the IDLffxMLSAX parent class.  StartElement is
;	called automatically when the parser encounters an XML element.
;
; ARGUMENTS:
;	URI
;	Local
;	qName		Name of the XML element
;	AttNames	Array of attribute names
;	AttValues	Array of atribute values
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
PRO gpidrsconfigparser::StartElement, URI, Local, qName, AttNames, AttValues

	COMMON PARAMS, PARAMETERS

	CASE strupcase(qName) OF
		'CONFIG': BEGIN
;				MYPARAMETERS = [[AttNames], [AttValues]]
;				PARAMETERS = MYPARAMETERS
;				PARMTRANS = TRANSPOSE(PARAMETERS)
;				StructString = '*Self.Parms = CREATE_STRUCT('
;				FOR i = 1, ((N_ELEMENTS(PARMTRANS)/2)-1) DO StructString = StructString + "'" + PARMTRANS[0, i-1] + "', '" + PARMTRANS[1, i-1] + "', "
;				StructString = StructString + "'" + PARMTRANS[0, i-1] + "', '" + PARMTRANS[1, i-1] + "'"
				;StructString = StructString + ')'
				;retval = EXECUTE(StructString) ;commented by JM: need to avoid EXECUTE function for compilation!
				;*Self.Parms = CALL_FUNCTION('CREATE_STRUCT',AttNames,AttValues)
				;if n_elements(AttNames) gt 1 then stop
			END
		;'ARP_SPEC': Self.PipelineLabel = 'ARP_SPEC'
		'MODULE': begin
		    Self -> NewModule, AttNames, AttValues
		    Self.modulenum+=1
		    end
		'PRIMITIVE': begin
		    Self -> NewModule, AttNames, AttValues
		    Self.modulenum+=1
		    end
	
		'ARGUMENT': Self -> NewArgument, AttNames, AttValues
		ELSE:
	ENDCASE


END

;-----------------------------------------------------------------------------------------------------
; Procedure NewModule
;
; DESCRIPTION:
; 	This procedure adds a new module to the array of modules retreived
;	from the conifig file (Self.Modules). This is a 3 column module
;	containing the name, IDL function name and pipeline type of
;	each module.
;
; ARGUMENTS:
;	AttNames	The names of the attributes
;	Attvalues	The values of the attributes
;
;-----------------------------------------------------------------------------------------------------
PRO gpidrsconfigparser::NewModule, AttNames, AttValues

	;Name IDLFunc Comment Order Type Sequence
moduleName ='' & moduleFunctio='' & moduleComment='' & moduleOrder='' & moduleType='' & moduleSequence='' 
	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values into
	
		CASE AttNames[i] OF			                    ; variable fields.
			'Name': moduleName = AttValues[i]
			'IDLFunc': moduleFunction = AttValues[i]
        	'Comment': moduleComment = AttValues[i]
         	'Order': moduleOrder = AttValues[i]
         	'ReductionType': moduleType = AttValues[i]
         	'Type': moduleType = AttValues[i]
			'Sequence': moduleSequence = AttValues[i]
      	ELSE:
		ENDCASE
	END

	if self.verbose then print, "FOUND PRIMITIVE: ", modulefunction, modulename

	newmodule =  {name: moduleName, idlfunc: moduleFunction, comment: modulecomment, order: moduleorder, reductiontype: moduletype, sequence: modulesequence}

	IF N_ELEMENTS(*Self.Modules) EQ 0 THEN begin
		*Self.Modules =  newmodule
	endif ELSE *Self.Modules = [*Self.Modules, newmodule]

END


PRO gpidrsconfigparser::NewArgument, AttNames, AttValues


      argName ='' & argtype='' & argrange='' & argdefault=''& argdesc='' & argCalFileType=''
  FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN  ; Place attribute values into

    CASE AttNames[i] OF                         ; variable fields.
    	'Name': argName = AttValues[i]
      	'Type': argtype = AttValues[i]
      	'Range': argrange = AttValues[i]
      	'Default': argdefault = AttValues[i]
        'CalFileType': argcalfiletype = AttValues[i]
       	'Desc': argdesc = AttValues[i]
      ELSE:
    ENDCASE
  END


  newarg = {modnum: self.modulenum, name: argName, type: argtype, range: argrange, default: argdefault, desc: argdesc, calfiletype: argcalfiletype} 
  IF N_ELEMENTS(*Self.Arguments) EQ 0 THEN begin
    *Self.Arguments = newarg
  endif ELSE   *Self.Arguments = [*Self.Arguments, newarg] 


END

;-----------------------------------------------------------------------------------------------------
; function getIDLFunction
;
; DESCRIPTION:
; 	This function  returns the IDL command name corresponding to a given 
; 	module long descriptive name. 
;
; 	Basically does the same thing as getIDLFunctions, just with a different
; 	calling convention
;
; ARGUMENTS:
; 	description=	string name to compare to. 
;
; 	matched=		if present, will return the number of matches. 
; 					NOTE: if matched is not present, this function will *stop*
; 					on errors, but if matched IS present, then it will return
; 					a null string and set matched=0. 
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
function gpidrsconfigparser::getidlcommand, description, matched=count

	; error check
	if ~self.valid_config_read then begin
		message,/info, "No valid config file read - skipping translation"
		count=0
		return, ""
	endif

	; now do the comparison
	wm = where( strmatch((*self.modules).name, description,/fold_case), count)
	if count eq 0 then begin
		if arg_present(count) then return, "" else begin
		MESSAGE, 'No IDL function is specified in the ' + 'configuration file for module: ' + description
		stop
		endelse
	endif else return, (*self.modules)[wm[0]].idlfunc
end 


;-----------------------------------------------------------------------------------------------------
; Procedure getIDLFunctions
;
; DESCRIPTION:
; 	This procedure receives a reference to a backbone object,
;	with a Modules array and assigns the appropriate IDL function
;	to each module in the array.
;
; ARGUMENTS:
;	Backbone	The backbone object to be updated
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
PRO gpidrsconfigParser::getidlfunctions, Backbone


	;names = (*self.modules).name
	;idlfuncs = (*self.modules).idlfunc
	;stop

	FOR i = 0, N_ELEMENTS(*Backbone.Modules)-1 DO BEGIN
		FOR j = 0, N_ELEMENTS(*Self.Modules)-1 DO BEGIN
			IF ((*Self.Modules)[j].name EQ (*Backbone.Modules)[i].Name) THEN $
				(*Backbone.Modules)[i].CallSequence = (*Self.Modules)[j].idlfunc
		ENDFOR
		If (*Backbone.Modules)[i].CallSequence EQ '' THEN $
			MESSAGE, 'No IDL function is specified in the ' + $
			'configuration file for module: ' + (*Backbone.Modules)[i].Name
	ENDFOR


;	FOR i = 0, N_ELEMENTS(*Backbone.Modules)-1 DO BEGIN
;		FOR j = 0, N_ELEMENTS(*Self.Modules)/3-1 DO BEGIN
;			IF (*Self.Modules)[0, j] EQ (*Backbone.Modules)[i].Name AND $
;			   (*Self.Modules)[2, j] EQ Backbone.ReductionType THEN $
;				(*Backbone.Modules)[i].CallSequence = (*Self.Modules)[1,j]
;		ENDFOR
;		If (*Backbone.Modules)[i].CallSequence EQ '' THEN $
;			MESSAGE, 'No IDL function is specified in the ' + $
;			'configuration file for module: ' + (*Backbone.Modules)[i].Name
;	ENDFOR
;

END

;-----------------------------------------------------------------------------------------------------
function gpidrsconfigParser::getidlfunc


return, {  names : (*self.modules).name, $
    idlfuncs : (*self.modules).idlfunc, $
    comment : (*self.modules).comment, $
    order : (*self.modules).order, $
    reductiontype : (*self.modules).reductiontype, $
    sequence : (*self.modules).sequence, $
    argmodnum : (*self.Arguments).modnum, $
    argname : (*self.Arguments).name, $
    argtype : (*self.Arguments).type, $
    argrange : (*self.Arguments).range, $
    argcalfiletype: (*self.Arguments).calfiletype, $
    argdesc : (*self.Arguments).desc, $
    argdefault : (*self.Arguments).default} 

END

;-----------------------------------------------------------------------------------------------------
; Procedure getParameters
;
; DESCRIPTION:
; 	This procedure receives a reference to a backbone object
;	and transfers the configuration parameter information to
;	the backbone ParmList.
;
; ARGUMENTS:
;	Backbone	The backbone object to be updated
;
; KEYWORDS:
;	Inherited from parent class.  See documentation.
;-----------------------------------------------------------------------------------------------------
;PRO gpidrsconfigparser::getparameters, Backbone
	;Backbone.ParmList = Self.Parms
;END
;
;
;PRO gpidrsconfigParser::printinfo
;
;	COMMON PARAMS
;
;
;	;drpIOLock
;	OPENW, unit, "temp.tmp", /get_lun
;	FOR j = 0, N_ELEMENTS(*Self.Modules)/3-1 DO BEGIN
;		if self.verbose then PRINTF, unit, (*Self.Modules)[0, j] , "  ", (*Self.Modules)[1, j], "  ", (*Self.Modules)[2,j]
;	ENDFOR
;
;	FOR j = 0, 31 DO BEGIN
;		PRINTF, unit, PARAMETERS[j, 0] , "  ", PARAMETERS[j, 1]
;	ENDFOR
;	FLUSH, unit
;	CLOSE, unit
;	FREE_LUN, unit
;	;drpIOUnlock
;
;
;END


;-----------------------------------------------------------------------------------------------------
; CLASS gpiDRSConfigParser
;
; DESCRIPTION:
;	gpiDRSConfigParser is responsible for parsing the configuration file.
;	gpiDRSConfigParser inerits the IDL IDLffXMLSAX class, a general XML parser.  IDLffXMLSAX is
;	an event driven parser, using callback functions to handle XML elements on the fly.
;-----------------------------------------------------------------------------------------------------
PRO gpidrsconfigParser__define

	void = {gpidrsconfigparser, INHERITS IDLffXMLSAX, $
			;Parms:PTR_NEW(), $
			Arguments:PTR_NEW(), $
			modulenum:0, $
			verbose: 0, $  ; should we print out stuff as we go?  (set in init)
			valid_config_read: 0, $
			Modules:PTR_NEW(), $
			PipelineLabel:'' }

END
