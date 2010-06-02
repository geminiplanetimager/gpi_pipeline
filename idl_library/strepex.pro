;+
; NAME:
;             strepex
;
;
;
; PURPOSE:
;             Performs replacements of parts in strings by using
;             regular expressions (REPlacement of regular
;             EXpressions). Subexpressions may be also  
;             inserted into the replacement string.
;
;
;
; CATEGORY:
;             String processing
;
;
;
; CALLING SEQUENCE:
;             newstring = strepex( string, expression, [replacement],
;                                 /fold_case, /all) 
;
;
;
; INPUTS:
;             string     -  the string which will be analyzed and whose
;                           parts will be replaced in return.
;
;             expression -  A regular expression as being used for the
;                           REGEX function. Subexpressions must be
;                           given in parentheses.
;
;             replacement - String to replace for matching regular
;                           expressions. If it contains "&n" it
;                           will be replaced with the n-th
;                           subexpression in expression above
;                           (starting from 0). "&" may be escaped with
;                           "\&", "\" with "\\".
;                           If not given replacement will be empty
;                           string (deletion of string).
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;              fold_case -  Use case-insensitive regular expression
;                           matching. But replacement remains case
;                           sensitive. 
;                           
;              all      -   Replace all occurrences of expression in
;                           given string. Default is to replace only
;                           the first occurrence of expression.
;
;
; OUTPUTS:
;              Returns the input string with a replacement of all
;              occurrences of a matching expression by the replacement
;              (which in turn may contain replacements of
;              subexpressions).
;              If no subexpression was found the input string remains
;              unaltered. 
;
;
; OPTIONAL OUTPUTS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;            Do not use in time critical sections: It involves lot of
;            looping on  input and replacement string (but the
;            recursion mentioned in earlier versions was replaced to
;            allow escaping). 
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;             s = "x5*y3+2"
;             s1 = strepex(s,"(x|y)([0-9])","&0(&1)",/all)
;             -> s1 contains "x(5)*y(3)+2"
;
;
;
; MODIFICATION HISTORY:
;            $Log: strepex.pro,v $
;            Revision 1.1  2010/02/05 21:39:49  gpi
;            *** empty log message ***
;
;            Revision 1.5  2004/06/30 07:15:46  goehler
;            replace of subexpression expansion (&n -> n-th subexpression) with a more
;            elaborated but quirky version which now supports escaping within replacement string.
;
;            Revision 1.4  2004/06/29 07:55:01  goehler
;            added: internal noexpand keyword which fastens up the subexpression expansion
;            waiver: implementation of escaping using "\" is wrong. must be replaced with something else
;
;            Revision 1.3  2003/04/09 13:03:37  goehler
;            updated documentation/fix of example bug
;
;            Revision 1.2  2002/09/10 07:01:51  goehler
;            typos/fixed aitlib html style
;
;            Revision 1.1  2002/09/04 14:59:26  goehler
;            string function to perform regular expression replacements.
;
;
;-

FUNCTION strepex, input_string, regexstr, replstr, fold_case=fold_case, all=all

    ;; Implementation:
    ;; 1.) Search index of regular expression with stregex
    ;; 2.) Extract subexpressions
    ;; 3.) Copy part before into destination string
    ;; 4a.)Replace &n in replacement string by subexpression n 
    ;;     using the similar algorithm starting from 1.)
    ;; 4b.)Also replace escaped characters like "\&" or "\\".
    ;; 6.) Copy replacement string to destination expression
    ;; 7.) If /all repeat with 1.) till end of string.


    ;; ------------------------------------------------------------
    ;; SETUP
    ;; ------------------------------------------------------------

    
    ;; copy of input string which may be modified (to support multiple
    ;; expression look up)
    instr = input_string

    ;; string for result
    newstr=""

    ;; index where to start regex search:
    s_index=0


    ;; ------------------------------------------------------------
    ;; MAIN LOOP
    ;; ------------------------------------------------------------

    REPEAT BEGIN 


        ;; ------------------------------------------------------------
        ;; LOOK FOR SUBSTRING
        ;; ------------------------------------------------------------

        sub_index = stregex(instr,regexstr,fold_case=fold_case,length=regex_len,/subexpr)


        ;; sub exrpession found -> replace it:
        IF sub_index[0] NE -1 THEN BEGIN 


            ;; ------------------------------------------------------------
            ;; ADD PART *BEFORE* MATCHING STRING:
            ;; ------------------------------------------------------------

            newstr = newstr + strmid(instr,0,sub_index[0])


            ;; ------------------------------------------------------------
            ;; PERFORM REPLACEMENT-EXPANSION OF SUBEXPRESSIONS:
            ;; ------------------------------------------------------------

            ;; auxilliary replacement string which holds a copy being
            ;; replaced with substrings:
            aux_replstr = replstr

            ;; subexpressionpattern:
            subsubexpr = "([^\]&[0-9])|(^&[0-9])|(\\\\)"

            
            ;; replacement string which will be the expanded original one:
            new_replstr = ""

            ;; for all replacement patterns do:
            REPEAT BEGIN 

                ;; ------------------------------------------------------------
                ;; LOOK FOR SUBSUBSTRING EXPANSION
                ;; ------------------------------------------------------------

                subsub_index = stregex(aux_replstr,subsubexpr,length=subregex_len)

                IF subsub_index[0] NE -1 THEN BEGIN 

                    ;; matched sub-replacement pattern:
                    subsubstr = strmid(aux_replstr,subsub_index[0],$
                                       subregex_len[0])

                    ;; add part before matched expression:
                    new_replstr = new_replstr + strmid(aux_replstr,0,subsub_index[0])                    
                    
                    ;; look for  subexpressions at start of replacement
                    ;; string ("^&[0-9]"):
                    IF strmid(subsubstr,0,1) EQ "&" THEN BEGIN
                        subexpr_num = fix(strmid(subsubstr,1,1)+1)
                    ENDIF 

                    ;; look for  subexpressions in between replacement
                    ;; string ("[^\]&[0-9]"):
                    IF strmid(subsubstr,1,1) EQ "&" THEN BEGIN
                        subexpr_num = fix(strmid(subsubstr,2,1)+1)

                        ;; add ignored character before "&":
                        new_replstr = new_replstr+strmid(subsubstr,0,1)
                    ENDIF 

                    ;; unescape "\\":
                    IF subsubstr EQ "\\" THEN BEGIN 
                        new_replstr  = new_replstr + "\"
                    ENDIF ELSE BEGIN 
                        ;; no escape -> 
                        ;; actually insert replacement of subexpressions
                        IF subexpr_num LE n_elements(sub_index) THEN        $
                          new_replstr = new_replstr     +                   $
                                        strmid(instr,sub_index[subexpr_num],$
                                                     regex_len[subexpr_num])
                    ENDELSE 
                                            
                    ;; remove matched regex from replacement string::
                    aux_replstr = strmid(aux_replstr,subsub_index[0]+subregex_len[0])
                ENDIF                
            ENDREP UNTIL subsub_index[0] EQ -1

            ;; add reminder of replacement string
            new_replstr = new_replstr + aux_replstr

            ;; ------------------------------------------------------------
            ;; ADD REPLACEMENT STRING
            ;; ------------------------------------------------------------

            newstr = newstr+new_replstr

            ;; remove matched part from input
            instr = strmid(instr,sub_index[0]+regex_len[0])
        ENDIF 
        

        ;; ------------------------------------------------------------
        ;; FINISH IF NO REGEX FOUND OR NOT ALL TO MATCH
        ;; ------------------------------------------------------------

    ENDREP UNTIL (sub_index[0] EQ -1) OR (keyword_set(all) EQ 0)


    ;; ------------------------------------------------------------
    ;; ADD REMINDER OF INPUT STRING:
    ;; ------------------------------------------------------------    

    newstr = newstr+instr
    

    RETURN, newstr 
END
