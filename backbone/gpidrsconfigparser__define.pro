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
;	from the config file (Self.Modules). This is a 3 column module
;	containing the name, IDL function name and pipeline type of
;	each module.
;
; ARGUMENTS:
;	AttNames	The names of the attributes
;	Attvalues	The values of the attributes
;
;-----------------------------------------------------------------------------------------------------
PRO gpidrsconfigparser::NewModule, AttNames, AttValues

	;Name IDLFunc Comment Order Type 
moduleName ='' & moduleFunctio='' & moduleComment='' & moduleOrder='' & moduleType='' 
	FOR i = 0, N_ELEMENTS(AttNames) - 1 DO BEGIN	; Place attribute values into
	
		CASE AttNames[i] OF			                    ; variable fields.
			'Name': moduleName = AttValues[i]
			'IDLFunc': moduleFunction = AttValues[i]
        	'Comment': moduleComment = AttValues[i]
         	'Order': moduleOrder = AttValues[i]
         	'ReductionType': moduleType = AttValues[i]
         	'Type': moduleType = AttValues[i]
      	ELSE:
		ENDCASE
	END

	if self.verbose then print, "FOUND PRIMITIVE: ", modulefunction, modulename

	newmodule =  {name: moduleName, idlfunc: moduleFunction, comment: modulecomment, order: moduleorder, reductiontype: moduletype}

	IF N_ELEMENTS(*Self.Modules) EQ 0 THEN begin
		*Self.Modules =  newmodule
	endif ELSE *Self.Modules = [*Self.Modules, newmodule]

END

;-----------------------------------------------------------------------------------------------------
; Procedure NewArgument
;
; DESCRIPTION:
; 	This procedure adds a new argument to the array of arguments retreived
;	from the config file for the current module.
;
; ARGUMENTS:
;	AttNames	The names of the attributes
;	Attvalues	The values of the attributes
;
;-----------------------------------------------------------------------------------------------------

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
function gpidrsconfigParser::getidlfunc


return, {  names : (*self.modules).name, $
    idlfuncs : (*self.modules).idlfunc, $
    comment : (*self.modules).comment, $
    order : (*self.modules).order, $
    reductiontype : (*self.modules).reductiontype, $
    argmodnum : (*self.Arguments).modnum, $
    argname : (*self.Arguments).name, $
    argtype : (*self.Arguments).type, $
    argrange : (*self.Arguments).range, $
    argcalfiletype: (*self.Arguments).calfiletype, $
    argdesc : (*self.Arguments).desc, $
    argdefault : (*self.Arguments).default} 

END



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
