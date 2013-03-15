property pTitle : "Use FT path expressions"property pVer : ".002"property pAuthor : "Rob Trew"-- Like the test script, but:-- Allows multiple selections from results,-- and copies the harvest from the clipboard.property pstrPath : "/Node paths/@line matches '^##'"property plstNodes : {}property pblnExcludeRoot : false -- Defaults to excluding the virtual root from any query resultsproperty pblnSelect : false -- Select chosen line, rather than focusing on itproperty pblnClipMatches : true-- SUMMARY OF SOME SYNTAX ELEMENTS - USED TO ADD PATH SYNTAX ELEMENTS FROM MENUSproperty plstMain : {"EXAMPLES", "Simple path", "Axis", "Attribute", "Node type", "Comparison operator", "Set operation"}property plstExamples : {{"/@type=heading", "Top-level headings"}, {"//@type=heading", "All headings"}, ¬	{"/*/@type!=empty", "2nd level, excluding blank lines"}, {"///problem", "Any line containing 'problem', with its ancestors"}, {"//* except //*/ancestor::*", "Leaf nodes - 'anything except nodes with descendants'"}}property plstSimplePaths : {{"/*", "All children (of top level, by default)"}, {"/*/*", "All grandchildren"}, ¬	{"/*/*/*", "All great-grandchildren"}, {"//*", "All descendants"}, {"///*", "All descendants + their ancestral paths"}, {"/*///*", "Whole document"}}-- Ver .015 Corrects description of following-sibling:: and preceding-sibling::property plstAxes : {¬	{"ancestor::", "All ancestors matching predicate"}, ¬	{"ancestor-or-self::", "Nodes and their ancestors matching predicate"}, ¬	{"descendant::", "All descendants matching predicate. Same as '//' operator"}, ¬	{"descendant-or-self::", "Nodes and their descendants matching predicate"}, ¬	{"following::", "All nodes following each of the previously matched nodes"}, ¬	{"following-sibling::", "Sibling nodes following each of the previously matched nodes"}, ¬	{"preceding::", "All nodes preceding each of the previously matched nodes"}, ¬	{"preceding-sibling::", "Sibling nodes preceding each of the previously matched nodes"}, ¬	{"child::", "Searches child node, same as '/' operator"}, ¬	{"parent::", "Searches parent node, same as '..' operator"}, ¬	{"self::", "Matches predicate on the same node"}, ¬	{"filter-descendants::", "Filter all descendants & return with ancestors, same as '///' operator"} ¬		}property plstTypes : {{"heading", "#"}, {"body", "plain"}, {"ordered", "1. 2. 3."}, {"unordered", "- or *"}, {"blockquote", ">"}, ¬	{"codeblock", "(4 spaces)"}, {"linkdef", "[id]:"}, {"property", "key : value"}, {"term", "(above :)"}, {"definition", ":"}, {"horizontalrule", {"***"}}, {"empty", "blank"}}property plstAttribs : {{"@type", ""}, {"@line", "includes the Markdown prefix"}, {"@mode", ""}, {"@modeContext", ""}, {"@id", ""}, {"@property", ""}, {"@<tagname>", "user-defined"}}-- Enclose regexes and special characters in single quotesproperty plstRelns : {{" contains ", ""}, {" matches ''", "Javascript regex in single quotes"}, {" beginswith ", ""}, {" endswith ", ""}, {"=", ""}, {"!=", ""}, {"<", ""}, {">", ""}, {"<=", ""}, {">=", ""}}property plstSetOps : {{" union ", ""}, {" intersect ", ""}, {" except ", ""}}property plstSub : {plstExamples, plstSimplePaths, plstAxes, plstAttribs, plstTypes, plstRelns, plstSetOps}property pCancel : "Cancel"property pEditHelp : "Add element from path syntax menus"property pManual : "Return to manual editing"property pOK : "OK"on run	tell application "FoldingText"				-- EXIT IF THERE IS NO FRONT DOCUMENT		set lstDocs to documents		if length of lstDocs < 1 then return		set oDoc to item 1 of lstDocs				-- OTHERWISE LOOP UNTIL A VALID PATH EXPRESSION IS ENTERED, OR THE USER EXITS		set blnEsc to false		set strPath to pstrPath		repeat while not blnEsc						-- PROMPT FOR A FOLDINGTEXT PATH EXPRESSION			activate						set strBtn to ""			repeat while strBtn ≠ pOK				try					tell (display dialog "Path expression:" default answer strPath & linefeed & linefeed buttons {pCancel, pEditHelp, pOK} cancel button ¬						pCancel default button "OK" with title pTitle & tab & "  Ver " & pVer)						set {strBtn, strPath} to {button returned, my RTrim(text returned)}					end tell				on error					return				end try								if strBtn = pEditHelp then					set strPath to my EditHelp(plstMain, strPath, pManual)				else					set strBtn to pOK				end if			end repeat			set pstrPath to strPath						-- DISPLAY ANY MATCHES			set plstNodes to {}			tell oDoc				set strSafePath to strPath				if pblnExcludeRoot then set strSafePath to "(" & strSafePath & ") except ///@id=0"				--display dialog strSafePath				try					set plstNodes to (read nodes it at path strSafePath)				end try								set lngNodes to length of plstNodes				set lngDigits to (length of (lngNodes as string))								set lstChoice to {}				repeat with i from 1 to lngNodes					set end of lstChoice to my PadNum(i, lngDigits) & tab & |text| of item i of plstNodes				end repeat								set lngChoice to length of lstChoice				if lngChoice < 1 then					activate					display dialog "No matches for " & strPath buttons {"OK"} default button "OK" with title pTitle & "  ver. " & pVer				end if			end tell						-- FOCUS THE DOCUMENT  AND ALLOW THE USER TO CHOOSE SOME OF THE MATCHING LINES			if lngChoice > 0 then				if pblnClipMatches then -- to clipboard in Markdown code format (4 space prefix for each line)					set {dlm, my text item delimiters} to {my text item delimiters, linefeed & "    "}					set the clipboard to "    " & (lstChoice as string)					set my text item delimiters to dlm				end if												tell oDoc					-- FOCUS ON THE RESULTS					--update node path it with text strPath										-- AND OFFER TO SELECT					activate					set varChoice to choose from list lstChoice with title pTitle & tab & pVer with prompt ¬						(lngChoice as string) & " matches in  " & name of it & " :" & return & return & strPath default items item 1 of lstChoice ¬						OK button name "Copy selected lines	(⌘[ to Focus Out) " cancel button name pCancel with empty selection allowed and multiple selections allowed										if varChoice ≠ false then												set {dlm, my text item delimiters} to {my text item delimiters, tab}						set strSub to ""						repeat with i from 1 to length of varChoice							if i > 1 then set strSub to strSub & " UNION "							set {lngNum, _} to text items of (item i of varChoice)							set strSub to strSub & "//@id=" & |id| of item lngNum of plstNodes						end repeat						set my text item delimiters to dlm																		-- MAKE SURE THAT THE BRANCH CONTAINING THE SELECTED LINE IS NOT COLLAPSED						--set lstBranch to read nodes it at path "//@id=" & strID & "/ancestor::@type!=root"						set lstBranches to read nodes it at path strSub						update expanded nodes it with changes {|addNodes|:lstBranches}												-- SELECT THE CHOSEN LINE						-- first allow a moment for the expansion to complete ...						--do shell script "sleep 0.2"						--if pblnSelect then						--	update selection with changes {textRange:{location:lngTextIndex, |length|:(length of strLine)}}						--else						update node path it with text strSub						set the clipboard to (read text at path strSub)						--end if						blnEsc = true					end if				end tell			end if		end repeat	end tellend runon BuildChoice(lstMenu)	set lst to {}	set lngMenu to length of lstMenu	set lngMax to 0	-- FIRST PASS	repeat with oItem in lstMenu		set {strTerm, _} to oItem		set lngChars to length of strTerm		if lngChars > lngMax then set lngMax to lngChars	end repeat	set lngTarget to lngMax + 8	repeat with oItem in lstMenu		set {strTerm, strComment} to oItem		set lngChars to length of strTerm		set end of lst to strTerm & NChars(((lngTarget - lngChars) div 4) + 1, tab) & strComment	end repeat	return lstend BuildChoiceon NChars(lngN, strChar)	set str to strChar	repeat with i from 1 to (lngN - 1)		set str to str & strChar	end repeat	return strend NCharson EditHelp(lstMenu, strPath, strCancel)	-- Append strings from menus until exit	set strNewPath to strPath	set strBtn to ""	if lstMenu ≠ plstMain then		set lstChoice to BuildChoice(lstMenu)		{}	else		set lstChoice to plstMain	end if	tell application "FoldingText"		activate		repeat while strBtn ≠ pOK						set varChoice to choose from list lstChoice with title pTitle & tab & pVer with prompt strNewPath default items item 1 of lstChoice ¬				OK button name "OK" cancel button name strCancel with empty selection allowed without multiple selections allowed			if varChoice ≠ false then				set varChoice to item 1 of varChoice			else				return strNewPath			end if			set {dlm, my text item delimiters} to {my text item delimiters, tab}			set varChoice to first text item of varChoice			set my text item delimiters to dlm						if plstMain contains varChoice then				repeat with i from 1 to length of plstMain					set strChoice to item i of plstMain					if varChoice = strChoice then						set lstSubMenu to item i of plstSub						exit repeat					end if				end repeat				set strNewPath to my EditHelp(lstSubMenu, strNewPath, pCancel)			else				set strBtn to pOK				-- replace * with axis				if varChoice ends with "::" and strNewPath ends with "*" then					return (text 1 thru -2 of strNewPath) & varChoice				else if strNewPath ends with "::" then					return strNewPath & "*" & varChoice				else					return strNewPath & varChoice				end if							end if		end repeat	end tell	return strNewPathend EditHelp-- LEFT PAD NUMBERS WITH ZEROS TO GET A FIXED LENGTHon PadNum(lngNum, lngDigits)	set strNum to lngNum as string	set lngGap to (lngDigits - (length of strNum))	repeat while lngGap > 0		set strNum to "0" & strNum		set lngGap to lngGap - 1	end repeat	strNumend PadNum-- REMOVE ANY INSTANCE OF NODE 0 WITH THIS-- (FOCUSING ON THE VIRTUAL ROOT NODE CAN TRIP AN ERROR)on PruneList(varItem, lst)	set lstPruned to {}	repeat with oItem in lst		set oItem to contents of oItem		if varItem ≠ oItem then set end of lstPruned to oItem	end repeat	return lstPrunedend PruneListon RTrim(strText)	set lngChars to length of strText	if lngChars is 0 then return ""	set lstWhite to {space, tab, return, linefeed, ASCII character 0}		repeat with iChar from length of strText to 1 by -1		if character iChar of strText is not in lstWhite then exit repeat	end repeat	set strText to text 1 thru iChar of strText	return strTextend RTrim