#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=..\..\Users\GRAZIANI\Pictures\icon_sortshort.ico
#AutoIt3Wrapper_Outfile=Sortshortx86.exe
#AutoIt3Wrapper_Outfile_x64=sortshortx64.exe
#AutoIt3Wrapper_Compile_Both=y
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Description=Trieur de raccourcis
#AutoIt3Wrapper_Res_Fileversion=5.0.0.0
#AutoIt3Wrapper_Res_CompanyName=Marc graziani
#AutoIt3Wrapper_Res_Language=1036
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------
 AutoIt Version: 3.3.14.5
 Author:         Marcgforce based on Se7enstars UI
#ce ----------------------------------------------------------------------------

Opt("GUIOnEventMode", 1)
opt("MouseClickDragDelay",10)

#include <Array.au3>
#include <ButtonConstants.au3>
#include <file.au3>
#include <GDIPlus.au3>
#include <GUIConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiRichEdit.au3>
#include <Misc.au3>
#include <MsgBoxConstants.au3>
#include <Process.au3>
#include <ScreenCapture.au3>
#include <WinAPIShellEx.au3>
#include <WinAPIRes.au3>
#include <WindowsConstants.au3>
#include <WinAPISysWin.au3>

Local Const $sFilePath = @ScriptDir & "\Assets"
DirCreate($sFilePath)
$assets = @ScriptDir & "\Assets\"
$sysdll = @WindowsDir & "\System32\"
$now = @HOUR & ":" & @MIN
$version="V 5.0"
$ui_width = 826
$ui_height = 474
$left_margin = 20
$top_margin = 20

;-------------------------INSTALLATION DE ICONSET.DLL---------------
$search = FileFindFirstFile(@ScriptDir & "\iconset.dll")
if $search = -1 Then
	SplashTextOn("SortShort " & $version,"Installation de iconset.dll")
	FileInstall(".\iconset.dll", @ScriptDir & "\iconset.dll",1) ; Votre chemin vers le fichier dll a integrer(chemin direct)
    SplashOff()
EndIf
Global $dll_icones_system = @scriptdir & "\iconset.dll"
Global $dll_icones = @scriptdir & "\iconset.dll"
;-------------------------INSTALLATION DE NAVICONES.DLL---------------

$search = FileFindFirstFile(@ScriptDir & "\Assets\cursor.cur")
if $search = -1 Then
	FileInstall(".\Assets\cursor.cur", @ScriptDir & "\Assets\cursor.cur",1)
EndIf

Global $cUI = 0xFFFFFF, $cContent = 0xEEEEEE, $cSearch = 0x6A1B9A ;colors
Global $iconCtrl[4][32] ; tableau 2d des icones
Global $anavilinks ; tableau 2d du fichier link en cours d'utilisation
Global $flag, $flagbutton, $flagbouton
Global $filelink
Global $clic_combo = 0 ; variable (0,1) qui permet de detecter un clic dans la combobox (à épurer)
Global $first_launch = True
Global $IconButton ; l'icone selectionné dans la GUI incone
Global $GuiIcon ; la GUI icone est intergrée à une fonction et detruite lorsqu'elle ne sers plus
Global $section ; id du bouton dans le fichier ini
Global $dll_icones_new
Global $hRichEdit , $hGUI_hypelink
Global $richedit_content
Global $g_hCursor = _WinAPI_LoadCursorFromFile($sFilePath & "\cursor.cur")
Global $ReadComboGuiQuestion
Global $title_GuiQuestion = ""

;~ creation de la gui d'initialisation = image en base 64 dans le code
$logoUi = GUICreate("",640,200, Default, Default, $WS_POPUP) ; sans bordures
$logoPic = GUICtrlCreatePic("", 0, 0, 640, 200); l'image prend toute la gui
_GDIPlus_Startup()
Global Const $Bmp_Logo = _GDIPlus_BitmapCreateFromMemory(initialize_logo(), True); decodage de l'image
_WinAPI_DeleteObject(GUICtrlSendMsg($logoPic, $STM_SETIMAGE, $IMAGE_BITMAP, $Bmp_Logo)); insertion dans la gui
guisetstate(); montre la gui
;~ fin de creation de la gui d'initialisation

$ui = GUICreate("", $ui_width, $ui_height, Default, Default, $WS_POPUP, $WS_EX_CONTROLPARENT + $WS_EX_ACCEPTFILES ); creation de la gui principale
GUISetBkColor($cUI, $ui)

$date = GUICtrlCreateLabel(@MDAY &'/'& @MON &'/'& @YEAR, $left_margin, 0, 100, 20, Default, $GUI_WS_EX_PARENTDRAG)
GUICtrlSetFont(-1, 11, 500, Default, "Segoe UI", 5)

$time = GUICtrlCreateLabel(@HOUR &':'& @MIN, $ui_width/2 - 50, 0, 100, 20, $SS_CENTER, $GUI_WS_EX_PARENTDRAG)
GUICtrlSetFont(-1, 11, 500, Default, "Segoe UI", 5)

$offup = GUICtrlCreateIcon($dll_icones_system,-344, $ui_width-36, 2, 16, 16) ; bouton off en haut à droite
GUICtrlSetCursor(-1, 0)

$minup = GUICtrlCreateIcon($dll_icones_system,-337, $ui_width-54, 2, 16, 16) ; bouton minimiser en haut à droite
GUICtrlSetCursor(-1, 0)

$about = GUICtrlCreateIcon($dll_icones_system,-442, $ui_width-72, 2, 16, 16) ; à propos (idem)
GUICtrlSetCursor(-1, 0)

$winBtn = GUICtrlCreateIcon($dll_icones_system,-425, $left_margin, ($ui_height - ($top_margin*4))+32, 32, 32) ; bouton windows qui permet de retourner au bureau
GUICtrlSetTip(-1,"Afficher le bureau")
GUICtrlSetCursor(-1, 0)

$setBtn = GUICtrlCreateIcon($dll_icones_system,-438, $left_margin+36, ($ui_height - ($top_margin*4))+32, 32, 32) ; bouton cmd
GUICtrlSetTip(-1,"Lancer l'invite de commandes (cmd)")
GUICtrlSetCursor(-1, 0)

$offBtn = GUICtrlCreateIcon($dll_icones_system,-369, $left_margin+(36*2), ($ui_height - ($top_margin*4))+32, 32, 32) ; bouton off (quitte l'application)
GUICtrlSetTip(-1,"Quitter le programme")
GUICtrlSetCursor(-1, 0)

$combo_ajout = GUICtrlCreateIcon($dll_icones_system,-368,($ui_width-$left_margin) - 344, ($ui_height - ($top_margin*4))+32, 32, 32); bouton plus qui crée une nouvelle liste
GUICtrlSetTip(-1,"Créer une nouvelle liste de liens...")
GUICtrlSetCursor(-1, 0)

$combo_suppr = GUICtrlCreateIcon($dll_icones_system,-338,($ui_width-$left_margin) - 384, ($ui_height - ($top_margin*4))+32, 32, 32); supprime la liste en selection (detruit le fichier link)
GUICtrlSetTip(-1,"Supprimer la liste de liens en cours...")
GUICtrlSetCursor(-1, 0)

$findInBk = GUICtrlCreateLabel('', ($ui_width-$left_margin) - 304, ($ui_height - ($top_margin*4))+35, 304, 24)
GUICtrlSetState(-1, $GUI_DISABLE)

$findIn =GUICtrlCreateCombo( "", ($ui_width-$left_margin) - 302, ($ui_height - ($top_margin*4))+35, 300, 20, -1) ; combobox de selection des listes de raccourcis
GUICtrlSetFont(-1, 11, 500, Default, "Segoe UI", 5)
GUICtrlSetColor(-1, $cSearch)
GUICtrlSetOnEvent($findIn, "_charger_combo")


$contentBK = GUICtrlCreateLabel('', $left_margin, $top_margin, ($ui_width - ($left_margin*2)), ($ui_height - ($top_margin*4)))
GUICtrlSetBkColor(-1, $cContent)
GUICtrlSetState(-1, $GUI_DISABLE)

GUISetOnEvent($GUI_EVENT_SECONDARYDOWN, "ClickDroitCandidat"); clic droit
GUISetOnEvent($GUI_EVENT_PRIMARYDOWN, "ClickGaucheCandidat") ; clic gauche
GUISetOnEvent($GUI_EVENT_DROPPED, "dropped") ; Drag and drop de fichiers ou links


;-------------------------  recherche d'un fichier de lien-------------------------------
$search = FileFindFirstFile(@ScriptDir & "\*.link")
if $search = -1 Then ; si aucun lien on va demander à créer une liste
	$nomfichier = InputBox("SortShort " & $version, "Veuillez donner un nom à votre première liste" & @CRLF & "Exemple : 'Mes raccourcis' ")
	if $nomfichier="" then
		msgbox(0,"SortShort " & $version, "Merci de n'avoir pas utilisé ce programme :-)")
		exit
	EndIf
	$filelink = @ScriptDir & "\" & $nomfichier & ".link"
	for $i = 1 to 32
		IniWriteSection($filelink,"bouton" & $i,"label=Libre" & @CRLF & "link=" & @CRLF & "icone=")
	Next
Else
	$filelink = @ScriptDir & "\" & FileFindNextFile($search)
EndIf
Global $arraylink = _FileListToArray(@ScriptDir & "\","*.link"); recherche de tous les fichiers de liens pour alimenter le combo
;-------------------------  recherche d'un fichier de lien-------------------------------

GUIRegisterMsg($WM_COMMAND, "WM_COMMAND") ; gestion de la combobox
refresh_combo() ; au lancement, alimentation du combobox
local $nb_section
Global $anavilinks ; declaration du tableau qui contiendra l'ensemble des données
$ini = @ScriptDir & "\" & GUICtrlRead($findIn) & ".link" ; Lecture du fichier ini qui contient les raccourcis
$sections = IniReadSectionNames($ini) ; lecture de toutes les sections du fichier ini (.link)
if @error <> 0 then $nb_section = 0
if IsArray($sections) then $nb_section = $sections[0]
if $nb_section < 32 Then
	fileopen($ini,1)
	for $i = $nb_section + 1  to 32
		iniwritesection($ini, "bouton" & $i,"label=Libre" & @CRLF & "link=" & @CRLF & "icone=")
	Next
	FileClose($ini)
	$sections = IniReadSectionNames($ini)
EndIf
$nb = $sections[0] ; tableau de toutes les sections
Local $res[$nb+1][4] ; création d'un tableau qui va contenir l'ensemble des liens
$res[0][0] = $nb
For $i = 1 to $nb ; remplissage du tableau $res
   $res[$i][0] = $sections[$i]
   $res[$i][1] = IniRead($ini,$sections[$i],"label","erreur") ; lecture du fichier et remplissage des ruches du tableau
   $res[$i][2] = IniRead($ini,$sections[$i],"link","erreur")
   $res[$i][3] = IniRead($ini,$sections[$i],"icone","erreur")
Next
$anavilinks = $res
; creation de tableaux séparés qui vont nous servir pour remplir la GUI au cours de l'utilisation
Dim $labelNames[33]; tableau des labels
Dim $LinkNames[33]; tableau des liens
Dim $iconNames[33]; tableau des icones

for $i = 1 to 32; tableau général contenant tous les tableaux précédents
	$labelNames[$i] = $anavilinks[$i][1]
	$LinkNames[$i] = $anavilinks[$i][2]
	$iconNames[$i] = $anavilinks[$i][3]
Next

$x = $left_margin+2 ; fabrication de la gui principale
$y = $top_margin+2
$iconID = 0
For $i=0 to 3; remplissage de la GUI avec les icones et labels
	For $j = 0 To 7
		$box = GUICtrlCreateLabel("", $x, $y, 96, 96) ; taille du label situé sous l'icone
		GUICtrlSetBkColor(-1, $cUI)
		GUICtrlSetState(-1, $GUI_DISABLE)
		$icon_new = StringSplit($iconNames[$iconID+1],",") ; si l'icone provient d'une dll ou d'un exe
		$icon_ico = StringSplit($iconNames[$iconID+1],".") ; si l'icone provient d'un fichier ico
		if $icon_new[0] >1 Then ; si il y a une icone
			$iconCtrl[0][$iconID] = GUICtrlCreateIcon($icon_new[1],number($icon_new[2]), $x+16, $y+16, 64, 64) ; creation de l'icone en taille 64
			GUICtrlSetTip($iconCtrl[0][$iconID],$LinkNames[$iconID+1], $labelNames[$iconID+1]) ; au passage de la souris on donne les infos sur l'icone
		Elseif $icon_ico[0] >1 Then ;
			$iconCtrl[0][$iconID] = GUICtrlCreateIcon($icon_ico[1] & "." & $icon_ico[2], default, $x+16, $y+16, 64, 64) ; si c'est un fichier ico le traitement est different
			if $iconCtrl[0][$iconID] = 0 then $iconCtrl[0][$iconID] = GUICtrlCreateIcon($dll_icones_system, 327, $x+16, $y+16, 64, 64)
			GUICtrlSetTip($iconCtrl[0][$iconID],$LinkNames[$iconID+1], $labelNames[$iconID+1])
		Else
			$iconCtrl[0][$iconID] = GUICtrlCreateIcon($dll_icones_system,80, $x+16, $y+16, 64, 64) ; si l'emplacement est libre on met une icone blanche (pour pouvoir cliquer dessud)
			GUICtrlSetTip(-1,"Cliquez ou déposez (fichier/dossier/raccourcis) pour créer un nouveau lien")
			GUICtrlSetState (-1, $GUI_DROPACCEPTED) ; pour le drag and drop uniquement sur les emplacements libres
		EndIf
		GUICtrlSetCursor(-1, 0) ; curseur main sur chaque emplacement
		$iconCtrl[1][$iconID] = GUICtrlCreateLabel(_String_cut_with_dots($labelNames[$iconID+1]), $x+6, $y+80, 90, 16, $SS_CENTERIMAGE + $SS_CENTER) ; label de l'icone mais coupé si il est trop grand
		$iconCtrl[2][$iconID] = $x + 16 ; sauvegarde de la position des icones dans la GUI pour utilisation ulterieure (non devellopée)
		$iconCtrl[3][$iconID] = $y + 16
		GUICtrlSetBkColor(-1, -2)
		GUICtrlSetFont(-1, 6.5, 700, Default, "Comic Sans Ms", 5)
		GUICtrlSetCursor(-1, 0)
		$x += 98
		$iconID +=1
		$icon = ""
	Next
	$x = $left_margin+2
	$y += 98
Next
;_ArrayDisplay($iconCtrl)

;----------------------------GUI QUESTION----------------------------------------------
$gui_question = GUICreate($title_GuiQuestion , 345, 300, 192, 125) ; Gui qui permet de créer, modifier ou supprimer un lien en faisant un clic gauche ou droit
GUISetBkColor($cUI, $gui_question)
$checkbox_internet = GUICtrlCreateCheckbox("Hyperlien (lien vers site web)", 20, 7, 160, 40)
GUICtrlSetOnEvent(-1, "check_internet") ; checkbox qui permettent de savoir ce qu'il y a faire
$checkbox_Fichier= GUICtrlCreateCheckbox("Lien vers fichier", 20, 47, 120, 40)
GUICtrlSetOnEvent(-1, "check_fichier")
$checkbox_dossier= GUICtrlCreateCheckbox("Lien vers dossier",20, 87, 120, 40)
GUICtrlSetOnEvent(-1, "check_dossier")
$checkbox_nothing=GUICtrlCreateCheckbox("Supprimer le lien",  20, 127, 120, 40)
GUICtrlSetOnEvent(-1, "check_nothing")
$btn1 = GUICtrlCreateButton("Valider", 240, 250, 80, 25)
GUICtrlSetOnEvent(-1, "valider_guiquestion")
$Checkbox_icone = GUICtrlCreateCheckbox("Changer l'icône", 20, 167, 192, 40)
GUICtrlSetOnEvent(-1, "check_icone")
$checkbox_moveto = GUICtrlCreateCheckbox("Déplacers vers (Sélectionnez la liste)", 20, 207, 192, 40)
GUICtrlSetOnEvent(-1, "check_moveto")
$combo_GuiQuestion =GUICtrlCreateCombo("",20,250,192,40)
GUICtrlSetOnEvent(-1,"_read_combo_GuiQuestion")
GUICtrlSetState($combo_GuiQuestion,$GUI_DISABLE)
GUICtrlSetColor(-1, $cSearch)
$icon_GuiQuestion = GUICtrlCreateIcon($dll_icones_system,80, 250,10, 64, 64)
;----------------------------GUI QUESTION----------------------------------------------

WinSetTrans($ui, Default, 0); set transparent to 0
GUISetState(@SW_SHOW, $ui); show GUI (but unvisible)
_GUI_Incones() ; la gui icone est crée en arrière plan également
_WinAPI_DeleteObject($Bmp_Logo) ; debut de suppression de la GUI d'initalisation
_GDIPlus_Shutdown() ; on quitte la ressource GDI dont on a plus besoin
_Transparent("show", $ui); on affiche la principale
_Transparent("hide",$logoUi); on efface lentement la gui d'initailisation
GUIDelete($logoUi) ; et on la detruit


While 1
	If $now <> @HOUR & ":" & @MIN Then ; gestion de l'heure et de la date dans le bandeau haut de la GUI principale
		$now = @HOUR & ":" & @MIN
		$date1 = @MDAY &'/'& @MON &'/'& @YEAR
		GUICtrlSetData($time, $now)
		GUICtrlSetData($date, $date1)
	EndIf

	sleep(100) ; en dessous trop de conso
WEnd

Func _ajout_liste(); permet d'ajouter de listes dans le programme
    $nomfichier = InputBox("SortShort " & $version, "Veuillez donner un nom  à cette liste" & @CRLF & "Exemple : 'Raccourcis ministère' ")
    if @error <> 0 or $nomfichier = "" then Return
    if _CheckForbidden($nomfichier) <> 0 Then ; si le nom de fichier contient des caractères interdits
        msgbox (64,"SortShort " & $version, "Erreur, le nom comporte des caractères interdits :"& @CRLF & '["/\\*?<>|:]',2)
        Return
    EndIf
    $filelink = @ScriptDir & "\" & $nomfichier & ".link"
    if FileFindFirstFile($filelink) <> -1 Then ; test si le fichier existe, si - 1 rien est trouvé
        local $messagefile = msgbox(4,"SortShort " & $version, "Un fichier portant le même nom existe déjà " & @CRLF & " Voulez vous l'ecraser ?")
        if $messagefile = 6  Then
            ecrireFichier($filelink)
            MsgBox(64,"SortShort " & $version, "La liste : " & $nomfichier & " a été ajoutée",2)
        Else
            Return
        EndIf
    Else
        ecrireFichier($filelink)
        MsgBox(64,"SortShort " & $version, "La liste : " & $nomfichier & " a été ajoutée",2)
    EndIf
EndFunc

func apropos()
	Msgbox(64,"A propos...","SortShort "& "version : " & $version & @CRLF & "Concept & developpement : Marc GRAZIANI (Août 2020)" & @CRLF & _
			"- Drag and Drop des fichiers/Dossiers pour créer une tuile" & @CRLF & _
			"- Drag and Drop d'hyperlien (web)" & @CRLF & _
			"- Clic droit sur une tuile utilisée pour la gérer" & @CRLF & _
			"- Possibilité de déplacer les tuiles dans l'interface grâce au CTRL + CLIC + Glisser/déposer" & @crlf & _
			"- Possibilité de déplacer les tuiles entre les listes (clic droit sur tuile existante)")
EndFunc

Func _Base64Decode($input_string)
    Local $struct = DllStructCreate("int")
    Local $a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", "str", $input_string, "int", 0, "int", 1, "ptr", 0, "ptr", DllStructGetPtr($struct, 1), "ptr", 0, "ptr", 0)
    If @error Or Not $a_Call[0] Then Return SetError(1, 0, "")
    Local $a = DllStructCreate("byte[" & DllStructGetData($struct, 1) & "]")
    $a_Call = DllCall("Crypt32.dll", "int", "CryptStringToBinary", "str", $input_string, "int", 0, "int", 1, "ptr", DllStructGetPtr($a), "ptr", DllStructGetPtr($struct, 1), "ptr", 0, "ptr", 0)
    If @error Or Not $a_Call[0] Then Return SetError(2, 0, "")
    Return DllStructGetData($a, 1)
EndFunc   ;==>_Base64Decode

func _charger_combo()
	local $nb_section
	Local $ini = @ScriptDir & "\" & GUICtrlRead($findIn) & ".link" ; Lecture du fichier ini
	$filelink = $ini
	local $sections = IniReadSectionNames($ini) ; lecture de toutes les sections
	if @error <> 0 then $nb_section = 0
	if IsArray($sections) then $nb_section = $sections[0]
	if $nb_section < 32 Then
		fileopen($ini,1)
		for $i = $nb_section + 1  to 32
			iniwritesection($ini, "bouton" & $i,"label=Libre" & @CRLF & "link=" & @CRLF & "icone=")
		Next
		FileClose($ini)
		$sections = IniReadSectionNames($ini)
	EndIf
	local $nb = $sections[0]
	Local $res[$nb+1][4]
	$res[0][0] = $nb
	For $i = 1 to $nb ; création du tableau 2D
		$res[$i][0] = $sections[$i]
		$res[$i][1] = IniRead($ini,$sections[$i],"label","erreur") ; lecture des labels et alimentation du tableau
		$res[$i][2] = IniRead($ini,$sections[$i],"link","erreur")
		$res[$i][3] = IniRead($ini,$sections[$i],"icone","erreur")

	Next
	local $alinks = $res
	Local $labelNames[33]
	Local $LinkNames[33]
	Local $iconNames[33]
	for $i = 1 to 32
		$labelNames[$i] = $alinks[$i][1]
		$LinkNames[$i] = $alinks[$i][2]
		$iconNames[$i] = $alinks[$i][3]
	Next
	$iconID = 0
	For $i=0 to 3
		For $j = 0 To 7
			$icon_new = StringSplit($iconNames[$iconID+1],",")
			$icon_ico = StringSplit($iconNames[$iconID+1],".")
			if $icon_new[0] > 1 Then
				GUICtrlSetImage($iconCtrl[0][$iconID],$icon_new[1],Number($icon_new[2]), 1)
				GUICtrlSetTip($iconCtrl[0][$iconID],$LinkNames[$iconID+1], $labelNames[$iconID+1])
			Elseif $icon_ico[0] > 1 Then
				Local $image = GUICtrlSetImage($iconCtrl[0][$iconID],$icon_ico[1] & "." & $icon_ico[2])
				if $image = 0 then GUICtrlSetImage($iconCtrl[0][$iconID],$dll_icones_system,327)
				GUICtrlSetTip($iconCtrl[0][$iconID],$LinkNames[$iconID+1], $labelNames[$iconID+1])
			Else
				GUICtrlSetImage($iconCtrl[0][$iconID],$dll_icones_system,80)
				GUICtrlSetTip($iconCtrl[0][$iconID],"Cliquez ou déposez (fichier/dossier/raccourcis) pour créer un nouveau lien")
				GUICtrlSetState ($iconCtrl[0][$iconID], $GUI_DROPACCEPTED)
			EndIf
			GUICtrlSetData($iconCtrl[1][$iconID],_String_cut_with_dots($labelNames[$iconID+1]))
			GUICtrlSetCursor(-1, 0)
			$iconID +=1
		Next
	Next
	$anavilinks = $alinks
EndFunc

Func check_dossier()
	GUICtrlSetState($checkbox_Fichier,$GUI_UNCHECKED) ; permet de n'avoir qu'une seule case cochée
	GUICtrlSetState($checkbox_internet,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_nothing,$GUI_UNCHECKED)
	GUICtrlSetState($Checkbox_icone,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_moveto,$GUI_UNCHECKED)
	GUICtrlSetState($btn1,$GUI_ENABLE)
	GUICtrlSetState($combo_GuiQuestion,$GUI_DISABLE)

	$flag= "dossier" ; le $flag permet de savoir ce qu'il y a à faire dans la fonction faislien()
EndFunc

func check_fichier()
	GUICtrlSetState($checkbox_dossier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_internet,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_nothing,$GUI_UNCHECKED)
	GUICtrlSetState($Checkbox_icone,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_moveto,$GUI_UNCHECKED)
	GUICtrlSetState($btn1,$GUI_ENABLE)
	GUICtrlSetState($combo_GuiQuestion,$GUI_DISABLE)
	$flag="fichier"
EndFunc

Func _CheckForbidden($string) ; vérification qu'une string ne contienne pas des caractères interdits
	Local $pattern_forbid = '["/\\*?<>|:]'
	$string = StringRegExp($string, $pattern_forbid)
	_DebugPrint("CHECKSTRING" & @CRLF & _
				"--> $pattern " & @TAB & $string)
	Return  $string
EndFunc

func check_icone()
	GUICtrlSetState($checkbox_Fichier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_internet,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_dossier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_nothing,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_moveto,$GUI_UNCHECKED)
	GUICtrlSetState($btn1,$GUI_ENABLE)
	GUICtrlSetState($combo_GuiQuestion,$GUI_DISABLE)
	$flag="iconbutton"
EndFunc

func check_internet()
	GUICtrlSetState($checkbox_Fichier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_dossier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_nothing,$GUI_UNCHECKED)
	GUICtrlSetState($Checkbox_icone,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_moveto,$GUI_UNCHECKED)
	GUICtrlSetState($btn1,$GUI_ENABLE)
	GUICtrlSetState($combo_GuiQuestion,$GUI_DISABLE)
	$flag="internet"
EndFunc

Func _Check_LabelForbidden($string)
	if $string = "Libre" then $string = 1
	_DebugPrint("CHECKSTRING" & @CRLF & _
				"--> $pattern " & @TAB & $string)
	Return  $string
EndFunc

func check_nothing()
	GUICtrlSetState($checkbox_Fichier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_internet,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_dossier,$GUI_UNCHECKED)
	GUICtrlSetState($Checkbox_icone,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_moveto,$GUI_UNCHECKED)
	GUICtrlSetState($btn1,$GUI_ENABLE)
	GUICtrlSetState($combo_GuiQuestion,$GUI_DISABLE)
	$flag="Suppression"
EndFunc

func check_moveto()
	Local $name
	GUICtrlSetState($checkbox_Fichier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_internet,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_dossier,$GUI_UNCHECKED)
	GUICtrlSetState($Checkbox_icone,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_nothing,$GUI_UNCHECKED)
	GUICtrlSetState($btn1,$GUI_DISABLE)
	GUICtrlSetState($combo_GuiQuestion,$GUI_ENABLE)
	For $i=1 To Ubound($arraylink)-1
			$name = stringsplit($arraylink[$i],".")
			GUICtrlSetData($combo_GuiQuestion,$name[1])
	Next
	$flag="MoveTo"
EndFunc


Func ClickGaucheCandidat() ; quand on clique dans la GUI pricipale
	Local $a
	$a = GUIGetCursorInfo(@GUI_WinHandle) ; on récupère les infos du curseur et surtout l'id cliqué qui va permettre de savoir sur quel bouton j'agis
	if $a[4]==0 then Return ; si on clique sur les bords de la GUI
	if _IsPressed("11") then _MoveTile()
	Local $cursor_info = MouseGetCursor() ; recupère le type de curseur
	if $cursor_info <> 0 and not _IsPressed("11") then Return ; si le curseur est different de la main on sort
	local $link = $anavilinks
	For $i = 0 To uBound($iconCtrl, 2)-1 ; clic dans une des cases de liens
		If $a[4] == $iconCtrl[0][$i] Or $a[4] == $iconCtrl[1][$i] and not _ispressed("11") Then ; Detection du clic sur les liens
			$flagbouton = $anavilinks[$i+1][2] ; le label de l'icone
			if $anavilinks[$i+1][1] = "Libre" Then ; si le lien est libre
				GUICtrlSetState($Checkbox_icone,$GUI_DISABLE)
				GUICtrlSetState($checkbox_moveto,$GUI_DISABLE)
				GUICtrlSetState($checkbox_nothing, $GUI_DISABLE)
				$flagbouton = $anavilinks[$i+1][0]; la valeur flagbouton est mise sur le bouton (1 à 32)
				$section = $flagbouton
				uncheckall(); deselectionne toutes les checkbox
				$title_GuiQuestion = "Création d'un nouveau lien"
				WinSetTitle($gui_question,"",$title_GuiQuestion)
				GUICtrlSetImage($icon_GuiQuestion,$dll_icones_system,80)
				WinSetTrans($ui, Default, 160 )
				GUISwitch($gui_question)
				GUISetState(@SW_SHOW, $gui_question) ; on passe la main pour savoir que faire
				GUISetOnEvent($GUI_EVENT_CLOSE, "LinkCreateEvents") ; en cas de fermeture
				ExitLoop ; sortie de la boucle
			EndIf
			Local $aEnv = StringSplit($flagbouton,"\") ; recuperer le dossier d'execution du programme
			local $sEnv
			For $i = 1 to UBound($aEnv)-2
				$sEnv = $sEnv & $aEnv[$i] & "\"
			Next
			$sEnv = StringTrimright($sEnv,1)
			ShellExecute($flagbouton,"",$sEnv) ; execution du lien $flagbouton
			ExitLoop
		EndIf
	Next
	if $a[4] == $offBtn or $a[4] == $offup then quitter() ; gestion des autres boutons de la GUI
	if $a[4] == $combo_ajout then _ajout_liste()
	if $a[4] == $combo_suppr then _suppr_liste()
	if $a[4] == $winBtn then _returnToDesktop()
	if $a[4] == $setBtn then _rundos("start")
	if $a[4] == $minup then _minimize()
	if $a[4] == $about then apropos()
	_DebugPrint("CLIC GAUCHE" & @CRLF & _
				"--> clic_combo:" & @TAB & $clic_combo & @crlf & _
				"--> quel bouton ? :" & @tab & $a[4] & @CRLF & _
				"--> $cursor_info" & @TAB & $cursor_info )

EndFunc

Func ClickDroitCandidat() ; zen cas de clic droit
	GUICtrlSetState($Checkbox_icone, $GUI_ENABLE)
	GUICtrlSetState($checkbox_moveto, $GUI_ENABLE)
	GUICtrlSetState($checkbox_nothing, $GUI_ENABLE)
	uncheckall()
	Local $a
	$a = GUIGetCursorInfo(@GUI_WinHandle) ; recuperation des infos de la souris
	For $i = 0 To UBound($iconCtrl, 2)-1
		If $a[4] = $iconCtrl[0][$i] Or $a[4] = $iconCtrl[1][$i] and $anavilinks[$i+1][1] <> "Libre" then
			$flagbouton = $anavilinks[$i+1][0]; fait la correspondance entre l'icone cliqué et le bouton du fichier ini en cours
			$section =$flagbouton
			$title_GuiQuestion = "Modification du lien..."
			WinSetTitle($gui_question,"",$title_GuiQuestion)
			consolewrite($anavilinks[$i+1][3])
			$icon_new = StringSplit($anavilinks[$i+1][3],",")
			$icon_ico = StringSplit($anavilinks[$i+1][3],".")
			if $icon_new[0] > 1 Then
				GUICtrlSetImage($icon_GuiQuestion,$icon_new[1],Number($icon_new[2]), 1)
			Elseif $icon_ico[0] > 1 Then
				Local $image = GUICtrlSetImage($icon_GuiQuestion , $icon_ico[1] & "." & $icon_ico[2])
				if $image = 0 then GUICtrlSetImage($icon_GuiQuestion,$dll_icones_system,327)
			EndIf
			WinSetTrans($ui, Default, 160 )
			GUISwitch($gui_question)
			GUISetState(@SW_SHOW, $gui_question)
			GUISetOnEvent($GUI_EVENT_CLOSE, "LinkCreateEvents")
		EndIf
	Next
EndFunc   ;==>ClickDroitCandidat

func clicicone() ; fonction de la gui icones, permet de selectionner une icone
	global $Icon = GUICtrlRead(@GUI_CtrlId)
	$image = GUICtrlSetImage($IconButton, $dll_icones_new, $Icon)
	_DebugPrint("clicicone" & @CRLF & "-->$dll_icones:" & @TAB & $dll_icones_new)
EndFunc

func close_iconset() ; fermeture de la gui de selection d'une icone
	;GUIDelete($GuiIcon)
	GUISetState(@SW_HIDE,$GuiIcon)
	GUISwitch($ui)
EndFunc

func close_hyperlinkGui() ; fermeture de la gui de selection d'une icone
	_GUICtrlRichEdit_Destroy($hRichEdit)
	GUIDelete($hGUI_hypelink)
	GUISwitch($ui)
	WinSetOnTop($ui, "", $WINDOWS_ONTOP)
	WinSetOnTop($ui, "", $WINDOWS_NOONTOP)
EndFunc

Func _DebugPrint($s_Text , $sLine = @ScriptLineNumber) ; pour le debuggage
    ConsoleWrite( _
            "!===========================================================" & @CRLF & _
            "+======================================================" & @CRLF & _
            "-->Line(" & StringFormat("%04d", $sLine) & "):" & @TAB & $s_Text  & @CRLF & _
            "+======================================================" & @CRLF)
EndFunc   ;==>_DebugPrint

func dropped() ; gestion du drag and drop
	Global $link_dropped ; variable pour passer le fichier déposé
	global $iconToPlaceOn
	$a = @GUI_DropId ; recuperation de l'id de la case où on dépose le fichier
	For $i = 0 To uBound($iconCtrl, 2)-1
		If $a == $iconCtrl[0][$i] Or $a == $iconCtrl[1][$i] Then
			if $anavilinks[$i+1][1] = "Libre" Then ; si c'est libre
				$flag="Drag_n_Drop" ; pour la fonction faislien()
				Global $link_DnD = @GUI_DragFile ; le fichier qui est déposé
				local $sExt = StringRegExpReplace($link_DnD, "^.*\.", "") ; extraction de son extension
				_DebugPrint("dropped" & @CRLF & "-->$sExt" & @TAB & $sExt)
				local $sExt_count = stringlen($sExt)
				if $sExt_count > 4 then $sExt = "Folder"
				Switch $sExt
					Case "lnk" ; si c'est un fichier lnk (lien)
						If Not @error Then
							$link_dropped = @GUI_DragFile ; utilisé pour le label de l'icone dans faislien
							Local $alink_DnD = FileGetShortcut($link_DnD) ; on retouve le fichier source du raccourcis déposé
							$link_DnD = $alink_DnD[0] ; dans un tableau a l'idex 0
							_DebugPrint("Fichier Lnk dropped" & @CRLF & "-->Fichier :" & @TAB & $alink_DnD[0] & @CRLF & _
										"Répertoire de travail :" & @TAB & $alink_DnD[1])
						Else
							$link_DnD = @GUI_DragFile
							$link_dropped = @GUI_DragFile

						EndIf
					case "doc" , "docx" , "odt"
						$link_DnD = @GUI_DragFile
						$link_dropped = @GUI_DragFile
						$iconToPlaceOn = "WordIcon"
						_DebugPrint("Filextention" & @CRLF & "-->extension :" & @TAB & $iconToPlaceOn)

					case "xls" , "xlsx" , "ods"
						$link_DnD = @GUI_DragFile
						$link_dropped = @GUI_DragFile
						$iconToPlaceOn = "ExcelIcon"
						_DebugPrint("Filextention" & @CRLF & "-->extension :" & @TAB & $iconToPlaceOn)

					case "pdf"
						$link_DnD = @GUI_DragFile
						$link_dropped = @GUI_DragFile
						$iconToPlaceOn = "PdfIcon"
						_DebugPrint("Filextention" & @CRLF & "-->extension :" & @TAB & $iconToPlaceOn)

					Case "ppt" , "pptx" , "odp"
						$link_DnD = @GUI_DragFile
						$link_dropped = @GUI_DragFile
						$iconToPlaceOn = "PowerPtIcon"
						_DebugPrint("Filextention" & @CRLF & "-->extension :" & @TAB & $iconToPlaceOn)

					Case "txt", "rtf"
						$link_DnD = @GUI_DragFile
						$link_dropped = @GUI_DragFile
						$iconToPlaceOn = "TxtIcon"
						_DebugPrint("Filextention" & @CRLF & "-->extension :" & @TAB & $iconToPlaceOn)

					Case "Folder"
						$link_DnD = @GUI_DragFile
						$link_dropped = @GUI_DragFile
						$iconToPlaceOn = "IsAFolder"
						_DebugPrint("Filextention" & @CRLF & "-->extension :" & @TAB & $iconToPlaceOn)
					Case "html" , "htm" , "asp"
						$link_DnD = @GUI_DragFile
						$link_dropped = @GUI_DragFile
						$iconToPlaceOn = "IsWebPage"

					Case Else
						$link_dropped = @GUI_DragFile ; pour tous les autres types d'extention (exe, xls, pdf...)
						$link_DnD = @GUI_DragFile
						$iconToPlaceOn = "unknow"
						_DebugPrint("Filextention" & @CRLF & "-->Extension is " & @TAB & $sExt & @crlf & _
									"Nombre de caractères : " & @TAB & $sExt_count & @crlf & _
									"Lien dropped :" & @TAB & $link_DnD)
				EndSwitch
				$flagbouton = $anavilinks[$i+1][0]
				$section = $flagbouton
				Faislien($flagbouton,$flag, $iconToPlaceOn)
				_DebugPrint("ENSWITCH" & @CRLF & "-->Extension is " & @TAB & $sExt & @crlf & _
							"Nombre de caractères : " & @TAB & $sExt_count & @crlf & _
							"Lien dropped :" & @TAB & $link_DnD)
			EndIf
			Return
		EndIf
	Next

EndFunc

func ecrireFichier($nomfichier) ; ecriture du fichier .link vide
	for $i = 1 to 32
		IniWriteSection($nomfichier,"bouton" & $i,"label=Libre" & @crlf & "link=" & @CRLF & "icone=")
	Next
	GUICtrlSetData($findIn,"")
	$arraylink=""
	$arraylink=_FileListToArray(@ScriptDir & "\","*.link")
	refresh_combo() ; suite au changement il faut rafraichir la liste
	_charger_combo() ; et recharger les icones
EndFunc

Func Faislien($section,$lien="",$iconToPlaceOn="") ; permet de créer les liens
	Switch $lien
		Case "fichier" ; le lien est un fichier selectionné via fileopendialog()
			$choose = FileOpenDialog("Selectionner un fichier",@DesktopCommonDir ,"tous les fichiers (*.*)"); gestion de la selection du fichier
			if @error  <> 0 then Return
			$ProposeLink = stringsplit($choose,"\")
			$ProposeLink = StringRegExpReplace($ProposeLink[UBound($ProposeLink)-1], '(.*)\..*', "$1")
			$reponse = InputBox("Nom de l'icone","Donnez un titre à l'icone !",$ProposeLink); quel label aura le raccourcis
			if @error == 1 or $reponse = "" or _Check_LabelForbidden($reponse) <> 0 Then ; si le nom de fichier contient des caractères interdits
				msgbox (64,"SortShort " & $version, "Erreur, vous ne pouvez pas mettre ce Label :" & $reponse,2)
				Return
			EndIf
			iniwrite($filelink,$section,"label",$reponse); tout est ok on peut ecrire la valeur dans le fichier de config
			IniWrite($filelink,$section,"link", $choose); on peut ecrire le chemin du fichier dans la configuration
			local $sExt = StringRegExpReplace($choose, "^.*\.", "") ; extraction de son extension
			Switch $sExt
				case "doc" , "docx" , "odt"
					IniWrite($filelink,$section,"icone",$dll_icones_system &",436")
					_charger_combo()

				case "xls" , "xlsx" , "ods"
					IniWrite($filelink,$section,"icone",$dll_icones_system &",441")
					_charger_combo()

				case "pdf"
					IniWrite($filelink,$section,"icone",$dll_icones_system &",400")
					_charger_combo()

				Case "ppt" , "pptx" , "odp"
					IniWrite($filelink,$section,"icone",$dll_icones_system &",431")
					_charger_combo()

				Case "txt" , "rtf"
					IniWrite($filelink,$section,"icone",$dll_icones_system &",406")
					_charger_combo()

				Case Else
					if _WinAPI_ExtractIconEx( $choose,-1,0,0,0) > 0 Then ; permet de tester si le fichier possède une ou plusiers icone(s)
						Local $aIcon[3] = [64, 32, 16]
						For $i = 0 To UBound($aIcon) - 1
							$aIcon[$i] = _WinAPI_Create32BitHICON(_WinAPI_ShellExtractIcon($choose,0, $aIcon[$i], $aIcon[$i]), 1)
						Next
						_WinAPI_SaveHICONToFile(@ScriptDir & "\Assets\" & $reponse & ".ico", $aIcon)
						For $i = 0 To UBound($aIcon) - 1
							_WinAPI_DestroyIcon($aIcon[$i])
						Next
						IniWrite($filelink,$section,"icone",@ScriptDir & "\Assets\" & $reponse & ".ico"); si oui écriture dans le fichier
						_charger_combo()
					Else
						$flag = "iconbutton"
						iconbutton()
						GUISwitch($ui)
					EndIf
			EndSwitch

		case "dossier" ; le lien est un dossier selection via fileselectfolder()
			$choose=FileSelectFolder("Choisissez un dossier", @HomeDrive) ; on fais la même chose avec le dossier
			if @error <> 0 or $choose = "" then Return
			$ProposeLink= stringsplit($choose,"\") ; proposition par defaut le nom de l'executable
			$reponse = InputBox("Nom de l'icone","Donnez un titre à l'icone !",$ProposeLink[UBound($ProposeLink)-1]); quel label aura le raccourcis
			if @error == 1 or $reponse = "" or _Check_LabelForbidden($reponse) <> 0 Then ; si le nom de fichier contient des caractères interdits
				msgbox (64,"SortShort " & $version, "Erreur, vous ne pouvez pas mettre ce Label :" & $reponse,2)
				Return
			EndIf
			iniwrite($filelink,$section,"label",$reponse)
			IniWrite($filelink,$section,"link", $choose)
			IniWrite($filelink,$section,"icone",$dll_icones_system &",153")
			_charger_combo()

		Case "internet" ; le lien hyperlink
			_GUI_hyperlink()

		Case "Suppression" ; supression d'un lien
			$suppr = msgbox(1,"SortShort " & $version,"Etes vous sur de vouloir supprimer cette tuile ?")
			if $suppr == 2  then Return
			Local $lect_icone = IniRead($filelink, $section,"icone","Erreur")
			if StringRegExpReplace($lect_icone, "^.*\.", "") = "ico" then FileDelete($lect_icone); supression de la ressource inutilisée
			iniwrite($filelink,$section,"label","Libre")
			IniWrite($filelink,$section,"link", "")
			IniWrite($filelink, $section,"icone","")
			_charger_combo()

		Case "Drag_n_Drop" ; lien créé via glisser déposer
			$choose = $link_dropped ; le fichier lnk
			$ProposeLink = stringsplit($choose,"\")
			$ProposeLink = StringRegExpReplace($ProposeLink[UBound($ProposeLink)-1], '(.*)\..*', "$1") ; on choisis le nom du fichier en proposition
			$reponse = InputBox("Nom du lien","Donnez un titre au lien que vous venez de poser !",$ProposeLink)
            if @error == 1 or $reponse = "" or _Check_LabelForbidden($reponse) <> 0 Then ; si le nom de fichier contient des caractères interdits
				msgbox (64,"SortShort " & $version, "Erreur, vous ne pouvez pas mettre ce Label :" & $reponse,2)
				Return
			EndIf
			iniwrite($filelink,$section,"label",$reponse)
			IniWrite($filelink,$section,"link", $link_DnD) ; le raccourcis mis en place pointe directement vers le fichier
			if _WinAPI_ExtractIconEx( $link_DnD,-1,0,0,0) > 0 Then ; permet de tester si le fichier possède une ou plusiers icone(s); on teste pour voir si il y a une icone dans le fichier
				Local $aIcon[3] = [64, 32, 16]; si oui
				For $i = 0 To UBound($aIcon) - 1
					$aIcon[$i] = _WinAPI_Create32BitHICON(_WinAPI_ShellExtractIcon($link_DnD,0, $aIcon[$i], $aIcon[$i]), 1)
				Next
				_WinAPI_SaveHICONToFile(@ScriptDir & "\Assets\" & $reponse & ".ico", $aIcon) ; elle est extraite en fichier ico et sauvegardé dans le répertoire assets
				For $i = 0 To UBound($aIcon) - 1
					_WinAPI_DestroyIcon($aIcon[$i])
				Next
                IniWrite($filelink,$section,"icone",@ScriptDir & "\Assets\" & $reponse & ".ico")
				_charger_combo()
			ElseIf $iconToPlaceOn <> "" Then
				_DebugPrint("CASE DRAG AND DROP FAIS LIEN" & @CRLF & "-->extension :" & @TAB & $iconToPlaceOn)
				switch $iconToPlaceOn
					Case "WordIcon"
						IniWrite($filelink,$section,"icone",$dll_icones_system &",436")
						_charger_combo()
					Case "ExcelIcon"
						IniWrite($filelink,$section,"icone",$dll_icones_system &",441")
						_charger_combo()
					Case "PdfIcon"
						IniWrite($filelink,$section,"icone",$dll_icones_system &",400")
						_charger_combo()
					case "PowerPtIcon"
						IniWrite($filelink,$section,"icone",$dll_icones_system &",431")
						_charger_combo()
					Case "TxtIcon"
						IniWrite($filelink,$section,"icone",$dll_icones_system &",406")
						_charger_combo()
					Case "IsAFolder"
						IniWrite($filelink,$section,"icone",$dll_icones_system &",153")
						_charger_combo()
					Case "IsWebPage"
						IniWrite($filelink,$section,"icone",$dll_icones_system &",221")
						_charger_combo()
					Case "unknow"
						;uncheckall()
						$flag = "iconbutton"
						iconbutton()
						GUISwitch($ui)

				EndSwitch
			EndIf
		Case "MoveTo"
			Local $selection, $flagbouton_destination , $FlagMvt = False
			local $ini = $ReadComboGuiQuestion ; Lecture du fichier ini qui contient les raccourcis
			local $section_ini = IniReadSectionNames($ini) ; lecture de toutes les sections du fichier ini (.link)
			;_ArrayDisplay($section_ini)
			For $i = 1 to UBound($section_ini) -1
				consolewrite( $i & "--")
				$selection = IniRead($ReadComboGuiQuestion,$section_ini[$i],"label","Erreur")
				if $selection = "libre" then
					$flagbouton_destination = $section_ini[$i]
					$FlagMvt = True
					ExitLoop
				Else
					if $selection <> "Libre" and $i > 31 Then
						MsgBox(64,"SortShort " & $version, "Plus aucun emplacement libre sur la liste selectionnée, veuillez en utiliser une autre.")
						Return
					endif
				EndIf

			Next
			if $FlagMvt = True Then
				$lectIniSource_label = IniRead($filelink,$flagbouton,"label","Erreur")
				$lectIniSource_link = IniRead($filelink,$flagbouton,"link","Erreur")
				$lectIniSource_icone = iniread($filelink,$flagbouton,"icone","Erreur")

				iniwrite($ReadComboGuiQuestion,$flagbouton_destination,"label",$lectIniSource_label) ; ecriture des tuiles d'arrivée
				iniwrite($ReadComboGuiQuestion,$flagbouton_destination,"link",$lectIniSource_link)
				iniwrite($ReadComboGuiQuestion,$flagbouton_destination,"icone",$lectIniSource_icone)

				iniwrite($filelink,$flagbouton,"label","Libre") ; effacement des tuiles de départ
				iniwrite($filelink,$flagbouton,"link","")
				iniwrite($filelink,$flagbouton,"icone","")

				_charger_combo()
			EndIf
			_DebugPrint("Moveto" & @CRLF & "--> id selectionné:" & @TAB & $flagbouton & @crlf & _
						"LISTE SOURCE :" & @TAB & $filelink & @CRLF & _
						"LISTE DESTINATION :" & @TAB & $ReadComboGuiQuestion & @CRLF & _
						"BOUTON DESTINATION :" & @TAB & $flagbouton_destination)
	EndSwitch
	$lien=""
	$iconToPlaceOn=""
EndFunc

Func _Find_icon() ; bouton de la gui_icone qui permet de selectionner un autre fichier contenant une ou des icones
	GUISetState(@SW_HIDE, $GuiIcon)
	$result = FileOpenDialog("Choisir un fichier",@HomeDrive,"Fichiers dll (*.dll)| Fichier icône (*.ico;*.exe)",1)
	if @error <> 0 then
		GUISetState(@SW_SHOW,$GuiIcon)
		Return
	EndIf
	$sExt = StringRegExpReplace($result, "^.*\.", "") ; test de l'extension du fichier choisi
	$sFile = StringSplit($result,"\")
	$sFile = StringRegExpReplace($sFile[UBound($sFile)-1], '(.*)\..*', "$1")
	_DebugPrint("FIND ICON" & @CRLF & "--> extension:" & @TAB & $sExt )
	Switch $sExt
		Case "dll"
			GUIDelete($GuiIcon) ; suppression de la gui_icones
			$dll_icones = ""
			_GUI_Incones($result) ; pour la recréer et lire le nouveau set d'icones
			GUISwitch($GuiIcon)
			GUISetState()
		Case "exe" ;si c'est un executable
			if _WinAPI_ExtractIconEx( $result,-1,0,0,0) > 0 Then ; permet de tester si le fichier possède une ou plusiers icone(s)
				Local $aIcon[3] = [64, 32, 16]
				For $i = 0 To UBound($aIcon) - 1
					$aIcon[$i] = _WinAPI_Create32BitHICON(_WinAPI_ShellExtractIcon($result,0, $aIcon[$i], $aIcon[$i]), 1)
				Next
				_WinAPI_SaveHICONToFile(@ScriptDir & "\Assets\" & $sFile & ".ico", $aIcon) ; on sauvegarde son icone 0 dans le repertoire assets
				For $i = 0 To UBound($aIcon) - 1
					_WinAPI_DestroyIcon($aIcon[$i])
				Next
                IniWrite($filelink,$section,"icone",@ScriptDir & "\Assets\" & $sFile & ".ico"); si oui écriture dans le fichier
				_charger_combo()

			Else
				$flag = "iconbutton"
				valider_guiquestion()
			EndIf
		Case "ico" ; si c'est un fichier ico
				_DebugPrint("FIND ICON" & @CRLF & "--> extension:" & @TAB & $sExt & @CRLF & _
							"-->Icone" & @TAB & $sFile)
				FileCopy($result, @ScriptDir & "\Assets\" & $sfile & ".ico") ; on le copie dans assets
				IniWrite($filelink,$section,"icone",@ScriptDir & "\Assets\" & $sFile & ".ico")
				sleep(100)
				_charger_combo()

		case Else
			Return
	EndSwitch
EndFunc

;---------------------------GUI ICONES------------------------------------------------
Func _GUI_Incones($file = $dll_icones) ; la gui_icone va changer en fonction du nombre d'icones à affichier
	Global $dll_icones_new = $file
	_DebugPrint("iconset" & @CRLF & "-->$dll_icones:" & @TAB & $dll_icones)
	Local $dll_icones_name = stringsplit($dll_icones,"\")
	Local $nbicons = _WinAPI_ExtractIconEx($file,-1,0,0,0); pour connaitre le nombre d'iconNavigatees dans la dll
	if $nbicons < 1 then ; si le fichier choisi ne contien pas d'icones
		Msgbox(64,"SortShort " & $version,"Aucune icône trouvée, veuillez charger un autre fichier")
		Return
	EndIf
	;SplashTextOn ( "SortShort " & $version, "Chargement des icônes..." & @CRLF & "Veuillez patienter",250, 60, -1, -1, 4, "", 12) ; au cas ou ça mette du temps à charger
	Local $nbIcons_columns = 29; nombre de colonnes de la GUI
	Local $nbIcons_row = Round($nbicons / $nbIcons_columns); calcul du nombre de lignes
	Local $bandeau_boutons = 60 ; bandeau bas pour placer les boutons sur le gui icones
	$Size = 40; taille des cases des icones
	Dim $array[$nbIcons_columns+1][$nbIcons_row+1]; definition du tableau des icones affichées
	$guimax_hauteur = $nbIcons_row *40 + $bandeau_boutons +30
	$guimax_largeur = $nbIcons_columns *40
	Global $GuiIcon = GuiCreate('Sélection icone: ' & $dll_icones_name[ubound($dll_icones_name)-1] ,$guimax_largeur,$guimax_hauteur)
	GUISetOnEvent($GUI_EVENT_CLOSE,"close_iconset")
	Global $IconButton = GUICtrlCreateButton("",100 , $guimax_hauteur -50 , 81, 41,$BS_ICON)
	$openFile = GUICtrlCreateButton("Autre Icone ?",$guimax_largeur / 2 , $guimax_hauteur -50 , 81, 41,$BS_ICON)
	GUICtrlSetOnEvent(-1,"_Find_icon")
	$validerbouton = GUICtrlCreateButton("valider", $guimax_largeur - 200, $guimax_hauteur -50 , 81, 41)
	GUICtrlSetOnEvent(-1,"validericone")
	For $y = 0 to $nbIcons_row ; construction des icones de la GUI
		For $x = 0 To $nbIcons_columns
			$Icon = ($y*30)+$x
        	If $Icon > $nbicons then ExitLoop
			$array[$x][$y] = GuiCtrlCreateButton($Icon ,($x*$Size) ,($y*$Size) ,$Size ,$Size,$BS_ICON)
			GUICtrlSetTip(-1,$Icon)
			GUIctrlSetOnEvent(-1, "clicicone")
            GUICtrlSetImage ($array[$x][$y],$file, $Icon, 4)
		Next
	Next
	;SplashOff()
	$dll_icones = $dll_icones_system
EndFunc
;----------------------------------GUI ICONES------------------------------------------------
Func _GUI_hyperlink()
	$hGUI_hypelink = GUICreate("SortShort " & $version, 650, 120, -1, 100, -1, $WS_EX_TOPMOST)
	GUISetOnEvent($GUI_EVENT_CLOSE,"close_hyperlinkGui")
	$label1 = GUICtrlCreateLabel("Copiez/collez ou Glissez/déposez l'hyperlien dans la zone d'édition",10,10,620)
	$hRichEdit = _GUICtrlRichEdit_Create($hGUI_hypelink, "", 10, 40, 630, 30)
	$bouton_cancel = GUICtrlCreateButton("Annuler",100, 75,100,40)
	GUICtrlSetOnEvent(-1,"close_hyperlinkGui")
	$bouton_OK = GUICtrlCreateButton("OK",450, 75,100,40)
	GUICtrlSetOnEvent(-1,"_Richedit_modified")
	GUISwitch($hGUI_hypelink,@SW_SHOW)
	GUISetState()
EndFunc

func iconbutton() ; affiche la gui qui permet de selectionner une icone
	;_GUI_Incones()
	GUISwitch($GuiIcon)
	GUISetState(@SW_SHOW, $GuiIcon)
	_DebugPrint("GUI ICONES" & @CRLF)
	GUISetOnEvent($GUI_EVENT_CLOSE, "close_iconset")
EndFunc

Func initialize_logo()
   Local $initialize_logo
$initialize_logo &= '970A/9j/4AAQSkYASUYAAQEBAGABABAA/+EAeEV4AGlmAABNTQAqAAAAAAgABgExFAACACQRAAxWAwEUAAUAHAEADGgDA2MCDgEGAFEQAxYBCFEIEQAEAy4OxFESAwcWAU5BZG9iZSAASW1hZ2VSZWEEZHkBG4agAACxAI//2wBDAAIBRgEBAgQAAwUDAQAGAAQEAwUHBgcHAQEDCAkLCQgICgAIBwcKDQoKCwIMAAAHCQ4PDQw+DgELAUQBPgE1AAIMCAwHCAEhKwD/wAARAAgAywJ9AwEiAAACEQEDEQH/6MQAH4BUBYCTAZUEAEABAgMEBQYASQoSCwAQtRAAXwMDAkkAVgUEAHoBfYAPAAAEEQUSITFBBgATUWEHInEUMgCBkaEII0KxwQAVUtHwJDNicgCCCQoWFxgZGgAlJicoKSo0NQA2Nzg5OkNERQBGR0hJSlNUVQBWV1hZWmNkZQBmZ2hpanN0dQB2d3h5eoOEhQCGh4iJipKTlACVlpeYmZqiowCkpaanqKmqsgCztLW2t7i5ugDCw8TFxsfIyQDK0tPU1dbX2ADZ2uHi4+Tl5gDn6Onq8fLz9ED19vf4+frBNQFcAAODNUY2zDURwDUCicBgBAfBNQECdwEIABEEBSExBhJBAFEHYXETIjKBAAgUQpGhscEJACMzUvAVYnLRgAoWJDThJfGBNjtCNiM2gnI2BjbHNdoAAgyAqgIRAxEAP4AA/fyiiigA/wD//wD/AP8A/wB/AH8AfwB/AAF0AL+bX/hsT4sAn/RU/iN/4UsAe/8Axyj/AIYAxPi5/wBFT+IAN/4Ut7/8cr4AD/14j/z5/wAAyb/gH9df8SkAOaf9DCn/AODAEv8AM/pKvwiiCACP9eI/8+f/ACAm/wCAH38IAMcAK/YT/grr+0cA+LP2eP2E9JsA7wnqUulat4kAtRstFm1GJ3UAu7SGS2nnd4YARWBSRjAF38kACu+MNtZfbyUAz9ZhOUFDl5UA'
	$initialize_logo &= 'X3v+iPynxN8AB3F8Gywsa+IAI1frDmlyxasAcnLe92735vwAD7Gor+ZG1YkAdee9aVo3868ApOQ/O/7B/v8AAOH/AAT+lygAr+bGJvnrTsUAvmpcpP8AYf8AAH/w/wCCf0cAdFfzr2bVoWwo3y0c4AJi5QJDFABX8/Ng3yCtWwBW4o5RPJ7fbwHBAn740V+Ddu0A/KqPjf4paP8AAAt0lbvWLowAPm7hBCi75bgAZRkhV/IZOFAAWGSMijlF/Y4I27KXoQ/98qK/AC1/4ICft/8AAIo+OPxe8cfDAD8RXF3eabDpACPEHh+F5BJHAKNDBNFbTwBiADewf7TbsBnaAKY5CFXeRX6lAFSebisNKhUdADkFFFfMf/BTAF/4KvfDH/glALfDG31jxtcXABqniLWQ40PwAN6eym+1Rl6uAHdxFCpI3StwADOFDthSHOfTAJRX8zv7Rn/BANfftNfFXXbhALwP/wAIn8LdACNx+zw2OmRaAKXip28ya7V0AHb3SKMe1ea+ABb/AIOWv2zPAA5qKzTfFa21AHhBy1vfeF9JADG/OeTHbI4/AAYVXKyuVn9VAJRX4I/snf8AAAeIeJtK1C1sAH42fDHS9YsGACEl1fwjK1pdAES/3jazu8crAB9BLEPbtX7GAH7GP7fHwo/bAeAxy3ib4WeLbAB8RWtrsW/tMABhv9KdgcJcWwC+HjJ2sASNrwC1irMBmpsTYwDYqKbPOltC8gBIyxxxqWZmOABVA5JJ9K/IPwD4KX/8HWnhHwCAHijUPBvwHwBE034j69p7tAAXPiTUJXGgwQAg4KwJGVku8AByC6vHH0KtIAA5oA/X6iv5XwDxV/wc4/tleACHWmurP4l6VgCFAzbhZ2PhXQAt4VHoDPbySQCPq5PvXvH7IgD/AMHdPxh+HgD4htbT4w+F/AA78Q/DzOFuLwA0yAaVq8SnggDrtP2eTA52GADjyeN69RXKygDlZ/RRRXlH7ABt+2x8OP29'
	$initialize_logo &= 'vgAL2fjv4Z6/DgC3o9w3k3ETLwCXeaZOAC1vcQAR5jkXI4OQwACGUspDH1epJAAor8O/+Cq3/AAcm/Hj9iD9vwD+I3ws8I+G/gAV33h3wjc2sADZz6rpd7NeSAAlsredvMaO8gA0J3SsBhBwBwBTyfnr/iL6/YCm/wDoUfgnUCkAXUf/AJPp8o+AlP6SaK/m288BAJPr2X9l7/g8AGNeTxLb2vxnAPhVos2kzOFmANS8HTS289oPAO8LW5kkEv08APT8elHKw5WfALyUVwP7M37UAB4D/bD+D2meADz4c+IrHxN4AGdVBEdzbkq0ADIMbopY2AeKAFXI3I4DDI4wCEE/PFATcb/goAQeNCAHbH7E8fwARvAen+G9S1wAbxFZ6SYdctoAa4tfKmSZmO0AilibcDGuDuwAdeDSEfYlFfwA23/EX1+03/0ACj8E/wDwS6gA/wDyfR/xF9cA7Tf/AEKPwT+A/BLqP/yfVXIWIJNFfzbfvgFH/ABF9ftN/wDQowTwT9A2uo//ACeC0WEM0k0V+JMQAQKIMC2O/jp+3p8A8FDvh78J/GUA4d+F1j4b8V8A9pfbJ9I0u9gAbxPs+mXd0mwAeS7kQZkgQHIAhypYDBwR+vkA+0t+0l4O/ZEAfgj4g+Ifj3UAeLRfC/hu388AurhhudySFSIAjXq8jsVRUHIAzMBUkndUV/MIT/t4gBDT/wAdAD9oPxLfaf8AAAnkh+EfgsOyAFu1vDFda3dxAPQNNcOGWIngAO2BVK5I8x+pAPi++/4Kf/tKAGo6m15L+0B8AGr7QxzuTxrqAEgX6BZgAPYAAAquUrlP7KKKEP5O/gCgBcN/tQC3wA1KGSL4qQCoeL7GMgyWHgAqt49WjnA7NAiuBcCwWEqmv1sAP+CXP/B0J4MAf2yPiF4f+HMA8TfCd14F8fcAiK6i07TLzSgASX+j6rdSMFQAj24M1szMQAEAvMQdWkWlysUAys/ViiuT+PMA4kvfBvwN'
	$initialize_logo &= '8Z4AsabN9m1HStAAr68tZtit5UsAHbu6NhgQcMAAHBBBxyK/lv8AAPiI+/bS/wAAotVx/wCExosA/wDIdFgtc/oAvKK84/Y58d4ArfFH9kX4V+IAbXro3+ueIvAAhpOp6jcmNI8A7Rcz2UMssm0AQBV3OzHCgAYAcAAcV6PSEFECXxAE8HK3/BVXAOPn7BX7VngPAMN/CXx/J4R0AF1jwmNSvLZdACLC8864+2XEAHv3XEEjD5EUAGAQOOmc1b/4ADaP/gqZ8ef2APj9pD4iaD8WALx9J4u0nQ/DAFHf2MDaRYWXAJE5uo0L7reCADY/KxGGJHPTADTsOx+ytFFfChsgFVlga7QfDn8A4JWeCreHVIkAvFfxG1qAzaMA+FrScRyOmSoALi5kwfIg3AgADbWZyCFU7XIAqEfZFFfyh/sBsCbBxJ+1Z+0vgOILmaP4kXsAYgBIkYmDSvCC/wAAZcdsvp565gDlzjHLyn2ArwAx+H//AAWJ/QCqPhprceoabwDtAfFW5uI2DAAXVfEE+rQE+wDFdNLGR7FSKgC5SuU/sKor8RAn/glXsFVYDx4AeKtN8C/tKWsApWkzX7rbWfgA306L7PaCQ8AA+3wfdiBPWaIAwi5G6NVDOP0AsrW6jvbaOaEAkjmhmUPHIjAAZXUjIII4II5A9SSSUV8foAp2AP8Aad8dfsefAPBM3xx4++HGALreG/F2kXemAEVpfraQXRhWAGv4IpB5c6PGAHcjsOVOM5GDAINfgH/xEfftEqVgf6rjkCyNF/8AAJDp2HY/q8oAK/lD/wCIj78AbS/6LVcf+ExAaL/8h1e8UDkHACz+2boGqx3EAN8WbfVYUOWtAG88LaR5UvsTCB2yONApsDT5RwDKf1XUV+Qv/AASo/4OltA/aQCfG+l/D/466AD6T4D8UatIlgC6d4i053XRbwCmY4WKZJGZ7QBZjgBy7xkk5ADGMZ/XqpJCigD+bX/gpn/wXgAP2r/gD/wU'
	$initialize_logo &= 'CwDjB4K8I/FibQAfwz4Y8UXmnwCmWQ8PaTMLWAAjkIRN8lqztgAHdmJ968N/4gAj79tL/otVxwD+Exov/wAh1UBylcp/V5SQHP8AABEfftpf9FoArj/wmNF/+Q4Cj38tdHKHKf1eAFFfyh/8RH37AGl/0Wq4/wDCAGNF/wDkOv6DAH/gh9+0h40/AGuP+CXfww+IAF8Q9abxF4w8AEH9q/2hqDWsADam48nVr23jAP3cKJGu2KKNAH5VGduTkkkqAMKx9X0UUUhBEEUUUAE4AAfy3wBFFFfgZ/tAFEBRRQAV+x2wI+IBUFwI8D/9jPp3AP6br+vxxr9jAL/gvF/yYR4HAP8AsZ9O/wDTEHX9fbcwVB6nogD8z+QfpVfxMgB/8Vb8qR+SNgCfeWtO0/rWZQCn3lrTtP61+gBh/Lpfi+/WlQCP3qzYvv1pWAD96pIlualnVwDtvu1Qs6v23wB2gyNOw+4K1AC16Vl2H3BWJwDFr4sx/CTQbQBu/sqX811P5ACtv9o8liu1iwA4+ViQCFB4/gAxz6guVt2R0QB4s+Imi/Dy0gAZtYvo7NLhtgBECrO0hAycKgCCcDjJxgZHqADPyp8X/iB/wgDN8fXmrKtxFQC0m2O3ilfc0QBGqgD2XJyxUQDALHk9TneNPABpqHj7xBNqWgCU3m3Enyqo4QAhQdEQdlGf1AEwEzlUHdRoqGsE1P2QDoNqf+UgAJ4k/wCye6h/AOnLSq/cyvwzA28BYAGJbnyGd/4A9P0QV/Hr/wD/PwVy/au1z9sj/goZ8TvF2sXU01vba1c6No8DMdtjp1rK8NvEo6L8q72xwZJHbqxr+wqv5S/+C9f/AATR8WfsKftreLteOk3c3w1+IWsXOs+H9YjiLWqNcO00lk7DhJYmZ1CsctGquM5OHE8uJ6H/AMEDv+CHPhn/AIKlaV4s8ZePfFeraP4Q8JahHpa6ZojRJqGoXDRiVmeWRXEUSqyDhGLlmAKbMn9O/En/'
	$initialize_logo &= 'AAaafsq61ozW1pN8TdHuNuBd2uvxvKD64lgdP/Ha/nx/ZE/bk+K37CXxAk8S/CvxlqnhTULlVjvI4ds1pqCKSQk8EgaKUDJxuUldxKkE5r9ZP2Sf+DxHVNOS20/43/C+DUkXCya14Pn8mbA4ybO4YqzHqSs6DPRR2NQdzlf2xv8Ag0F8feBLC61b4KePNN8eQRAuuh67Eul6iQOiRzgmCVj/ALfkD39f0h/4N9f+Ccd9/wAE8P2FbW38U6X/AGb8RvHl0db8RxPtaWz6pbWhZSR+6i+YjtJNKOa9O/Yw/wCCw37PH7elzb6f4A+Iemt4knXI8P6srabqhPUqkMuPOIHJMJkA9a+m6Wors/G//g6u/wCCo2pfBTwHpn7PfgfU5LHW/G1j/aPiy7tpCstvpjMyRWYYcqbhlcuMg+XGFOVlNfh/+yD+yN44/bk+Puh/Df4e6X/aXiHW3JDSMY7axhXmS4nfB2RIvJOCTwqhmZVPqn/BaX4x3fxz/wCCqfx01q7mkm+xeLLvQ7fceFgsG+wxhfQbbcH8c9Sa/Wr/AIM8/wBmTTfD/wCzj8SPi9cW8ba54k1weGbSZly8FlaxRTPtPYSTXA3DubdPSnsh7I3fgt/wZ9/BPQ/h9bw+PvH3xF8Q+KJYh9qutGntdNsoXxz5MUkEz4B4y7nOM7V6V+dn/BZv/g398Uf8Ex9Ij8d+FdYuvHXwoubhbaa+mtxHqGgSucRpdKnyNG5wqzKFBchWVCU3/wBRFcj8fPgpoX7SHwT8VeAfE1qt3oPi/S59KvYyoJEcqFdy56OpIZT1DKCORSuK5/Jv/wAEhv8AgpXr/wDwTJ/a30jxZbXF1N4L1iWPT/F2koS0d/YFuZAnQzQ5MkZ4OQVyFdgf66vD+v2XirQbHVNNuob7TtSt47q1uIW3RzxOoZHU91ZSCD6Gv4hfHng+6+HvjnWvD99t+26HfT6fcbenmRSNG2PxU1/Vx/wb5fGG7+NX/BIX4N6h'
	$initialize_logo &= 'fzSTXuj6fcaA7OckJZXc1tCM+0EcQpyHI/AL/g4c/wCUyfxu/wCv/T//AE12ddv/AMEkf+CBer/8FW/gH4g8daf8TNN8Fw6D4gk0FrO40V75pmS3t5/MDrMmAROFxg/dznmuI/4OHP8AlMn8bv8Ar/0//wBNdnX6xf8ABnj/AMo9/iJ/2UO4/wDTbp9PoPofPh/4MyvE2P8Akvmg/wDhKS//ACTXwv8A8FR/+CI/xZ/4JZLp+seJJdK8VeBtYuPslp4i0jeIY59pYQXETgNDIyqxXlkYKcOSCB/WpXxN/wAHE2s+GtI/4I/fF5fEzW3l3ltZ2+mpKRvkvzewGDyx1LKy7zjnajnoDSuK7PxA/wCDcz/gotq37Ff7ePh/wne6hL/wr34sX0GgavZyOfJt7uVvLs7xR0VklZUZunlSPnJVSP3z/wCCvv8AwTrvf+Cn/wCyVH8M7HxVa+D501y11j7fcWLXiEQpKpTYrocnzOueMdK/kx+BtpqGofGzwfb6T5h1SbW7KOzCfe84zoEx77sV/bnRIJH4Kf8AEGV4m/6L5oX/AISkv/yVXzB/wVl/4N+NY/4JWfs3aT8RdQ+J2m+NIdU8RQeHxY2+iPZNG0tvcz+bvaZwQPsxG3H8ec8c/wBRVflX/wAHff8AyjK8I/8AZSNP/wDTbqlF2F2fgf8AsM/ssXH7bX7WXgn4V2usw+HrjxpfNZJqMtsbhLUiJ5NxjDKW+5jG4da/Vn/iDK8Tf9F80L/wlJf/AJKr4K/4IK/8pfPgX/2HZP8A0lnr+uCiQSPyP/4Jif8ABsvrn/BPj9uPwR8X7z4u6T4otvCP2/fpkPh+S1e5+06fc2gxIZ3C7TOG+6chccZzXj//AAeR/HfW7a7+Dfw0t7iaDw9dRXviO9iUkJeXCslvAW9fLVp8f9dvpX7oV+cv/Bxl/wAEntf/AOCj37PGgeIPh/bx3nxH+GslxNZaezrGdbspwnn2ysxA80NFG8e4gHDr'
	$initialize_logo &= 'wXBB1F1P53f2APgB4b/an/bP+HPw98X+I18J+GvFmsxWN/qZkSNoYyCdiM+VWSQgRIWBAeRSQeh/py8Df8G+/wCyD4E8NQ6bF8F9D1IRxhHutTvLu8uZj3ZneU4J6/LtA7ADiv5P/GXgzWPh34pv9D8QaXqOh61pczW95YX9u9vc2ki9UkjcBlYehANfXH7HH/BfD9pz9iu2s9N0Xx7N4r8M2ICR6H4rjOqWqoOiJIzC4iQDgLHKqj0pu5TP2s/aQ/4NXf2XfjLplw3hPTvE3wt1ZwWiuNG1SW8tt/q8F2ZQV/2Y2j6cEV5j/wAEiv8Ag291z/gn5+37ffEbxt4k8O+NPD/hfTXHhC5tIpIJ5L2fdE808D5ETRQ+YAA7gmdWDZQgYn7Jf/B4D8O/Gstppvxk+H2t+B7qQhJNX0KX+1dPB7u8LBJ419k85v6fqx+z9+0l4D/ar+HNr4u+HPizRfGHh27O1bzTrgSLG+ATHIv3o5BkZRwrDPIFLUnUZ+1B/wAm0/ET/sWdS/8ASWWv4na/ti/ag/5Np+In/Ys6l/6Sy1/E7REcT+z7/gn1/wAmE/BH/sQNB/8ATdBXr1fzQ/Bv/g66/aA+CPwh8K+C9L8D/B240zwjo9potpLdabqTTyw20KQo0hW9VS5VASQoGc4A6V0n/EYT+0d/0IPwT/8ABXqf/wAn0crDlZq/8Hiv/J8fwx/7EVf/AE4XdX/+DOL/AJO9+LX/AGJ8X/pbFXwT/wAFLv8Agp546/4KmfFfQfGHjzRvCei6l4e0kaPbxaBb3EMDxedJNucTTSsW3SsMggYA47197f8ABnF/yd78Wv8AsT4v/S2Kh7A9j90v2tP2kdD/AGQP2avG3xN8RZbSfBelTajJErBWunUYigUngPLIUjXPG5xX8cn7T/7SXiv9rz49+J/iN421B9R8R+Kr17u5fJ8uBTxHDGCTtijQKiL2VAK/od/4O2viddeCf+CX+l6LayMq+MvG2n6d'
	$initialize_logo &= 'dqGxvgigurvn1xLbwnH+FfgH+wB8ELP9pP8Abg+EvgPUl8zS/FXizTtP1Be7Wr3CeeB7+VvoiET9VP8Agin/AMGzfh/44fCHR/iz+0NHqkum+JYEvdC8IWty9kZbRxmO4vJUIlHmKQyRRshClWZssUX7T/aZ/wCDX39lr40fDy6sPB/hnUPhf4kERFlrGk6ndXSxyAfL51vcSukiZ+8F2OR0detfona2sdjaxwwxxwwwqEjjRQqooGAABwABxgVJSuK5/Fp+2Z+yH4x/YV/aN8SfDLxzaJb654emCiaHLW+oQMN0VzCxA3RyIQwyARyrAMrAfun/AMGpH/BSXUv2gPgjrfwK8XahJfa98M7WO98PXEz7pbjRmcRmEk8n7NKyKCekc8ajhK8v/wCDyb4E6cum/Bf4mW9vHHqzS33hm+mA+a4h2pc26k+iN9pI/wCupr4Y/wCDbD4l3Xw5/wCCw/wvihkZbXxJHqWjXig482OSwndAfpNFE3/Aae6Huj9sv+DnP/lDZ8Sv+v8A0b/06W1fzOfss/Cmz+PH7Tvw58D6jcXVnp/jPxRpmhXVxbbfOgiuruKB3TcCNwVyRkEZAyDX9Mf/AAc5/wDKGz4lf9f+jf8Ap0tq/nF/4Jz/APKQj4Ef9lD8P/8Apyt6IhE/b/8A4g6vgd/0U/4rf99af/8AI9cv8X/+DODwHc+CLz/hAfi74usvEiRlrX+37O3urGZwOEfyUjdATxvG4rnO1uh/aCildiuz+JX9oP4C+KP2XfjX4m+H3jTT20vxP4TvnsL+3J3KHXkOjfxRupV1YcMrKRwa/po/4NtP26dV/bU/4J12Fr4mvZdQ8WfDK+Phi9upm3TX1ukaSWk7nqW8pxEWPLNAzHls1+JX/Bxr8a/C/wAc/wDgrT8RdQ8J3FrfWOjxWWiXV7bMGju7u2t0jnIYfe2ODCT6w8cYNfox/wAGanhTULP4CfG7XJFk/svUdf06xt2P3TNBbyvKB7hb'
	$initialize_logo &= 'iHP1FN7Dex7L+1L/AMGtfwh/at/aK8Z/EnWfiF8SNN1Xxtq0+r3VrZNZfZ4JJW3FU3wFto7ZJNcD/wAQdXwO/wCin/Fb/vrT/wD5Hr9eKKm5Nz+Kv9sj4LWH7N/7XHxQ+Hul3V5faZ4G8V6noFpc3W3z7iK1upIEeTaAu4qgJwAMk4Ar9Ov+CO//AAbqfC//AIKNfsPaL8UfFHjjx7oer6lqN9ZyWmlNaC2VYJjGpHmQs2SBk89a/Pf/AIKo/wDKTX9ob/spHiD/ANOVxX9CH/BrX/yiD8J/9h3V/wD0qaqexT2PGf8AiDq+B3/RT/it/wB9af8A/I9fo1+wd+x1of7AX7KXhX4SeG9U1bWtF8J/a/s95qRj+1TfaLye7bf5aqvDzsowo4A6nJr16ipJCiiigAooooAKKKKACiiigAooooA/lvooor8DP9oAooooAK/Y7/gvF/yYR4H/AOxn07/03X9fjjX7Hf8ABeL/AJMI8D/9jPp3/puv6+24J/j1PRfmfyD9Kr+Jk/8AirflSPyRtPvLWnaf1rMtPvLWnaf1r9MP5dL8X36+mP2KP+CcHjb9rqWHVFVvDPgtxKDr11B5izuh27LeHcrTHfkFgVRdkgL71CN4j8FfhR4o+MvxAs9H8I+H7rxJq2Vn+yxRb41QOql5iSFSLcyqzuVUbgCRmv0D8DeFf2xPhRrf/CUWfhzRbq3aF7aLwm2teZp2lQgfKIrYXaxqqqoVFjkYgEDHpJ5+OxDguWEkn5s7fwj/AMENPh9p+iRx614v8ZahqSs2+exNtZwsM8ARvFKwIGATvOTzx0rSuv8AgiP8MRZMtr4l8exXBxtea6tJEHPOVFupPHuP6Uz4H/8ABVd18X2nhf40eDr/AOGOsX0ayW17dW89vazB5HVS8UyiSFOAvmFnQlXLGMCvrHwp440nx34et9W0TU9P1jS7vd5F5ZXC3EEu1irbXUkHDKynB4II6ii1z52ticZSfvt/p/kf'
	$initialize_logo &= 'lz+1x/wS98ffs1eD5te8KW998UdPtoQ0sGlWBj1GOQyKgAtg0jSJ8yktGXKgSFkULk9F+wB/wRIt/iDod746/aU0mbUNY1yPy9K8JpfTWqaLbhsiWd7eRW85sfLCHxGjEybpXKw/pg9zuak8/wB6rlYSziu6fItH3W5/PN/wWH8C6P8ADT/go78R9D8P6fZaTo9i2m/ZrKzgWC3tQ+mWkhREUBVUFzhQAAOgFfM9faX/P/8ABfTwE3hD/gotrWpN08WaNp2qrwBwkP2P8ebQ9f8ACvi2pPtMDLmw1N+S/I/QT/g2p/5SCeJP+ye6h/6ctKr9zK/DP/g2p/5SCeJP+ye6h/6ctKr9zKiW58nnf+9P0QVhfEv4YeG/jN4I1Dwz4t0HSfEvh/Vo/JvNO1O1S6trlfRkcEHB5HGQQCOa3a/Iv9ur/g5k1D9gf/gph44+FereAdP8ZfD3wz9gg+16fdtaatbTy2cM85BbdFMqtLtCERkFT8/SkeSaP7Xn/BpH8FPi/c3mqfCvxN4g+FWpzkuthIP7Y0dT1wscjLOmT385gB0XjB/Mb9rP/g2l/ak/Zgiur/TvC1j8T9BtgX+2eEbg3dwF7Zs3VLgtjqI0kA9TwT+2P7Pv/ByB+yT8fNPhMnxGbwLqUoBfT/FWny2DxfWdQ9t+Uxr1nxb/AMFh/wBljwVoEmpXn7QHwpmt41LlLDxDb6hcEe0MDPKT7BSarUrU/kBubbUPCHiB4Zo7zS9U0u4Kujq0FxaTRtyCDhkdWHsQRX9Bn/BsP/wWD8aftaXGufBD4patceJPEXhnSv7Y8P67dvvvL2zjkjimt7hzzLJGZYmV2y7KZNxOwGvyf/4LfftoeAv29P8AgoN4k+IHw30uSx8My2drp6Xktr9lm1ySFCrXkkf3lLZCLv8AmKRIWCnKj6q/4NDfglqvjD9vrxf44jgkXQvBnhOa1uLgD5ftV5PEsMX1aOG4b/tn703sD2PiD/grF8PLr4W/'
	$initialize_logo &= '8FNPj1o93G0br451a8iBGMwXN1JcQn8YpUP41+2v/BoP8ZNP8WfsB+NPBazR/wBseD/GEt1NAD8wtby3haGQj/akhuV/7Z180f8AB2x/wTu1Lw18W9H/AGjvD1jJcaD4kgg0TxW0SbvsV9Evl2txJjoksISHJ4DQICcyKK/Pj/glF/wUu8S/8Euv2pLTxxpNu+seH9Ri/s7xJonm+WuqWRYMdp6LNGwDxvjggqfldgV0DdH9gVZ/izxTp/gbwtqWt6tdRWOlaPaS317cynCW8MSF5HY+iqpJ9hXyb8HP+C9/7Jvxl8Awa9D8YvDXhwyRB59N8QyHTb+0bGTG0cg+dh0zEXU9mNfmb/wXs/4OKfDH7Q3wj1T4K/ATULzUNC14fZ/E/iowSWsd5bA/NZWquFkKORiSRlUMgKKGVy1KwrH49/GPx3/wtL4u+KvE3ltD/wAJFrF3qnlnqnnzPLg/Tdiv6j/+Dbf4fXXw+/4I6/ClbyNorjWjqWrbCMYjm1C4MR/4FGEb/gVfzSfsQ/sgeKf27v2nvCnwx8I27vqPiK7VLi68stFplqvM91L6JHHlj/eOFGWYA/2Q/B74V6P8DPhN4Z8F+Hrf7LoXhLS7bR9PiPJSCCJYowT3O1Rk9zk05Dkfyr/8HDn/ACmT+N3/AF/6f/6a7Op/+Can/Bdr4rf8Etvg1rXgfwH4Z+HutaXrmtPrk82v2d5NcJM0EMBVTDcxLs2wKcFSck84wBB/wcOf8pk/jd/1/wCn/wDprs66r/glH/wQS8Uf8FVvgTr3jrQ/iFoPhG10HXpNBe1vtPluJJXS3gn8wMjAAETgY65U0+g+h7Mf+Dwn9o7H/Ig/BL/wV6p/8n18Y/8ABQr/AIKw/Gb/AIKaa9p83xK1yzGj6O7S6doGkW5tNLspGGDIIyzO8mCRvld2AJAIBIP0/wDt7f8ABsD8Yf2L/gBqHxC0fxHo3xMsNCzNq9jpFjNDe2NqAS1yqMT5iJjLhfmV'
	$initialize_logo &= 'fmwVDFfzW0e+j0vV7W6ms7fUIbeZJXtbguIblVIJjfYyvtbGDtZWwTgg80aBofpf/wAGzX/BMPWP2rv2vNK+LmvabND8N/hTfJqEdxNGRHq2rx4e2t4ieG8p9szkZ27I1P8ArAR/TJXxz/wRR/4KCfCP9t79kfR7P4aaLo/gO+8F20djq/gmzCxjQXOfniUAeZbyNuZZcZYlg3zhhX2NUslhX5V/8Hff/KMrwj/2UjT/AP026pX6qV+Vf/B33/yjK8I/9lI0/wD9NuqUhH45/wDBBX/lL58C/wDsOyf+ks9f1wV/I/8A8EFf+UvnwL/7Dsn/AKSz1/XBVSKkFFFfn3/wcX/8FDfHH/BO39knwZ4g+GusQ6P4w1zxjb2aPNaxXUctnHbXEs6MkikFWZYVOMMN+QQQDUkn0j+2B/wTW+B/7eOniP4o/DvQ/EV9HH5UGqqrWmqWy9gl1CUl2g87CxTPVTX5fftW/wDBnZoWrfar/wCCvxSvtHmbLRaP4utxdW5J7C7t1V0UdBmGQ46k96P7KP8AweLWEtlbWPxt+Fd3DcqAsuseDZ1kjkPTP2O5dSnqSLhvYdj9geG/+Dnr9jjXNJW4uviJrWjTFc/ZbzwtqTTA+mYYZEz/AMCxVaorU/nu/bv/AOCVnxu/4Jx6pbL8TvCMljo+oTm3sNdsJlvNKvnAJ2rMn3HIDERyhHIUkLgE1S/4Jyf8FCvHH/BOD9pDR/HHhHUrxdNFxFHr+jCU/Zdest37yCRM7S20sUcjKPhh3B/Q/wD4L2/8HBXw1/bp/Ztk+Dvwn0fWtS07UdStr7VPEOrWgtIwkD+YkdtESZCzOF3O4TCqVCtuyv5U/s5fAbX/ANqH48eEvh54XtZLrXvGGqQ6ZaKqlhGZGAaRsdERdzs3RVRieAar1K9T+yP9oLW7bxL+yb431Kzk86z1Dwlf3MEgH343s5GU/iCK/inr+1P46+Hbfwf+yD4y0m13fZdL8HXtnDu67I7J'
	$initialize_logo &= '0XP4AV/FZUxJifrx8Cf+DSTxn8c/gh4N8bW/xm8Mafb+MNDstcjtZNDnd7Zbm3SYRlhKASofBIAziuq/4g0vHP8A0XHwn/4ILj/47X7Of8E+v+TCfgj/ANiBoP8A6boK9epXYrs/kN/4Ky/8EtdX/wCCUnxn8N+DdY8Xab4wn8RaKNaS5s7J7VIVM8sOwqzMScxE5z3r7c/4M4v+Tvfi1/2J8X/pbFVD/g8V/wCT4/hj/wBiKv8A6cLur/8AwZxf8ne/Fr/sT4v/AEtipvYb2Ptz/g7N+E938Qf+CWtvrVpE8i+BvGOnatdsozsgkjuLLJ9vMuof0r+fX9hL45237M37aXwq+IF9u/s3wh4q07U77aCWNrHcIZwAO5i3496/sK/ac/Z90L9q39nvxj8N/EsbNonjPSp9LuWUAvB5ikLKmeN8b7XU9mQV/HX+2L+yX4w/Yf8A2i/Evw08b2LWmteHbkxrKFIh1CA8xXUJP3opEwynqMkHDAgEQif2j6Xqlvrem295Z3EN1Z3kSzQTROHjmjYAqysOCpBBBHUGp6/nn/4Ivf8ABzDbfsl/CTS/hP8AHLT9c1vwroEYtdA8Raai3F5plsOFtbiJmUyQoOEdCXRQE2sACv2Z+0v/AMHZX7O/w5+Ht1P8OLXxR8RvFEkRFlaNpsml2UcmODcTTAOEH/TNHJ6cZyFYVj52/wCDyH9ofTby9+DvwqtLiObVLL7Z4n1OIN81vG4W3tc/7226PPZB618Xf8G0Pwpuvib/AMFgvhxdQxvJZ+EbXUtdvWUZ8uNLKWFCfQefPCP+BV8k/tSftN+MP2xfj14k+JHjrUv7T8TeJ7o3Fy6jbFAoAWOGJcnbFGgVEXJwqjJJyT/QH/wa2f8ABMjUv2Uf2edW+MHjTTpNP8Y/FS3iTS7SePbNp2jKfMjLA8q1y+2Qqf4I4DwSwD2Q9keuf8HOf/KGz4lf9f8Ao3/p0tq/l6+G/wAQtX+EnxE0HxX4fuvs'
	$initialize_logo &= 'OveGdRt9W025MSS/Z7mCVZYn2OCjbXRTtYEHGCCOK/qF/wCDnP8A5Q2fEr/r/wBG/wDTpbV/M1+y/wDCi2+PX7S/w78DXt1PY2fjTxNpuhT3MChpbeO6uooGdQeCyhyQDxkURCJ9af8AES3+2l/0V6D/AMJLRf8A5Erl/i//AMF/P2vPjj4HvPDuufGbVodK1CMxXC6TpdhpM8qEYK+fawRygEZBAcAg4NfqT/xBvfCr/osHxB/8ALP/AOJr8kP+CqH/AASx8df8Etvjy/hvxGrat4V1ZpJvDfiSGIrb6xbqRkEc+XOmVEkRJIJBBZWVi9B6Hiv7PP7PPjL9qz4w6L4D8BaHe+IvFHiCcQ2tpbrnH96SRukcaDLM7EKqgkkAV/XT/wAEyv2FdJ/4Jzfsa+E/hfps0V9fabG15rWoIpUalqMx3TzAHnbnCIDyI40B5BNfzqf8EG/+Cutn/wAEvvj7e2/inRbHUPh745aK21u/gsUbVdH2n5LiOQDzJIVzl4CSCPmQBxh/6kfAPj7Rfin4K0vxJ4b1Sx1zQdctkvLC/s5hNb3cLjcrow4IINKQpGvRRRUkn8bv/BVH/lJr+0N/2UjxB/6criv6EP8Ag1r/AOUQfhP/ALDur/8ApU1fz3/8FUf+Umv7Q3/ZSPEH/pyuK/oQ/wCDWv8A5RB+E/8AsO6v/wClTVT2Kex+iVFFFSSFFFFABRRRQAUUUUAFFFFABRRRQB+eP/DVP/BO3/nx+H//AIQV/wD/ACHR/wANU/8ABO3/AJ8fh/8A+EFf/wDyHX4w0V/Qn/EuOT/8/V/4Kh/met/xEzE/z4n/AMKX/wDKz9nv+Gqf+Cdv/Pj8P/8Awgr/AP8AkOj/AIap/wCCdv8Az4/D/wD8IK//APkOvxhoo/4lxyf/AJ+r/wAFQ/zD/iJmJ/nxP/hS/wD5Wfs9/wANU/8ABO3/AJ8fh/8A+EFf/wDyHWl/wXzvbTUv2GPBtxp7K1jceLLCS2Kq'
	$initialize_logo &= 'VBjOn35XAPI+Ujg81+J9fs1/wW0/5RufDP8A7Dmk/wDprva/POPPDjBcKSw/1SXN7bnv7qjbk5Lbb/EdGH4iqZxOM6kqr9nJJe0q+0+JPb3Y2+HXe/yPyhtPvLXb/BH4b3Hxi+LPhrwpaym3m8R6pb6cJxEZRbiWRUMpUYJVASx5HCnkda4i0+8tfUX/AASN02W+/b18FyxqrR2SahPLnsv2GdAf++nWvhY6ux7mJqezoyqLomz9ZP2df2XPA/7K2hahp/grR10yLVp1uLuV5WnuJyq7UVpHJcovzFVzhS7kAFmz0nxY+K+kfBX4b614q12Yw6Xods1zMVK75McLGm5lBkdiqKpIyzKM81p+f718Wf8ABeT4n3nw0/Yq06S1kmH9reKLWxliVysc6/ZrqYLJzygeFHx/eRenUbSjZHwmHjLEYiMJPWTPlL9t3/gqd4o/aJ06PSG0HSdP0a8mWPTNBhtI9Svrq4KqgInkjLiQMXAeBIiFl2HeSN3uP/BFb9mT4ueH9a1L4meMtW17wb4T1aB7bTPBki7BqgyALy4ikXMQXb+7cBZpDk7kgws/5U/DL9o3xh8H/ipZ+NdB1O3t/EmnAra3dxp9teC3yMZSOaN0RsZ+ZVDDJwQSc/Ungb/g4A+PvhOy8rUP+EJ8Tyf89tT0ho3H/gNLCv6VlFq92fX4zL6yo+wwsY1JvgCe99/y/G9z9wAfz/ejz/evxwAPBH/Bx58S9AD9QLeJPAXgfQBa1zxFpj3WnQAn/fckk4/8dgC9Y8D/APByVwCF9QST/hJPhQD+INJZR8n9mQCrxaiHPv5kcABt/WtOaB83UwAkxsfsX9GjxgC/4OO9GvI/2wAPwbqckf8AxAC+68GwWsMn9wClivr15B+CzQAZ/wCBV+fFfQCd/wAFdf8AggCJ+CP2/D8PXwDB+k+KNLl8KgA1EXx1i2gh8wAFx9l8sRmKaQA3Y8mTO7bjcADGcnHxjWMrXwBD7LK4zhhY'
	$initialize_logo &= 'RgCis10+Z+gn/AAbU/8AKQTxJwD9k91D/wBOWkBVfuZX4Z8RFlYAUtz5nO/96foAIK/Gr/gr5/wAGw+uftUfGzwAV/Fz4ReNrdsAxN4ru31HVPAA74kYpDLMRz8AZbpFOwEABY4AVCB/z1AwB+wArXOSfGHwjDIAMreKfDispwQAHUoQQf8AvqlAHkn8jXxugGU8AH7UH7PeozW/AIk+B/xAaOAkADXelaY+sWYHAK+faebGAfdhAF5bp/7I3xX1AG1FbO1+GPxCALq7Y7RDF4cvAB5CfTaI81/ZALf8Ll8H/wDQANfhv/wZw/8AAMVR/wALl8H/AAD0Nfhv/wAGAHD/APFVXMVzIB/MN+xVgAfa/gDS37WGv2cmvQDhWf4S+FJHUwBzqviqI290iQD8XlWORcO+OQAB1jQnguK/ogDf+Cfn/BP/AADAP/BN79nqxwDh94BtZfIV/gDVqep3WDea1QDbAB7iZgAM4AAFVR8qKoA7kwDpn/C5fB//AAhDX4aAf2cP/wAEFUcNJ1K4rk3xAEfhd4e+Nnw7ANZ8JeLNHsteAPDfiC1ey1HTAO7j3w3UTjBUAI/UEYIIBBBAADX893/BS7/gANW/iZ8FfFGoAPiT4BLJ8RvBADM7TJock6R6AO6Qp58sByqXAEg6BkIkPQxnEAXP9BcPP1R/wgDl8H/9DX4b/wAAwZw//FUriAD+NTxT+xX8YwDwPrT6brPwnwDiVpV/G2029wB+Gb2GTP0aMMBP4V7r+yKAC8AuAGnf2wPEVrDpAL8NNb8H6LM4APO1zxbbyaPZAMCH+MLKommHgLQxv+HJH9WmYQI1gBUm/wDgj/8CAEBI4JVfC+4tAHRZD4k8ea9GAIuv+KLmARzXAGByIIEyfJt1AG5CAkscFmYhIEL9cVzfIRgknwDOn/wXA/4JcxD7Q/x7gJenfFsA8XeDPg/448QAnhnWbyyex1IAsdPaS3ulTT4A1jYq3fDoy/UAU1+kv/Br'
	$initialize_logo &= 'x+wAtfET9k39iTwAcaD8SvB+ueAAvWdQ8cT39vYAeqW5hlmtzYUAlGJFB/hLxuswn1U1+iAX3iw7jgDnRsodSrAMrCAwQe9fg0BCXU8A+Db7Vo/GVx8AFb9m3wzLqVkA61c7te8E6dEAjzLGZzzc2McAwDCzH54RzGQA5QbCVj/b3/gEXL4gDaGvw3/4ADOH/wCKo/4XAi8ACehr8N/+DADh/wDiqQj+XAA/ZI/YR/bp/QCIPjro/wARPgAd/Bz4m6P4gwBHfBB0p2t76ABJHmW08eQJIQBwAGU+gIKsqgDD+l/9jT4++ACH9pH4CaR4kwDF3w/8TfDHxQBMvkat4f1q2QCjktLhQNxicgAxLC2co45wcCDBWBA7Dz8R3HcAOkr85v8Ag56AP2ZPiB+1d0FnAMM+G/hv4R1rAMZ67a+PLLUZAKx0u3M00dulAIahG0pA/hDSAMYz6uK+9f8AAIXL4P8A+hr8AjfgBzh/+Ko/4YBy+D/+hr8NIEQAzh/+KpCP5wcA/gjT/wAEr/0Eov7AQMFO/g/4ALPF3wc8deHvAA3ousPPf6jeAOnNHb2qG2mXAHO3YbmA/Gv6KGKub80UqG8NAOkAK+ev+Ci//BMAL+GX/BTv4T0An4X+I1vqsckAo8slzo+qaZcAZgvNKmdQrOgACGjcMFAKyIxACBxg4I9hvxaAAD+en9qX/g0bAPjp8M9Tubj4AF/iTwp8TdHyAEwQTzf2NqmOAMGSYmA+m7zxQJ67RXyxr6AaBQD/AGvvDV81vQDHwL8WSSKcEwBrNa3cf4PFK0Ap/A1/V7//i1UAcxXMz+Yn4A8A/Bsn+1p8a9YAoI9U8F6X8PcAS5GG/UPEerwACKg7/uYGlnIAcdAYwCe45I8A24/4JIf8ELsA4cf8EtLCXXkALt/HHxQ1K3MAb3fiS7txClkAxNjdBZw5byUADgbmLM745IUwOwfX398QwJxH8QDDwteeOfgr4wANE09Fk1DWNABL'
	$initialize_logo &= '2xtlZgqtLACwOiAk8AbmHBCelfzOoN0tf7UA9/0KfhT/AMJCmiA8iq/pm782qgAuFzB/ZI+HmgCnwi/ZS+GPhAD1uOOHWfC/hAD0rSb+OOQSIgBcW9nFFIAw4QCAdGAI4NehVwPgBj52IR+UP/BxAF/8Ed/jj/wUAGv2oPA/ij4XAGi6Lqej6H4WABpV3JeavDZuAJP9rnlwFkIJABtkXkcVa/4NETAMgkD8sWxxftAAvxA8RfFLRdEAtM0vxB4dj04As3s9WhvGeYUAykhBWMkgbVMwya/VT780vzQ6ShD5b/4KEEwEk/gBkCYFS/hvBpvjAAgm0bxVo8bLAKH4o0+Nft2mAJPPlsDxNAW5AGiYjuVZGO6vCqAdKI+9BqQj+Z8A/ae/4Nev2pMA4E6/cjwvoGkAHxS0FGJh1DQAHUIYZynbzLYAuGjkV/VY/MAAP7x615j4B/4ADfn9r/4h63EA2Vv8Fde03cwAA9xqt5aWEEQAO7FpZVyB6KBgn0Br+q4fGr0IqwCYrmZ+Un/BKgC/4NZPD37OngAr0zx78fNT0gB8eeJtNkW5sADwzYK0miWUoADlXuHkVWumUwCPkKLGCDkSgoAx+v4GBXN/XychXSdUknzjsBK5/QCSvGn7cH/BOID8afDf4f2dcJMAirWrrTZbWG4ArpLWJlhvoJoATMj4UYRGPPUA6V+N37HX/BsAZ/tVfBv9rr4AFfi/XfC/hmAA0Twr4v0nWNQAJI/EVtI8dvYA97DNKyqGyxAAiMQByelf0P8GAN9o/yXuO50leQB37Yv7HXgP9gDr+A2sfDv4iQCjpqmhaou6OQAXC3Wm3ABEdwA28mD5cyZOGwCQQSrBlZlPWwN/BH8qH83/AMY/APg1I/ab8I/EAdCk8IW3hbxd4QCLa5ZdM1d9YgAbGS9gPKM8MgAd0bgHDLyAwADhmGCfu7/ghiC/sgfttTAl1vEAfH4J8ceF9F8AEHwV1m4Lz2sAH4mtZrnw'
	$initialize_logo &= '1M4Aebq1UtzGx5kAIRw3Lrh8h/0GUn8dfR2dx3Okohy5v18tv2rwLG7f+AA3D/al+PH7bQB8XvG/h3wz4QCbjw/4w8Z6vgC1pssviG2ikgBLa4vJZYmZGQCypKOpIPI6VwTrn/BJ9jvxx+wCJ7AL9NB+HfxEALKz0/xPp+qaAIXU0NrdpdRiADmnZ0IdCQcqYHp2r6d/TzCrCacQcdzpKL9hq6C1ALqO9to5oZI5AKGZQ8ciMGV1ACMggjggjvSEIElFFFABPAAH8gCnRRRX+iB8GABRRRQAV+zX/AAW0/5RufDP/gDDmk/+mu9r8QCWv2a/4Laf8gCNz4Z/9hzSfwD013tfzr49/ABYD/uL/wC4jwC04R+3/ih+UwA/KG0+8tfVXwDwSW+Jnh74TwD7VX9qeJtX0wC0TTm0e6gW6gD2ZYYlkYx4GwCbjJANfKtp9wCWrGo65b+HtADpLq6fbGvAAwDvOewA7k/54gC/AIuzufoeIgCKrU3SfVWP3QBr/wDbu+DelQBv5tz8UPAsEQDnaGk1mBcn0ABlq+HP+C6X7QBT8O/jn+yZ4QDdL8I+OPCviQC1K38XW13JaQCmalFcyxwizgD1DIVRiQoZ0AAT0yw9a/LLWwDxJfeI5Y3vbgAadoxtTIChfQB4AA/H2HpVGgC5Vm1ax52F4QDqdCrGqpttBQAUUVifRBRRRQIAMQB+gn/BtT8A8pBPEn/ZPdQAP/TlpVfuZX4DIM1fAUS3Pic7/wAAen6IK+BdcwD+DZr9kHxFrQBeahdeAtckugC+ne4mYeJ9QQBDO7FmOBLgcgBPAr76opHknwCff/EMD+xz/6AARP8AXUBkp6A4AOPUf8QwP7HPAP0T/Xf/AAqdAEf/AI9X6CUUcFwufn0gZ60BEAMQAMD+xz/0T/XfAPwqdR/+PV+gQJRRcLn5944BRwD8QwP7HP8A0QA/13/wqdR/+AD1foJRRcLn5wrfjgEffwnj1fbHAMevHd58'
	$initialize_logo &= 'LfgZAONPE2nx201/AOHdCvtUto7hAFmheWC3eVA4AFIJUsoBAIOMAPI61+Un/BMzFP4KAWAS8GWrfs8At58SPh5pP7EAbo2h2OsTaI8AB4itfE1vdmYAijikZgsE8yYAwiZcHfnIPA4ACZpz55zpx3gApSfkm2l+KsUAT9yMZyfxNpfAqld/gfQfrwqvCgDj1eyftBf8FQAj4X/8E5PhVxCAh+1FsMd+DfEA94i02H7daaAA2eoahb3F4sYAPtMlrbxxS3QAtmJQ4SSZRxsAVLbuK2vgx/wAFX/2d/2gv2YAXxP8YvCfxU8AD9/8OfBe8a4A6tPHPYnSioAAds0FxGk6s+QACMGPMpICbiQACqlJLnfMmo0A7tPRWdrt9F4AvcmPM3GNneUAsurv0S6v0PAAH/iGB/Y5/wAkon/QZuFTQIHx6gA/4hgf2Of+iQT+u4BKTqP/AMcQq9y+EMAlWn4DAPx9+JGm+CfDAD40vLPxl4i0ABPiTQdM8SeFALWPDsmu2G1mAFubP+0LWD7XABlUd/3BclI5ABgCqMR+bHxpQXBOkP4zfCwQF2gAN8ZND1VOvwD9mv4k+JP+FgB6eC2fw5oPiQDg0e2tG057ogCyR6i1pcG6DgCj5kLRbGA5bADh+9zOLT6f+QA01TX/AJM7PgDa9dC6cXP4XwB/wi5/jFXXcwDrX/iGB/Y5/wAAon+u/wDhUwCo/wDx6j/iGAAf2Of+if67/wAAhU6j/wDHqwDoz4J/8FHvhAB/Gv4m+NPh/gCb4uhk+IHwxwBLh1TxfpEmmQB7aHSonjWQygCvNEqTR4ZTugAXkGHQ5+YZ6AD/AGO/22fhnwDt9/CL/hPPhAC+IpvFXhP7bAC6cNQfSrzTlQDniCmRVS6iiQDYDeBuClc5GQDIIFcru0tbKwDprpeyfo2rJwCzehjGqmlLawC7a97Xt6pO7TBvbU+UD56AWohgAH9jn/on+u/+ABU6j/8AHq7bAOK3/Bwn'
	$initialize_logo &= '+x38AA/xj4u8O+KvAIz2Ok694F1pALw9rWnvoGrSAFzbXqtMroiJAGrNMiNBIGlhAA8anYC48yPdALXwr/4LqfsmAHxv+Pfhn4ZeAhOAd+13xp4wSABfSLO2s70wXQA0sPnRwm6MIgDeOcr8phkkWQBWT92VEnyVNADvUtya3ta2twC6ureq1XlqaQBS9NtVNLXvfQAtbR37We55fwD8QwP7HP8A0QA/13/wqdR/+AD1H/EMD+xz/wAARP8AXf8AwgCnUf8A49Xo3wC09/wXs/ZI/QCOPjFqXgH4hQDxj03SfF2jhQD7fYWejalq3wBiY5/dyyWdtACxpKMcxswdcgAyoyM9h8Zv+AArl+zh+z54WwDhhr3jD4raDgCR4f8AjJuPhAB1bybm407U1QBMId3uYo2itwBEM8e57ho1TAC24jY22YzUogCnF3Tdr9Lu9gBeuj08mN3UuQAe9m7dbLd+ixCr6HhP4yzuv7EA9/wVz/Zy/b0AZPFSfCr4paMA+I38E2ov9aUAuLS70prG2+YAzcEXkUJaFdoAd0ibkTK7iNwAufOPAv8AwcUAH7GHxI+MNj4ABNH+OWi3HiIA1PUf7KtRLo8AqdvYzXG8oAIA9ktltdrMMLIAebsbI2scjNoAUnNU18T1S6sAT0Vl1uTKXLEAcntHRvs1un0IrHI/UCbUf8QwAD+xz/0T/Xf/AAAKnUf/AI9XALl+1H/wV9/ZALP2LPjho3w4APih8WNB8JeMALXFheCxuILmAGW2SVwkb3U0AFE8NohJzuuHAI1C5ckKC1L8AC//AIK8/s4fABi/Za8WfGvQAP4paQ3wv8E3ALJpusa9fWV3AKbDb3SRxyGBACO5hjlmkZZoAIIsSOZGkVE3ADHbURmpQdRPAEW76Kzs7vpZALS9dNyuWXMoAHV2066q6+9JILXkrnhn41ns/wAAsYf8Flv2ZwFgEYP8Qbzwn8IAP4qab4o8S2MAbfbH02bTb7QAu5mi'
	$initialize_logo &= 'GdzxJeQAEJmC4y3lbigACC2AQT6D+1kAft3fCn9hq18ACdx8VPFX/CIAdr421dNB0e4AJNNvLqC4vXEAlYnkgikWHIwAndKUXCsc4U4ALakrX+1a3ncAdlbvd6Lz03IAOdO9n8N7+VkAXd+1lq/LU+UGfz+HIYfqHXf2/gD4R+Gv2vbT4AA974t8n4q3mgA7a+mijTLx0gA7FVkZp5LpYQA20ShYnOJJVAD93j5lz494CxD+C/8AQHdO+P0Ab/DLQ/jp4ZsAzxZeahJpVsoAbO9h026uFLAA2Rai8C2UgcoA7Y2WYrKzIIwAuXUFQvNqMNUAu9rdbNp29GkAp+aaHJ8qcpYAiW/ldX1+Wvowann/AH8sYSz07gCN/wAFCPhB4gAP2vvEnwFs/ABd53xY8I6UNQC9W0P+yr1fsgBZmOGUS/aDCAC3f5LiE7UkZgD58YyCB5Yv/AAXe/ZTb9mWbwCMX/C1P+LcQQDiceDZNX/4RgC1j5dVNv8AaQD7N5P2Tzv9TwDN5nl+X23Z4gCUbyScdbpNegA5cqfo5e6u8gDTcrlle1v65QDm/wDSfe/w6xix5r9fWkJa1l+yAM/tp/DP9tfQAPxFqnwv8TL4ALdK8K6zNoGoAF9BYXUFqL2IACmSOKWaNEuFAAGU+ZCXQ7hhII5rzL4xAHBlfwBnP4DeLfGmjQDiLx5qHnfDeQDt7XxZeaX4TwBZ1jS/DU1wwQAiivb6ztJbWwB3Zzs2ySqQ2QBSAwIo5tUurQAmvNO1mvJ3VgD1XcmL5leO1wC3z2t63VjxrwP/QuFCi/27v+C9AFP+yJ/wVM+BAL8OI9W+FI+AAB8SfCMXivV/ABjetNNLFbyGAP8AZLa3UVyIABo3W2h2fupCAOZMLuLKB9efArLAjRfgB+2T8ABjxN8Q/h78UADw/qvg3wW7JgC/qd8JtIj0UACx+YZLhbxIXgAotmSJHUIdrwCGO1sEZc1OVQB6Rck/Lldm3wBlfS7H'
	$initialize_logo &= 'U9yoqQC95KLXnzLmSQB3dtWkfO//AAAQwP7HP/RP9QDf/Cp1H/49RyGORnqH7K8ARNH9AJR/bU+McHw/APhv8YtJ1rxfAHkbyWmnXWl6AIaU19sIDJA9AOQRRzSYO4RxALM5VWYKVViKBF48gHb3/sm/DQB8eeKvC2sfFgAEPiTwXr//AAAIxq2lw+GdYgDq8i1AGcGGOACitGacKbaUNACQh41IXLDemwCJOyTfXVel0gD82l6tLqO0tQDy0fk9d+2z+3iZ558PIg8iACLQfwSAm/8Ag4u8F7ALADn9q/4k/D+SAMtN8G2+jKZvAAZCTd3Vz4isAK3a4N3qE07QAMcNunlC1ZYJAAK6b3G+T+D1FL8GgCLCsEenj/4AN9r8O9J+OvgAeufE17qTaTYA+7TtQi06e4AAxUBNQe3FmyMAMMJIJtjkrtYAbcuaUZNxit4ASTS6tPbTffQAa3TunqmjN1EAJSk3pFtN9E0AK++22t9mtVocanF/Wz8MMQzTujcA/BQj4QeIP2sA7xJ8BbPxd50A8WPCOlDW9W0AD/sq9X7JZmMAhlEv2gwi3f4AS4hO1JGb58YAMggfJH7Z3/AAcxfAf4G/sO0Ax8YfhdqC/FoAmuPELeFdK0sAa11HQ0u7+OMAhmuFaW4s8osADBPHLkoFkzsAFbdkrjOsow8AabqyenZy5U8A0cvdvtfS5tEApzcuX8/8PN8A+k+9bdrVG19HnwufC5ALcfs6ABRuAH4J/EP9iX4UAPxU8UeNbSHUAD4iS2+gLp2jAPh/Vbq7vvEAAIo/tdlZafHDAC3k6xzPs3IkAIvzJ87blJ9wAP2Vv27fhT+2AKnxRF8N/Fa6ANaj4I1E6V4hANKvNOu9J1bQAO5BYeXc2N5FAA3MOWV1BeMKAFo5FBJRgOmdADlGcob8u9tVANNfT3ou/aSfAFRzwrKUI1NkAPa+ndW9bpq3cHTXRnygLB8vHC9+AIJRWVzS5+ffAw9UDxDj'
	$initialize_logo &= '1foJRRdwC5+ff78BzxHAEegAJRRcLn59/wAHrgEQA7wJX6CUUXAIufn3jwF2fDvwAB6b8LPh/oXhAI0WF7fR/DenANvpdhE8jSNFAAQRrFGpZiSxAAqgZJya2KKABAooPwA/lTor3AC/4dn/AB//ABDokfjnYDKvR/wAOz/j/wD9Ej8BUA/gtev7r/10CTCV+g4QTINh/wAAyR83/q9mv/QADVP/AACX+R4wG0V7lysDALCHZwT8f9BQR+Of/BYAvR/rpw//ANAAdR/8Gw/+SD8A1ezX/oGqf+AAEv8AI8Nr9msA/gtp/wAo3PgB4H1hzSf/AE13BLX5EBoOz/j/AAGQFI/HP/gtev0Cb3BEnX7LHij9AKJ/YI8P6HoKACrr3hcWerJpAPPiP7dNDaSRABt95OI3ImfDADfLuADFQS6/AIR41Z1l+PlgAL6hXhV5fa35ACUZWv7O1+VuANeztfez7H03AA/g8RglJ4ynACp3lC3MnG9lADva6V7XV+10AH4keINf/wCEAHNHa4Cq0mQkAGrZwWPr9Bk9ALpiuB8QeJLrAMS3Sy3LL8gwAIiDCJ64Hv6/AOArvPEP7M3xAHtR1OaO8+G3AMQWktZGiwnhAMu2jUg87GWMAKsP9oEggDk1AEf+GUfin/0TAD+IX/hN3n/xALr8PP0KFSklAH5l96OBorvvAPhlH4p/9Ez+UCF/4TeAe8ZgFIYIUfinIBDP4hf+ABN3n/xugv29AD/mX3nA0V33APwyj8U/+iZ/IBC/8Ju8UCZ0f4jDKPwgGaJn8XCEAAm7z/43QHt6cH/MvvO/Bb8FsAWAAPb0/wCZfecDgEV33/DKPxQQIQiZ/EJALG7z/wAAjdB/ZS+Kaj8A5Jn8Q/w8N3sBIQQPb0/5l959AYCDBtT/AMpBPAJJgGv3UP8A05YglV+5lfnwIgb7AP7Bmvfs923iAI+IfjTRY9M1AO8TWEFhpcMwACLzT7IsJpRIAANhTMwgJjZd'
	$initialize_logo &= 'APGbdQdpLIP0ALqh7nxWbVo1ADEylB3WgUUUgFI80KKKKAA0AAADgf2q9HvPEQB+y98SNP0+1gDm+v77wtqdvQC1tbxNLNcSvQCkqoiIoJZmYgAAABJJAr+bfwD4JmfsPfCP4QB/7Pt5p37UPwDwT3/bS+I/xABH1iaa31Tw7wCC9dgtI7AxxAAihKpfWg3q4gBST5R4YfMegwD6hqKzp0+SrADq/wA0Yx225QBt3XZ629NOpQDUlzU40/5W30Ct0lZ+Wl9whz0BUCmNeJfjA/7UAF+zZ4k+Hf7PAN8b/BvwTh+HAJFYtq/g34QaAHeIfit4cjCzAEJ0s3V6k8+kAM0ULxqjiZCPALTPIDOylV8lARAEa3/BN/xV4QDvgp+314Q+PAB8C/2nL/wz4wALzSLu2tLOGAAuvF2tpb3uoQBwbm0vZmistQAruItDLIYWkABKxO2OQuEP9AA5RWnSaevNzQB29X701Na76ADVt/NWepN9IgCWnLybafAraAC2V+v6rQ/CHwD4JdfsxftRfAAF/bm+Gum+AwD4lftMeNvgDwD8IjdjxTofxQBfBuseF7LwhQCnkMlrpMNvqABJJbz3kTi3VQCTTjtXYwB8kgD5+Lv+Hd/7QEB/w4t1LwiQIYsE+MWgJmSfHtNYAF0X/hDNS/tFAKx/sRovtQg8AJ8zyPM+TzNuAN3cZzxX9V9FAFRk023r8O+rAPdqqqtd3quXAFu7attu46cuAEd156bLWnKGAN3fM3pZbJJJAB/Pv/wcr+F/ABd+wR+0H4F+ADT8N/L0/Vv2AID4bX3quwDwq8U2SJ5d1QDD/Z4I1lCghwBpTHJCoODtNgCRg/eAr9kv+AAmX+yPa/sK/gDBfwu+FsFvBAA3fhfQoE1RogBQBPqEg828kwCOu64eU5PbAwC1cx4j/wCCNQB+zR4x/bGb4wD2sfC3T9W+LAA1/Fqh1i91SwD7iL7VFEsUUwB9jec2m5FRCgCfJ+VkVxhw'
	$initialize_logo &= 'GgC+naqnUtRlFwDxSd32SvKSigB9UpTm7tLTlQBbQxlT9+FvhgARsvN2jHma6AD5YQWjfU/APwAJ/sSfFQ6v/wAABWi4uvhF8QADzviE16PB0gDL4Vu93iZW1ACv5QNPJizcgwD7lx5O7P7tvwC6a53/AIYU+ACzYfDD/glDDQCvwb+IkN18PgDxNPdeL0i8JwB4snhpX8QWcwCZL8CLNsGVXgBN023IDN0BNQD9D1FThZewlQAZR/5d+yt5+wAlO3387v6GmACf306s3/y89gCXXb2igvw5NAD1Z/Or+138KAD9pv4u/tB/tQD3gXUvgn8c/AA1Z+Nbu+k8LQBv8H/hzo+h6AAeLliWeWOfXQDxH5IuL+GSBgBpGtfNle4nuAB4x5cm2KuS8QAX7Bfxm179ggD/AOCbPh2b4ACvxSur3wT44wDEEvizTZfB1wDtJodtN4gtZQBXvYjDmGKSEADOGlAVkDHJAADX9K9FThf3CgCaWvI6b9XT5gC1/Xm19NNNCgDEy9s5N/a5/gBc8XF28kndHwCK1/8Asy/GTQAD/gvX+2148wDDPwb1TxFpfgAm+D17Y+GZtQD/AA7KfC/ivQBFrPSFWxaeVQBba4EjRyI0ZgBPmCSA4AbH5wB/7Sf7Ln7T3wC1N+wR4H0++wDgr+1dN4p8CwDiDdqPhq2+FwDYeEPAukQXBgDhon03RdOtogCa8u2bzGmvfACVEYkCMPnRmwD6uaKMO/YqkgBa+zUEr/3JygB3+fNZ21st9wBPSpWc5Sn/AAAzbfzhGH/ttwD1Z+JvxK+CfwATf2Jf+C7HxQCvizqHwE+IHwAZvAfx68BDRQDQtS8P6Sl1bwCh3D2llBJDqADJMyx2MINu6wAjyugET7gHwwCq/Bf7Jf7BXwATv23f+DcLxQAWvwz0e/8AEgBqPgf45XHiawC9B052F1rVnAB6LbQSfZAc+QDTRmXcqAMzAADBAz7Ub99P2gDb/ghr+yr+3AD/'
	$initialize_logo &= 'ABhuPH3xQwDhHp/iDxheWwDHbXWpW2salgCVJeLGMI0q2QDcRJLIFwvmOgCX2qi7tqqB7wBfs5fs1+BP2QAb4PaP4B+G3gAY03wj4R0GPwAuz06yU7VzywA7uxLyyMeWkgBGZ3YksxJJpQCHXJRlCW/LGADG2tlCr7WN3gCXs9Nru+5j8ADOPJqrtu+jbQDS9nK29r772QBbbofjH/wTOwD2JdY+Ov8AwQBS/h/8TZ/hvwDt7W9v8L9NSwCJvGnx/wDGEABaSWrtHcIdNgDWxl0t5ryAtACPjyrqIKJHZwARkqJP0O/4L0CH7HVn+2sAECsAvip4ekFrHrEA4b0yTxZolzMAbR9mvbBGnGEA2ICeZGssJbIAMLM2eM19jV4AMfttf8E9/hAAf8FF/h/pPhYA+MnhH/hMdB0AD1AarZWv9q0A7p/k3IjeLzMAfazRO3ySONoAxK85xkAiMZwA1Wh7Gn7ru2kA66Nu/N6rRpcAWyu7tsvBtUYAuq0tdErd0lYAt6PVPsnouh8AjV/wRZ/Z6+IAR/wVw/Zz/bAAfj14mvLWL4kAPxW8G/8ACp8AwvqU++OKFocASo47hg3LJHIAt9jDsucHzuAA8ivLfFf7M/wAdP2hP+CVPwgA/wBhvT/2S/gAueGfit4N8dQA91qfjLV/D6UAr4Pto0lvnksAuPVhmOQskyoAlkO2RUxG8xYARG/oY/Z2/ZwAvA/7Jnwc0T4AH/w58N6f4T8AB/h2HyLDTrMADFIwSWZmdiUA5JGYlmkkZncAYlmYkk121dUAWlTlVvFe5aEAptrTk5J3WqsAycnJX1vvdXMACgpwppP4k5MAT3spRULWemkAFRS228z8R/gAnfC/40fsD/8AAAcG+LvitH8AA34t/Gfwr8QAX4cWfhbStU8AB2lG9ie++w0AhaBry4dhDaIA/aLNvMaaQbIAOQSfMBg/E8UA/wAE+vj4/wAA8G7mqeCJfgcA/FxfGk37QqYBQHUI'
	$initialize_logo &= '+PCGoNqZALH+w/KN0LcQAPmGASfJ5oXZALuM54r+pCisAGDajaeukV8oANX2qVvW6fkzAKKdTka5dl/8AKvZf+k2fre9AO+nO/CPw5D4ADvhR4Y0i2s1ANOt9K0m1s4rAEWPyxapHCiCADC/w7QAMdsVBPghwKwB/YF8YwDgn9pn4/eMPwBmrVP27PgZ8QADVtSGpXnh3QA3wdqd94e+JABqM07yLJY6zgCNcvBBbqJXlAD9vJMZnZfkIQDjj/oRoorN1ACu67bTd9U9VwAzTunqunVNXgDNrRGWHXsqCwAOtUuXfb3drgC/yafZo/EP4gCH7LH7Qvjz/gALh/sHeNvifwCAPEfiTU/C/wAAD3TY/HviXQA3QpLvQ9N1eADbU3k866gjNgCxSrI8THayqAB2Up8pSvIvBwHgWyr+O37QHgYBYNGdeDdD8A+KALwtqfxE8a6dAKt4R/tvTZtGALHxdDa63qN2APFa3E6xwyK8AHsKvuMe6SLcAMqtuH9DNFKSAOaEobXdR6aJADnOE9F2i4JJAHbc0U2mmu1JAGvVUk0r7fEnAKtWa6WP5/f+ABTnxe/4KSeLAD9g/wCHfhj9AJl+L3wWuv2ZAM2V14v8W+MvAA0dB0u1itHsAASCwnYK1wXeAN2dY12SM7g7IDaHlT6ewBMa/iDLXjX4VUAsev0Au7xr4u+HviyA8Nab4n8VyyA8AN63q+h3NnbaAL2smp30rm0nAJUVJo2AgcmMALAjyz0xX6yUAFbxrNVHV6v2AI361OXma7aRAEkl3d27mMqaAHR9gvhXs7eSAKbk0vNtyd36AFkrH4N/sC/sAHvxg+HnxK/4ACgX7PWr/DH4AKfhzVf2gjrSAHhHxzJ4dnTwAIMPL1FovO1JAE7EE63UQXZvQOrq2GG032AKfQB8QPGvwF/YEwDAX7Kvi7/gnBAfEj4r8GNeKLsCF0ALDdtb+BLiAGa4uXOpnV7mAAuIBIiSGNXEAGyMgwkx'
	$initialize_logo &= 'DKp/AHVorGj+7UY7AKUacX5qn8L8ALR2fyas0mXVAPfcpbNynJeTAJqz9e6+ad0zAPFH41+BfjJ+AMS/8HFHjv4yAFr+z38T/iZ4AD/il8P7bw9oANJ4D0z+0LKzALxrOxtljuLlAIRw2sSXFmysAPMY9sTrLtI+IFr5t/Z6wApyfAB117/g2P8AjwB+AZ/hN8QtJwDiA3xSi8R2fgAZ1DQLq11XUwC0ij0zzHt7eQARZJhhZSvlqwBvMTKoJ4r+kAAorOMLUXSf8gCoryUantY+vgD2ju7tdmbe2QDzqXZp272p+wAn/wCS7W2d9wDp+If7T/wJ0gD/AG3v+Cb37ACvN4m+Ef7a3wALfiJ8KUtfCwDpPibw34Da4wBQ8F6hbwWaSQB/eaUlwuoS2ACzQCaK4tEEgADBjcjkRSfQ3wDwbz/Dz9p34QCviX43ab8YPABx8TviJ8KbfQBaCHwLr/xF0wB1DS9e1aRVYQBzPHZ6iWvrewBmTyQI5js3ggBjGTKT+m1FdQB7Z+1qVf5+ZgDXS8mm3bvdNgCtbfXmaTOP2AD+6hRT+CyT6wBo3sr9tVe99gB2sm0FFFFYmx1AAEA/AD8AMgA2aFYA4iZJFVkYYIIAODTqKAMKf4YAeg3D7n0u1ZsA6Gmf8Kr8O/8AAECbX8j/AI0gdBRQBz/gWq/DAL/0CbX8j/jRwckA10FFAHMgTBkDHh//A/8D/wMWAwvwtwDDynjSbX8j/gA10FFAENjp8ADplusVvEkMawDRVGAKmoooAP6iPwA/AD8APwA/AD8APwD/PwA/AD8APwA/AD8APwA/AP8/AD8APwA/AD8APwA/AD8A/z8APwA/AD8APwA/AD8APwADPwA7AAP/2Q=='

    $initialize_logo = _Base64Decode($initialize_logo)
    Local $tSource = DllStructCreate('byte[' & BinaryLen($initialize_logo) & ']')
    DllStructSetData($tSource, 1, $initialize_logo)
    Local $tDecompress
    _WinAPI_LZNTDecompress($tSource, $tDecompress)
    $tSource = 0
    Return Binary(DllStructGetData($tDecompress, 1))
EndFunc   ;==>$initialize_logo

Func _IsChecked($idControlID)
    Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>_IsChecked

func LinkCreateEvents() ; permet de fermet guiquestion
	GUISetState(@SW_HIDE, $gui_question)
	WinSetTrans($ui,Default,255)
	GUISwitch($ui)
EndFunc

Func _Logo_end($bSaveBinary = False, $sSavePath = @ScriptDir)
	Local $Logo_end
	$Logo_end &= '/z//2P/gABBKRklGAAEBAQBgAGAAAP/hAIRFeGlmAABNTQAqAAAACAAHARIAAwAAAAEAAQAAATEAAgAAABEAAABiAwEABQAAAAEAAAB0AwMAAQAAAAEAAAAAURAAAQAAAAEBAAAAUREABAAAAAEAAA7EURIABAAAAAEAAA7EAAAAAEFkb2JlIEltYWdlUmVhZHkAAAABhqAAALGP/9sAQwACAQECAQECAgICAgICAgMFAwMDAwMGBAQDBQcGBwcHBgcHCAkLCQgICggHBwoNCgoLDAwMDAcJDg8NDA4LDAwM/9sAQwECAgIDAwMGAwMGDAgHCAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwM/8AAEQgAgQI5AwEiAAIRAQMRAf/EAB8AAAEFAQEBAQEBAAAAAAAAAAABAgMEBQYHCAkKC//EALUQAAIBAwMCBAMFBQQEAAABfQECAwAEEQUSITFBBhNRYQcicRQygZGhCCNCscEVUtHwJDNicoIJChYXGBkaJSYnKCkqNDU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6g4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2drh4uPk5ebn6Onq8fLz9PX29/j5+v/EAB8BAAMBAQEBAQEBAQEAAAAAAAABAgMEBQYHCAkKC//EALURAAIBAgQEAwQHBQQEAAECdwABAgMRBAUhMQYSQVEHYXETIjKBCBRCkaGxwQkjM1LwFWJy0QoWJDThJfEXGBkaJicoKSo1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoKDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uLj5OXm5+jp6vLz9PX29/j5+v/aAAwD'
	$Logo_end &= 'AQACEQMRAD8A/fyiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACiiigAooooAKKKKACig9KBQAUU1gxddpUL/ECOT9KdQAUU3DeZnd8vpihm2kcj3yaAHUV+d/7bP/BwR4J/ZI17QtB8L2fh/wCN2pX1iL+91Tw74gt7bR7dWkkRIlkjN23nDy9zRtjCvGwY7sL832f/AAdQeLE8f3FxcfCHw/J4Wa2KwadFrkseoRz7wQ7XZiaNk2bhsFupyQd4A2n0qOU4qpHmjHTzaR4uI4gwFGfJKevkm/yR+0FFfm3+xt/wcjeAf2hfivb+FfHfg+T4WrqRK2etXPiG3utJhKxSyP8Aa5pltjACUREKrLveXDeWACfuj4VftL/Dz45andQ+C/iF4I8XvZhDNBoutWt/Lb7t+0uIpGIDCNyuQPuP1wcctfB1qLtUi1/XfY7cLmWGxMeajNPp2f3OzO8oooHArnO0KKKKACiiigAooooAKKKKACiiigAooooAKKKQtg9KAFopu72o3e1ADqKbu9qGbJoAdRTTzThwKACiiigAooooAKKKKACigjNJnHrQAtFAOaM80AFFJ/FS0AFFFGaACiimrIrlgrK204OD0PWgB1FGaFxjj9KACis/xN4t0rwXp0d5rGpafpNpNd21hHPeXCQRvcXM8dvbwhmIBklnliiRRy8kiKoLMAdDcKACisHV/in4X0DWr7Tb/wAR6DY6jpdpBf3lrcahFHNaW87zRwTSIzBkjke3uFR2AVmglAJKNjifEf7dXwR8H3a2+r/GP4V6XO671jvPFlhA7LkjIDSg4yCM+xqowlLZGc60IfG0vVnqlFeOxf8ABRD9n+cZj+Ofwdceq+M9OP8A7Wpzf8FCfgGDj/hd/wAIf/Cx07/49Wn1er/K/uZn9ao/zr70ewUV'
	$Logo_end &= '4/8A8PC/gF/0XD4Q/wDhY6d/8eprf8FC/gCPm/4Xf8IMjj/kcdOz/wCjqXsan8r+4PrVH+dfej2KivnfXP8AgrR+zb4eLfaPjL4Ik2qWP2a9+1cD08sNk8dBzXE3v/BeX9k/TZWjk+KqsyHH7rw1q8o444K2pB/CrWDrvaD+5mcsywkfiqxX/by/zPr6ivjtP+C+v7Jkn/NVJfx8Ka0P/bOpP+H9P7J4H/JVf/LZ1j/5EqvqOJ/59y+5/wCRP9qYL/n9H/wJf5n2BRXx/wD8P6v2Tz/zVQ/+EzrH/wAi0L/wXr/ZPb/mqp/HwxrH/wAiUfUcT/z7l9zD+1MF/wA/o/8AgS/zPsCivj6X/gvZ+yfGuR8U2c+i+GdX/wDkWue8Q/8ABxD+zDo1s0lv4l8Rasy4/d2nh+5Vj/39VBx9aawGJe1OX3Ml5tglr7WP/gS/zPuKgjNfnTrf/Bzh+z9pUm238PfFTUhz81vpNko9v9Zdoeazl/4OhfgNK/zeCPjEvHU6Xph/9v6v+zMV/IzL+3MB/wA/UfpPRX5v/wDET/8AAQr/AMij8Xc++lad/wDJ1Zuuf8HRPwdt5B/ZvgP4l3S9zcwWVuf/AB24eqWV4t/YZLz7AL/l6j9MqAMCvyS8Rf8AB1VpNtMw0n4KajfR4+VrvxQlqxOe4W1kxx3yf61jD/g61uMt/wAWBt19/wDhOSf/AHHVayfGP7H4r/MxfEuWrT2n4S/yP2CurZby1khffsmUo2xyjYIwcMpBB9wQRUgGBX4p+Jf+Dpnx5d20g0n4V+EbKRhhDeajcXSrz3CiPPH0rjLn/g5/+PzN+58I/B6Nc/x6TqL/AMr4VqsjxfZfeZS4qy9bSb+T/Wx+5+peGLbVde03UpZNQW40rzfJSG/nht38xQrebCjiObAHy+arbDyu081oHkV+DM3/AAc1/HK4vLe5k8EfBeS4tSxhlbR9Q3xFhhtp+3ZGRwcdRVh/+Dn/AOPjHjwj8HwP'
	$Logo_end &= '+wXqPT/wOp/2Di+y+8lcV4B9X9x+22j/AAk0vRvinqvjCO98TSatrFtHaT283iLUJ9KjRAoUw6e87WkEh2jMkUSO2TuY5Ofzi/4OF/8Agpl4y/Zp1Hw38Jfh7qGoeG9Y17Tl1/V9ctS0NzBbfaGjt4bWZHDKzSW0/m/KPkEYBIdwPjLQv+C+Pjzwt8YtU+Iml/Bf9m/TfH2uWgsNR8S2vhG4h1jULcCICGa7W7E0kYEEACMxGIY+PlXHz9+3F+3F4y/4KG/Gay8Z+MNP0Kz1ez0qLR4LfRLWaOAQRySyj5ZJJXLbppCfmxjsMGu3L8lqwrKddKy+evQ8vN+JqFXDSp4WTUn5W066niuMDiv0t+An7Dvwz8Qfs4eEo9Z8KRXl5qVlaaxeXE8skV4bmS3UsnmoyusalyBECE4BKlvmrzz/AIJu/sXXfhq6k8eeM9Jms7xfMtdL0rUbQK6KRte4kRxuQnLIoIBI3NyrKa+z6/QsFhLLnqLfoz+UuP8AjF1KywWXTa9m7uUZNXfZW7d77+h8U/Hb/gkyupazaz/DnUrewguJZnvLXWryRorYMymJLcxwu5UAuD5jM3C8k5r5P8jx7+y38SvPt5/E3gTxVpplWG8srmbT7uNWDws8M0ZVijqXXfGxVlJwSDX7DUEbhWlbLac/h0/FHnZJ4m5jgo8mJXtktm3yyX/b1nf5rtqfLn7N3/ByZ8bvh9r2k2nxBj8OeOvD7aksuq3baStrrC2h2q8dsbd4bYMoBZfMiJJJBYAgp+sv7GX/AAUo+DP7bMselfDvxNc32uWulrqF1pF9aXMN7YxDyVcSNIuyRkeeNGeOSRS2drsATX5efFn/AIJrfDj4seNJdbb+2PD8txGqy2ujPb29rIwz+82NC2HPGdpAJGSMlifiH4rfsPfE74O6Zfahq3hmW60jT5HWS/0+ZLuFo0DMZyinzUh2qW3yom0Y3BScV8rmHDMHrFcvmtvmv+GP3fhXxdw2K9yV'
	$Logo_end &= 'TXT3Zuzu+kX1+5n9UbDcMevpRX82f7H3/BaX47fsa6AdF0vW7Hxh4fhtIrKx0vxSk15b6WkZJXyDHLHImASu3fsC4G35Vx+wf7OP/Bdb9nf426N4YtdW8faV4R8WaxYxy6hp+qQXVpY6ZdC382eFr6aJLfajB0V2dRIVAXJZQfkcVk+Io6pcy7r9V0P2HL+IsJiVZvkl2bX4PqfZOOaKoX/ijTNLu9NgutQsbWfWLg2lhHNOsb3swhkmMcQJy7iGKWTauTsiduiki/mvLPeCigNk0UAFFAORRQAUUUUAFFFFABX49/8ABT//AIKN/Gj4Gft0eOvCvhTxxdaP4f0l7IWlmllaSLDvsbeV/mkiZjl3Y8k9fTAr9hK/A3/gsv8A8pKfiZ/1007/ANNtpXy/F1apTwcZU20+ZbadGf0H9G3I8vzXiirh8yoxqwVGTtJJq6nTV7PrZv7yj/w90/aK/wCil33/AILbH/4zR/w90/aK/wCil33/AILbH/4zXzfRX5v/AGhiv+fkvvZ/cv8AxDPhT/oX0f8AwCP+R9If8PdP2iv+il33/gtsf/jNA/4K6/tFA/8AJTL7/wAFtj/8Zr5voo/tHFf8/Jfew/4hnwp/0L6P/gEf8j91f2Ev2sfE+u/8EwLj4reMLqTxVr2h6drOqT7zHam9W0e4ZIsxptTKxhdwQ46kHofyu8e/8FEfjZ8S/GWoa5c/EzxnpsuoyeZ9k0nWLiwsrcABVSKGJ1RVCgDpknJYsxZj9/8A7Dwx/wAEHvFX/Ys+Kf8A0G9r8mLfpX6/kcpTwVOU3d2P85uJsBhqHEmY0aUFGMK04xSSskpOyS6WPX7b9tH4xEjd8WPiV0/6Ge9/+O1dj/bM+MBA/wCLrfEn/wAKa9/+OV5Nbfe/CtCL7q167PLlQp2+Ffcer2n7Y/xcYrn4p/Ec/wDcy3v/AMcrStv2wPi0W/5Kh8RP/CkvP/jleS2nVa1rX71SZSo0/wCVfceqW/7X'
	$Logo_end &= 'XxXJ/wCSnfEL/wAKO8/+OVesv2tfiozfN8TPiAf+5ivP/jleW233q0LDqaCfYw/lX3Hqtr+1d8UWxn4kePv/AAoLv/45V2H9qn4nE/8AJRvHnX/oP3f/AMcrzO0/hq011FYwSTTSRwwwqZHd2CqigZJJPAAAPJ46+9Bn7GHZfcemD9q/4j2VvJNcfEnxvDbwqZJZJPEF0FjQcliTJxjHU8flW5+xB/wWF8Rad+2v4R8A6r4iv/E3gvxZqC6Jd3d/LJfTLfXGIrVraRm3BPtBiRiSyFZHYLwrn4d/aq+MVt4kjs9D0XUvtNpDmS+MDAwTt8pjXeD823lsfdyV/iUhcX9h8f8AGb3wU7/8XB8Pduo/tS2oLqYGm6EnJa2P6f0bcuaHcIuW4FC8Y+lJPOtvHubdjIHyqWP5Csz4wdTfMXzNv8WM4p1N3fN0NADq43QPir4S1LxL4xsdHuLW/z/jWPDGrw6Z4jit4dk1veyWFrdRiUkDeTaT2pDAsNpVc5Qqv5n/APBxh/wUF+IHwC+JXgf4b/D3xV4i8GyXeiya7rN1pc4t5LxJbnyrZEmUCWMxtaXBbY6hhMAwIrkf+CAHi/40fHXx3408aeNPiF458VeBdH086HbW+u6/dajDJqLyQTl41mkYK8UKgFsZxdLyATmc6o1MHlM8xUlGy0v3bsvvPLw2b0quZLLowbd9X0Wl3935n6BfGv8A4KcfDv4Ma1f6TcTahqWsaa4juLKztGaRH+Xjc+yI8NniTsR14Pnyf8Fn/AwX/kBeKh3wLG3/APkmvzq8W+Jrrxr4r1TWr/yzfaxeTX1yUGFMsrtI+B2G5jgVnk4FfxljvGHiOrWcqVVRjfRKKWnS/mf6AZX9HvhilhoRxSnOpZcz59L21tZLS+3Xu2foX4s/4KzfDbx5p0dnrHhjxHqdnDd21+lvd6TY3ES3FtOlxbyhXmYCSKeKKVGHzJJGjAgqDXlGu/tRfBfWdGntY779pixkmjKC'
	$Logo_end &= '4h+I+tPJHnuBJqroe/3lYV474+/Y88bfC7RNLvvEUfh7Q4tZmitbRdT1+y095bmVGdbcefKgM21WOwEt8rYBwa5n4l/Arxj8HZ2XxN4b1bR41mEAuJoCbWSQqXCpMuY3O0E/Kx+63ocOtx9xphYqvVnUhF7NqSTt57Hm4Twp8NMxq/V8NVhVmvsqrGUvuWpR8QfsZfsx/GjxJNJrXj39oaDUL4YGreIrnT9QggwzPsfZE8zKSzAHnDOWY4ya3IP+CA3gy/sba68M+KNa8VWN3KYvP0PWLGeGFwoYCRvswC5Ug9TjjOMrnha+uP8AgnPa6p4u+Bvxm0G1ubjbNpscdmiH/Uzz293GXUf3j5cYz1+RfSvueB/HriWGLWFxfLXUuZrmVtVFu11Z20Xz9WflfjB9FfhdZW8zyuvVwsoOEZOMrpqVSMb2kmrrm7beiPF0/wCDenw/p3h+61TVvEniHR7exjeWcX2rWuIo0Xc0haK1ZQuM9+xrgx/wT2/Zf+HFw9tr3ij4ieLbp5CoHhy5gaG1C4+/JNBEr793Hl7sbDk8ispHkdcyK0bf3SORSjrXLnX0kOJcXTlSw0KdG/WKu1rsm9l63fmetwp9C/hjLqsa2aY2virLZyUIu6teSje7W6tyq9tD6TT/AIJVfsy+Lf2PovF3hzwX4gjluECw6jqWs3Q1Bil6YHZ445jbgkqw+VANpBwG6YS/8Epv2e/hj8BpvHnjjw9r8ljJLFHZ21hq0y3U+5ymAskiqSeXABHyIzc8Cvo74Bfs9aL+1V/wTP0bwH4iuNWtdH137R9ol02ZYbpfJ1eaddjMjqPmiXOVORkcHkfN/wC3X8eNL+KXjnTfDfhu0sYfCngON9N02WAh1uOI1dkI+XygIkVMZyFLbvnCr9bivGDMMu4QglVcsXVkpcz1ai4Q0V72XNd2WmlvtH5Hk/0fcJn3ibWpq8cuwqnCVOLcU3GrUScmmrylHlguv2teQ5OT9iD9k24e'
	$Logo_end &= '1j0/UtOklumCbb5NdtvKYnA3MrugHTLEgDn0r0XQP+CJfws8YaX9u0fTfBeqWTHAuLPxNqU0OQAT86uR0IP4185E4H/1s19p+O/iD4f/AGRf2JNF8HWul3E2vfEjQJbq6SaXbJbTXMMSTSSrwygLIUjGBkwYOSGry8h+kRxPVp1J432XLTV3L2aTbvZKy018kj6Xjr6HfCeFrYajkuIxnta8+VQ9vKSUUryldtNKK11bv5HzlYfsNfsmyDbea3ptrIpKsIotemGR6E7cj3qjqn7JX7IPh68ZfsfirxBHGcbtNiu7cSD2M92pHXuo6H2rhwMCug+FPgGb4p/EzQfDcLzQtrd/DZtNFAZ2t0dwHl2AjcEXc5GRwpyQMkfNV/pEca4qXsqU6ceZ2SjTj183d/ifouF+hv4cZbB4nEzxVSME23PE1LWWrbUeW+i2t8jcg/Z5/YuKDzPAfxUDAdtRXk/+BVDfs7/sWtwPAfxVX3/tEc/+TNepfEX9kT4RfCPxTc6H4n/aQ8E6Drdls+06ffQ20N1bb0WRPMiN7vTcjqwLAZVgRkGqPg39mL4P/EjUJrPw7+0R4b1y6t4/NlSx0oT+WuQMkrckDOfx59DXtUeKvFerZ0ozlfa0YO/pqfH4jg/6P+Hi5V8S4Jb3qYhW9W1oSfBr9h39jf4j+G/EmrWvw78WSQeHxbrKmq6xdxNK83mbFi8i6wT+6bO7GOD0zjz0f8E5/g1j/kTR/wCDa+/+PV9G2fw48F/BX4Ot4f8AD2uN4j1bUtWjv72+aya2JSOBo1jweNoZ3ZRkkeY3PQ1gV/WfhFgc4/sT61xI5vE1G7qaaUVFvl5Yva6erS107H+bv0juLMmXFTwHAta2ApRXJKnNtzlJJzcpp3lZr3U9Ypvu0eIn/gnN8GT/AMyb/wCVa+/+PU1/+CcHwYfr4Ob8NYvx/wC169woJxX6p9Xpfyr7kfgP+smb/wDQVU/8Dl/meG/8O2vgvj/kT5P/'
	$Logo_end &= 'AAdah/8AH67T4S/8EhPhj8VDff2X4T06FNP8sSNeavqHzF92AuHbptOc46ivg79sr9rvxxq/7QPibTdH8TeINB0fQtQl062tLG8a12mEiKRmaPaX3yIzjeTtDYBxX6J/sk/tYax+zl/wS1+GeqTQ6lqvjbx9Jq90b3Vp5ZJSEuZo47tmkJZwIhZhBnayAEcHNfl/ibxtT4cyeWOoxSlzKKbSaW7bt1ulZebTP6X8HfCPPuLM7w+CxOMqSjOLk4KpNN+7ouZuy5b80nrpFpXvc8/PwD/ZD8EzQxHRtY8VLLGJjPpemtHDETx5Z+2ShywxnIXbhhjnONaz0H9kSzPy/DfxOyjjEmj6W+fxLE14qKfa20t9dxW8EUs88ziOOONCzyMTgKoHJJJAAHJJr+Ga/j1xpWqOaxNr9FGKXySR/qphvoheGtChGlPD1J8v2p1pyb822/8AJH0hbeLP2PIYsN8DEkb1bQbL+k4pt94p/Y9u7eSOP4G/Z2dSqyx6BY7kJHUbpyMjryCPY15lJ+y34rf4pTeCbWXwnfeK7fPmaRB4q0w36Yj83m2M4mH7sh+U+6QenNcr4x+G/iL4ePCuvaFrGi/aSwh+3Wclv523G7bvA3Y3LnHTcPWs8X4nceYVqpia9aHVc3Ok/PV2a/AWXeAfhDmL9lgKVGq9rQlTk1vp7qbT0fnoe3eDfhH+zL8YtdttH8PeG9N8Pa1dzpbWlv4g8L2TRalLJkKkclurCPBABMnUuoUE5Fdtff8ABL7SbLXVsV+GHgG4RsYuo9KsxBj5cklkDDG7oVycHAIGa+Qa+4PETa18e/8Agl7Hrd9q1/da5przXt46ysWn8q8lRkk7lRbspwePlB7V+hcG/SG4njRrUsUoV5QhKS5o20W+qs7rpuraW2Z+I+LH0M+DY4rB4jLK9bC061WFKXLUclFy2aUrrlaT5rWadmnq0c/4w/4Jo+Bfh3oLapr2hfBrR9PD+V597Ywwxl8FgoLQ'
	$Logo_end &= 'csQCQBknHSuB8LN+zP8ADHXbO8j8MzX2s2od11Hw34fs7SGLeGTYjTLHNu2E7iAAdxGSM18+06L71fPZz9JDivGQVLDuFFX3jFc332Vl8r6bn3HDP0GeA8tlKtmdStirppRlNqGtt43k29LaytZvQ+8/2nPAek/Dr4gWthpNqtjbyWKyunmvIC/mSKTliT0UVg/Fi4+H/wAEE0DS/E2peJrLxFq2mR6pMtvZJcQWyOWUKyllbduVujN/q2zjK17R8Rvgd4M8Hftgx/HbxZ4isbG4s/DS+D9Otb8ww2sLNdT3DziSTJaZlbYqrjaglJ3bvk+AP2nPjpe/tCfF/UteuJmksY2a00pGhWFoLJZHMSsFz82GLMSTyxGcAAfovHHjhmWW5PhMHldZrERXvzk+ZyfVNSV7K+7bu/S5+A+Df0Tci4j4kx+ZZ7QUsFJe5TinTUL2S5XHS7absuWy33sfQml3PgDxXcLHo3xQ8K/KoMp1lJ9HCEgkAGVNrdCDhuDgfxCup8c/s/X3w28D3HibWtc8P2/h+zWKSa9ia5uAqyuqRsFjhJYMzryAeDnpzXxB4b8M6l401630nR9PvNU1S8LCC1tYjJLKVUscAdgoJJ6AAk8A19Qf8FQfHi6X4u8N+A9HeG00Xw/pKtJbWsxwpkYBIJUzwI44InQHnEuehFfO5b9JHix5dVxGI9m3CyT5Lc0nffppa7tb5Xufe8QfQT8PIZ/g8uwEqyhW5pTi6l3CnDlvZ2veTfLFtNJ3etrO5ZeMPhTNBuuPipawvjlI/DuoSfqY1rD1L41/Bt7Sa01Ofxn4gs7hDDPDb6RbRxzowwQRNMQVIyCCOc/WvmGvTP2Uv2cJf2oPiZN4ej1ZdFS2sJL+W4Nt9pbarxoFVNyZJaRf4hxn6V8w/pDce46osPRrRTlolGEV+L2+8/Q/+JJfB3I6E8wxuHqyhTV251ZySS68sUr+ln6EXjz4K/sdfEB7iaXwR8SdLu7iF41l'
	$Logo_end &= '0z7JZi3Zk2B1ijlEO5cBhuQruGSGywPncP7EP7JsdyJG1T9oxlDZ2GbRQv5iLP617fcfA34B2+Sf2qPhy69QYzayZ+m29Ofw61qeLP2TPhb4M+HEni7UPj1osXhxLaO7F+mhtNG0Um3y2Gyck7ty4AySWAHJFezT4k8Wqr9yNSXpGL/I8pcN/R8wMVCWKUE3Zc0qu/Zc0fwR6Z4p0KP9kH9jqx+LHw50vx5428R+HF0tfAmkePvEdzrFpaNfPb6fFLbWouTDDJ9mvZYkMflyKsssYKRyOD634X/4KQeKPg3+zp4D1r44eFodN8ceMYZ7qTT/AA5BugtIlZGjDrPPlJBHLEGUSP8APuxjoPlb4l/txeC/+CiH/BQT4H+CvB+rXmrfDHwDdzePte1iK0nsIre+sobh7Yz/AGi3RoYIWjQNJkRuL/ZkMFNV/wDgof8AHu0+NHxuWz0e+S+8P+GbcWltNDMJLe5mfDzSxnA4J2R5BZWEAYHDCvc444uzfh7JqdGvUf1qq+e8k+dRvyqLTei92UtEmrxR8x4TcF4HiziSo6dNrA0lJNRfu3tdWl1d5RXmlJpW2+pl/wCCz/gfezf2B4rDMMZ+wW+TjPX/AEmoLj/gst4Lfc39neMoR14sbPA/76uP5mvzkr6g/Y08A6P+zv4c1D45fFK41Xwf4W8MJC2nXstu8kd0t2GtjI0Ecck7RkzwbGVQCZN2Sqtj8ryfj7i3OMbTwOHrNyk0tE+vo16JX1enU/oDi/wv4F4byqrmmMhK0FonUtzPok2n83Z8sbyasj9IPh3r+ueL9Ntbu6jk0tmVJZrOdUMsG7nym25XeBw20kA5wSME9lJKsKbmIUZAz7k4FcL+zt8efAn7Qvw7tdc+H/inRPFWklI/Mm0+5WRrd3RZBHPHnfBNtdS0UgV1zggY/z+uy1nWIdCsvtEy3UiGWOEC3t5Lh90jrGvyoC23cwy2NqrlmIVSR/WWT5fXwmHVPEzlOp9p'
	$Logo_end &= 'ybevbXa3lvufxnicTTr1HUopKL2S2t/XqWqKKjW5Vp2j+fcvXKEL+Bxg9e1eoc5IelN3fWnMcCo/Kb1X8j/jQBJX4G/8Fl/+UlPxM/66ad/6bbSv3yr8Df8Agsv/AMpKfiZ/1007/wBNtpXyXGX+4x/xL8mf0x9FX/krq3/Xif8A6XTPmGiiivzA/wBCAooooA/YP9h//lA74q/7FnxT/wCg3tfkxb9K/Wf9h/8A5QPeKv8AsWfFP/oN7X5MW/Sv2nh//cafoj/Lni3/AJKjNP8Ar/U/9LZp233vwrQi+6tZ9t978K0IvurXss8Uv2nVa1rXrVr4TfCvxF8ZvF9roPhbRtQ1zV7ogJb2kW8qpZV3ueFjjBYbncqqggswHI+4Ph5/wQr8W3/nHxN468O6QNqmEabaTaizHJyGDmDaAMYI3ZJIOMAmThr4qlT0mz4lt/v1oWHU197Qf8EJGUn/AIuopP8A2LP/AN1fz/8A1+WfGr/gkz8Svg9pFxqmltYeNLCF0HkaUkv9olSBl/s5XkBuMRs7YYHaBnaGNPH0JuyZ8zaprMfh3QrzUJlkeGxt3uJFjwXZUUsQMkDJwepGT39Pnf42fH+f4ngafpy3Fpoow7xvhZbtuD8+1iAoI4UHGRk5ONv1P+x5+xf4u/4Kb/ElbWFdS8L/AAb0WZW1nXzCY5NWdTxbWm8FXmYqeoKQj95ICxiid/8AwWm/YB8A/sE+HPhFpngePUpG1wax/aN9qdys95fvE9o0ZcqqoNqzbFCoqgKCQWLOwdVHEUfbKjvJnwfndz+P1r1D9h7/AJPe+Cn/AGULw9/6dLavL+v4816h+w9/ye98E/8AsoXh7/06W1B3Yr+FL0f5H9P47fSlNIO30pTWZ+dhUbTMs4Xy22kE7h0HTr+v5VIK4D9pr9onw/8AspfBjWfHvi66+w+GdBEP2y5VHkaMzXEUEYCIrE5eVRkdPTGSKjFykordkzkoxcpaJH4V/wDBxD8c'
	$Logo_end &= 'tM+Mn/BRzUNP0za8fgDRLPw1c3Ec6TR3NwrTXcm0qeDG135LKeVeFwcYwPrT4XeG9U/Y1/4I9fDOHw9fR2Oq+Nnj1LVr6xj8mS5XU7a4uVDHr5kcH2aEuME/ZlIxwB+bn7N3wnvf+Cmf7fH9ja9rU2g6h8SdS1TWtR1Kxs/tAtJTFcXjlY2YYRpF2DLALvA5OAf02/4KefE2G38X6H8NdDWzsfD3hOyglextYfJjt5yhWKLaMKFjtymwLwBMw7V+e+PmewwGSU8rhNqbSbt81HXzfM7La12tj6n6OfDs874w+vzgpU4tt3V1yqzd184JXW7Wu58r1c8OX9ppfiGwutQsRqljb3EctzZmYw/a41YFot4BKbgCu4AkZzg1Tr2z4F/smaV8UvgD4o+ImueM/wDhFdD8IvdPqDf2Q995Nvb20dxJNhJA7YRz8iozHbxkkCv4ryzLsTjsQqGEjzTey01+/R+nU/0h4iz7LsowUsZmlT2dLZytLS/+FNr1W3c7z4kf8FBvA/ximibxb8DfDPigQhQi6vdw3qx4LEbRLasoI3PzjPzt6mvFPib+0t4s+K3hOz8O6lc6bbeGdLlSTTtJsNNt7O105Y0aOKKIRoGEUaOUVSTgAZyRmuu+EHwA+E37SOmsnw6+P3hjxHr919oj07RLnTTpmo380ULSlVt7iZZ9m1STIsTKArHnaceYafc6h8JviC32rTrFtS0O6eC5sdStI7uDehKSRSRuCrfxD1B5UggEfVcTVOJsMoYPPHOnF/ZdkvPRWXyZ+Z+H+B8PsVOrjuEadOrVhZ399tPXladRNxvs5RXr0On+Hv7LPjj4hzQyJot1omkyWTai2tazDLZ6XFbKnmec1wUK7CvIIzkc9ASPqb/gnd4++GPw4+Il38MvC/jbQ/iJ4x1jSH8V6jqXh6eO80yytoJILZLVpkkZWkEs8jKu0NsZmcJlA3CeJ9Yg/wCCq3w0k+Hb+L9d+DHiSxs1ht30XVZG'
	$Logo_end &= 'sPEUEi7b23msFMKzQ+VHxE0rMgfO5kWQP4x/wR+/ZO8WfsUf8FQPF3g3xtaW9vf3fgO9u9KniuY5l1Kz/tW1SO4ARm8vzPs8h8tyHUDkdK/WeAuCuHamVVs3o4l1MRTi2o2cbdG9d/Rarro03/PfjF4mcXyzOHDuYYVUMPJx5rNS5teaPvK+m22l13TSv/tveDLH4e/tQeKNH01Io7Oz+y7FjXao3WkLnA+rGvKR1r3T/go9oraV+1x4imbcV1CCzuFyOwto4/5xmvC6/n7OKahj60ErJTl+bP7H4MryrZBgqs5czdGndvdvkV7/ADufR1x+16PAX7E/hX4faGLldbvra5ubrUrS/ED6X/xNp5Ejwh3+Y6KSQxTCSIRvD/L84KNq/QUte8/sp/sv6F428M6h48+JGtW/g/4e6RIkZvdTmSwtNQLl4Ti6kkRYgkxhXcQwdm2AggiuqlHHZziaWFpLmkoqMV0SSt/wX16LojzsRUyXhDAYnMsQ+SNSpKpN7ylOcm7JX+SSskk5O3vSOj/Z6/Y007w9L4P8TfFHxFYeBptU1+Cz0nw9rccEMmvy74mjgAllUl5Tvj8nyy5ABwQwFcv/AMFFfirY/FP9pW8XT4ZoYvDNt/YUzy4/fzQzzNIyjsoaQqPXZnjOBvfsM6hD/wAFQvGN9+0d8WLi10/Q/hdqb6d4X8N2zyjT9CltWg1A6nK7uwkn2yRIzrHGGERyAAqr4P8AEjxj/wALD+ImveIPsv2L+3NRuNQ+z+Z5nkebK0mzdgbtu7GcDOOlfoHiFw/heHMLSymhK9Vu9X/Etkn5X1tZX2vZs/G/BnijMuM85xHEOYL91Sjy0baKKm9dLXbaj1bdtXZtJYtfR3/BOXQvDmhfFlvGXiTxZ4f8ProMRWxtr2/hha9eZJYnPzSKyhFzwVO7zFPGAa+ca9E8L/so+PfGHw+t/FVnotsvh663eVfXWq2dpG212Q582VSPmRhyBnGRxX5zkvtl'
	$Logo_end &= 'i41KFJ1ZR1UUm/R6a6O3zsfuHGawlTKamFxuLjhoVVyOcnFaPeKc2leUU13tdrXVO+P/APwSn8I/tDftC+MPHeuftC+E7iXxRq09+sL67bGS2hZz5NuJGVspFCEiUdljUDgYr2D9kf8A4JoeG/hHFri/Dzxd4b8QPerb/wBpPHrgvzFs83yyRFCNmd0nXrt9jXz/AKx8KL7QCRfa14Bs9rbCJ/HGixYPp812Oa+xf2PoPDH7If7K158RtW1yzvG8XIMR2d9Bf2tzLBJdCCK2mt3kSRpFPJUkKQxJAVsf1BkvjRxlRcY4nCxoUYR+KVNxSSVkk5WV/JdLvofwPxz9GvgDFYOUMFmtTGYirNKNKnVpy5pSkm7qnqkkm03pey3aHy/sv+Oohn+wZG4z8tzCxx9A9UZ/2f8Axpbj5vDuoY/2VDfyNfH978W/FmqazJqV14m1+fUJBhrl9QlMhGS2N27gbiTgYAJPFXrf4/ePLRsxeNfF0Z9U1i4X/wBnrWn9LLMlpUwdN+nMv/bmeRW/Zt5S4r2WbVL21vGL1+UUfVyfAzxhI+3/AIR3VM5xzCRV2w/Zu8cX8oVNAuo/9qVlRR+Zr5Ib9or4guPm8deMmz661c//ABdUb/4zeMNTX/SvFfiS4Xv5upzP/Nqup9LTH2/d4KF/Ny/zMqP7NvLr/vc3n8ox/WJ5L8ZP+CNn7Sfjv4w+LNZ0/wCG5ay1fWLu+t/N8Q6THJ5Us7um5TdZUkEZB6HNfbn/AAVB8VeH7bxR4R8DaDawWMfgiykja2tY1jtrKOZYPJt0VeBtjiU4wPldK9w/4Jm/DKfwn8E7nxNqEl1NqXjO488mctuFvCXSLg5OSzSvu/iWReMcn4q/aq+Kdl8af2gvE3iXTYzHp+oTpHbEknzY4okhWTkAjesYfBGRuxzjNfA+KHiNmHEGTUHjoQpuTbUY32dpXd29rR6K12tT9t8B/CnAcO8YYmlgas60MLHl52klz25LWXk6'
	$Logo_end &= 'i3d+VPTY8+rvP2b/AIx6d8CPiZH4k1Dwvb+KmtIWFnBNd/ZxaTllInB8twWVQ4AI4LhgQVFcHXvHxF/ZY8B/Av4AeE/iJ8QviufCmi+LI7NYGHhi4v1S4uLZrhYcwOzHCxyfOVCnZ2JAP43kGVZljcUlldNzqRs0lZu/Sye/3M/p/jbiLIcrwDjxFV9nRq3i37+umqvDVaeavsWPH/7X/gXxNql54i0j4F/D/R/H81wL228US2VneX1pdhwwuQzWqu0q4yrF/lYKeQNp8n+I/wAXfFXxt16K68Raxfa1dhiII2wI4ywUERxIAi7tiZCqMkAnJ5r1TX/2LdH1n4Bah8Q/h18StB+JWj6WA90NMgCmJQiySBissgSSON0do5NrqpJIBAB8g+GHxEvvhP4707xFpsOn3F5psyTRpe2iXERKsGHDglTlRh02uvVWU816nEWKzz28cLntSaskrO2iv2Vlp23PneA8v4P+p1Mw4No05NN+97yfM0tOaac4pq22m+jdzvPAX7HviPW9M1LV/F1zZ/DHw3ob251DU/FkcumxLHK5XdGZVVHK4+6zoCzINw3ZH0b8DP20/hP+1D+zf8Z/D/wn03UrHSfBHh2eS4afT1s7a5a8tbpleJd5ckNA4YuqnKjG4YNeLftvfstaD/wUP+Aus+M/AfxH8a2d14P0m78T674MuLnVtet7vVGt3nhgt4bmcR27KyTwqbaNo8SAIgC7W8c/4ITNFD+zj+1a3y+Z/wAI5ZEZ6lRbatn8sj86/dsj4FyLDcIYvOcFWdWsopXtZRvK1uqd03s7d1dWX8n8YeJnFGbca4LJc3ofV6Uai9zW7dk762fRNcy2fu+67vFozg9M0A5or+WUf6B7rU+gv+Chv7SK/Gv4wzabouqSXXhTQwkcKwXJazvbkby9wFwASvmGJW+YYQspw/Ph/hXwbrHjvU2stE0vUtYvVQym3sbZ7iXaCFztQE4yyjPTLD1rNAzXttp8eYf+'
	$Logo_end &= 'CWHwG0j4q614Zh8Q+KPH2ox6TpOjSeIYrGSXR3tlunvo1RJmZRKkKMGQbfMiyV3gP9jkeT47irOlh6SbnUbemyXZNuytsrs/LuJs+yvw84WVRW5aSUYp7zlpdu2rb+KVl6LZH1P+wB+yRc/BHwu2va8lrca14jt7a4ht3sCs+i/JITGZHAdZGWYK6hV2spXLjmvg/wCMXxHuPjB8VfEHii6WRZNavZLhI5HEjW8WcRQ7sDPlxhIwcDIQV65+zb8cPiZ4e/ZZ+KXxc8c+L9c0fWvjVqC3fgHw1qV5NcnSdOWcl5rJmfEaGK8GwBI/lto5PmDqB8/17PiJgaOT1oZDhpqSpaya1XM7XT63T5l22tpY+R8DsZjs++tcX5lC0sQ1CF1ZqEd7/z9olytclnveL5veTuV9Qfsm/CPR9D+GHizWLr4ueFfCOveNPC+oaDYW6arBDeaM84Xyrsy+aHjlRk3BAuR8p3A8D5fJwK9Y8U/sRfEzwRpX27WtD0/SbPds8+917TreLdgnG55wM4BOM9Aa+V4brYmhjI4rC0HWlBppJSaTvpdLe9no99T9E8QsPgMZlksszDHxwkKyabbgnKKWqXO7K1021qtNVfXg9F/4IifDS0nj+2fHrwfdQr95ItdtYd3Pr5bYFbv/AAU+/ZF8afDD9h21vNJ1jwbH8NvDEWnfvLXX7ia91qEulvbRLH9mWKVAJI5ifNO7ZuCkopKx/s5eKJvDc2sI3hWTSbeOSWW9XxbpBt40TdvZpPtW0Ku1sknA2nPQ16F+2V4y8G/t/eK/g/8AspfDDxnDqGgrjU9a8V6Tu1GDTrews7iKKCRUIikEjAHeZdiuLc4O5d39hcD+J3GWZYpxzTDewoRSlOTpyj7iu5avyVtLu7SV2z/OXxQ8FeAMnhQxGT5k8diOaSjFVqc1CWii2qb0d5ac3Zvo7cl+wj+yLrP7Ev7BPxM8e+MNO0/SPGXxIs7TSdJgu0i+2RaZOkbPGpb5'
	$Logo_end &= '0kkE0jSQYDA2aM3KAr5gOlfU3/BT34+2fj7xrpPhHQ76O60rw55sl+Id6qt+HeExupABMSoQGH/Pdxz2+bfBPgrVviP4rsdD0Oxm1LVtTlENtbxD5nOCSSTwqqoLMxICqpJIAJr+YfEriSvn+fTxEtXpFJaq/ZfgvOx/dHgTwnT4Z4Sj7f3OdyqSctGo7LmbtZWTlrspeR6p+wz+z1Y/tA/FyaPW0nbw5oFr9v1DarrHP86qkDSqy+WXHmMCDkiF8Dgkbn/BVn4Pah+1n4L8N+CfBGrN4Z0X4eyT2kOm3N1NJY6xjyIoWkKscGCOKXy3ZZWbzjym5q9g0b4Xz/sj/AS18M/bIv8AhJvF0q6jq8kMccc9tEIUX7GXRmLxrIXAYMFbEuBhiK4xmLsWYlmbkk9TX9afR78LaWCy6Ge5hD97O/Kuq3jd6+qSeifvb2Z/mr9Mb6RmMzDiWfD2QVn7ChyqT0cZO12kmurs3JWla0b2TPyo0Xxh8av+Ce/ji4k0fW/GPw/nk1FA09lcT2+na3JaOWjJBxFdxL5jEK6spWUgrhyD9/8A7In/AAc5ap4M8M6HoPxk8G6l4subdrj+1PFWk3VtDeTqWkeELp4hihyuY4iROnyqXwW+VvSfEHhjS/F1iLXWNM07VrUHd5F7bJcRZwR91wR0Zh9GPrXyb+0n/wAE2fh5Jqv9uWPi6z+G9rcO73EF4I5bEsxQDyQ8sflDcxyu5l+dQoQAA/0Jj8hpVldpP8H95/PvCvjFyyjRxHNTl5Jyg/8At2zab8k35o/dD4D/ALQ/gn9pv4f2/ijwH4l0jxNotwqbprG5WVrWR4kl8mdAd0MypIhaKQK67gCorsiz+bjauzHXPOfpj+tfyk/DH9o/4g/sv+Kbxfh98QvE3h+KG/WR20bU7i1s9TMLny3lhyqzIRnCyoQVcgrgkV/Sp+wJ+1i37cX7JnhP4o/2Avhf/hJ2vP8AiWi++3C2Fvez2v8ArvLj3bvJ'
	$Logo_end &= '3/cGN2OcZP57mWVywvvp3i3b0P6UyLiCGYLkatNK/qu/l00fc9kpNg9B+VLRXkn0QV+Bv/BZf/lJT8TP+umnf+m20r98q+Lf2r/2X/2Q/iD8ftf1j4neK/B+m+ObwwHU7a98Zrp9xGVt4li3QGddmYVjI+UZBB5zk+HxBldfH4ZUcOru6fys/wDM/YvBLjrB8KZ7UzHG05zjKlKFoK7u5Qd+mnus/EGiv16/4Yt/YH/6Hr4f/wDhxE/+SaP+GLf2B/8Aoevh/wD+HET/AOSa+N/1JzT+Vfe/8j+qv+JnuH/+gWv/AOAr/M/IWiv16/4Yt/YH/wCh6+H/AP4cRP8A5Jo/4Yr/AGCD/wAz18P/APw4qf8AyTR/qTmn8q/H/IX/ABM9w/8A9Atf/wABX+ZZ/Yf/AOUDvir/ALFnxT/6De1+TFv0r9z/ABD4K+HHw7/4Jg/EjR/hTqWl6p4LtfCev/ZLiw1QalCXa1uGkAmDPkiRmyNxweOMYr8L7Y5X+dfomVYWeHw0KNXeKs/U/jvNM0p5lnOOzCkmo1aspJPRpSk2r+eupqW33vwrQiPyDr6HH+f/AK9Z9ucN/wAB7/8A66/Vj/gmn/wTT8L+DvCXgf4qeIvN1rxJfacmrWdlMVlsdPeUiW1uEXaCZUhKnDlgkjFl+ZUcejy32PNxuMjh6fPI8P8A2VfF3xw+CXgTTZPh38I/E+l6ascN94guhpYeXxUoZnRkea3Mmzym2qkBdV3MwGXOfp34cf8ABY/w7d+Pn8N/EbwX4g+HOpLKkEhuXNwlmxDN/pCtHFLEP9WQRG/3yTtUbj9cCYfVfX/P4dfzr4F/4KIf8FLfBNzFrnw/sfBuk+Mm0m4mt9Rv/EEZXTrKWNQjtAEZJi6q06GYPAY2XcjOpzScbHzlOqsXNpQ17o+/tH8SWXiPSre+0+8ttQsLuJZ4Li2mWWGaNgGV0ZeCpUggg4IIxkVNJdYGM898d6/EX/gmt4++MPxe/amh'
	$Logo_end &= 'svgjdf8ACOaDZ3EN34r1C+t3uNJSzEjbYpYi4MhZfMWJAyzsWcrJCqSyr+1In9/zqowurnHjsJ9Xny81/wBC6s2wcYH+c1+YP/BzH4Nn1T4d/CbxIvNvpOo6lpkh5+9dRQSKPTpaP19PrX6Y+f718Cf8HGUFxe/sO+G2ihaWO38b2ck7Af6mP7DqC7j7bmUfVhRKDsXlNRrFwbPxVPBr1D9h7/k974J/9lC8Pf8Ap0tq8vHA/CvUP2Hv+T3vgn/2ULw9/wCnS2rM+8xWtKbXb9D+n8dvpSnkUg7fSlPI9KzPzoO1fkT/AMHSnxJ8S6Ha/CvwzaeJGg8L68moXV9osG6Np5rdrby5pyHxJH+9IjQoArRyNlyV8v8AXVm2ISewzX873/BbrxD4m/aY/wCCq/jTw14auNa8dLootNJ0XStID6k1qY7CGW8ghhi3fOk4uTKANytG4bGzC+tksE8Tzy0UU27/AHfrc+d4or8mBdNbzaS/P9LfM9+/4N6vBfh74U/BD4nfGLxJPpMNv/alt4eguZLLddaYsSI8u2XBYRzteWylVxk26ls/Ljj/AIr+Ppfin8Tdf8STRyxNrd/NeLFJMZmt0dyUi3kAlUUhBwBhRgAcV6L8RfhNJ+wP+zH4N+B2nXrvf6tbP4k8aTwgSW2rX0skaxiN3+cJCbUoAqxhljidlLlseNDn/wCtX8ReM3FUc34grRoO9OMtH3sklbySWmieruf3t9GvgR5Lw3TzHEq1WutFfaN29dPilK7erVlG1tUFfXXhr9r34LeGP2ab/wCG/wDwi/jG/wBL1TTprTUoxHHYf2y8seyVpZorkyxiQfKdpYqmFGQAK+Rc1ueEvhj4l8fwSS6D4d13W4omKO+n2EtyqMACQSinBAIJHoR61+dZLm2MwFb2uC+Po7Xatrp2P2LjDhjK87wsaGcSapRd2ubli3t73fS6Xqz1DTP2mPAPwy8L2ifDT4I+B/h/4o0u2W003xFDDb3m'
	$Logo_end &= 'o2CbdjkTPbiWSR4y6M8kjFt7Ft2a8a1PU7nWtSuLy8uLi8vLuRpp555DJLPIxJZ2ZslmJJJJOSTXpfgP9jjx94zu7v7do83hDTNPtZby81XxJHJptjaRxjLM7uucYPUKQBkkgKxHrHgb9kT4a+DtA0/xVq3jjSfiZa3NttTSdAu4xay3JQ/MbmOYyPbqysu5FUk7CRgNGfrsPkfF3F+JgnCdaV+VOWiV312+btf7j80zDjTwy8MsFVn7Wnh425moNzlKy0Sd5PppFtJN9L64P/BOj4bXq/FRviNfS2Gl+D/AkF1Pqmo6jL9nt4w1pMrESEbP3asJJCzKETkkZUHvvhf8QPDv7T3/AAWXk8ZeAdct/E3hnwT8Ljouq6ppimexjv31O4C2hm4UsyM0qsm5XWFipIBI+K/+CoX/AAUP1C3spvhN8MrjQ/CfhG8guI/Elp4dSBftjNIIvstxIq+YJkSArLhl81JQrqV4rt/+CWXjW3/Zs/4Jv+O/Elnp88PjD4i+KT4dt7oXksEv2SPT4pYJ40B/5ZNdXBV4wCXnTcxAUD+gsP4fz4F4ZxGNzKadVpq0Xde/ZO+m9lZWur2d9dP5GzTxIfivxdhYZTScaU7KHMuWXLFyabV9m25O9nbS2mvpP/BRj4gab8QP2mr2TSZ7W8s9NsbazF1bXCXENy2zzSyuhIOPN2Hngoa8JrqNB+BnjbxRYfatL8HeKdQtckeda6TPNHkdfmVCOKv2/wCzR8Rrm5jjXwF4yXzCBubRrhVXPqSmK/kvGxxOLxE8T7N++29n1P8AQrJZ5ZlGApZasRD9zFRu5RTdlq2r6X3t02O3/YS/Zvj/AGgfi3u1fT1vvCWixNJqqvcSW/mM8brCiNGQ27zMNwQNsbZPQH5x/wCC2X7Z958RfjzcfCvwnfXGk/DvwFCum3Gk2EyR6fqF6shkeVkiwrrGPKRUfPlvFIQFLNX6B/8ACV6X/wAE4/2I/wC0tWmns/EWqmC/'
	$Logo_end &= 'vXighae2aWSJAjJKR8qKRHhsgOXIxnj8cPgR8Gde/wCCgf7X0Phm11TTdF8QePr+/wBQa7vS7W0MginvJAduWORGyj8O1f2R4F8DUsryx5/mUUnZtNptpJXlLbZLRWb95T0Wl/8AOL6RXijX4l4pnkWW1JSoUbRsmuSUm9Fv8b+KWkfclSTb1t+w2t+FvAP/AATK/Yih+Etii6prfibTLqG8mtUEM2oXc9u0UmozozsVQsEQLk/LGFXhMD4lr2z/AIKAfGnSvjb+0FNdaPiXT9Cs00mO6WZZI70xySyGZCpI2EykAgnIXPGcDxNTvmSNfmkkICqOWYnpgV/KPGmeVs1zSpWqy5rN69+7+/5dtD+8/CHg+lkHD1KnGDhOolKSfTT3VbpaNr9b76gf/r19Hft2f8E+Pif+1J8F/Aujy6o3h/wx8P8ARYZTp8Udtsubo2dusjTeZcwp5iSRzqryYx50nzKGYnyG1/Z4+IF/YQ3UHgXxjPa3Kb4po9FuWjkU9CCEwQfUV0Hin4f/ABr8cweVrmh/FTWIf7t9Z39wp6dnB9B+Qr3PD3ivE8LYyeY0sJ7Wo42jzKVlfd6NO9tFurN6Xs18z4zcB4XjzB4fLFmiwtOnNym4Om5S0so2mpRtu3ondRs7XT8D+FP/AART8ReJPGegwaz8UPgitrdahbxX2kx+KzJqhjaQK8CJFEyGYj5QqyEbiAGPWv0I/wCClf7U/wANP2QvBHgHw78Svhzea1oOsNOdF0/w9fmC3sPsUcUeCoaAKoS5VUVdwAB4GBXk/wCxv+yh4w1f9oLw7ea14a8QaDpPh+6TVZp9QsJbVGMJDxopcLljIE4HYHtXqX7a/z/+HfDvx0+KX2XxBpmi+KNP8O5XTRdwR3SWpmihM2zcCBuaNc4/u+1f0VwHjsx8R8b7LPqUVRpKTcbNJp2XzfM479E9dD+J/G6OS+DtGnieHsVOrWqOKUoyjzRl7z3TVlyxd7bOUe58XeI/'
	$Logo_end &= '+Cp/7OsCx/2V+zzrt2STv+0+Lri22+mNrSZ/SsZf+CrfwVLfN+zTcAe3xBvD/wC0K+iH/Zb+GrjH/Cv/AAb+Gj24/wDZKq3P7IXwvu02t4D8LqP9ixRD+agV+zR8CeEUtcFB/f8Aoz+cf+Jw+LW/99xK9Kn+bPDdP/4Kp/ASR/8ASv2ctUhGRzF43upf0KrXUaD/AMFQP2UbtQNU+BvjazJ6m11mS5x/31dR1tfFP9j34M+DvA2teItS8C2rWuh2M9/NHZzzRSOkaF2CBZFG44wMkDJHIr47/Yp/Ze0f9uX9t+38F6fB4h0fwbq02o3zS2dv51xotjHHLJbmUksqrv8As8JdyQXlUbizDPk5t4N8GYGhLE18JCMYpydr7JXe9z7nhD6SHGuf1fZYTHYi90rym0m29FdS/wAtD9rvEf7afg34J/sw/DnxJpui6odO8XaFbXXh7SS+JIrc2kUkaTSMzbdiyQoxBc5bI34zX5t16x+1/wCN7e++IVv4J0WCew8H/DCAeGNEsZZWlaCO2CwOxZmYsWMKgMTkoiZ5zXk9fwPxjm8cZj5U8P8Awabagra20T/L7j/VHwj4ReT5LDE4rXE4iMZ1Hdu+7iteqUterbeuxY0gWraxZrftcR6e06C6eBA8qRbhvKKSoZgucAsoJwMjqPoj9qv45/s+ftJWWm/2z8K/FHij+yLeG0s9OufEF1omm2sUXmbNkFpctDuXzGUN5Qfa23cFUCvm/cK6rRPgV438S6RBqGm+DfFWoWF0u6G5tdJnmilHqrKhBHuOK5eH+IM0yycp5VJwm95RXvJLz6bns8bcF8P59Gk+IUpU4N2jKXLFt2vfa70XW6tp1O1+I/7WLX/he88MfDzwvovwr8F6tGW1PRdBtbaCO/nY4klZ4YIiN8YijZQOUiCklSVryDpXtGhfsR69aeBIfFPjfxB4U+GPh9rlIZpfFN99gnjRio37HAQE5YKkjxsWUg7QQ1es+Ef2Wfhn'
	$Logo_end &= '8AfEUl/r2tL8ULpUDWVjb2ot7K1lRlcGc+a3m7vlUL8yAeYHRjjb9Nl/BXFnFGKjNUp1JS+1LZaX+X3Jfefnmd+Lnhp4d5bUpfWKdKNP7FNOUpO6jur8z1Wrk3bvoi7+yo99/wAE/f2fPiN8RviVZ22g6fJaW93p1he30Fvdak8EFzKtuodsLNKXWNI2IkL5BUY5+VP+CInw21vSf2Xv2kvE11p+o2Wg6x4aFlp11LbFLbUZEt77zfKkJw/lFlVtuQDJjOQRXyl8Yv2wfjJ/wUc8deFvB/ibxKuqrqGurBoumfZobOztrm7kSGPd5EQMgXcFDyB3VS+OWbP6wftq6To/7MHwE8J/Bn4XabcaLp+qXE839m6fdyzTC3LlniYOzzOs005OS2D5LJyvyj9+4hyelwLwlVyuo/aVK61tqkoyurXs23KWnu7X7Jv+UeG84xniTx/QzdRVJQknba1oK/WStGENfe1du+nxSTk0V2w/Zr+IzRhv+EA8bbScA/2Hc4P47K2vhx+xt8RviN41s9FHhfWdD+2b/wDTtY065tbGDbGz/vJfKO3O3aOOWZR3r+RY5fipyUY05Xfkz/ROvxFldGnKrUxEFGKbfvLRLfZnuf8AwTt/Z+8K3Hw81bx542stPuLW6uDpmnxaxZI9rsXYzzx+ZkOzOTHkD5fKkGeWA/OT4y6f8TP+CsP/AAUA8QaXoM1t4ibTby403SZ0SGK10bQI9SdIGd4UHmQxfalJkO9mDk5PAr7W/wCCyXx5n/Yx+AvhH4d/DfVrLQ2ju45FiaZLu9RW+0Syvtl3/wARQn5do+0jAX5MeT/8G23we1Kf4x/EX4jSO9roWi6CNA3ywskV3PcTxXDbJfufuUtF8xeoF1ETgEZ/uTgLhilwnwo85aj9YlBNNq6V3bTZtybv6Jban+V3iRx9i+OuNK2GjKX1SFRxir2b5d7rWKUUktN5c17+6z3r/goH4Gtfg38I/gj4Aj1aDVrzwT4f'
	$Logo_end &= 'OlSy7RFNKkMFnAk7RZYxiTyXIBJ+6wBOM18v13n7Tvj+4+Jfx+8WanNqn9sW/wDadxb2Fwsgkj+yJK4gWMr8uwJjGOuS3JYk8bomhX3ibUFs9NsrvUbuQ4WC1haaRjgnhVBPQE/hX8W8R5hLMc0rYpK7lL77WV9O9r6H+mnh/kayPhvC4CpJe5G76Jczc2teivbXtqbHwi8AyfFT4o+H/Dkf2hf7Yv4bWSSCEzPBGzgSS7QRkIm5zyAApJIHNeqft/f8E0Pir+1d8XNa8UeMPirNoHgma8X+y9O1PyI9L0iFFZYzsF4sZkCmRmk2bzvfkiuK0L4H/FbwbrkV/pfhD4iaTqUKny7m00q9t5owwIOHVQRkEg4PIJFT+JfhP8YPGTbtY8MfErVSrebuvdNvbj5hn5vmU88nn3NfdeHvHGL4SdathsEqtWpZXmpWil2s1rdn5P4y+GOE8QK+EhWzf6tQoXbVN03Kbk1e/PGStZK1ra/IveJP+CX/AIx+If7L+g/Cv4XfEz4a6pHo0zT6rfxeJblGuYnMrtE0EEMuY5JJSxDvtHkrgNn5fo//AIJ9fsu/Bn/gnr4Skhm8U+Af+Fk3ltHZ+INTOsxGaGVUi8+1iMrh44ftEZcrtQsRHvXMaBdP436R4i/Z9/YY8NR/D3T9W0XUriC2TXZrSwP26K3NpPJcSzMAWhKyHJkyDGWIBWvgy/1CfV7+a7up5rq6upGmlnlcySSuxyzMx5ZiSSSeSTX2/G3jRntelDBYxJ3SbUU4xa6Le7t1v1PyHwt+jLw5N4jHZfWlGn7SSTk1Ko5X96clZRjza2Svofcvg/8AZI/Zxt9XX7V4+s/ElxO+RDN4otczOe2IijEk++cnrXf6V4M+Hf7KU91rXh34f6pDNcRgW+qGT7VbyKc7dszTSGJX3AcAFhjg8V+azfMPm/WvsL/gnB4l1NvAnja68ZataxfCbw9pxa5m1q4KWGmtHmeR1kkPlwwxRLJJKQyh'
	$Logo_end &= 'MxO2Bk18XwLxBlUs1pUsZl8ZRb+zdSVtXZ77f5aXuv0Dxo4B4lpcN4jF5fntSMor4aiThK7sk47PVrS3nrazzfjl+0LpL+LP7W8XeJdF0P8AtSSRLBNS1GG2VYlbPlRlyoYIHXJA6tk8tXzL8ZP+CpHgX4e32oafoNrqHizULNvLSa2ZItOmcPtcCcksQFDEMkbo3y4Yg7h1Pxn/AOCefgn/AIKWftx20Hwj/aW+COpeDby2lvbjR7Px5/wk2uaOwQtNJaadG7KYHmEeV+0xLGrErwqR1b/b+/4NprP4efsyaXrnw3+PPh/wH4k8MoX1/VviDHDbaHrck8tpCgNxhhp0UZ88xqYrl5HuI42k4Elf6C4PivBU8FSjhIOEOVWjbWKtot7XXqz/ACvw/gbia+MqYnOKzrVJSblJytGTvvp72vyPlu6/ae/aG/a+1zXv+FY+HfGk+jWoiE+n+FtHk1KTTFdHVDJcQwmVWk2yEHKglDtA28d98Gv+CHn7Uv7Y2inxN4k8vwsyxLDaN4+1S6h1C5jDygosKxzTxBGUnbMseRKrIGDEj7n/AODcT/glxr/7AXwd8ZeLvEHxm8JfGCT4uJp09vN4Wun1HQ7FLKS+Aa1vWYC4WUXS52wxhGiKjeMEfWf7aH7Ovxe+OWmWLfCX9oTWPgbqNpGUlaHwjpXiKzvGMiMHkiu4xIGCB0wkyKd4JB2kN5OK4mr1G+Rffr+Gx+q5P4b5ZgYJQiotK3upLy1drvTdt3b3PlX9kT/g22+FPws8Mal/wtq6b4qaxqZgeHyWu9GttHCqfMjj8i4DzFnbmRyMrGmEQ7t31V8FP2X/AB58Fv2m9e1ax+Jmkw/AeTSEsPDHwn0zwNp+l2vha5AtS9yl/CRNKGeO7bymQKDef9M1z7N4R0W68N+E9L0691bUPEF5YWkVtPql8kEd1qUiIFaeVYI44VkkILsIo40BY7UVcKOd0X4Z61pXxl1bxRN8RPF+paHqNqtt'
	$Logo_end &= 'b+ELm20saNpcgEQM8Mkdml8ZD5bkia7kTM8mEAEYj8HEYqtXd6sm/wAvu2Pt8Hl+HwseWhBR/N+r3fzOyooornOwK/n9/wCC2Jx/wU6+J310z/01Wdf0BV/P5/wWy/5SdfE766Z/6arOv17wVo06mezjUimvZS3V/tQPOzOvVpUlKlJxd907fkfK26jdRRX9T/2fhf8An3H7l/keF/amM/5/T/8AAn/mG6jdRRR9Qwq2px/8BX+Qf2njdvbT/wDAn/mfsR/wT1+b/ghN4+zz/wASDxR/6IuK/K+2OVr9UP8Agnp/ygl8ff8AYB8Uf+iLivyutvu1/DnFMVHOsWo7e0n/AOlM/U8hk5wvJ3bUd/Q19MtZb27jhgUyTTFVjUfxMTgD8zX9E1hbQaVYQWtrDHb21rGsUUSKFWNVGAABwABxgV/P98BhC3xs8Hi62fZ21qzEu7oU89M/hjOa/fEeLNNc/LfWLA/NxOvT8/615NHbU4uIG24K2mph/tH+Prr4Z/s8ePfEtncLa3nh7w5qGpQTMgkEUkFtJKrbcHcAVBxzn0r+cXxp8X7rxPepD9liOkwzLIbWUuFu1VgwWYowbbxn5GUjd1zhh+/37cXjHT7v9i/4vQw31m7SeCtZRQs6neTYzcAZ/l1r+c8HPI71NbRnZw1D3JSmtbn6CfAv/g4C8TfCHQ7XR5PhP8P00KyjSKCz0Fp9JCBEVBy7TgkKoGSCcAAk16lpH/BytaTanGuofBy6tbNvvyweKBPKo9ka0QH8WFflTR2qVUaPUqZLhJtycdWftZ4O/wCDhn4IeIb6O31HSfiD4f3Y33N3pttLbp9fKneT/wAcrz7/AIKef8FO/gT+1B+wv4w8K+F/Fjal4ovpLKTTrGXR72B2aO+gaRhI8IiX9yJTkuMjIHJAP5KZwaM0e0Zz08hw8KiqRvp5gevPXqa9Q/Ye/wCT3vgn/wBlC8Pf+nS2ry+vUP2Hv+T3vgn/ANlC8Pf+nS2r'
	$Logo_end &= 'M9TFfwpejP6fx2+lKRkUg7fSkcKV+bGOvNZn52fNP/BW74geIvC/7DPjrQ/B/hbxb4u8V+NtLm0CwsdC0S81J1W5xDcSO1vE4hCQSSsrOV3MoVTnp+F/wD/Z/wD2rf2YPiAvirwR8Jfi1o/iJLeS2S/k+Hs99LEkhG/b9ptZArNjBdQGKswzhmB/poxUYhj8zdhdw4z6Zx/gK9HDY6NKjKhOmpKW6lqmuzW1jw8xyV4qvGv7VxcdraW8773PxP8Ahd+2X+1Jb2efir+yPr/xe1aIeVBq+o/D26s71IeSIiUs2jKhizDbGvLt61U8Hf8A/z8Fhrb4t/EnWvA/g39jPw34h8c+GzONY0Kwt11HUtL8iUQT+faw2Alh8uZkjfeBtdgpwSK/b0oPp+FfJP7IP7Ln7H/w7/bn+KXjv4N3nga7+PGtPqUfjoaT44m1bUYGuNQSa9W4sWu5EtSbyJQwEUexlKDaMrXzWI4Z4er1HVqYCF3vZyS+5NL8D3MNmGfUKSoUsxqqK2Wmnzep+Vvx8/4KBftHfAFJvFM2hfC/9mm0VS0Oj3en6NoWt3yhhGZ4bLU2+3XCZfZ5kMJjwH5+Vyv0p+xDe/Hn/goh4Qnt9N/bk+E0r6ppc01zp3hCy03VNe0+A+XGzSRxx201qytKoMisDGzRlW3MMez/APBef9iv9iv4x/DeLx9+1Rr03gTUtM0+LS9J8TaZq9xHrdvbLexM0dpYos6XQ8y5CyE2kxjS4ZspgOuJ/wAG937Ef7Gfww8AeJPiZ+yz4k8U/EmaTULvw1feLPEguYb63zHY3ElgsL2tpGYl220ocQFsyMPMIyi99PBZdSgqeHwlKKW1oRb+9p6+Zx1KGKr1HWxmKq1JPe9SVvwa08rn4y/te6X8HfAvxo8Uato37cXgz4tXdncXbalZXngrXba41S5Rpt4t9QjgvLe7Z3VNk5uFhlMhbeiAOfpf9lX/AIKleHdG+BlnpOuQm6vvD+kyQ6Te'
	$Logo_end &= 'QTCS11pocJb22+JG8piP3ZdgyjyixYs22vjf/gqT+yX+xD+z1+2x408JeA/jH8ZbHTdF1K6s9Q0bTPh5Brtv4bv4rueG409Ly91TT5ZUhaMKreXMCmw/aJmLEfoX+0V/wSZ/Y2+An/BC63+OHw18ffES4tdNhsdQg+IukyPrN5rBudSSymjfRbi7tbEbXnaIxfuZoDbgu8kkciy/T5VxBVwjanqn+H9dFofEcYeHWXZ7RjCa5XF3W6v81rr1bvf1SPjPSvgF8UPjzqsusW/hXxJqlxr0hvpNSnsTBBemXMhkErhY8PuLAg4+YY4Ir7I0T9ob9vjw1odjpunalHY6dp1vHa2ttDp/htIreFFCpGqiPAVVAAHQACvyV/Z6/wCCgPiD4f8Aje70nUvin8QNA8D3E7yi+0bREmvxtDeW32JNRs4iz7Yw+bhtozgvtAb6g+N//BXy3+B/w20H/hWf7QHi74va9q3l3l9aal8O4PD0OhxtEd9vLcXF1eSS3KOqArCrQEM7LMSuH9GtjMjx0YrH0+a23NGMrel0z5bEcPca4KT/ALHnRUdviqRdumzS07W9D7I8Q/HL9vjx7pp0i+8S3tjZ3mY5LizOi6fJCrZUt5tuqzLgEnKHIwCOQK9Y/Yt0b40fCrSPEUvxF+JnirxHd6vLALa2uPEN5qCWSRh9xDSuQpcyYKqAP3YOTnC/l38Df+C8HibxL4uktviR4z8W+D9DNuTFqHh7wvpWv3Pn7kCq9vM1mqx7TIxkWRmBRVEbbiy6nxK/4L9618O/F6w+Ate174maK8AM114u8LWPh2WKYO4Kxw2dxcb4ygQ73kVssRsGNza4OfDOGd6NKMf+4aX5RPmc+4b8Sczw0qFapTs7fDUnd2d95N289VdH3x/wU68T+MvFfwsi8L6D4b8S+KpPEUitqV7a2s959hjgkjkjRiqNzI5yPmBAjPUNXjf/AATZ+LHir9gL4g674ovP2dvGHjvxBqFrHZaZ'
	$Logo_end &= 'dul1p50iIljcKq/ZZVcy/uvmwrKIiAcOwryv4If8HFOj654PvJPiEt34V1u3mP2W20PwYNdt7qH938xmk1izKSFmkJTyiu1AfMJbaOG0j/g5L8Wif/iZeC/Dm3oVtoJm59ma45H4V1ZliskzGjLDV5vkkrNJSjp2urO3z122OThnhnjfh+lFYXCQc03JydRSbk+rTur2sl6J76n1fdftwftW674sjfwT8O9P+GsMjoiW2j/D23tovM3cSNLeQyEH7vzbgoCg8YJrrj+05/wUDZyW1z5lPU2Xhv8A+N/yr5hsP+Dl/wAMxw/6V8L9bkfsYtWiQe4wUP8APv2pz/8ABzH4X3fL8K9d2+h1iLP/AKLrzMPkHB1GHJCjSSX/AE7j+sWepmGf+LGJq+0lh5N95VW//cq/I+lNT8Z/t0fGeAwa38RLrw1Go2bobyy01nB77tPj3H7o5PI3e7Vz+q/sMfHT4v2LaX8Qvjdq2qaO3DRT6zqGtIcdP3Vw0anovU/yroP2R/8Agol4n/bN0+G/8L/Ceax0tmxPe6rr4gitQVZ03BbZmbeFG3YG++hO1WBr6oFfU5fw/lEYqeFoxS3VoqP3WSPyjiTxF4ww1eWGx9RQns0mp28n707ej36GJ8NPBEPw0+HHh/w5BL9oh0DTrfTkmMewyrDGsYbbk4yFzjJx0yetbfaisnxh480P4e6Yt7r+s6VodnJJ5ST6hdx20bvtZtoZyBuwrHGc4BPavotEj8k/eVql0nKUm3pu29Wa1FfHM3/Bcv4HRXLxrca1Jt/iD2AVhnGQTdD8uvtV7SP+C2nwH1OYLNr11YLz89w1sVH/AH7mY/pXJ/aWF/5+L70fTy4E4hirvB1P/AWW/wDgqXpfjrxZ4U8L6F4V03xBquk6hLcy6tbaZYPciRovIMHmFFLAAtIQpIDEZwSgx8+fsu+Nv2jv2ONa1TUPhz4Z8WaLdaxHHDevL4NF80qIWKoGmgdo1y+SIyu4qm7d'
	$Logo_end &= 'sUD6i0P/AIK2fs867hV+JekQyNj928E7sSe3yI1bo/4KQfBSSJZIvGq3ETdHi0i/ZT/5ArgxmFwOOUoVpRnGW6dmvuf3+p9vw9nnEmQ4aGFw+X1E4tvmUKkW23vdLs7eiSKXgj/gqF44stHj/wCEy/Y90nxXr0gDXuqp4eks5dRmP+smkV7OX53bLHBHJNTeLv8Agp14nvY0/sj9iXQbHGQxvfD015n0x5dnFjHPrn2q1a/8FG/g1Nnb4x8v/f0q9TP5w10Wk/tkfC3WY98Pjrw7Gv8A08XS27flJtNfFS8JeEpzdT6vG783+XNb8D9Bl9ITxEoQ5ZRqxS0151+PLc8l0H9qD9trUzHN4N0rQvhvoOoSiQaTpehaPY2kLHAMrxXKvOGwBkk5IQYHr6B4n8L/ALT3xh8L2lv4s/aT1fR7qGUStH4a0tNPCldwH7+1NrI4Ickqy7c44O1SOw/4aV+HG3cPiD4H/wDB9a5/LzKav7TPw3c/L8QPBLf9xy1/+Lr6XC8G5Bh0lTw1NW292Onztc+Bzbxa44x0nKVScXJ3dlNt+vO5L7kjD+GX7FXwz+D3i+z1/wAO+G2sdYsFkSC5bUrubYHRo2/dvKY8lWYE7e5xjjHQftGQ3N3+z/44trK3vri8utBvbe2is4XmnkleB0RUSMFySxA4HHXgDNWPDPx58DeNNah03R/GfhPVtRuSVhtbPV7eeaUgEkKiuWOACeB2rrM/MR3HBHpX1EYx5Wo/gfluIxmN+swr41ylKNn77bdk7pa62vf8T8rvgz+zH8atB8eaP4i8MeDdb07WvD9/b6jYXF/ax2wt7iKRZIpNt1tRtrKDhgwyBkV9Z/8ADUH/AAUEMn/IdOf+vLw5t/8AReK+nqK8PFcL5bi2pYulGo1onKMXZeV0z9HpeM2e0LrCcsIvonP9Jr8j5H8XfEj9u/4whdP1nxdrWj2/DfaLDUNM0rBGSPnsNsnOcd/evpj9m7VPiR4F+B+j'
	$Logo_end &= '6J408aa/r/iC1M5vLubW7q+87dPI6fvJjvbEZQc9MYHAFdBRWmD4byzCq1ChFf8AbsV89FueFxB4l57nFJUcTVsk0/dck9E1u5PTXY+A/wDgpj8OvGHxa/aPiutE8H+MtWtdM0i3sXu4NJuJ4J33yzExuqlWAEqqSD95WHau0/Yn/bI+K37FP7NGsfD2w+AGseKm1rXp9XnudZ028e0MUtrDbtAbZYhu/wBSCWMm0hiuz+KvscqD2H5VjeMfiX4d+HMVvJ4g8QaLoKXbMsDahfRWomK4LBTIw3EblzjpketZZxw3gsypOjjlzQbTs9Fpts0e7wz4sZplEaVLLqS54Kyabcn3ez166Hy74M/bC/bO8R6nqh8DeHrL4d6e8oZtPsfCOmaPb7SWMag30e6XYMjIY4zz94Z3B+1B/wAFBI/mXWmLegsvDfP5x/zrP+M3/BV/wv4G8RJp/hbRZ/F0cZdbm8N39it1IxgRExu0n8WSQq8AqXByPjj42/8ABbPxTM9w0PjDTdPguIfLGn+HraKViM4JEzb2R+c5Mq9OBXgT4X4YwsFF4enZf3IfqtfvbP03L+LvEfOa3to+7zWd5zqOXbVKd1t9qMdPI+o/iJ8Sv2ovF2qmPxx+0VpfgPVJolnawm8ZJokyx8hW8qxVVAOTyOCR7Cvkr4vfGjxj8Ur2Sx8VeO/EXje2t7kyxTahql3eQSuu5VmQXBDAlWbBZVYBzwMmvpbQP2J/hX8X/wDgmsv7WHir9qmG1028sXfULa78NC/1KLWIYTu0cedqMLXF6DHtRDs8xAkikRMslfKf7D3wv/Z1/bW/an8E/DvxD+058X9JtPEWs2NpFY6t8JbXSYvEsk13DANKS70/WLt7eW4WZlWWWLyUwWZshVbgljsow1lhKKVtuWKVvwX4I/Q8u4a4gr3lmde7drp7edleTf8A281/l7T+yP8A8FNPi1+yHPpGneH/ABRqV14Nsb2Ce58OTGGW2ubdZ2lm'
	$Logo_end &= 't4mlilNr53mShnhCnL7juKrj6D0f/gp78Ofin4zjsdH/AGTr3WNd1qdmhsdL8bXrS3DnLEQwQ2v1wiLgDoABXHf8Fdv+CRX7J/7Mnxk8RalcftvXnwcmuNQLSeAIrGTxbqWkyTWy3MMKWtrdR3NvCVyyPcJs2zQr5gyrP9xf8EUP+CJv7PfwT1LwP+0B4D+Mvjr44atDpAlsL+81RYdItrq7sUWS5FgiiaCc29zKot7qSQxJdEMhkVZF+OzzI+Gs3qe3zDAxqTV9Xpq92+W12+7uz9F4fxnFGSJ08rzGdGLtfkbWi2Xy6LY+NPhB/wAFtf2X9Q+NXhHStb+FXg/wjpuqalFFc63qXjzUNWsNMh3DfJLBDZzbztJCpIFjZyoeSJN8qfcn7YX7PXwi/wCCnX/BLT4i6bb/ALUnw38PfCq48RadeaX4o0Jrez8P+DIIVsmTS9RjW9jjnkd5GlaO5ki2S3dswhVoI93wr+2J/wAG2P7Gnwd/bz+Gfw3uP2nfEvw51D4mXStZeBr/AExNY1HUhJdNGkNtfoqJYrIf3EDXscxkkjYK0zKyD9Xf2f8A/giD+z78A/2Atb/Zti8P6z4m+GfizUV1jxDHq+sTre63eLJbSJPJNbNCYmU2dqAsAiXEAypLOW8bA8K5Jga3tsvwsKT8rv56t6+Z9LjOIs6x9JU81xlTEW2c5Xt5Jbf8OflD/wAE7v8Ag3Z/Zq0X9tb4d6ppf7d3wy+LmpaHqy6va+E/Ck9nZ6tq8lqj3AWGa11aWePYYvNZo4y2/z/InwU++v6ef8FtP+CdPwz/AG0/+Cfw8JePPilH8HdD8F3Fldab4u13WJZNN0mRZYrdWvVuLuGO6aSN2gV7iUusk4ZWLMyvyH7Dn/BIb9hf9mP9vjUvEnwbudCk+MHga2kz4btvHsuqXPhMPFLa3Mz2bXDzqZY7vy3+071UmMoI2JLfWf7b3wW+E/7Qf7L/AIm8IfHAaWfhdq32X+2hqWsy'
	$Logo_end &= 'aPa/u7uGWDfcxyxNH/pEcOMSLuOF5DEH3Tyj4+/4N0/+CZXwr/4J7/Bz4jah8M/jr4Z/aCbxtrNtb6l4h8Ovb/2dZfY4C0VnsgurlRMv2ySR2MgLLNCNgChm+pf28/gd8G/i18KW1D45eIrvw34F8PlTd3EnxB1PwjpKmaeAR/bHtby2im/fpAIvtG7ZI37vaznMn/BPz9jr4I/sX/AKPR/2f9J07S/h74su/wDhKIJNP1u41i11OS4t4EF1FcTzTF45IYYNpR9hCgj7xJ1P20v2aPhF+1P8CdU8J/GzStH1TwPqcltBdDUdRk01Vc3UDQolzHJFJEXuEgUBJFLnah3BtpAPUPD+iw+G9BsdPt5LqW3sLeO2je6upbqd1RQoLzSs0kjkDl3ZmY5LEkk1zOkfA7RdA+M2rePIdQ8YNrWtWq2dxa3PizVLjRY0AiUGHTJLhrG3k/cpmSGBHJaQliZZC3ZA5rk9K+DHgfSPi3qXjay8LeF7bx1qlqLK/wBdh06BNVu7cCMCKW4C+a8YEUWFZiP3acfKMAHWE4FN/ef7NOIyKbvP+VoAdX8/n/BbL/lJ18Tvrpn/AKarOv6A6/n8/wCC2X/KTr4nfXTP/TVZ1+xeCH/I/qf9epf+lQPJzj+CvX/M+VqKKK/q+x8yFFFFJ7DP2I/4J6f8oJPH3/YB8Uf+iLivyutvu1+qP/BPQj/hxN4+/wCwB4o/9EXFflbDIsUTMzKqrksxPCjvn/8AWK/hPiz/AJHeL/6+T/8ASmfrvD/8FekfyNW2PzewGT/n9a4Hx78SLi+uLrT7SaH7CGC+bGP3jjA3c5wRuz0Hb0NVvE3xJm1uya1t42tIXzvYNmR07fT3/wAM1y5OR2+g6V4Nz6SNJbyQfht74ozRRUmsYpbBRRRQMKKKKACvUP2Hv+T3vgn/ANlC8Pf+nS2ry+vUP2Hv+T3/AIJ/9lC8Pf8Ap0tqDDFfwZPyZ/T+O30oZwgyeBSKMNTlORWZ'
	$Logo_end &= '+dBRn5veim+YPM2/xf5/z+IoAdXP+Efid4f8c+J/FGj6Rqlvfap4L1CPStbtk3eZp1zJawXiRvkfxW91BICMjEmM5DAdBVay1aK/urqGNbhXs5fJkMkDxqzbEf5GYAOuHUbkJXcGXO5WAAPI/wDgoD8QPgv8Lf2R/F2uftCW+h3Xwhs0tU1+PV9Fk1izIku4IrffbRxSu5Fy8BUqhKMFf5du4YH/AATR+JH7Ofxf/Zyk8Qfswab4P034cXmrTxzL4b8NN4ft5b+NIo5Xkt2ggYy7FhBdkyyqnJAFemftI/FOz+CfwQ8SeKtQ8K+KvG9notk88uheHNIbV9U1UcL5MFqv+tdiQMEhQMliqgkdB8PfFkPjvwNo+tW+n6ppUOrWUN4llqVm9le2iyRq4ingcB4pVBCsjAFSCD0oA/JP/gpV8Kf+CSvwh/bE8Vw/tB6PY6R8WNdkTW9dS1HizZPLdfvfPZdOJthJJkyNtAZixZsliT9jftA/ssfsz+Iv+CM2tfD+8tl8Hfsxx+C49XWbQ0nhk0zTYdmpR38Y8uSaScSItyxkjlkml3GVZWdw3H/8Fpv2qf2X/wBjDwroPjP9or4DD4r2+oXltolnfHwHp2ui3Z0vJo4jcXzRxLt8mdvLWQuPN3BCGZh9veK/Cul+PPCupaHrmm2GsaLrNrLY6hp99bpcWt9byoUlhljcFZI3RmVkYEMCQQQcUAfzD/svfssf8Em/jR+1TpXge1+Jn7UU0l1rdrpukS69Faw6N4snluxDFbq1rYC7ijmO3LSi2KpMDvjYNs+of+C5f/BKv/gm7/wTx8K/DnUPGXh/4zeAbvxDLe2mnaX8NNRF9d63HCsBlnuG1YzQqsBkiUFZY5HN1yswTMXq/wDwTn/4Kh/8E9/2yv24vA/w0+Gf7JNj4N+IWoXc17ous33wy8N6culXdhbz33m+dbzvNDIgtTsdFLCTb93G6vqT/g4F/aG+Av7J37GVn42+OvwT0n43'
	$Logo_end &= 'Wt1qcnhjw9pl1p9pLJa3t3Z3ExZbqYGSxjZLMhp7cNKrCMqhIBUA/Ff/AIJ3fsw/8Evf2wf2tfCngO11b9rfTdW1a/hXTLHxjNpKaX4jn82IDT3l02FriIyhnywaEBEbE6OUBz/+C037LX/BP/8AYL/ayk8FeFNN+OHibXIbyRPFPh3QvF8Wl2fgoeVbPDHDLqGk3T3hlSV3x9pbYUIaQbgF+4v+DZf9sD9ln9pj9qvxZ4V+GP7IuifBXxpoOhS+KLLxA/iKTxVdGFZIbG4ijuruJLi0yt3FhISUkVpd20gb0/4OhP2o/wBlv9n79qTwDovxW/ZOh+NnjXU/DsmsS69H4ruvCPl2jzm3hga4slaW9dTaynZMAsCsnlk+fIFAPmH9hP8AYf8A+CX37Sn7Evxa+I2ueJf2hfB8Hw/XR4vEl14kvI7jUPCRurmOOG4sRptk8N1DcTs9qTNDLIqozmG3ykp/K/8AaI1X4P3Xxcm/4VToPxJsfAtuZIox4s16yu9W1DEknlzk21nFDbbozFugAn2sHxM4II/p3/4N/wDUf2Zv26f+CbXiqTwX+y/4L+Hfg1vER8NeI/DOoxReKBr8ln5F/byXV1cw+bfLG18Gj+0BjCwITChTX43eKP2iP2Y/2mvjpf8AiPwL+wn4N07wbdahfXFzDqnxA8RWd1qxleRo3tYbCZLWwRDy1vHFLGgPlxsqrkaUaM6suSmrs58TiqWHp+1rS5Y92Z/x++G3/BLXwb8ArfWPAvjz9qzxh451TSZ5bTQNunWp0q+8ndBFqU02npCI/NKo72b3GAHIDcFuZ/4Jxf8ABGvXf2kdK0nxh4qtZNH8Pw6tGZIrmcRtfWqlTIscRifLj5gd+E3EKclZFH6A/D3/AIJa6J4x8Xw+IvixoXwzurzS08jTNP8ABvhPT/DtpHtkEomlNla23mSbiy4KblH8fO1Pq9f7O8IeHv8Alx0nSdJt+T8lvbWUEa9+ixxqq+yqo7AV'
	$Logo_end &= '99lHCfs5e1xln2X+Z/NHHnjlGdP6lw7fmejqNdGtorv5vbpczvhf8N9K+EXw80Xwzotutvpmh2iWluvlojMFHLsEVVMjtlmYKNzMx71vMcLXy38av+Cs/wAOfhXHrSWEN7r0mkyJHHeiWG20m7JKh9tyWLbRllDCJldgNpKsHPl3/BI39s3Rf+CsH/BR6X4a/EXUPH83hG7ttTuNH8PaQfsml6lbG3leaPULm2lt7lYolWMRZSQyswD+UC6SfRY/O8Jg4e+7vokflvDnhbxBn1V1ZR9nF6uc+7123vrd3t16qx6n+2b/AMFUvAP7LHhzVIbPULXVfFFhqB0t7WaC5WGzmAfczMsZEmxkwURsk8ZXBI+bfh18bf2Sv28v2N/GHxE/aM+KX7TGga54F1CxsLu20GGxtrXU729h1OS2sNNijjuEXzbfSyZGuFto/NjQmT5sjx/46f8ABSP9ie++JGq2MP7B+sazpmmavcQ202tfGzxBbXEtssjKGNqpdLWZ1CFkEkqoQVBcANX6gf8ABGz9pT9iX9rb/gn78Wf7B/ZD0Xw7pPwPsYvFPi7w5qWj2Xi9tUZRq8to9ve3ebnULhIEu1Q3SRmH7WYY2MeWr8+zbiTEYv3Ie7Dt1fqf1HwR4W5Vw9FVUvaVus5W0/w6aL+nfc/E/wDZxu/2IvH/AMebfTfiXoP7SXw78A3UC266rpni/SfEF1bXTXESia4j/se3K2qwtK7iFJpsxgIjlsD76/4ODP8Agnr/AME/P+Ccmr6bpuiaP8XdL+KGraJb32l+CfDXiBo9Jltnu54zqF3e6lbXjxlvKnQRwuxLQRgxRh2mPM/8EtP26/2B/HP7bPgvwhd/sG2Xhu88e31r4Y0q+vPGVz47tI72+u4LeHz7DVAkCRAuWadA8qBcIjbjj9Tv+Dlj4h/s6/AD9kLTfGfxu/Z/0/436hq2rW/hzQ1E39k3VtIS10yNq8Q+1WcXlwTNth3ea6hGUIzuvzh+'
	$Logo_end &= 'nH4cf8Edvgf+wz+1t+0bpvg/4yH4zeCda1PXNMtPCtgPEUWqaV4unnulhGmXTWulRXFsXZolMqyRqyySnzbdkUtz3/Baf4Mfsf8A7Lf7UXiTwD8B4PitruqaHqt3ba+9/r0UOj+HbuK6mil0q1hm0/7TOISm0TyXDggL88xLPX6jf8G0Hjz9kf8AbH+NHj+PwH+xt4f+F/iTwTFpWv2ms6p4huPGxhlSaZY3t59Qi3afOjlXUwYMuCWIMCZ43/g5M+O37J/7Lv8AwUG0/TfiP+xtpvxY8XeIvCVprt34jtPH2oeEDd+Zd3sIWWCziKXMg8g5uXJkIKxk7YlAAPCf2AP2N/8AgmH8bf2DvEHjjx54w+N3h/XdF/srTvFEuqyySTeF9Rnsr6Q/YBYWTRT20zWt26NMksgFjEGSHeUm/Jz4la54TvviBe3HgnSPEvh7wu7RfZLHWdci1bUIgEUSeZdQ2trG+6QMy7YE2qyqd5Uu39c3/BFLSf2c/wBqH/gmbomu/DP4A+Hfh14H8Z28ul614c1HTYdQ/tOSDzLaZbi5kVn1KLLTxrNcZZ1ZgyqSyD+ehf8AgoT+w/8A2nMz/wDBPWBrIxgRxL8c/EQlD9yX2YIx0GwEepoAzfi38TP2KdE/ZRFz8Odc/bIX4valpSPb6LqviLSD4d0XUC6pItxcxWsc08KDe6GKJWlCorfZy7eX87fs6fG7w5pnxGh/4WzdfFjWvCMyCKQeEvFkek6jZuZY8zhri2uY5lWMSjydsRdmQ+cgUhv1H+NX/BRn/gn94Y/4J2+AraP9hOD+3PGWk3Fzplk1z9lELQam0Mgk8Ro66ncYaFmyFLMuIWKK7bfhf9n79t/9mXwdY6hH8SP2KfCPjie4u5ZrSTRviV4l0EWsTFCkJD3F1vCYkG7gsGXPKktr7epa3M/vMPqtFu7gvuR5z+1D8d/B+nfGq6X4E6p8WLfwHZL5VrN461m11LUtRcO+bhkgt4ooEZDG'
	$Logo_end &= 'BCRKVKsxkO8InpP7Df7SXjC+8VyapFdbdY8PTW8lpcW6GN5md3JR0UhWVtigqFAIyDnNVv8Agpj+1r8Afjv8TvFUPwX/AGY/DvwhsrrVp5Rqk2uapPqbkXUzl47NbldPsY5IzEptI4JFgw6xyFdhXy39jf8AaFj+APjxbxTJa3st5Z3FlfKEdLGeGUlHkVztKAtuJOfuYwc8enlOOnDEx9pNqPXXTbT8TweIspp1svqxo0YynbRWWuqu/z+22te+/oz+lQUV8PD/AILK5j83/hXS/Z/veZ/wkHG3rnP2bHT3r5/+MP8AwVn+I3iH4T+MfHGk+I7WHw3o2qad4bvLLRLeAfZbnULK/mg8qeRTKAyaddM0iSs0b7NuDgD9QxGcYSjHmnI/izK/CjiLG1XSVJQt1bT/APSeb8bLzP1R8U+LNL8EaDc6prGoWOl6bZhTPc3c6wwxbmCruZiAMsQo9SQBya+bfit/wVd8AeEIceF7XUvGFwVVw2xtNtQCSGVnlTzAwwDxEVO4fNnOPyy+FX/BWGxtfjZp3iD4r/DFvjP4dhs5rO60nWPF+oWd3ggtE9veQ/NCUkwSrxyoytIu1WZZE+n/ANrv/goR+yL/AMKj+C+qar+wvDqY8deDZ9ctbZfjFrVpFpyR+ItZsDHL5EafbJS1i8nny4kVJo4eY4IxXzeM4ypr3aEW/P8A4f8AyP1zh/6PsY2qZtV5n/KtEvW2r9VJehz/AMdv+Cx3inWtQXSr/wAXWPhRo0Xz7fw/ZzRuzZ3BjL+8kVuxUSKCCMr62PjD8WP2ff2TPEdx4b+OEvxc+IHxcuJbbU9VTwVqtrb6dpFtc20cywXNxfWzvPqC7gz+QHt9kke2dnDqvr//AAQB+PP7HP7VX7aWl/DXUP2H/B+k+KPE2i6gsOsT65feMdJDQAXW1tN1UzJb5ihYC5R3kD4QAJM5X3v/AIOef2sP2XfgF+2H4N8O/Fj9kqy+NfjLUfCseuya/H40'
	$Logo_end &= 'u/CU8dtJcz2sUEklnG0l0V+xuR5xxGGAT7z4+ZxXEWLraXt+f4/okftGT8A5PlqtQprbskvwV/vbNT/gj7+x7+wb/wAFLv2ZPjlBoa/FTxd9oh0xfEtr8Q4bGPWPBCobqa2n0u7sbeNI1maKXfskcyC0jWaMIdkn52+Evhv/AMEnPEPxkPhu8+IH7Z2h6It1cQDxVf22ivpDJEJCk2yCzkvfLm2KEBtd4Mqb1jAcr+7n/Bv78c/2ff2mv2O5/F3wF+BkPwTs7GS08Na9bDS7eKbUbuztIn/4/wCMmXUli+0uq3NztndmdnRWc5+Df2bv+Cvf/BP39qH9srwv8KtB/YQ8MW8XjLVbTRNO1K5+HXh03EU8xKM09pEr+XFG5BZ0ldtgdioKhT4c6kpvmk7s+wp04U4qFNJJdFoj9avCX/BMH4E+Ef2K/wDhnuP4eaPffCZ7SW1m0a9LzmdpGZ3uDMW80XG9i6zo6yRsFMbJsTb+YP8AwQ2/YV/4Jr6t+20urfAX4leOvjV8RPCOiya5aaX4y0mT7FowiurVBqcPm6VaL9phlkiWMl2KGUuqbkV0/blmCJk9FGa/NX/gix/wUE/ZH/bM+PWvWf7O37M+ofCbWtP0C4lvvFA+Hmi6HaXECXFmJNP+2WM0jNKzzW8vkNgFYtx+6uZND3v/AIKvfAP9kzX/ANnbV/HH7U3hHwnceDfD7wm6164065OpWbTSRW6CKexX7aN7GFCsR5CruGEyPcP2Uf8AhBJP2Xfhq/wvC/8ACtG8K6WfCJAnH/Eo+yRfYv8Aj4/f/wDHv5f+t/ef3vmzXR/E7xyvwx+G/iDxI+k65ry+H9NudSbTNFsmvdS1AQxNJ5FtAvMs77dqRjlnZVHWt0UAeI/HjwJ+z/d/tM/DC8+Ingv4eav8WPEV29h4H1PVfC8GoawsunxT6mRb3TQu9uIFjnnVi6Krn5TvdQ3ty/d46emKqalrMOl3VlFMtyzX8xgiMVtJKqMI'
	$Logo_end &= '3kJkZVIjXbGw3uVUsVXO51U21bcoI6HkUAYthL4ffx9qkVs2l/8ACTpY2j6gI9n24Whkufsvm4+fyvMF35Yb5c+dt/irZdgq/NgD3pQc0jNsXPP4DNAEWmalb6xp1veWdxDdWl1Gs0E8LiSOZGGVZWHDKQQQRwQakllWFNzsqrkDJ9ScD9acDkUUAFNDqX25G7uKdRQAU3yE/uL+VOooAK/BH/gtB4D1zWf+ClvxKubPRtWureQ6ZslhtJJEfGl2YOGAwcEEfUV+91RSWUMr7mjVmPcivquD+Kq3D+NeNowU24uNndLVp309DGthqVePJVvby/4KZ/Lp/wAKw8Tf9C7rn/gBL/8AE0f8Kw8Tf9C7rn/gBL/8TX9RX9m2/wDzxj/Kj+zbf/njH+Vfpn/Edsf/ANA0Pvkcv9j4P+996/yP5df+FYeJv+hd1z/wAl/+Jo/4Vh4m/wChd1z/AMAJf/ia/qK/s23/AOeMf5Uf2bb/APPGP8qP+I7Zh/0DQ++Qf2Pg+8vvX+R+f/8AwTM+GGteL/8Agjjr3hOK3aw1bxBZ67psC3sbxLG0/nRKz/LuCjfnIBOPXpX44fHGz8QfC3xtqHhHxBpl14f1KxZop7e6Xy5ZVDFSytna0TEZV0JVl5DEMK/qRS2jjj2LGoX0xxXK6z8EfDut3Uk01mVkkOWKELmvxnMsfLG4yrjJqzqScrLZXd7H0eBzBYb3Yq6slq9dFY/lbWVdv3l9aPNX+8v51/Ux/wAM7eFz/wAus3/fz/61H/DOvhf/AJ9Zv++//rVw8x6b4h/ufifyz+av95fzo81f7y/nX9TH/DOvhf8A59Zv++//AK1H/DOvhf8A59Zv++//AK1HMH+sH9w/ln81f7y/nR5q/wB5fzr+pj/hnXwv/wA+s3/ff/1qP+GdfC//AD6zf99//Wo5g/1g/uH8s/mr/eX86PNX+8v51/Ux/wAM6+F/+fWb/vv/AOtR/wAM6+F/+fWb/vv/AOtR'
	$Logo_end &= 'zB/rB/cP5Z/NUfxL+dfXv/BGL9kXVv2iP2y/BfiSbStQk8G+CNXj1e81KMtFF9rtds9vCj7SruJ/s7vH/wA8s5KllLfu2P2dvDIP/HrN/wB/P/rVu+E/h1pPgwN9htVjZurNy1HMY4jPHUpuEY2ubasT+VOoAoqT58KKKKACmo7MzAoy7TgEkfNwDkfy5x0+hp1FABQDkUUDigDK8Va9eeHtLW4tND1LXpmureD7NYvbpKqSTpG8xM8sSbIUdpnAYuUiYIkkhWNtUdKaN272p1AHmfwi+LPjrx78WvHGj+IvhPrXgbwv4dkih0HxDf63p12PFhM10kskVtazSyW8Sxx2sim42SP9pZTHGYju6b4yeJfEHgz4UeJNY8J+Gm8ZeKNL0y5utJ0AX8en/wBtXaRM0Nr9ol/dw+a4VPMfKpu3EHGKy/2gvA/jn4ifD6bS/Afjq3+HOsXEiZ1o6FHrE9vGHVmEUU0ixB2AK7pFkADHC5wR5hp37AUnjvwvqVh8X/ij8SPitJqUD2MirrE/hewazdCrwPZ6TJbQzB90m5pldirBPurg6xhBq8pfKzv/AJfiYVKlRS5YQv53SX6v8DxD4A/8FcvG/wAMLrXNL/bD+Gfh/wCAPiK4ms28IaZo3iOHxXf+JIphMjj7Hp5nni2SwbVmcLHKZgi4aJi3lv7av/BwVN4N8Y6Fpnwps/D2jw/6d/al58QtLu9s/lm3EHkW9jcG7g3b58/a7ePOwbR8rCvpXwh/wQ1/Zb8Fa9Y6hZ/CXTZJNOlWaKK81jUb62ZgwbEkE07xSqcDKupU8gggkV6fD+xp4J+F3jLw/rnw1+Gfwc8K6hZ3ijUryPwjbwXpsjkulrLAIzHKWCYL7l45UkCu+jWwNLVxlN+dkvuV/wAzxMZhs3xHuQqwpRf8qcpfJuy++L7H5VfHL9vrVP8AgpP8LrjwTq/irxV4yuL2G2l1DwT8J/Bs6R3nluJg5N5DNcSbJFLFvOijZYYz'
	$Logo_end &= '5KurFuC8VeE/jr+xFLY+Dvh5+y74+t7PUoxqkmoXGg3/AIqOpIyLEj3EmnB4bWf9yxaB5Sy71IRAw3fvpCmBll2luSOOK+Sf229K/bKvP2xvhfJ8BdW+GFh8I00u/XxXF4ktDMWvtj+SZwpFwYv9T5QtWUiQSmbcmwV6EeJKlJcuFpxgvm/x0Pl63hnhca3LOMTVxF3e0mlFdlyxSVl000eu547r3/BOb9oy0/Zx8aanN4o+Glx8RrXQb+Xw7oXh/Rp5YbvUUt2a0jN5e3cUa+ZKFU+ZCEXIJbaCK/Nn/gkT+xD+0P8AG39oNdY+O37HuveLfButeI7a11nV/Emrz+E7rRFLSG5vRZ3M8cuoR5ljd1Ebqwt2RSWdgP6QWXKEeorwf9grTvj5YeGPiF/w0DfeGdQ1qTx5qknhV9Eijjt4/DpEIskKqNwYMJjiUvJtKb3LZrz8RnWNr/xKj+Wn5Hv5PwPkWV3eBw0Yt7vdv77/AHbHkX/BXvQ/jBH+zJpPw3+BP7Lnw7+PGna5aNY3lj4n1Wws9B8MQW0tm1vG1hNNbtcrIglEYhmi8h7aNzu+VD3H/BHD4a+K/hT/AME4PhroPjj4X+Gfg34msYr83XhHQXkax0gPqN1JFsMlxcvulieOZ907tvmfO0/Iv05KMp03e1Ng8znfjHYdx9f8/nXln1aVtj4N/wCCp3iP9ojXPit4Dsvhb+xv4D+O2i+DfEVvrMut+Mdd0iNI40jiZjpkdxcpJaXe55EFy6OIzBu8qUOpH3ksQVGwuGb9fSnSBiRtP1pwGBQB5npXxN8fah+1Pc+FZvhXcWHwzh8OPqSeO59fsm+06sLsRDTk06MtOFa3/fi5YqvGwoGwToftM+P/ABt8Lvgdr2vfDr4fP8VPGmnpEdN8LLrlvoh1VmmjRx9suAYoQkbPISwORHtALEV3mTu/2fXNI2ccUAeH/sR/HT4w/Hbwrrlx8ZfgHcfAfWNPuo0sLM+M9P8AE8Wq'
	$Logo_end &= 'wMmTKs1ptMbKwIZHQDDIVZssqT/tufGr4ufA/wCHulXvwd+Bs3x31+81AQXmk/8ACYWPhmOwtfLkY3DT3e4O3mCNRGqEkOzFl2AN7Qm7+Kg53fxdPagDn/hPrmt+LfhX4b1XxR4c/wCEP8TappNrdavoQv49Q/sW7khV5rT7TGAk/lSM8fmoAr7dw4Ir84/2xvDP7Rnh3/go/wCMvE3hH9gH4F/HDwK0WmrpfjG81TRNJ8TarJHbW7SPLc3c7uBFIJIEBt1IEMbBmUAH9Ph0pj7v4c+mCBj60AecfteaVqmsfsuePLPRfAOm/FDWL7Qrq1tfCV/cQw2PiCSSMoLWdp2WIQtnDFyPl3Y5wK/Nv/g3j/ZC+L37Mnxn8Xf8LC/Y3+F/wD0y90y+Efi3w/rkl9fXdybmxUafsudTvrgW7iGSYMjLBmCMqAW3P+toyV9D/Kok87PIXryc/wAvb9aAPxr/AODnL9mHx18RviFpvjnwz+xv4X+PWi+GvDdjFqPi681nVGvrIfbbxTp8WmaZqNpdzBDcRTmVVkVVmkLDEZaOh/waz/Bnxh4D+NPxS1PxV+xnZ/s9pc6FZwWfif7F4gsZ7zM7s9iqa1e3MzpJtSUtbbEU2yebuLwbf1s/actPiVe/AvxDF8ILvwhY/Ed4UGiT+KYZ5dIjk8xN5nWAiUjyvMC7c4cqSCAQd/4aQeJIvh5oK+MJGLMAtFuPFi2EH9sAUmjxSRae95sAF8426ylpBF4AZu2B2LbcZ5oAAP5K/ih+yD8AGD4bfE218M4Aq/8ABNrw/Z4AqfbHtIobO18AHl/a6g6yeWQAJcxa7JFKoYcADxSbSrBgSrIAmv6dfFXwaj0AG/4J1+NvBfgAM+DPhnTHuPAAlrlnpXw2EloA2ul3088VztsAF3geOFI7qR8A52V0A89iWU4ASL/7TOm/tBUA98YvhTL8I9QAfhnY+BbfVXYA+IsPiaK5k1AAu9P8222rpxgAVKrceULs'
	$Logo_end &= 'fvQAhNxh5I3CvbAA7jGcYDY4oA8A57f+COv7A3wAaPgj/wAFTvAAHdeK/wBgjwEA/DnTPDJuLrUAPxXp+q67cJoAMktpLFHNbTUA7rt1Y3EiyTQAW5I45pVXzCoAEdNyfq7/AMEAYRvi9rX7OtoAeGfhD+zd4H8A2jdS168VrywAPGV/p8eh6KsAC8UizTW11NAAm6d/nVBHInkAbDezEAI/1ksA5nm/Nyrew+QA698/Tt6/hI0A17/hQB8af8EADb4UfE74M/sAIGqaH8VvgP8AAAz/AGe/EEcA4nupbbw/4G8AJ/s++tWt7UoAX0hju7vM7ycAnREvKW2W8YwAKoXPr37bfxsAvi78C/BWj3UA8G/gRcfHjXIA9vTFeacPGOkA/hmHTbcRsfMAmnu8+YxfYqoAIh4LsWXaA/sAZGW/i/P1ok0AwxtwfXJoAxcA4a63qnij4eYAhanrugTeFdcANS0+3utR0aUAuorqTSbl41YAltmmiJjkMbkAZC8ZKMVyCQYAuT0r4r+Mbj8AaK1bwnc/CfwAR2ngq0t7Z9MA/G41bS5LG/kA3jmkuENqLn4A2RpGRBGHMJMAJJLJ8iRxiWQA9IpDncPTvQAALWZ4Q1y78ScAh60vr3RtQ8MA9xdR75NPv5IAB7q0P9yQwSQAsRbvlJGHPWsAToUEDk5oAbMAyNFA7LG0rKoASEXG5z6DJAwAn3IFOFFFAAQg0UUUAFHYAFInAN2iigBaKKKAAgrMAAHSiiigAgP/AOIAD//Z'
	$Logo_end = _Base64Decode($Logo_end)
	If @error Then Return SetError(1, 0, 0)
	Local $tSource = DllStructCreate('byte[' & BinaryLen($Logo_end) & ']')
	DllStructSetData($tSource, 1, $Logo_end)
	Local $tDecompress
	_WinAPI_LZNTDecompress($tSource, $tDecompress, 33610)
	If @error Then Return SetError(3, 0, 0)
	$tSource = 0
	Local Const $bString = Binary(DllStructGetData($tDecompress, 1))
	If $bSaveBinary Then
		Local Const $hFile = FileOpen($sSavePath & "\sortshort bye.jpg", 18)
		If @error Then Return SetError(2, 0, $bString)
		FileWrite($hFile, $bString)
		FileClose($hFile)
	EndIf
	Return $bString
EndFunc   ;==>_Logo_end

func _logo_exit()
	$logoUi = GUICreate("",570,130, Default, Default, $WS_POPUP) ; sans bordures
	$logoPic = GUICtrlCreatePic("", 0, 0, 570, 130); l'image prend toute la gui
	_GDIPlus_Startup()
	$Bmp_Logo_end = _GDIPlus_BitmapCreateFromMemory(_Logo_end(), True); decodage de l'image
	_WinAPI_DeleteObject(GUICtrlSendMsg($logoPic, $STM_SETIMAGE, $IMAGE_BITMAP, $Bmp_Logo_end)); insertion dans la gui
	guisetstate(); montre la gui
EndFunc

func _minimize() ; minimise par le bouton - en haut a droite
	WinSetState ( $ui, "", @SW_MINIMIZE)
EndFunc

Func _MoveTile() ; en cas d'appuie sur CTRL + clic permet de bouger les tuiles
	Local $a , $section
	Local $sfilename = $sFilePath & "\capture.bmp"
	Dim $MoveTileInfos[4]
	$a = GUIGetCursorInfo(@GUI_WinHandle)
	_DebugPrint("MoveTile" & @CRLF & "-->ControlId:" & @TAB & $a[4])
	while _ispressed("01") ; clic gauche
		For $i = 0 To uBound($iconCtrl, 2)-1 ; clic dans une des cases de liens
			If $a[4] == $iconCtrl[0][$i] Or $a[4] == $iconCtrl[1][$i] and _ispressed("11") and $anavilinks[$i+1][1] <> "Libre" Then
				 _WinAPI_SetCursor($g_hCursor)
				$section = $anavilinks[$i+1][0]
				$MoveTileInfos[0] = $section ; sauvegarde du bouton de départ
				$MoveTileInfos[1] = IniRead($filelink,$section,"label","Erreur"); sauvegarde des infos de la tuile
				$MoveTileInfos[2] = IniRead($filelink,$section,"link","Erreur")
				$MoveTileInfos[3] = IniRead($filelink,$section,"icone","Erreur")

			EndIf
		Next
	WEnd
	$a = GUIGetCursorInfo(@GUI_WinHandle)
	For $i = 0 To uBound($iconCtrl, 2)-1 ; relaché du clic dans une des tuiles libres
		If $a[4] == $iconCtrl[0][$i] Or $a[4] == $iconCtrl[1][$i] and _ispressed("11") and $anavilinks[$i+1][1] = "Libre" Then
			$section = $anavilinks[$i+1][0]
			iniwrite($filelink,$section,"label",$MoveTileInfos[1]) ; ecriture des tuiles d'arrivée
			iniwrite($filelink,$section,"link",$MoveTileInfos[2])
			iniwrite($filelink,$section,"icone",$MoveTileInfos[3])

			iniwrite($filelink,$MoveTileInfos[0],"label","Libre") ; effacement des tuiles de départ
			iniwrite($filelink,$MoveTileInfos[0],"link","")
			iniwrite($filelink,$MoveTileInfos[0],"icone","")
		EndIf
	Next
	_charger_combo()
	GUICtrlSetState($checkbox_moveto,$GUI_ENABLE)
EndFunc

func quitter()
	;SplashTextOn ( "SortShort " & $version, "Bye bye :p",180, 60, -1, -1, 4, "", 24)
	_logo_exit()
	_Transparent("hide", $ui)
	_WinAPI_DestroyCursor($g_hCursor)
	_WinAPI_DeleteObject($Bmp_Logo) ; debut de suppression de la GUI d'initalisation
	_GDIPlus_Shutdown() ; on quitte la ressource GDI dont on a plus besoin
	_Transparent("hide",$logoUi); on efface lentement la gui d'initailisation
	GUIDelete($logoUi) ; et on la detruit
	;SplashOff()
	Exit
EndFunc

func _read_combo_GuiQuestion()
	$ReadComboGuiQuestion = @ScriptDir & "\" & GUICtrlRead($combo_GuiQuestion) & ".link"
	if $ReadComboGuiQuestion <> "" then GUICtrlSetState($btn1,$GUI_ENABLE)
EndFunc

func refresh_combo() ;Permet de rafraichir les données de la liste en cas de nouvelle liste
   If IsArray($arraylink) Then ; si une liste de liens existe
	   For $i=1 To Ubound($arraylink)-1
		   $name=stringsplit($arraylink[$i],".")
		   GUICtrlSetData($findIn,$name[1])
	   Next
	   GUICtrlSetData($findIn,$name[1],$name[1]); affichage de la liste dans le combo
		$filelink = @ScriptDir & "\" & GUICtrlRead($findIn) & ".link"
	Else ; si jamais la seule liste en place est supprimée
		$nomfichier = InputBox("SortShort " & $version, "Il n'existe plus de liste valide" & @CRLF & "Veuillez en recréer une nouvelle") ; on en recrée une autre ou on quitte
		if $nomfichier="" then
			msgbox(0,"SortShort " & $version, "Merci de n'avoir pas utilisé ce programme :-)")
			exit
		EndIf
		$filelink = @ScriptDir & "\" & $nomfichier & ".link"
		for $i = 1 to 32
			IniWriteSection($filelink,"bouton" & $i,"label=Libre" & @CRLF & "link=" & @CRLF & "icone=")
		Next
		$arraylink=_FileListToArray(@ScriptDir & "\","*.link"); recherche de tous les fichiers de liens pour alimenter le combo
		$first_launch = False
		$clic_combo = 0
		refresh_combo()
	EndIf
EndFunc

func _returnToDesktop() ; permet de tout minimiser et d'afficher le bureau
	_Transparent("hide", $ui)
	WinSetState ( $ui, "", @SW_MINIMIZE)
	WinMinimizeAll()
	_Transparent("show", $ui)
EndFunc

Func _Richedit_modified() ; permet le glisser / déposé d'un hyperlien et son traitement en tuile
	$richedit_content = _GUICtrlRichEdit_GetText($hRichEdit)
	$choose = $richedit_content
	if $choose ="" Then
		msgbox(64,"SortShort " & $version, "Veuillez Copier/coller ou Glisser/Déposer un Hyperlien", 2)
		Return
	endif
	$reponse = InputBox("Nom du lien","Donnez un titre à l'icone !",StringTrimLeft($richedit_content,7))
	if @error == 1 or $reponse = "" or _Check_LabelForbidden($reponse) <> 0 Then ; si le nom de fichier contient des caractères interdits
		msgbox (64,"SortShort " & $version, "Erreur, vous ne pouvez pas mettre ce Label :" & $reponse,2)
		Return
	EndIf
	iniwrite($filelink,$section,"label",$reponse)
	IniWrite($filelink,$section,"link", $choose)
	IniWrite($filelink,$section,"icone",$dll_icones_system &",221")
	_charger_combo()
	close_hyperlinkGui()

EndFunc

func _suppr_liste() ; Permet de supprimer une liste
	$linktosupress = GUICtrlRead($findIn)
	$file2supress = @scriptdir & "\" & $linktosupress & ".link"
	$message = msgbox(1, "SortShort " & $version, "Etes vous sur de vouloir supprimer la  liste : " & @CRLF & $linktosupress )
	if $message = $IDOK Then
		FileDelete($file2supress)
		GUICtrlSetData($findIn,"")
		$arraylink=""
		$arraylink=_FileListToArray(@ScriptDir & "\","*.link")
		MsgBox(64,"SortShort " & $version, "La liste : " & $linktosupress & " a été supprimée")
		refresh_combo()
		_charger_combo()
	EndIf
EndFunc

func _String_cut_with_dots($string); mise en forme des labels sur la GUI
	$slongueur = stringlen($string)
	if $slongueur > 14 Then
		$count = $slongueur - 14
		local $string_corrected =StringTrimRight ($string,$count) & "..." ; cesure à 17 caractères
		return $string_corrected
	Else
		return $string
	EndIf
EndFunc

Func _Transparent($sType, $hWnd) ; affiche la GUI en transparence progressive
	If $sType = "show" Then
		For $i = 0 To 255 step 2
			WinSetTrans($hWnd, Default, $i)
			Sleep(10)
		Next
	Else
		For $i = 255 To 0 Step -4
			WinSetTrans($hWnd, Default, $i)
			Sleep(10)
		Next
	EndIf
EndFunc

func uncheckall() ; permet de deselectionner tous les items de la gui_question
	GUICtrlSetState($checkbox_Fichier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_internet,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_nothing,$GUI_UNCHECKED)
	GUICtrlSetState($Checkbox_icone,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_dossier,$GUI_UNCHECKED)
	GUICtrlSetState($checkbox_moveto,$GUI_UNCHECKED)
	GUICtrlSetState($combo_GuiQuestion, $GUI_DISABLE)
	_DebugPrint("UNCHECKALL" & @CRLF & "-->Fichier :" & _IsChecked($checkbox_Fichier) & @CRLF & _
				"-->Dossier" & @TAB & _IsChecked($checkbox_dossier) & @crlf & _
				"-->Suppr" & @TAB & _IsChecked($checkbox_nothing) & @CRLF & _
				"-->Icone" & @tab & _IsChecked($Checkbox_icone) & @crlf & _
				"-->Internet" & @TAB & _IsChecked($checkbox_internet) & @CRLF & _
				"-->Deplacement" & @TAB & _IsChecked($checkbox_moveto))
EndFunc

func valider_guiquestion(); permet de valider la selection de la gui_question
	_DebugPrint("Valider_guiquestion" & @CRLF & "-->$flag " & $flag)
	if _IsChecked($checkbox_Fichier) or _IsChecked($checkbox_dossier) or _IsChecked($checkbox_internet) or _IsChecked($checkbox_nothing) or _IsChecked($Checkbox_icone) or _IsChecked($checkbox_moveto) Then
		_DebugPrint("Valider_guiquestion" & @CRLF & "-->ALL CHECKBOX OFF ")
		if $flag ="iconbutton" then
			iconbutton()
			GUISetState(@SW_HIDE, $gui_question)
			WinSetTrans($ui,Default,255)
			GUISwitch($ui)

		Else
			GUISetState(@SW_HIDE, $gui_question)
			GUISwitch($ui)
			Faislien($flagbouton, $flag)
			WinSetTrans($ui,Default,255)
		EndIf
		GUICtrlSetState($Checkbox_icone,$GUI_ENABLE)
		GUICtrlSetState($checkbox_moveto,$GUI_ENABLE)
	EndIf
EndFunc

func validericone() ;fonction de la gui icones, valide la selection
	Local $lect_old_icon = IniRead($filelink,$flagbouton,"icone","Erreur")
	if StringRegExpReplace($lect_old_icon, "^.*\.", "") = "ico" then FileDelete($lect_old_icon); supression de la ressource inutilisée
	IniWrite($filelink,$flagbouton,"icone", $dll_icones_new &"," & $Icon)
	_charger_combo()
	GUIDelete($GuiIcon)
	_GUI_Incones()
	GUISwitch($ui)
EndFunc

Func _WinAPI_LZNTDecompress(ByRef $tInput, ByRef $tOutput, $iBufferSize = 0x800000)
    Local $tBuffer, $Ret
    $tOutput = 0
    $tBuffer = DllStructCreate('byte[' & $iBufferSize & ']')
    If @error Then Return SetError(1, 0, 0)
    $Ret = DllCall('ntdll.dll', 'uint', 'RtlDecompressBuffer', 'ushort', 0x0002, 'ptr', DllStructGetPtr($tBuffer), 'ulong', $iBufferSize, 'ptr', DllStructGetPtr($tInput), 'ulong', DllStructGetSize($tInput), 'ulong*', 0)
    If @error Then Return SetError(2, 0, 0)
    If $Ret[0] Then Return SetError(3, $Ret[0], 0)
    $tOutput = DllStructCreate('byte[' & $Ret[6] & ']')
    If Not _WinAPI_MoveMemory(DllStructGetPtr($tOutput), DllStructGetPtr($tBuffer), $Ret[6]) Then
        $tOutput = 0
        Return SetError(4, 0, 0)
    EndIf
    Return $Ret[6]
EndFunc   ;==>_WinAPI_LZNTDecompress

Func WM_COMMAND($hWnd, $iMsg, $wParam, $lParam) ; gère le clic sur la combobox
    #forceref $hWnd, $iMsg
    Local $hWndFrom, $iIDFrom, $iCode, $hWndCombo
    If Not IsHWnd($findIn) Then $hWndCombo = GUICtrlGetHandle($findIn)
    $hWndFrom = $lParam
    $iIDFrom = BitAND($wParam, 0xFFFF) ; Mot de poids faible
    $iCode = BitShift($wParam, 16) ; Mot de poids fort
    Switch $hWndFrom
        Case $findIn, $hWndCombo
            Switch $iCode
                Case $CBN_CLOSEUP ; Envoyé lorsque la liste déroulante d'une ComboBox a été fermée
                   $clic_combo = 0
				   _DebugPrint("$CBN_CLOSEUP" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)
                    ; Aucune valeur de retour
                Case $CBN_DBLCLK ; Envoyé lorsque l'utilisateur double-clique sur une chaîne dans la liste déroulante d'une ComboBox
                    $clic_combo = 0
					_DebugPrint("$CBN_DBLCLK" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)
                    ; Aucune valeur de retour
                Case $CBN_DROPDOWN ; Envoyé lorsque la liste déroulante d'une ComboBox est sur le point d'être rendue visible
                    $clic_combo = 1
					_DebugPrint("$CBN_DROPDOWN" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)

                    ; Aucune valeur de retour
                Case $CBN_EDITCHANGE ; Envoyé après que l'utilisateur ait pris une mesure susceptible d'avoir modifié le texte de la zone de saisie d'une ComboBox
                    _DebugPrint("$CBN_EDITCHANGE" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)
                    ;_Edit_Changed()
                    ; Aucune valeur de retour
                Case $CBN_EDITUPDATE ; Envoyé lorsque la zone de saisie d'une ComboBox est sur le point d'afficher un texte modifié
                    _DebugPrint("$CBN_EDITUPDATE" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)
                    ; Aucune valeur de retour
                Case $CBN_ERRSPACE ; Envoyé quand une ComboBox ne peut pas allouer suffisamment de mémoire pour répondre à une demande spécifique
                    _DebugPrint("$CBN_ERRSPACE" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)
                    ; Aucune valeur de retour
                Case $CBN_KILLFOCUS ; Envoyé quand une ComboBox perd le focus du clavier
                    $clic_combo = 0
					Local $hgui = @GUI_WinHandle
					ControlFocus($hgui,"",$about)
					_DebugPrint("$CBN_KILLFOCUS" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)

                    ; Aucune valeur de retour
                Case $CBN_SELCHANGE ; Envoyé lorsque l'utilisateur modifie la sélection courante dans la liste déroulante d'une ComboBox

                    _DebugPrint("$CBN_SELCHANGE" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)
                    ; Aucune valeur de retour
                Case $CBN_SELENDCANCEL ; Envoyé lorsque l'utilisateur sélectionne un élément, mais sélectionne un autre contrôle ou ferme la boîte de dialogue
                    $clic_combo = 0
					_DebugPrint("$CBN_SELENDCANCEL" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)
                    ; Aucune valeur de retour
                Case $CBN_SELENDOK ; Envoyé lorsque l'utilisateur sélectionne un élément de la liste, ou sélectionne un élément, puis ferme la liste
                    $clic_combo = 0
					_DebugPrint("$CBN_SELENDOK" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)

                    ; Aucune valeur de retour
                Case $CBN_SETFOCUS ; Envoyé quand une ComboBox reçoit le focus du clavier
                    _DebugPrint("$CBN_SETFOCUS" & @CRLF & "--> hWndFrom:" & @TAB & $hWndFrom & @CRLF & _
                            "-->IDFrom:" & @TAB & $iIDFrom & @CRLF & _
                            "-->Code:" & @TAB & $iCode & @CRLF & _
							"-->clic_combo:" & @TAB & $clic_combo)
                    ; Aucune valeur de retour
            EndSwitch
    EndSwitch
    Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND





