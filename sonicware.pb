EnableExplicit
InitSound()

; --- IDs, Events og Indstillinger ---
Enumeration
  #WinMain
  #WinAbout
  #ListFiles
  #ComboDevice      
  #ComboSampleRate
  #ComboChannels
  #ComboBitDepth
  #CheckReverse
  #CheckAutoTrim
  #CheckOpenDir
  #CheckNormalize
  #BtnConvert
  #BtnClear
  #BtnAddFolder
  #BtnAddFiles
  #BtnPreview
  #BtnStop
  #BtnSetOutputDir
  #TxtStatus
  #TxtOutputDir
  #TxtAboutLink
  #CanvasWave
  #Menu_Language_EN
  #Menu_Language_DK
  #Menu_About  
  #Event_ConversionProgress = #PB_Event_FirstCustomValue
  #Event_ConversionFinished
EndEnumeration

Structure ConversionData
  List Files.s()
  OutputDir.s
  SoXPath.s
  SampleRate.s
  Channels.s
  BitDepth.s
  Normalize.s
  AutoTrim.s
  Reverse.s
EndStructure

Declare ConversionThread(*Data.ConversionData)
Declare DrawWaveform(FileName.s)
Global hBackColor = RGB(50, 50, 50)    
Global hTextColor = RGB(255, 255, 255)
Global hAccent    = RGB(255, 135, 0)    
Global hSecondary = RGB(150, 150, 150)

Global G_TxtListHeader, G_FrameOutput, G_FrameSettings
Global G_LblSampleRate, G_LblBitDepth, G_LblChannels, G_LblDevice

Global NewMap Lg.s()
Global NewList FilesToProcess.s()
Global G_OutputDir.s = GetHomeDirectory() + "Documents\XT_Export\"
Global G_IniFile.s = "lofi_config.ini"
Global G_CurrentLanguage.s = "English"
Global G_SoXPath.s = ""
Global G_SelDevice = 0, G_SelSR = 1, G_SelBD = 0, G_SelCH = 0, G_SelNorm = 0, G_SelTrim = 0, G_SelReverse = 0, G_SelOpenDir = 1

; --- Procedures ---

Procedure.s FindSoX()
  Protected Path.s = ""
  Protected NewList SearchFiles.s()
  AddElement(SearchFiles()) : SearchFiles() = "sox_ng.exe"
  AddElement(SearchFiles()) : SearchFiles() = "sox.exe"
  
  ForEach SearchFiles()
    Protected CurrentExe.s = SearchFiles()
    If FileSize(CurrentExe) > 0 : ProcedureReturn CurrentExe : EndIf
    If FileSize("C:\Program Files (x86)\sox-14-4-2\" + CurrentExe) > 0 
      ProcedureReturn "C:\Program Files (x86)\sox-14-4-2\" + CurrentExe 
    EndIf
    Protected PathEnv.s = GetEnvironmentVariable("PATH")
    Protected i, Count = CountString(PathEnv, ";") + 1
    For i = 1 To Count
      Protected TempDir.s = StringField(PathEnv, i, ";")
      If Right(TempDir, 1) <> "\" : TempDir + "\" : EndIf
      If FileSize(TempDir + CurrentExe) > 0 : ProcedureReturn TempDir + CurrentExe : EndIf
    Next
  Next
  ProcedureReturn ""
EndProcedure

Procedure AddToFileList(Path.s)
  Shared FilesToProcess()
  Protected Ext.s = LCase(GetExtensionPart(Path))
  If Ext = "wav" Or Ext = "mp3" Or Ext = "flac" Or Ext = "ogg" Or Ext = "wma" Or Ext = "m4a"
    AddElement(FilesToProcess())
    FilesToProcess() = Path
    AddGadgetItem(#ListFiles, -1, GetFilePart(Path) + Chr(10) + GetPathPart(Path))
  EndIf
EndProcedure

Procedure.s EnsureTrailingSlash(Path.s)
  If Path <> "" And Right(Path, 1) <> "\"
    Path + "\"
  EndIf
  ProcedureReturn Path
EndProcedure

Procedure EnsureOutputDirectory(Path.s)
  Path = EnsureTrailingSlash(Path)
  If FileSize(Path) <> -2
    CreateDirectory(Path)
  EndIf
  If FileSize(Path) = -2
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure ScanDirectory(Path.s)
  Path = EnsureTrailingSlash(Path)
  Protected Dir = ExamineDirectory(#PB_Any, Path, "*.*")
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
  Protected FileName.s = GetFilePart(FullPath, #PB_FileSystem_NoExtension)
  Protected Invalid.s = "\/:*?" + #DQUOTE$ + "<>|"
  Protected i
  FileName = ReplaceString(FileName, " ", "_")
  For i = 1 To Len(Invalid)
    FileName = ReplaceString(FileName, Mid(Invalid, i, 1), "_")
  Next
  If FileName = "" : FileName = "sample" : EndIf
  ProcedureReturn FileName
EndProcedure

Procedure.s UniqueOutputName(OutputDir.s, BaseName.s, Suffix.s)
  Protected Candidate.s
  Protected Counter.i = 0
  Repeat
    If Counter = 0
      Candidate = OutputDir + BaseName + Suffix + ".wav"
    Else
      Candidate = OutputDir + BaseName + Suffix + "_" + RSet(Str(Counter), 3, "0") + ".wav"
    EndIf
    Counter + 1
  Until FileSize(Candidate) = -1
  ProcedureReturn Candidate
EndProcedure

Procedure ThemeGadget(Gadget, Front = -1, Back = -1)
  If IsGadget(Gadget)
    If Front = -1 : Front = hTextColor : EndIf
    If Back = -1 : Back = hBackColor : EndIf
    SetGadgetColor(Gadget, #PB_Gadget_FrontColor, Front)
    SetGadgetColor(Gadget, #PB_Gadget_BackColor, Back)
  EndIf
EndProcedure

Procedure ApplyDeviceProfile(DeviceName.s)
  Select DeviceName
    Case "Sonicware Lofi-12 XT"
      SetGadgetState(#ComboSampleRate, 1) ; 24000
      SetGadgetState(#ComboBitDepth, 0)   ; 16-bit
      SetGadgetState(#ComboChannels, 0)   ; Mono
    Case "Sonicware Lofi-12 (Original)"
      SetGadgetState(#ComboSampleRate, 0) ; 12000
      SetGadgetState(#ComboBitDepth, 0)   ; 16-bit
      SetGadgetState(#ComboChannels, 0)   ; Mono
    Case "Elektron Digitakt (Mk1)"
      SetGadgetState(#ComboSampleRate, 2) ; 44100
      SetGadgetState(#ComboBitDepth, 0)   ; 16-bit
      SetGadgetState(#ComboChannels, 0)   ; Mono
  EndSelect
EndProcedure

Procedure DrawWaveform(FileName.s)
  Protected File = ReadFile(#PB_Any, FileName)
  If Not File : ProcedureReturn : EndIf
  
  FileSeek(File, 44) ; Hop over WAV header
  Protected FileSize = Lof(File) - 44
  
  If StartDrawing(CanvasOutput(#CanvasWave))
    ; --- DPI FIX: Brug altid OutputWidth/Height inde i StartDrawing ---
    Protected W = OutputWidth()
    Protected H = OutputHeight()
    
    ; 1. Mal HELE det fysiske areal mørkt
    Box(0, 0, W, H, RGB(30, 30, 30))
    
    If FileSize > 0
      Protected x.i, i.i
      Protected.w PeakMin, PeakMax, Sample
      
      ; Beregn bytes pr. fysisk pixel
      Protected BytesPerPixel.f = FileSize / W
      
      For x = 0 To W - 1
        PeakMin = 0 : PeakMax = 0
        
        ; Find position i filen for denne fysiske pixel
        Protected SeekPos.q = 44 + (x * BytesPerPixel)
        If SeekPos > Lof(File) - 2 : SeekPos = Lof(File) - 2 : EndIf
        FileSeek(File, SeekPos)
        
        ; Tjek en blok samples for at finde peaks
        For i = 1 To 32 Step 2
          If Loc(File) < Lof(File) - 1
            Sample = ReadWord(File)
            If Sample > PeakMax : PeakMax = Sample : EndIf
            If Sample < PeakMin : PeakMin = Sample : EndIf
          EndIf
        Next i
        
        ; Skalér til den fysiske højde (H)
        Protected y1 = (H / 2) - (PeakMax * (H / 2) / 32768)
        Protected y2 = (H / 2) - (PeakMin * (H / 2) / 32768)
        
        If y1 = y2 : y2 + 1 : EndIf
        LineXY(x, y1, x, y2, hAccent)
      Next x
    EndIf
    
    ; Centerlinje
    Line(0, H / 2, W, 1, RGB(70, 70, 70))
    
    StopDrawing()
  EndIf
  
  CloseFile(File)
EndProcedure

Procedure ConversionThread(*Data.ConversionData)
  Protected SoX, ExitCode, Params.s, Suffix.s = ""
  Protected CurrentFile = 0
  Protected ErrorCount = 0
  If Len(*Data\Reverse) > 0 : Suffix = "_rev" : EndIf
  *Data\OutputDir = EnsureTrailingSlash(*Data\OutputDir)
  If Not EnsureOutputDirectory(*Data\OutputDir)
    PostEvent(#Event_ConversionFinished, #WinMain, 0, 0, ListSize(*Data\Files()))
    ClearStructure(*Data, ConversionData)
    FreeMemory(*Data)
    ProcedureReturn
  EndIf
  ForEach *Data\Files()
    CurrentFile + 1
    Protected In.s = *Data\Files()
    Protected Out.s = UniqueOutputName(*Data\OutputDir, CleanFileName(In), Suffix)
    Params = *Data\Normalize + #DQUOTE$ + In + #DQUOTE$ + " -b " + *Data\BitDepth + " " + #DQUOTE$ + Out + #DQUOTE$ + " channels " + *Data\Channels + " rate " + *Data\SampleRate + *Data\AutoTrim + *Data\Reverse
    SoX = RunProgram(*Data\SoXPath, Params, "", #PB_Program_Open | #PB_Program_Hide | #PB_Program_Wait)
    If SoX
      ExitCode = ProgramExitCode(SoX)
      CloseProgram(SoX)
      If ExitCode <> 0 : ErrorCount + 1 : EndIf
    Else
      ErrorCount + 1
    EndIf
    PostEvent(#Event_ConversionProgress, #WinMain, 0, 0, CurrentFile)
  Next
  PostEvent(#Event_ConversionFinished, #WinMain, 0, 0, ErrorCount)
  ClearStructure(*Data, ConversionData)
  FreeMemory(*Data)
EndProcedure

Procedure SetLanguage(Language.s)
  ClearMap(Lg())
  Select Language
    Case "Dansk"
      Lg("Title") = "Sonicware Lofi-12 XT Tool v1.6"
      Lg("ListHeader") = "SAMPLES KLAR TIL KONVERTERING"
      Lg("ColName") = "Filnavn" : Lg("ColPath") = "Kilde-sti"
      Lg("BtnFiles") = "Tilføj Filer" : Lg("BtnFolder") = "Tilføj Mappe" : Lg("BtnClear") = "Ryd Liste"
      Lg("FrameOut") = "OUTPUT DESTINATION" : Lg("BtnChange") = "Skift Mappe"
      Lg("FrameSet") = "HARDWARE INDSTILLINGER" : Lg("LabelSR") = "Sample Rate:"
      Lg("LabelBD") = "Bit-dybde:" : Lg("LabelCH") = "Kanaler:" : Lg("CheckNorm") = "Normalize"
      Lg("CheckTrim") = "Auto-Trim" : Lg("CheckReverse") = "Reverse" : Lg("CheckOpenDir") = "Åbn mappe når færdig"
      Lg("LabelDev") = "Mål-hardware:"
      Lg("StatusReady") = "Klar (SoX fundet)" : Lg("StatusError") = "FEJL: sox.exe ikke fundet!"
      Lg("StatusReadyNG") = "Klar (SoX-NG fundet)"
      Lg("StatusConverting") = "Konverterer..."
      Lg("MsgDone") = "Færdig!"
      Lg("MsgDoneErrors") = "Færdig med %ERRORS% fejl"
      Lg("MsgOutputError") = "Output-mappen kunne ikke oprettes."
      Lg("WordOf") = "af"
      Lg("BtnStart") = "START KONVERTERING" : Lg("MsgNoFiles") = "Vælg filer først!"
      Lg("AboutTxt") = "Konvertering til hardware samplere." + #LF$ + "Open Source (MIT) - tristan202"
    Default ; English
      Lg("Title") = "Sonicware Lofi-12 XT Tool v1.6"
      Lg("ListHeader") = "SAMPLES READY FOR CONVERSION"
      Lg("ColName") = "Filename" : Lg("ColPath") = "Source path"
      Lg("BtnFiles") = "Add Files" : Lg("BtnFolder") = "Add Folder" : Lg("BtnClear") = "Clear List"
      Lg("FrameOut") = "OUTPUT DESTINATION" : Lg("BtnChange") = "Change Folder"
      Lg("FrameSet") = "HARDWARE SETTINGS" : Lg("LabelSR") = "Sample Rate:"
      Lg("LabelBD") = "Bit-depth:" : Lg("LabelCH") = "Channels:" : Lg("CheckNorm") = "Normalize"
      Lg("CheckTrim") = "Auto-Trim" : Lg("CheckReverse") = "Reverse" : Lg("CheckOpenDir") = "Open folder when done"
      Lg("LabelDev") = "Target Hardware:"
      Lg("StatusReady") = "Ready (SoX found)" : Lg("StatusError") = "ERROR: sox.exe not found!"
      Lg("StatusReadyNG") = "Ready (SoX-NG found)"
      Lg("StatusConverting") = "Converting..."
      Lg("MsgDone") = "Done!"
      Lg("MsgDoneErrors") = "Done with %ERRORS% error(s)"
      Lg("MsgOutputError") = "Could not create the output folder."
      Lg("WordOf") = "of"
      Lg("BtnStart") = "START CONVERSION" : Lg("MsgNoFiles") = "Add files first!"
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
    SetGadgetText(#CheckAutoTrim, Lg("CheckTrim"))
    SetGadgetText(#CheckReverse, Lg("CheckReverse"))
    SetGadgetText(#CheckOpenDir, Lg("CheckOpenDir"))
    SetGadgetText(G_TxtListHeader, Lg("ListHeader"))
    SetGadgetText(G_FrameOutput, Lg("FrameOut"))
    SetGadgetText(G_FrameSettings, Lg("FrameSet"))
    SetGadgetText(G_LblSampleRate, Lg("LabelSR"))
    SetGadgetText(G_LblBitDepth, Lg("LabelBD"))
    SetGadgetText(G_LblChannels, Lg("LabelCH"))
    SetGadgetText(G_LblDevice, Lg("LabelDev"))
    SetGadgetText(#TxtOutputDir, G_OutputDir)
    If G_SoXPath = "" : SetGadgetText(#TxtStatus, Lg("StatusError")) : Else : SetGadgetText(#TxtStatus, Lg("StatusReady")) : EndIf
  EndIf
EndProcedure

Procedure SaveSettings()
  If CreatePreferences(G_IniFile)
    PreferenceGroup("Settings")
    WritePreferenceString("OutputDir", EnsureTrailingSlash(G_OutputDir))
    WritePreferenceString("Language", G_CurrentLanguage)
    WritePreferenceInteger("DeviceIdx", GetGadgetState(#ComboDevice))
    WritePreferenceInteger("SampleRateIdx", GetGadgetState(#ComboSampleRate))
    WritePreferenceInteger("BitDepthIdx", GetGadgetState(#ComboBitDepth))
    WritePreferenceInteger("ChannelsIdx", GetGadgetState(#ComboChannels))
    WritePreferenceInteger("Normalize", GetGadgetState(#CheckNormalize))
    WritePreferenceInteger("AutoTrim", GetGadgetState(#CheckAutoTrim))
    WritePreferenceInteger("Reverse", GetGadgetState(#CheckReverse))
    WritePreferenceInteger("OpenDir", GetGadgetState(#CheckOpenDir))
    WritePreferenceString("SoXPath", G_SoXPath)
    ClosePreferences()
  EndIf
EndProcedure

Procedure LoadSettings()
  If OpenPreferences(G_IniFile)
    PreferenceGroup("Settings")
    G_OutputDir = EnsureTrailingSlash(ReadPreferenceString("OutputDir", G_OutputDir))
    G_CurrentLanguage = ReadPreferenceString("Language", "English")
    G_SoXPath = ReadPreferenceString("SoXPath", "")
    If G_SoXPath = "" Or FileSize(G_SoXPath) < 0 : G_SoXPath = FindSoX() : EndIf
    G_SelOpenDir = ReadPreferenceInteger("OpenDir", 1)
    G_SelDevice = ReadPreferenceInteger("DeviceIdx", 0)
    G_SelSR = ReadPreferenceInteger("SampleRateIdx", 1) 
    G_SelBD = ReadPreferenceInteger("BitDepthIdx", 0)  
    G_SelCH = ReadPreferenceInteger("ChannelsIdx", 0) 
    G_SelNorm = ReadPreferenceInteger("Normalize", 0)
    G_SelTrim = ReadPreferenceInteger("AutoTrim", 0)
    G_SelReverse = ReadPreferenceInteger("Reverse", 0)
    ClosePreferences()
  Else
    G_OutputDir = EnsureTrailingSlash(G_OutputDir)
    G_SoXPath = FindSoX()
  EndIf
EndProcedure

Procedure MyWindowCallback(WindowID, Message, WParam, LParam)
  Protected Result = #PB_ProcessPureBasicEvents
  If Message = #WM_CTLCOLORSTATIC
    If IsGadget(#CheckNormalize) And IsGadget(#CheckAutoTrim) And IsGadget(#CheckReverse) And IsGadget(#CheckOpenDir)
      Select lparam
        Case GadgetID(#CheckNormalize), GadgetID(#CheckAutoTrim), GadgetID(#CheckReverse), GadgetID(#CheckOpenDir)
          Static hBrush
          If Not hBrush : hBrush = CreateSolidBrush_(hBackColor) : EndIf
          SetBkColor_(WParam, hBackColor)
          SetTextColor_(WParam, hTextColor)
          ProcedureReturn hBrush
      EndSelect
    EndIf
  EndIf
  ProcedureReturn Result
EndProcedure

; --- Main Program ---

LoadSettings()
LoadFont(0, "Calibri", 12)
LoadFont(1, "Calibri", 12, #PB_Font_Bold)
SetGadgetFont(#PB_Default, FontID(0))

If OpenWindow(#WinMain, 0, 0, 700, 880, "", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  SetWindowColor(#WinMain, hBackColor)
  
  If CreateMenu(0, WindowID(#WinMain))
    MenuTitle("Language") : MenuItem(#Menu_Language_EN, "English") : MenuItem(#Menu_Language_DK, "Dansk")
    MenuTitle("Help") : MenuItem(#Menu_About, "About")
  EndIf

  G_TxtListHeader = TextGadget(#PB_Any, 10, 15, 680, 20, "") : ThemeGadget(G_TxtListHeader, hAccent) : SetGadgetFont(G_TxtListHeader, FontID(1))
  ListIconGadget(#ListFiles, 10, 40, 680, 250, "", 250, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#ListFiles, 1, "", 400)
  SetGadgetColor(#ListFiles, #PB_Gadget_BackColor, RGB(60, 60, 60)) : SetGadgetColor(#ListFiles, #PB_Gadget_FrontColor, hTextColor)
  EnableWindowDrop(#WinMain, #PB_Drop_Files, #PB_Drag_Copy)
  ButtonGadget(#BtnAddFiles, 10, 300, 110, 35, "")
  ButtonGadget(#BtnAddFolder, 125, 300, 110, 35, "")
  ButtonGadget(#BtnPreview, 240, 300, 40, 35, Chr($25B6))
  ButtonGadget(#BtnStop, 285, 300, 40, 35, Chr($25A0))
  GadgetToolTip(#BtnPreview, "Play Sample") : GadgetToolTip(#BtnStop, "Stop Playback")
  ButtonGadget(#BtnClear, 580, 300, 110, 35, "")
  CanvasGadget(#CanvasWave, 10, 350, 680, 80)
  G_FrameOutput = TextGadget(#PB_Any, 10, 450, 680, 20, "") : ThemeGadget(G_FrameOutput, hAccent) : SetGadgetFont(G_FrameOutput, FontID(1))
  Define canvas1 = CanvasGadget(#PB_Any, 10, 473, 680, 1)
  If StartDrawing(CanvasOutput(canvas1)) : Box(0, 0, OutputWidth(), OutputHeight(), hAccent) : StopDrawing() : EndIf
  TextGadget(#TxtOutputDir, 25, 485, 520, 25, G_OutputDir) : ThemeGadget(#TxtOutputDir, hSecondary)
  ButtonGadget(#BtnSetOutputDir, 550, 480, 130, 35, "")
  
  G_FrameSettings = TextGadget(#PB_Any, 10, 540, 680, 20, "") : ThemeGadget(G_FrameSettings, hAccent) : SetGadgetFont(G_FrameSettings, FontID(1))
  Define canvas2 = CanvasGadget(#PB_Any, 10, 563, 680, 1)
  If StartDrawing(CanvasOutput(canvas2)) : Box(0, 0, OutputWidth(), OutputHeight(), hAccent) : StopDrawing() : EndIf
  
  G_LblDevice = TextGadget(#PB_Any, 30, 580, 120, 20, "") : ThemeGadget(G_LblDevice)
  ComboBoxGadget(#ComboDevice, 160, 575, 250, 25)
  AddGadgetItem(#ComboDevice, -1, "Sonicware Lofi-12 XT")
  AddGadgetItem(#ComboDevice, -1, "Sonicware Lofi-12 (Original)")
  AddGadgetItem(#ComboDevice, -1, "Elektron Digitakt (Mk1)") : SetGadgetState(#ComboDevice, G_SelDevice)
  
  G_LblSampleRate = TextGadget(#PB_Any, 30, 620, 120, 20, "") : ThemeGadget(G_LblSampleRate)
  ComboBoxGadget(#ComboSampleRate, 160, 615, 100, 25)
  AddGadgetItem(#ComboSampleRate, -1, "12000") : AddGadgetItem(#ComboSampleRate, -1, "24000")
  AddGadgetItem(#ComboSampleRate, -1, "44100") : AddGadgetItem(#ComboSampleRate, -1, "48000") : SetGadgetState(#ComboSampleRate, G_SelSR) 
  
  G_LblBitDepth = TextGadget(#PB_Any, 300, 620, 120, 20, "") : ThemeGadget(G_LblBitDepth)
  ComboBoxGadget(#ComboBitDepth, 430, 615, 100, 25)
  AddGadgetItem(#ComboBitDepth, -1, "16-bit") : AddGadgetItem(#ComboBitDepth, -1, "24-bit") : SetGadgetState(#ComboBitDepth, G_SelBD) 
  
  G_LblChannels = TextGadget(#PB_Any, 30, 660, 120, 20, "") : ThemeGadget(G_LblChannels)
  ComboBoxGadget(#ComboChannels, 160, 655, 100, 25)
  AddGadgetItem(#ComboChannels, -1, "Mono") : AddGadgetItem(#ComboChannels, -1, "Stereo") : SetGadgetState(#ComboChannels, G_SelCH)

  CheckBoxGadget(#CheckNormalize, 300, 655, 100, 25, "Normalize")
  CheckBoxGadget(#CheckAutoTrim, 410, 655, 100, 25, "Auto-Trim")
  CheckBoxGadget(#CheckReverse, 520, 655, 100, 25, "Reverse")
  CheckBoxGadget(#CheckOpenDir, 300, 695, 300, 25, "Open folder when done")
  
  SetWindowTheme_(GadgetID(#CheckNormalize), @"", @"") : SetWindowTheme_(GadgetID(#CheckAutoTrim), @"", @"")
  SetWindowTheme_(GadgetID(#CheckReverse), @"", @"") : SetWindowTheme_(GadgetID(#CheckOpenDir), @"", @"")
  ThemeGadget(#CheckNormalize) : ThemeGadget(#CheckAutoTrim) : ThemeGadget(#CheckReverse) : ThemeGadget(#CheckOpenDir)
  
  ; 6. STATUS & CONVERT
  TextGadget(#TxtStatus, 10, 740, 680, 20, "", #PB_Text_Center) : ThemeGadget(#TxtStatus, hAccent)
  ButtonGadget(#BtnConvert, 10, 770, 680, 60, "") : SetGadgetFont(#BtnConvert, FontID(1))
  
  SetGadgetState(#CheckNormalize, G_SelNorm)
  SetGadgetState(#CheckAutoTrim, G_SelTrim)
  SetGadgetState(#CheckReverse, G_SelReverse)
  SetGadgetState(#CheckOpenDir, G_SelOpenDir)
  SetLanguage(G_CurrentLanguage)
  
  ; SoX Status Check
  If G_SoXPath <> ""
    If FindString(LCase(G_SoXPath), "sox_ng.exe")
      SetGadgetText(#TxtStatus, Lg("StatusReadyNG"))
    Else
      SetGadgetText(#TxtStatus, Lg("StatusReady"))
    EndIf
    SetGadgetColor(#TxtStatus, #PB_Gadget_FrontColor, hAccent)
  Else
    SetGadgetText(#TxtStatus, Lg("StatusError"))
    SetGadgetColor(#TxtStatus, #PB_Gadget_FrontColor, RGB(255, 0, 0))
  EndIf
  
  SetWindowCallback(@MyWindowCallback())
  If StartDrawing(CanvasOutput(#CanvasWave))
    Box(0, 0, OutputWidth(), OutputHeight(), RGB(30, 30, 30))
    StopDrawing()
  EndIf

  Define Event, i, FileList$, Dir$, Count
  Repeat
    Event = WaitWindowEvent()
    Select Event
      Case #Event_ConversionProgress
        SetGadgetText(#TxtStatus, Str(EventData()) + " " + Lg("WordOf") + " " + Str(ListSize(FilesToProcess())))
      Case #Event_ConversionFinished
        DisableGadget(#BtnConvert, 0)
        If EventData() > 0
          SetGadgetText(#TxtStatus, ReplaceString(Lg("MsgDoneErrors"), "%ERRORS%", Str(EventData())))
          SetGadgetColor(#TxtStatus, #PB_Gadget_FrontColor, RGB(255, 120, 0))
        Else
          SetGadgetText(#TxtStatus, Lg("MsgDone"))
          SetGadgetColor(#TxtStatus, #PB_Gadget_FrontColor, hAccent)
        EndIf
        If GetGadgetState(#CheckOpenDir) And FileSize(G_OutputDir) = -2 : RunProgram(G_OutputDir) : EndIf
      Case #PB_Event_Menu
        Select EventMenu()
          Case #Menu_Language_EN : G_CurrentLanguage = "English" : SetLanguage("English") : SaveSettings()
          Case #Menu_Language_DK : G_CurrentLanguage = "Dansk" : SetLanguage("Dansk") : SaveSettings()
          Case #Menu_About : MessageRequester("About", Lg("AboutTxt"))
        EndSelect
      Case #PB_Event_WindowDrop
        FileList$ = EventDropFiles()
        Count = CountString(FileList$, #LF$) + 1
        For i = 1 To Count : AddToFileList(StringField(FileList$, i, #LF$)) : Next
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #ListFiles
            If EventType() = #PB_EventType_LeftClick Or EventType() = #PB_EventType_Change
              Define Selected = GetGadgetState(#ListFiles)
              If Selected <> -1
                Define Path.s = GetGadgetItemText(#ListFiles, Selected, 1)
                Define File.s = GetGadgetItemText(#ListFiles, Selected, 0)
                If Right(Path, 1) <> "\" : Path + "\" : EndIf
                If LCase(GetExtensionPart(File)) = "wav" : DrawWaveform(Path + File) : EndIf
                mciSendString_("close myaudio", 0, 0, 0)
                mciSendString_("open " + #DQUOTE$ + Path + File + #DQUOTE$ + " alias myaudio", 0, 0, 0)
                mciSendString_("play myaudio", 0, 0, 0)
              EndIf
            EndIf
          Case #BtnAddFiles
            FileList$ = OpenFileRequester(Lg("BtnFiles"), "", "Audio Files|*.wav;*.mp3;*.flac;*.ogg;*.wma;*.m4a|All Files (*.*)|*.*", 0, #PB_Requester_MultiSelection)
            If FileList$ 
              Count = CountString(FileList$, "|") + 1
              If Count = 1 
                AddToFileList(FileList$) 
              Else
                Define BaseDir.s = StringField(FileList$, 1, "|")
                If Right(BaseDir, 1) <> "\" : BaseDir + "\" : EndIf
                For i = 2 To Count : AddToFileList(BaseDir + StringField(FileList$, i, "|")) : Next
              EndIf
            EndIf
          Case #BtnPreview
            Define Selected = GetGadgetState(#ListFiles)
            If Selected <> -1
              Define Path.s = GetGadgetItemText(#ListFiles, Selected, 1)
              Define File.s = GetGadgetItemText(#ListFiles, Selected, 0)
              If Right(Path, 1) <> "\" : Path + "\" : EndIf
              mciSendString_("close myaudio", 0, 0, 0)
              mciSendString_("open " + #DQUOTE$ + Path + File + #DQUOTE$ + " alias myaudio", 0, 0, 0)
              mciSendString_("play myaudio", 0, 0, 0)
            EndIf
          Case #BtnStop : mciSendString_("stop myaudio", 0, 0, 0) : mciSendString_("close myaudio", 0, 0, 0)
          Case #BtnClear
            ClearList(FilesToProcess()) : ClearGadgetItems(#ListFiles)
            If StartDrawing(CanvasOutput(#CanvasWave))
              Box(0, 0, OutputWidth(), OutputHeight(), RGB(30, 30, 30))
              StopDrawing()
            EndIf
          Case #BtnAddFolder : Dir$ = PathRequester(Lg("BtnFolder"), "") : If Dir$ : ScanDirectory(Dir$) : EndIf
          Case #BtnSetOutputDir : Dir$ = PathRequester(Lg("BtnChange"), G_OutputDir) : If Dir$ : G_OutputDir = EnsureTrailingSlash(Dir$) : SetGadgetText(#TxtOutputDir, G_OutputDir) : SaveSettings() : EndIf
          Case #ComboDevice : ApplyDeviceProfile(GetGadgetText(#ComboDevice)) : SaveSettings()
          Case #ComboSampleRate, #ComboBitDepth, #ComboChannels, #CheckNormalize, #CheckAutoTrim, #CheckReverse, #CheckOpenDir : SaveSettings()
          Case #BtnConvert
            If G_SoXPath = ""
              G_SoXPath = OpenFileRequester("Find SoX / SoX-NG...", "C:\", "SoX (sox.exe, sox_ng.exe)|sox.exe;sox_ng.exe", 0)
              If G_SoXPath <> "" : SaveSettings() : Else : Continue : EndIf
            EndIf
            If ListSize(FilesToProcess()) = 0 : MessageRequester("!", Lg("MsgNoFiles")) : Continue : EndIf
            Define *ThreadData.ConversionData = AllocateMemory(SizeOf(ConversionData))
            InitializeStructure(*ThreadData, ConversionData)
            *ThreadData\OutputDir = EnsureTrailingSlash(G_OutputDir) : *ThreadData\SoXPath = G_SoXPath
            If Not EnsureOutputDirectory(*ThreadData\OutputDir)
              MessageRequester("!", Lg("MsgOutputError"))
              ClearStructure(*ThreadData, ConversionData)
              FreeMemory(*ThreadData)
              Continue
            EndIf
            *ThreadData\SampleRate = GetGadgetText(#ComboSampleRate)
            *ThreadData\Channels = Str(GetGadgetState(#ComboChannels) + 1)
            *ThreadData\BitDepth = "16" : If GetGadgetText(#ComboBitDepth) = "24-bit" : *ThreadData\BitDepth = "24" : EndIf
            If GetGadgetState(#CheckNormalize) : *ThreadData\Normalize = "--norm " : EndIf
            If GetGadgetState(#CheckAutoTrim) : *ThreadData\AutoTrim = " silence 1 0.1 1% reverse silence 1 0.1 1% reverse" : EndIf
            If GetGadgetState(#CheckReverse) : *ThreadData\Reverse = " reverse" : EndIf
            ForEach FilesToProcess() : AddElement(*ThreadData\Files()) : *ThreadData\Files() = FilesToProcess() : Next
            DisableGadget(#BtnConvert, 1) : SetGadgetText(#TxtStatus, Lg("StatusConverting")) : CreateThread(@ConversionThread(), *ThreadData)
        EndSelect
      Case #PB_Event_CloseWindow : mciSendString_("close all", 0, 0, 0) : End
    EndSelect
  Until Event = #PB_Event_CloseWindow
EndIf
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 365
; FirstLine = 354
; Folding = ---
; EnableThread
; EnableXP
; DPIAware
; UseIcon = sonicware.ico
; Executable = ..\sonicwaretool.exe