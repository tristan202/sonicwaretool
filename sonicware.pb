EnableExplicit

; --- IDs and Settings ---
Enumeration
  #WinMain
  #WinAbout
  #ListFiles
  #ComboSampleRate
  #ComboChannels
  #ComboBitDepth
  #BtnConvert
  #BtnClear
  #BtnAddFolder
  #BtnAddFiles
  #BtnSetOutputDir
  #TxtStatus
  #TxtOutputDir
  #CheckNormalize
  #TxtAboutLink
  #Menu_Language_EN
  #Menu_Language_DK
  #Menu_Language_DE
  #Menu_Language_IT
  #Menu_Language_ES
  #Menu_Language_FR ; Tilføjet Fransk ID
  #Menu_About
  #AppIcon
EndEnumeration

Global G_TxtListHeader, G_FrameOutput, G_FrameSettings
Global G_LblSampleRate, G_LblBitDepth, G_LblChannels

Global NewMap Lg.s()
Global NewList FilesToProcess.s()
Global G_OutputDir.s = GetHomeDirectory() + "Documents\XT_Export\"
Global G_IniFile.s = "lofi_config.ini"
Global G_CurrentLanguage.s = "English"
Global G_SoXPath.s = ""

Global G_SelSR = 2, G_SelBD = 1, G_SelCH = 0, G_SelNorm = 0

; --- Core Functions ---

Procedure.s FindSoX()
  Protected Path.s = ""
  If FileSize("sox.exe") > 0 : ProcedureReturn "sox.exe" : EndIf
  Path = "C:\Program Files (x86)\sox-14-4-2\sox.exe"
  If FileSize(Path) > 0 : ProcedureReturn Path : EndIf
  Protected PathEnv.s = GetEnvironmentVariable("PATH")
  Protected i, Count = CountString(PathEnv, ";") + 1
  For i = 1 To Count
    Protected TempDir.s = StringField(PathEnv, i, ";")
    If Right(TempDir, 1) <> "\" : TempDir + "\" : EndIf
    If FileSize(TempDir + "sox.exe") > 0 : ProcedureReturn TempDir + "sox.exe" : EndIf
  Next
  ProcedureReturn ""
EndProcedure

Procedure AddToFileList(Path.s)
  Shared FilesToProcess()
  If LCase(GetExtensionPart(Path)) = "wav"
    AddElement(FilesToProcess())
    FilesToProcess() = Path
    AddGadgetItem(#ListFiles, -1, GetFilePart(Path) + Chr(10) + GetPathPart(Path))
  EndIf
EndProcedure

Procedure ScanDirectory(Path.s)
  Protected Dir = ExamineDirectory(#PB_Any, Path, "*.wav")
  If Dir
    While NextDirectoryEntry(Dir)
      If DirectoryEntryType(Dir) = #PB_DirectoryEntry_File
        AddToFileList(Path + DirectoryEntryName(Dir))
      EndIf
    Wend
    FinishDirectory(Dir)
  EndIf
EndProcedure

Procedure.s CleanFileName(FullPath.s)
  Protected FileName.s = GetFilePart(FullPath)
  Protected i, LastDot = 0
  For i = Len(FileName) To 1 Step -1
    If Mid(FileName, i, 1) = "." : LastDot = i : Break : EndIf
  Next
  If LastDot > 1 : FileName = Left(FileName, LastDot - 1) : EndIf
  FileName = ReplaceString(FileName, " ", "_")
  ProcedureReturn FileName
EndProcedure

Procedure SetLanguage(Language.s)
  ClearMap(Lg())
  Select Language
    Case "Dansk"
      Lg("Title") = "Sonicware Lofi-12 XT Tool v1.0"
      Lg("ListHeader") = "Samples klar til XT (WAV):"
      Lg("ColName") = "Filnavn" : Lg("ColPath") = "Kilde-sti"
      Lg("BtnFiles") = "Tilføj Filer" : Lg("BtnFolder") = "Tilføj Mappe" : Lg("BtnClear") = "Ryd Liste"
      Lg("FrameOut") = "Output Destination" : Lg("BtnChange") = "Skift Mappe"
      Lg("FrameSet") = "XT Optimeret Eksport (SoX)" : Lg("LabelSR") = "Sample Rate:"
      Lg("LabelBD") = "Bit-dybde:" : Lg("LabelCH") = "Kanaler:" : Lg("CheckNorm") = "Normalize"
      Lg("StatusReady") = "Klar (SoX fundet)" : Lg("StatusError") = "FEJL: sox.exe ikke fundet!"
      Lg("BtnStart") = "START KONVERTERING" : Lg("MsgDone") = "Færdig!" : Lg("MsgNoFiles") = "Vælg filer først!"
      Lg("MenuLg") = "Sprog" : Lg("MenuHelp") = "Hjælp" : Lg("MenuAbout") = "Om"
      Lg("AboutTxt") = "Konvertering til hardware samplere, f.eks. Sonicware Lofi-12 xt." + #LF$ + 
                       "Open Source (MIT) - Frit til brug og ændring." + #LF$ + #LF$ + "Skabt af: tristan202"
      Lg("Mono") = "Mono" : Lg("Stereo") = "Stereo"
      
    Case "Français"
      Lg("Title") = "Outil Sonicware Lofi-12 XT v1.0"
      Lg("ListHeader") = "Samples prêts pour XT (WAV):"
      Lg("ColName") = "Nom du fichier" : Lg("ColPath") = "Chemin source"
      Lg("BtnFiles") = "Ajouter fichiers" : Lg("BtnFolder") = "Ajouter dossier" : Lg("BtnClear") = "Vider la liste"
      Lg("FrameOut") = "Destination de sortie" : Lg("BtnChange") = "Changer dossier"
      Lg("FrameSet") = "Export optimisé XT (SoX)" : Lg("LabelSR") = "Taux d'échantillon:"
      Lg("LabelBD") = "Bits:" : Lg("LabelCH") = "Canaux:" : Lg("CheckNorm") = "Normaliser"
      Lg("StatusReady") = "Prêt (SoX trouvé)" : Lg("StatusError") = "ERREUR: sox.exe non trouvé!"
      Lg("BtnStart") = "LANCER LA CONVERSION" : Lg("MsgDone") = "Terminé!" : Lg("MsgNoFiles") = "Ajoutez des fichiers!"
      Lg("MenuLg") = "Langue" : Lg("MenuHelp") = "Aide" : Lg("MenuAbout") = "À propos"
      Lg("AboutTxt") = "Conversion pour échantillonneurs matériels, ex. Sonicware Lofi-12 xt." + #LF$ + 
                       "Open Source (MIT) - Libre d'utilisation et de modification." + #LF$ + #LF$ + "Créé par: tristan202"
      Lg("Mono") = "Mono" : Lg("Stereo") = "Stéréo"
      
    Case "Deutsch"
      Lg("Title") = "Sonicware Lofi-12 XT Werkzeug v1.0"
      Lg("ListHeader") = "Samples bereit für XT (WAV):"
      Lg("ColName") = "Dateiname" : Lg("ColPath") = "Quellpfad"
      Lg("BtnFiles") = "Dateien hinzufügen" : Lg("BtnFolder") = "Ordner hinzufügen" : Lg("BtnClear") = "Liste leeren"
      Lg("FrameOut") = "Ausgabeziel" : Lg("BtnChange") = "Ordner ändern"
      Lg("FrameSet") = "XT Optimierter Export (SoX)" : Lg("LabelSR") = "Abtastrate:"
      Lg("LabelBD") = "Bittiefe:" : Lg("LabelCH") = "Kanäle:" : Lg("CheckNorm") = "Normalisieren"
      Lg("StatusReady") = "Bereit (SoX gefunden)" : Lg("StatusError") = "FEHLER: sox.exe nicht gefunden!"
      Lg("BtnStart") = "KONVERTIERUNG STARTEN" : Lg("MsgDone") = "Fertig!" : Lg("MsgNoFiles") = "Dateien hinzufügen!"
      Lg("MenuLg") = "Sprache" : Lg("MenuHelp") = "Hilfe" : Lg("MenuAbout") = "Über"
      Lg("AboutTxt") = "Konvertierung für Hardware-Sampler, z. B. Sonicware Lofi-12 xt." + #LF$ + 
                       "Open Source (MIT) - Frei zu verwenden und zu ändern." + #LF$ + #LF$ + "Erstellt von: tristan202"
      Lg("Mono") = "Mono" : Lg("Stereo") = "Stereo"
      
    Case "Italiano"
      Lg("Title") = "Strumento Sonicware Lofi-12 XT v1.0"
      Lg("ListHeader") = "Campioni pronti per XT (WAV):"
      Lg("ColName") = "Nome file" : Lg("ColPath") = "Percorso"
      Lg("BtnFiles") = "Aggiungi file" : Lg("BtnFolder") = "Aggiungi cartella" : Lg("BtnClear") = "Pulisci lista"
      Lg("FrameOut") = "Destinazione di output" : Lg("BtnChange") = "Cambia cartella"
      Lg("FrameSet") = "Esportazione ottimizzata XT (SoX)" : Lg("LabelSR") = "Frequenza:"
      Lg("LabelBD") = "Profondità bit:" : Lg("LabelCH") = "Canali:" : Lg("CheckNorm") = "Normalizza"
      Lg("StatusReady") = "Pronto (SoX trovato)" : Lg("StatusError") = "ERRORE: sox.exe non trovato!"
      Lg("BtnStart") = "AVVIA CONVERSIONE" : Lg("MsgDone") = "Fatto!" : Lg("MsgNoFiles") = "Aggiungi file!"
      Lg("MenuLg") = "Lingua" : Lg("MenuHelp") = "Aiuto" : Lg("MenuAbout") = "Informazioni"
      Lg("AboutTxt") = "Conversione per campionatori hardware, ad esempio Sonicware Lofi-12 xt." + #LF$ + 
                       "Open Source (MIT) - Libero di usare e modificare." + #LF$ + #LF$ + "Creato da: tristan202"
      Lg("Mono") = "Mono" : Lg("Stereo") = "Stereo"
      
    Case "Español"
      Lg("Title") = "Herramienta Sonicware Lofi-12 XT v1.0"
      Lg("ListHeader") = "Samples listos para XT (WAV):"
      Lg("ColName") = "Nombre" : Lg("ColPath") = "Ruta"
      Lg("BtnFiles") = "Añadir archivos" : Lg("BtnFolder") = "Añadir carpeta" : Lg("BtnClear") = "Limpiar lista"
      Lg("FrameOut") = "Destino de salida" : Lg("BtnChange") = "Cambiar carpeta"
      Lg("FrameSet") = "Exportación optimizada XT (SoX)" : Lg("LabelSR") = "Frecuencia:"
      Lg("LabelBD") = "Bits:" : Lg("LabelCH") = "Canales:" : Lg("CheckNorm") = "Normalizar"
      Lg("StatusReady") = "Listo (SoX encontrado)" : Lg("StatusError") = "ERROR: sox.exe no encontrado!"
      Lg("BtnStart") = "INICIAR CONVERSIÓN" : Lg("MsgDone") = "¡Hecho!" : Lg("MsgNoFiles") = "¡Añada archivos!"
      Lg("MenuLg") = "Idioma" : Lg("MenuHelp") = "Ayuda" : Lg("MenuAbout") = "Acerca de"
      Lg("AboutTxt") = "Conversión para samplers de hardware, p. ej. Sonicware Lofi-12 xt." + #LF$ + 
                       "Open Source (MIT) - Libre de usar y modificar." + #LF$ + #LF$ + "Creado por: tristan202"
      Lg("Mono") = "Mono" : Lg("Stereo") = "Estéreo"
      
    Default ; English
      Lg("Title") = "Sonicware Lofi-12 XT Tool v1.0"
      Lg("ListHeader") = "Samples ready for XT (WAV):"
      Lg("ColName") = "Filename" : Lg("ColPath") = "Source path"
      Lg("BtnFiles") = "Add Files" : Lg("BtnFolder") = "Add Folder" : Lg("BtnClear") = "Clear List"
      Lg("FrameOut") = "Output Destination" : Lg("BtnChange") = "Change Folder"
      Lg("FrameSet") = "XT Optimized Export (SoX)" : Lg("LabelSR") = "Sample Rate:"
      Lg("LabelBD") = "Bit-depth:" : Lg("LabelCH") = "Channels:" : Lg("CheckNorm") = "Normalize"
      Lg("StatusReady") = "Ready (SoX found)" : Lg("StatusError") = "ERROR: sox.exe not found!"
      Lg("BtnStart") = "START CONVERSION" : Lg("MsgDone") = "Done!" : Lg("MsgNoFiles") = "Add files first!"
      Lg("MenuLg") = "Language" : Lg("MenuHelp") = "Help" : Lg("MenuAbout") = "About"
      Lg("AboutTxt") = "Conversion for hardware samplers, e.g. Sonicware Lofi-12 xt." + #LF$ + 
                       "Open Source (MIT) - Free to use and modify." + #LF$ + #LF$ + "Created by: tristan202"
      Lg("Mono") = "Mono" : Lg("Stereo") = "Stereo"
  EndSelect
  
  If IsWindow(#WinMain)
    SetWindowTitle(#WinMain, Lg("Title"))
    SetGadgetItemText(#ListFiles, -1, Lg("ColName"), 0)
    SetGadgetItemText(#ListFiles, -1, Lg("ColPath"), 1)
    SetGadgetText(#BtnAddFiles, Lg("BtnFiles"))
    SetGadgetText(#BtnAddFolder, Lg("BtnFolder"))
    SetGadgetText(#BtnClear, Lg("BtnClear"))
    SetGadgetText(#BtnSetOutputDir, Lg("BtnChange"))
    SetGadgetText(#BtnConvert, Lg("BtnStart"))
    SetGadgetText(#CheckNormalize, Lg("CheckNorm"))
    SetGadgetText(G_TxtListHeader, Lg("ListHeader"))
    SetGadgetText(G_FrameOutput, Lg("FrameOut"))
    SetGadgetText(G_FrameSettings, Lg("FrameSet"))
    SetGadgetText(G_LblSampleRate, Lg("LabelSR"))
    SetGadgetText(G_LblBitDepth, Lg("LabelBD"))
    SetGadgetText(G_LblChannels, Lg("LabelCH"))
    SetGadgetText(#TxtOutputDir, G_OutputDir)
    If G_SoXPath = "" : SetGadgetText(#TxtStatus, Lg("StatusError")) : Else : SetGadgetText(#TxtStatus, Lg("StatusReady")) : EndIf
    
    Protected OldCH = GetGadgetState(#ComboChannels)
    ClearGadgetItems(#ComboChannels)
    AddGadgetItem(#ComboChannels, -1, Lg("Mono"))
    AddGadgetItem(#ComboChannels, -1, Lg("Stereo"))
    If OldCH >= 0 : SetGadgetState(#ComboChannels, OldCH) : Else : SetGadgetState(#ComboChannels, G_SelCH) : EndIf
  EndIf
EndProcedure

Procedure OpenAboutWindow()
  If OpenWindow(#WinAbout, 0, 0, 350, 220, Lg("MenuAbout"), #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#WinMain))
    TextGadget(#PB_Any, 10, 30, 330, 70, Lg("AboutTxt"), #PB_Text_Center)
    HyperLinkGadget(#TxtAboutLink, 75, 120, 200, 25, "github.com/tristan202/sonicwaretool", RGB(0, 102, 204))
    Protected BtnClose = ButtonGadget(#PB_Any, 125, 170, 100, 35, "OK")
    Repeat
      Protected Event = WaitWindowEvent()
      If Event = #PB_Event_Gadget
        If EventGadget() = #TxtAboutLink
          RunProgram("https://github.com/tristan202")
        ElseIf EventGadget() = BtnClose
          CloseWindow(#WinAbout) : Break
        EndIf
      ElseIf Event = #PB_Event_CloseWindow
        CloseWindow(#WinAbout) : Break
      EndIf
    Until Event = #PB_Event_CloseWindow
  EndIf
EndProcedure

Procedure SaveSettings()
  If CreatePreferences(G_IniFile)
    PreferenceGroup("Settings")
    WritePreferenceString("OutputDir", G_OutputDir)
    WritePreferenceString("Language", G_CurrentLanguage)
    WritePreferenceInteger("SampleRateIdx", GetGadgetState(#ComboSampleRate))
    WritePreferenceInteger("BitDepthIdx", GetGadgetState(#ComboBitDepth))
    WritePreferenceInteger("ChannelsIdx", GetGadgetState(#ComboChannels))
    WritePreferenceInteger("Normalize", GetGadgetState(#CheckNormalize))
    ClosePreferences()
  EndIf
EndProcedure

Procedure LoadSettings()
  If OpenPreferences(G_IniFile)
    PreferenceGroup("Settings")
    G_OutputDir = ReadPreferenceString("OutputDir", G_OutputDir)
    G_CurrentLanguage = ReadPreferenceString("Language", "English")
    G_SelSR = ReadPreferenceInteger("SampleRateIdx", 2) 
    G_SelBD = ReadPreferenceInteger("BitDepthIdx", 1)  
    G_SelCH = ReadPreferenceInteger("ChannelsIdx", 0)  
    G_SelNorm = ReadPreferenceInteger("Normalize", 0)  
    ClosePreferences()
  EndIf
EndProcedure

Procedure.s FixPath(Path.s)
  If Right(Path, 1) <> "\" And Right(Path, 1) <> "/" : Path + "\" : EndIf
  ProcedureReturn Path
EndProcedure

; --- Main Program ---
LoadSettings()
G_SoXPath = FindSoX()

If OpenWindow(#WinMain, 0, 0, 700, 780, "", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If FileSize("sonicware.ico") > 0 : SendMessage_(WindowID(#WinMain), #WM_SETICON, #ICON_SMALL, LoadImage(#AppIcon, "sonicware.ico")) : EndIf

  If CreateMenu(0, WindowID(#WinMain))
    MenuTitle("Language")
    MenuItem(#Menu_Language_EN, "English") : MenuItem(#Menu_Language_DK, "Dansk")
    MenuItem(#Menu_Language_DE, "Deutsch") : MenuItem(#Menu_Language_IT, "Italiano")
    MenuItem(#Menu_Language_ES, "Español") : MenuItem(#Menu_Language_FR, "Français")
    MenuTitle("Help") : MenuItem(#Menu_About, "About")
  EndIf

  G_TxtListHeader = TextGadget(#PB_Any, 10, 10, 680, 20, "")
  ListIconGadget(#ListFiles, 10, 35, 680, 280, "", 250, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#ListFiles, 1, "", 400)
  EnableWindowDrop(#WinMain, #PB_Drop_Files, #PB_Drag_Copy)
  
  ButtonGadget(#BtnAddFiles, 10, 325, 110, 35, "")
  ButtonGadget(#BtnAddFolder, 125, 325, 110, 35, "")
  ButtonGadget(#BtnClear, 580, 325, 110, 35, "")
  
  G_FrameOutput = FrameGadget(#PB_Any, 10, 375, 680, 85, "")
  TextGadget(#TxtOutputDir, 25, 410, 520, 25, G_OutputDir) 
  ButtonGadget(#BtnSetOutputDir, 550, 405, 130, 35, "")
  
  G_FrameSettings = FrameGadget(#PB_Any, 10, 475, 680, 130, "")
  G_LblSampleRate = TextGadget(#PB_Any, 30, 505, 120, 20, "")
  ComboBoxGadget(#ComboSampleRate, 160, 500, 100, 25)
  AddGadgetItem(#ComboSampleRate, -1, "24000") : AddGadgetItem(#ComboSampleRate, -1, "44100") : AddGadgetItem(#ComboSampleRate, -1, "48000")
  SetGadgetState(#ComboSampleRate, G_SelSR) 
  
  G_LblBitDepth = TextGadget(#PB_Any, 300, 505, 120, 20, "")
  ComboBoxGadget(#ComboBitDepth, 430, 500, 100, 25)
  AddGadgetItem(#ComboBitDepth, -1, "16-bit") : AddGadgetItem(#ComboBitDepth, -1, "24-bit")
  SetGadgetState(#ComboBitDepth, G_SelBD) 
  
  G_LblChannels = TextGadget(#PB_Any, 30, 555, 120, 20, "")
  ComboBoxGadget(#ComboChannels, 160, 550, 100, 25)
  SetGadgetState(#ComboChannels, G_SelCH) 
  CheckBoxGadget(#CheckNormalize, 300, 550, 200, 25, "")
  SetGadgetState(#CheckNormalize, G_SelNorm)
  
  TextGadget(#TxtStatus, 10, 640, 680, 20, "", #PB_Text_Center)
  ButtonGadget(#BtnConvert, 10, 675, 680, 60, "")
  SetLanguage(G_CurrentLanguage)

  Define Event, i, FileList$, Dir$, Count
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #PB_Event_Menu
        Select EventMenu()
          Case #Menu_Language_EN : G_CurrentLanguage = "English" : SetLanguage("English") : SaveSettings()
          Case #Menu_Language_DK : G_CurrentLanguage = "Dansk" : SetLanguage("Dansk") : SaveSettings()
          Case #Menu_Language_DE : G_CurrentLanguage = "Deutsch" : SetLanguage("Deutsch") : SaveSettings()
          Case #Menu_Language_IT : G_CurrentLanguage = "Italiano" : SetLanguage("Italiano") : SaveSettings()
          Case #Menu_Language_ES : G_CurrentLanguage = "Español" : SetLanguage("Español") : SaveSettings()
          Case #Menu_Language_FR : G_CurrentLanguage = "Français" : SetLanguage("Français") : SaveSettings()
          Case #Menu_About : OpenAboutWindow()
        EndSelect
      Case #PB_Event_WindowDrop
        FileList$ = EventDropFiles()
        Count = CountString(FileList$, #LF$) + 1
        For i = 1 To Count : AddToFileList(StringField(FileList$, i, #LF$)) : Next
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #ComboSampleRate, #ComboBitDepth, #ComboChannels, #CheckNormalize : SaveSettings()
          Case #BtnAddFiles
            FileList$ = OpenFileRequester(Lg("BtnFiles"), "", "WAV (*.wav)|*.wav", 0, #PB_Requester_MultiSelection)
            If FileList$
              Count = CountString(FileList$, "|") + 1
              If Count = 1 : AddToFileList(FileList$) : Else
                Define BaseDir.s = FixPath(StringField(FileList$, 1, "|"))
                For i = 2 To Count : AddToFileList(BaseDir + StringField(FileList$, i, "|")) : Next
              EndIf
            EndIf
          Case #BtnAddFolder : Dir$ = PathRequester(Lg("BtnFolder"), "") : If Dir$ : ScanDirectory(FixPath(Dir$)) : EndIf
          Case #BtnClear : ClearList(FilesToProcess()) : ClearGadgetItems(#ListFiles)
          Case #BtnSetOutputDir : Dir$ = PathRequester(Lg("BtnChange"), G_OutputDir) : If Dir$ : G_OutputDir = FixPath(Dir$) : SetGadgetText(#TxtOutputDir, G_OutputDir) : SaveSettings() : EndIf
          Case #BtnConvert
            If G_SoXPath = "" : MessageRequester("Error", "SoX not found!") : Continue : EndIf
            If ListSize(FilesToProcess()) = 0 : MessageRequester("!", Lg("MsgNoFiles")) : Continue : EndIf
            Define SR.s = GetGadgetText(#ComboSampleRate)
            Define CH.s = Str(GetGadgetState(#ComboChannels) + 1)
            Define BD.s = "16" : If GetGadgetText(#ComboBitDepth) = "24-bit" : BD = "24" : EndIf
            Define Norm.s = "" : If GetGadgetState(#CheckNormalize) : Norm = "--norm " : EndIf
            ForEach FilesToProcess()
              Define In.s = FilesToProcess()
              Define Out.s = G_OutputDir + CleanFileName(In) + "_XT.wav"
              RunProgram(G_SoXPath, Norm + #DQUOTE$ + In + #DQUOTE$ + " -b " + BD + " " + #DQUOTE$ + Out + #DQUOTE$ + " channels " + CH + " rate " + SR, "", #PB_Program_Wait | #PB_Program_Hide)
            Next
            SetGadgetText(#TxtStatus, Lg("MsgDone"))
            RunProgram(G_OutputDir)
        EndSelect
      Case #PB_Event_CloseWindow : End
    EndSelect
  Until Event = #PB_Event_CloseWindow
EndIf
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 214
; FirstLine = 211
; Folding = --
; EnableXP
; DPIAware
; UseIcon = sonicware.ico
; Executable = ..\sonicwaretool.exe