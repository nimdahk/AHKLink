; AHKLink - returns a link based on multiple searches.
; Defaults to an unshortened link from the AHK_L documentation.
; Set the ForceBasic flag to return links such as
;    www.autohotkey.com/docs/commands/GuiControl.htm
; Set the ShortLink flag to return links such as
;    http://d.ahk4.me/~GuiControl ; Documentation
;    http://ahk4.me/qt4MLI        ; Forum
; 
; returns: a link on success, 0 on failure

AHKLink(SearchText, ForceBasic=0, ShortLink=0, ForceSearch=0)
{
	If ForceSearch
		link := AHKLink_ForumSearch(SearchText)
	Else
		link := AHKLink_TSVRet(SearchText, ForceBasic)
	If !ForceSearch && !link ; TSVRet failed
		link := AHKLink_ForumSearch(SearchText)
	If !Link
		return 0
	If ShortLink
		link := AHKLink_Shorten(link)
	return link
}

; AHKLink_ForumSearch() - Searches the forum using PhpBB's search
; Slight modification of AHKSearch: http://ahk4.me/n1UrzR by nimda
; The optional parameter OutTitle receives the title of the link;
; This must be parsed to remove any html entities
; returns: a link on success, 0 on failure

AHKLink_ForumSearch(SearchText, ByRef OutTitle = 0)
{
	url := "http://www.autohotkey.com/search/search.php?site=0&path=&result_page=search.php&query_string=" AHKLink_EncodeURL(Trim(text)) "&option=start&search=Search"
	UrlDownloadToFile, % url, % f := A_Temp "\AHKLinkForumSearch.tmp"
	FileRead, Outdata, % f
   	RegExMatch(OutData, "<p class='blue'>.*?<a.*?href=""(.*?)"".*?>(.*?)</a>.*?</p>", t)
	If (t1 = "")
		return 0
	OutTitle := t2
	return t1
}

; AHKLink_Shorten() - Shortens an autohotkey link using d.ahk4.me
; Original code posted at http://ahk4.me/oVRhg9 by nimda
; returns: shortlink on success, 0 or bit.ly errcode on failure

AHKLink_Shorten(Link)
{
	static rep :=		"&|%26,=|%3D,?|%3F,#|%23,:|%3A,/|%2F, |%20"
	     , endpoint :=	"http://api.bitly.com/v3/shorten?login=ahk4me&apiKey=R_4b3df1f5417d94ff356ed511fd50a153&format=txt&longUrl="
	If RegExMatch(Link, "i)$http://www.autohotkey.net/~Lexikos/AutoHotkey_L/docs/commands/(.*?).htm(#.*)?$", match)
		return "http://d.ahk4.me/~" . match1 . match2
	If RegExMatch(Link, "i)$http://www.autohotkey.net/~Lexikos/AutoHotkey_L/docs/(.*?).htm(#.*)?$", match)
		return "http://d.ahk4.me/" . match1 . match2
	Loop Parse, rep, `,
		StringReplace, Link, Link, % SubStr(A_LoopField, 1, 1), % SubStr(A_LoopField, 3), All
	UrlDownloadToFile
	, %endpoint%Link
	, % fn :=   A_Temp "\BitlyAHK4MEAHKLinkShorten.tmp"
	If ErrorLevel
		return 0
	Fileread, Url, % fn
	return RegExReplace(Url, "\R")
}

; AHKLink_TSVRet() - returns a link from the AutoHotkey TSV file.
; The AHKTSV file was generated through AutoHotkey.chm
; and much of this code is taken from the TSV library by nimda.
; Set the forceBasic flag to return a link like
;    http://www.autohotkey.com/docs/commands/Input.htm
; whenever possible.
; returns: a link on success, 0 on failure

AHKLink_TSVRet(SearchText, ForceBasic=0)
{
	If !FileExist("AHKLink_index.tsv")
	{
		UrlDownloadToFile, http://www.autohotkey.net/~crazyfirex/index.tsv, AHKLink_index.tsv
		If ErrorLevel
			return 0
	}
	Loop Read, AHKLink_index.tsv
	{
		lf := A_LoopField
		pTab := inStr(lf, A_Tab)
		If SubStr(lf, 1, pTab-1) = SearchText
			out := SubStr(lf, pTab+1)
	}
	If !out
		return 0
	If SubStr(out, 1, 4) <> "http"
		If ForceBasic
			out := "http://www.autohotkey.com/" 				. out
		else	out := "http://www.autohotkey.net/~Lexikos/AutoHotkey_L/" 	. out
	return out
}



; AHKLink_EncodeUrl() - Returns an encoded url for use with the autohotkey search

AHKLink_EncodeUrl(Text){
   f := A_FormatInteger
   SetFormat, integer, hex
   Loop Parse, Text
      If A_loopField is not alnum
         r .= "%" . SubStr(Asc(A_LoopField), 3)
      else r.= A_LoopField
   SetFormat, integer, %f%
   return r
}

/*
; For reference, the following script was used to generate index.tsv after AutoHotkey.chm was decompiled:

#NoEnv
SetWorkingDir %A_ScriptDir%
Loop Read, index.hhk, index.tsv
{
	If SubStr(A_LoopReadLine, 1, 2) = "`t<"   ; <LI> <Object type="text/sitemap">
		b := true,  L := false
	Else If SubStr(A_LoopReadLine, 1, 5) = "    <"
		b := false, L := true
	Else if (b || L)
	{
		If RegExMatch(A_LoopReadLine, """Name""\s+value=""([^""]+)"">", out)
			append := out1
		Else If RegExMatch(A_LoopReadLine, """Local""\s+value=""([^""]+)"">", out)
			append := A_Tab . (L ? "http://www.autohotkey.net/~Lexikos/AutoHotkey_L/" : "") . out1 . "`r`n", b := L := 0
	}
	FileAppend % append
	append := ""
}
return
*/