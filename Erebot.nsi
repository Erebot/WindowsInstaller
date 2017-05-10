; vim: et sw=2

;Maximum compression
SetCompressor /SOLID lzma

;Request an Unicode installer
Unicode true

;--------------------------------
;Variables

  Var StartMenuFolder
  Var NbModules
  Var ComposerDir


;--------------------------------
;Constants

  !define INSTALLER_VERSION   "0.0.0.1"
  !define INSTALLER_COPY      "(c) 2012-2017 - François Poirotte"
  !define INSTALLER_DESC      "Installer for Erebot, a modular IRC bot written in PHP"
  !define UNINST_KEY          "Software\Microsoft\Windows\CurrentVersion\Uninstall\Erebot"
  !define INST_FILE           "Erebot-setup.exe"
  !define URL_HOMEPAGE        "https://github.com/Erebot/Erebot/"
  !define URL_SUPPORT         "https://github.com/Erebot/Erebot/issues"
  !define URL_DOC             "http://docs.erebot.net/"
  !define NB_SECTIONS         0
  !define NB_EXTENSIONS       0
  !define MIN_PHP_VERSION     "5.3.3"
  !define COMPOSER_GUID       "{7315AF68-E777-496A-A6A2-4763A98ED35A}"


;--------------------------------
;General

  ;Name and output file
  Name              "Erebot"
  OutFile           "build/${INST_FILE}"

  ;Always display details by default
  ShowInstDetails   show
  ShowUnInstDetails show

  ;Default installation folder
  InstallDir "$PROGRAMFILES\$(^Name)"

  ;Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\$(^Name)" ""


;--------------------------------
;Includes

  ; Pre-defines for MultiUser.
  !define MULTIUSER_INSTALLMODE_COMMANDLINE
  !define MULTIUSER_MUI
  !define MULTIUSER_EXECUTIONLEVEL                          "Highest"
  !define MULTIUSER_INSTALLMODE_INSTDIR                     "$(^NAME)"
  !define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY        "Software\$(^NAME)"
  !define MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_VALUENAME  "Installation Folder"
  !define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY        "Software\$(^NAME)"
  !define MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME  "Installation Mode"

  ; Built-in scripts.
  !include "MultiUser.nsh"  ; Multiuser mode
  !include "MUI2.nsh"       ; Modern UI
  !include "FileFunc.nsh"   ; Compute install size
  !include "LogicLib.nsh"   ; Logic library


;--------------------------------
;Interface Settings

  ;Common settings
  !define MUI_COMPONENTSPAGE_SMALLDESC
  !define MUI_ICON                        "Erebot.ico"
  !define MUI_ABORTWARNING
  !define MUI_UNABORTWARNING
  !define MUI_PAGE_HEADER_TEXT            "Erebot"
  !define MUI_PAGE_HEADER_SUBTEXT         "$(ErebotDescription)"

  ;Finish page settings (installer)
  !define MUI_FINISHPAGE_LINK             "${URL_DOC}"
  !define MUI_FINISHPAGE_LINK_LOCATION    "${URL_DOC}"

;  !define MUI_FINISHPAGE_LINK             "Support"
;  !define MUI_FINISHPAGE_LINK_LOCATION    "${URL_SUPPORT}"
;  !define MUI_FINISHPAGE_SHOWREADME       "${URL_DOC}"
;  !define MUI_FINISHPAGE_SHOWREADME_TEXT  "${URL_DOC}"
;  !define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
  !define MUI_FINISHPAGE_NOAUTOCLOSE

  ;Finish page settings (uninstaller)
  !define MUI_UNFINISHPAGE_NOAUTOCLOSE

  ;Language selection settings
  !define MUI_LANGDLL_REGISTRY_ROOT       "SHCTX"
  !define MUI_LANGDLL_REGISTRY_KEY        "Software\$(^NAME)"
  !define MUI_LANGDLL_REGISTRY_VALUENAME  "Installation Language"
  !define MUI_LANGDLL_ALWAYSSHOW

  ;Start Menu settings
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT       "SHCTX"
  !define MUI_STARTMENUPAGE_REGISTRY_KEY        "Software\$(^NAME)"
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME  "Start Menu Folder"


;--------------------------------
;Pages

  ;Installer pages
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "LICENSE"
  !insertmacro MULTIUSER_PAGE_INSTALLMODE

  ;This page only checks the prerequisites
  ;(and displays some feedback while at it)
  !insertmacro MUI_PAGE_INSTFILES

  !define MUI_PAGE_CUSTOMFUNCTION_PRE loadComponents
  !insertmacro MUI_PAGE_COMPONENTS
  !insertmacro MUI_PAGE_DIRECTORY

  !define MUI_PAGE_CUSTOMFUNCTION_PRE skipIfAlreadyHasMenu
  !insertmacro MUI_PAGE_STARTMENU               Application $StartMenuFolder
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  ;Uninstaller pages
  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH


;--------------------------------
;Languages

  !macro AddLocale NLFID
    !insertmacro MUI_LANGUAGE "${NLFID}"
    !include "i18n/${NLFID}.nsh"
  !macroend

  !insertmacro AddLocale English
  !insertmacro AddLocale French
  !insertmacro MUI_RESERVEFILE_LANGDLL

  ; Software information
  VIProductVersion "${INSTALLER_VERSION}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} ProductName     "Erebot Setup"
  VIAddVersionKey /LANG=${LANG_ENGLISH} FileDescription \
    "Setup program for Erebot - A modular IRC bot written in PHP"
  VIAddVersionKey /LANG=${LANG_ENGLISH} ProductVersion  "${INSTALLER_VERSION}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} FileVersion     "${INSTALLER_VERSION}"
  VIAddVersionKey /LANG=${LANG_ENGLISH} LegalCopyright  "${INSTALLER_COPY}"


;--------------------------------
;Macros

!macro FocusProgram
  BringToFront
  ; Check if already running
  ; If so don't open another but bring to front
  System::Call "kernel32::CreateMutexW(i 0, i 0, t '$(^Name)') i .r0 ?e"
  Pop $0
  StrCmp $0 0 launch
   StrLen $0 "$(^Name)"
   IntOp $0 $0 + 1
  loop:
    FindWindow $1 '#32770' '' 0 $1
    IntCmp $1 0 +5
    System::Call "user32::GetWindowText(i r1, t .r2, i r0) i."
    StrCmp $2 "$(^Name)" 0 loop
    System::Call "user32::ShowWindow(i r1,i 9) i."         ; If minimized then restore
    System::Call "user32::SetForegroundWindow(i r1) i."    ; Bring to front
    Abort
  launch:
!macroend

!macro AddModule
  Section /o "" "module_${NB_SECTIONS}"
    SectionIn 2
  SectionEnd
  !define OLD_NB_SECTIONS ${NB_SECTIONS}
  !undef NB_SECTIONS
  !define /math NB_SECTIONS ${OLD_NB_SECTIONS} + 1
  !undef OLD_NB_SECTIONS
!macroend

!macro Add10Modules
  !insertmacro AddModule
  !insertmacro AddModule
  !insertmacro AddModule
  !insertmacro AddModule
  !insertmacro AddModule
  !insertmacro AddModule
  !insertmacro AddModule
  !insertmacro AddModule
  !insertmacro AddModule
  !insertmacro AddModule
!macroend

!macro Add100Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
  !insertmacro Add10Modules
!macroend

!macro AddExtensionCheck EXT
  Push ${EXT}
  !define OLD_NB_EXTENSIONS ${NB_EXTENSIONS}
  !undef NB_EXTENSIONS
  !define /math NB_EXTENSIONS ${OLD_NB_EXTENSIONS} + 1
  !undef OLD_NB_EXTENSIONS
!macroend
!define AddExtensionCheck `!insertmacro AddExtensionCheck`

!macro DetailUpdate Text
  Push `${Text}`
  Call DetailUpdate
!macroend
!define DetailUpdate `!insertmacro DetailUpdate`


;--------------------------------
;Installer Sections

InstType "-"
InstType "$(FullInstall)"
InstType "$(MinimalInstall)"

Section /o "Erebot" section_Erebot
  SectionIn 2 RO
  SectionIn 3 RO
  SectionIn 4 RO
SectionEnd

SectionGroup /e "Additional Modules" section_Modules
  !insertmacro Add100Modules
SectionGroupEnd

Section /o "-Finalization" section_Finalization
  SectionIn 2 RO
  SectionIn 3 RO
  SectionIn 4 RO

  ; Save registers
  Push $0
  Push $1
  Push $2
  Push $3

  SetOutPath        "$INSTDIR"

  ; Initialize a new Composer project
  Push `"cmd" /C "$ComposerDir\composer" init -n --no-ansi`
  Call RunAndLog

  ; Add a requirement on Erebot's core
  StrCpy $3 "erebot/erebot"

  ; Handle modules
  IntOp $0 0 + 0
  ${While} $0 < $NbModules
    ; Point at the module's section
    IntOp $1 ${module_0} + $0

    ; Determine whether this module was selected or not
    SectionGetFlags $1 $2
    IntOp $2 $2 & ${SF_SELECTED}

    ; Add a requirement for the selected module
    ${If} $2 = ${SF_SELECTED}
      SectionGetText $1 $2
      StrCpy $3 "$3 $2"
      DetailPrint "Adding a requirement on $2"
    ${EndIf}

    ; Move on to the next module
    IntOp $0 $0 + 1
  ${EndWhile}

  ; Remove leftovers from previous installations if necessary
  SetDetailsPrint none
  RMDir /r "$INSTDIR\vendor"
  ClearErrors
  SetDetailsPrint both

  ; Run Composer to do the actual work
  Push `"cmd" /C "$ComposerDir\composer" require -n --no-update $3`
  Call RunAndLog
  
  Push `"cmd" /C "$ComposerDir\composer" update -n --no-progress --prefer-dist --no-ansi --no-suggest --no-dev --prefer-stable`
  Call RunAndLog

  ; Determine the actual version installed
  DetailPrint "Checking installed version"
  nsExec::ExecToStack `"php-win" -f "$PLUGINSDIR\get_version.php"`
  Pop $1
  Pop $2
  ${If} $1 != 0
    Abort "Unknown error (code: $1). Aborting!"
    Goto leave
  ${EndIf}

  ; Create uninstaller
  Delete            "$INSTDIR\uninstall.exe"
  WriteUninstaller  "$INSTDIR\uninstall.exe"

  File "launch.bat"
  File "Erebot.xml"
  File "defaults.xml"
  SetDetailsPrint none
  CopyFiles /SILENT "$EXEPATH" "$INSTDIR\setup.exe"
  ClearErrors
  SetDetailsPrint both

  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    ; Create shortcuts
    CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
    CreateShortCut  "$SMPROGRAMS\$StartMenuFolder\Start Erebot.lnk" \
                    "$INSTDIR\launch.bat" "" "$INSTDIR\setup.exe" 0 \
                    SW_SHOWNORMAL "" "$(ErebotDescription)"
    CreateShortCut  "$SMPROGRAMS\$StartMenuFolder\Online Documentation.lnk" \
                    "${URL_DOC}" "" "%SystemRoot%\system32\SHELL32.dll" 23 \
                    SW_SHOWNORMAL "" "Help"
    CreateShortCut  "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk" \
                    "$INSTDIR\uninstall.exe"
  !insertmacro MUI_STARTMENU_WRITE_END

  ; Write information about the installation mode into the registry.
  ; This key will be looked up by MultiUser on Uninstall
  WriteRegStr SHCTX \
    "${MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_KEY}" \
    "${MULTIUSER_INSTALLMODE_DEFAULT_REGISTRY_VALUENAME}" \
    "$MultiUser.InstallMode"

  ; Write uninstaller information into the registry
  WriteRegStr SHCTX "${UNINST_KEY}" "DisplayName"           `$(^NAME)`
  WriteRegStr SHCTX "${UNINST_KEY}" "UninstallString"       `"$INSTDIR\uninstall.exe" /$MultiUser.InstallMode`
  WriteRegStr SHCTX "${UNINST_KEY}" "QuietUninstallString"  `"$INSTDIR\uninstall.exe" /$MultiUser.InstallMode /S`
  WriteRegStr SHCTX "${UNINST_KEY}" "InstallLocation"       `"$INSTDIR"`
  WriteRegStr SHCTX "${UNINST_KEY}" "ModifyPath"            `"$INSTDIR\setup.exe"`
  WriteRegStr SHCTX "${UNINST_KEY}" "Readme"                `${URL_DOC}`
  WriteRegStr SHCTX "${UNINST_KEY}" "HelpLink"              `${URL_SUPPORT}`
  WriteRegStr SHCTX "${UNINST_KEY}" "URLInfoAbout"          `${URL_HOMEPAGE}`
  WriteRegStr SHCTX "${UNINST_KEY}" "DisplayVersion"        `$2`

  ; Write info about installation size to the registry.
  ${GetSize} "$INSTDIR" "/S=0K" $1 $2 $2
  IntFmt $1 "0x%08X" $1
  WriteRegDWORD SHCTX "${UNINST_KEY}" "EstimatedSize" "$1"

  leave:
    ; Restore registers
    Pop $3
    Pop $2
    Pop $1
    Pop $0
SectionEnd

Section "-Prerequisites" section_Prerequisites
  ;Notify the user about what we're doing
  !insertmacro MUI_HEADER_TEXT_PAGE "$(PrerequisitesCheck)" "$(PrerequisitesWait)"

  ; We change the output directory: this makes it possible to download
  ; Composer's installer there if necessary and also, this avoids issues
  ; with the calls to cmd.exe later on when the installer was run from
  ; a network share.
  SetOutPath "$PLUGINSDIR"
  File "fetch_modules.php"
  File "get_version.php"

  SetAutoClose true
  ClearErrors

  ; Save registers
  Push $0
  Push $1
  Push $2

  ; Retrieve PHP version
  DetailPrint "Checking PHP version..."
  nsExec::ExecToStack `"php" -r "echo phpversion();"`
  Pop $0 ; Return code
  ${If} $0 != 0
    Pop $0 ; Error message
    ${DetailUpdate} "Checking PHP version... NOT FOUND"
    Goto errors
  ${Else}
    Pop $0 ; PHP version
    ${DetailUpdate} "Checking PHP version... found $0"
  ${EndIf}

  ; Make sure we have a compatible PHP version
  nsExec::ExecToStack `"php" -r "exit((int) version_compare('$0', '${MIN_PHP_VERSION}', '<'));"`
  Pop $0 ; Return code
  Pop $1 ; Output (none is expected really)
  ${If} $0 != 0
    DetailPrint "Error: PHP ${MIN_PHP_VERSION} or later is required."
    Goto errors
  ${EndIf}

  ; Now, check if the required extensions are present
  ${AddExtensionCheck} "xsl"
  ${AddExtensionCheck} "SPL"
  ${AddExtensionCheck} "sockets"
  ${AddExtensionCheck} "SimpleXML"
  ${AddExtensionCheck} "Reflection"
  ${AddExtensionCheck} "Phar"
  ${AddExtensionCheck} "pdo_sqlite"
  ${AddExtensionCheck} "libxml"
  ${AddExtensionCheck} "json"
  ${AddExtensionCheck} "intl"
  ${AddExtensionCheck} "iconv"
  ${AddExtensionCheck} "DOM"
  IntOp $1 0 + ${NB_EXTENSIONS} ; Number of extensions to check
  ${While} $1 > 0
    Pop $2 ; Next extension name
    IntOp $1 $1 - 1

    DetailPrint "Checking whether the $2 extension is loaded..."
    nsExec::ExecToStack `"php" -r "echo (int) extension_loaded('$2');"`
    Pop $0 ; Return code
    ${If} $0 != 0
      Pop $0 ; Error message
      SetErrors
      ${DetailUpdate} "Checking whether the $2 extension is loaded... UNKNOWN"
      ${Continue}
    ${EndIf}

    Pop $0 ; 1 = extension loaded, 0 = extension missing
    ${If} $0 != 1
      SetErrors
      ${DetailUpdate} "Checking whether the $2 extension is loaded... NO"
      ${Continue}
    ${EndIf}

    ${DetailUpdate} "Checking whether the $2 extension is loaded... yes"
  ${EndWhile}

  IfErrors errors

  ; Check whether Composer is installed or not
  ReadRegStr $1 HKLM \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPOSER_GUID}_is1" \
    "Inno Setup CodeFile: BinDir"
  nsExec::ExecToStack `"cmd" /C "$1\composer" --no-ansi -V`
  Pop $0 ; Return code
  ${If} $0 != 0
    Pop $0 ; Output
    MessageBox MB_YESNO "Composer was not found on your computer.$\r$\n\
Would you like to install it now?$\r$\n\
$\r$\n\
Note: this requires an active Internet connection." \
      /SD IDYES IDNO composer_missing

    ; Download the installer
    DetailPrint "Downloading Composer's installer..."
    inetc::get /CAPTION "Downloading Composer's installer..." \
      /POPUP "" \
      /RESUME "" \
      "https://getcomposer.org/Composer-Setup.exe" \
      "Composer-Setup.exe" \
      /END
    Pop $0
    StrCmp $0 "OK" download_ok 0
    DetailPrint "Failed to download Composer's installer: $0"
    Goto composer_error

    download_ok:
      ${DetailUpdate} "Downloading Composer's installer... ok"

    ; Run the installer
    DetailPrint "Running Composer's installer..."
    nsExec::ExecToLog `"$PLUGINSDIR\Composer-Setup.exe"`
    Pop $0 ; Return code
    ${If} $0 == 0
      ${DetailUpdate} "Running Composer's installer... ok"
      Goto composer_installed
    ${Else}
      ${DetailUpdate} "Running Composer's installer... FAILED (exit code: $0)"
    ${EndIf}

    composer_error:
      DetailPrint "Composer's installation failed!"
      Goto errors

    composer_missing:
      DetailPrint "Composer is not installed!"
      Goto errors

    composer_installed:
      ; Check Composer's version again
      ReadRegStr $1 HKLM \
        "Software\Microsoft\Windows\CurrentVersion\Uninstall\${COMPOSER_GUID}_is1" \
        "Inno Setup CodeFile: BinDir"
      nsExec::ExecToStack `"cmd" /C "$1\composer" --no-ansi -V`
      Pop $0 ; Return code
      ${If} $0 != 0
        Pop $0 ; Output
        DetailPrint "Unknown error: $0"
        Goto errors
      ${EndIf}
  ${EndIf}

  Pop $0 ; Composer version
  DetailPrint "Found $0"
  StrCpy $ComposerDir "$1"

  ; Fetch the modules' metadata.
  ; This relies on Composer for several operations.
  ExecWait `"php-win" -f "$PLUGINSDIR\fetch_modules.php" -- "$ComposerDir"` $0
  ${If} $0 != 0
    Goto errors
  ${EndIf}

  Goto leave

  errors:
    SetOutPath $EXEDIR
    DetailPrint "Some prerequisites could not be satisfied. Aborting..."
    Abort

  ; Restore registers
  leave:
    Pop $2
    Pop $1
    Pop $0
SectionEnd


;--------------------------------
;Uninstaller Section

Section "Uninstall"
  Delete "$INSTDIR\composer.json"
  Delete "$INSTDIR\composer.lock"
  Delete "$INSTDIR\defaults.xml"
  Delete "$INSTDIR\Erebot.xml"
  Delete "$INSTDIR\launch.bat"
  Delete "$INSTDIR\setup.exe"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r /REBOOTOK "$INSTDIR\vendor"
  RMDir /REBOOTOK "$INSTDIR"

  !insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
  Delete "$SMPROGRAMS\$StartMenuFolder\Start Erebot.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\Online Documentation.lnk"
  Delete "$SMPROGRAMS\$StartMenuFolder\Uninstall.lnk"
  RMDir /REBOOTOK "$SMPROGRAMS\$StartMenuFolder"

  DeleteRegKey SHCTX "${MULTIUSER_INSTALLMODE_INSTDIR_REGISTRY_KEY}"
  DeleteRegKey SHCTX "${UNINST_KEY}"
SectionEnd


;--------------------------------
;Functions

Function .onInit
  !insertmacro MULTIUSER_INIT
  !insertmacro FocusProgram
  !insertmacro MUI_LANGDLL_DISPLAY
  InitPluginsDir
  IntOp $NbModules 0 + 0
  SetCurInstType 0
FunctionEnd

Function un.onInit
  !insertmacro MULTIUSER_UNINIT
  !insertmacro FocusProgram
  !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

Function .onMouseOverSection
  Push $R0
  Push $1

  FindWindow $R0 "#32770" "" $HWNDPARENT
  GetDlgItem $R0 $R0 1043 ; Description item

  ${If} $0 = ${section_Modules}
    Goto empty
  ${ElseIf} $0 = ${section_Erebot}
    ReadINIStr $1 "$PLUGINSDIR\modules.ini" "versions" "core"
    ReadINIStr $0 "$PLUGINSDIR\modules.ini" "descriptions" "core"
  ${Else}
    IntOp $0 $0 - ${module_0}
    ${If} $0 < 0
      Goto empty
    ${ElseIf} $0 >= $NbModules
      Goto empty
    ${EndIf}

    ReadINIStr $1 "$PLUGINSDIR\modules.ini" "versions" "module_$0"
    ReadINIStr $0 "$PLUGINSDIR\modules.ini" "descriptions" "module_$0"
  ${EndIf}

  SendMessage $R0 ${WM_SETTEXT} 0 "STR:$0 (latest release: v$1)"
  ClearErrors
  Goto leave

  empty:
    SendMessage $R0 ${WM_SETTEXT} 0 "STR:"

  leave:
    Pop $1
    Pop $R0
FunctionEnd

Function skipIfAlreadyHasMenu
  ReadRegStr $0 SHCTX "Software\$(^NAME)" "Start Menu Folder"
  ClearErrors
  ${If} "$0" != ""
    StrCpy $StartMenuFolder "$0"
    Abort
  ${EndIf}
FunctionEnd

Function DetailUpdate
  Exch $R0
  Push $R1
  Push $R2
  Push $R3

  FindWindow $R2 `#32770` `` $HWNDPARENT
  GetDlgItem $R1 $R2 1006
  SendMessage $R1 ${WM_SETTEXT} 0 `STR:$R0`
  GetDlgItem $R1 $R2 1016

  System::Call *(&t${NSIS_MAX_STRLEN}R0)i.R2
  System::Call *(i0,i0,i0,i0,i0,iR2,i${NSIS_MAX_STRLEN},i0,i0)i.R3

  SendMessage $R1 ${LVM_GETITEMCOUNT} 0 0 $R0
  IntOp $R0 $R0 - 1
  System::Call user32::SendMessage(iR1,i${LVM_SETITEMTEXT},iR0,iR3)

  System::Free $R3
  System::Free $R2

  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd

Function loadComponents
  Push $0
  Push $1
  Push $2
  Push $3

  ; Disable auto-close which was temporarily enabled
  ; during the prerequisites' check.
  SetAutoClose false

  ; Prepare the sections, but only if we're running for the first time
  ${If} $NbModules = 0
    ; Set the output directory to the plugin directory
    ; where "modules.ini" resides.
    SetOutPath "$PLUGINSDIR"

    ; Disable the prerequisites section & installation type
    IntOp $1 ${SF_SELECTED} ~
    SectionGetFlags ${section_Prerequisites} $2
    IntOp $2 $2 & $1
    SectionSetFlags ${section_Prerequisites} $2
    SectionSetInstTypes ${section_Prerequisites} 0
    InstTypeSetText 0 ""

    ; Enable the core section
    SectionGetFlags ${section_Erebot} $2
    IntOp $2 $2 | ${SF_SELECTED}
    SectionSetFlags ${section_Erebot} $2

    ; Enable the finalization section
    SectionGetFlags ${section_Finalization} $2
    IntOp $2 $2 | ${SF_SELECTED}
    SectionSetFlags ${section_Finalization} $2

    ; Retrieve the number of available modules
    ClearErrors
    ReadINIStr $3 "$PLUGINSDIR\modules.ini" main "modules"
    IfErrors error

    ; Prevent overflows
    ${If} $3 > ${NB_SECTIONS}
      Goto error
    ${EndIf}

    ; Enable the modules' sections
    ${While} $NbModules < $3
      ; Load the module's name
      ReadINIStr $2 "$PLUGINSDIR\modules.ini" names "module_$NbModules"
      IfErrors error

      ; Load the module's section index & increment the counter
      IntOp $1 ${module_0} + $NbModules

      ; Set the section's name (enables it)
      SectionSetText $1 $2

      ; Turn a few select modules into mandatory dependencies
      ${Switch} $2
        ${Case} "erebot/autoconnect-module"
        ${Case} "erebot/ircconnector-module"
        ${Case} "erebot/pingreply-module"
            SectionSetInstTypes $1 0xE
            SectionGetFlags $1 $2
            IntOp $2 $2 | ${SF_RO}
            SectionSetFlags $1 $2
            ; Fall-through

        ${Default}
            ; Select the module by default
            SectionGetFlags $1 $2
            IntOp $2 $2 | ${SF_SELECTED}
            SectionSetFlags $1 $2
      ${EndSwitch}

      ; Increment the counter
      IntOp $NbModules $NbModules + 1
    ${EndWhile}
  ${EndIf}

  Goto leave

  error:
    SetOutPath "$EXEDIR"
    MessageBox MB_ICONSTOP|MB_OK "Unknown error. Aborting..."
    Quit

  leave:
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

Function RunAndLog
  Push $1

  Exch
  Pop $1

  DetailPrint "Executing: $1"
  nsExec::ExecToLog `$1`
  Pop $0

  ${If} $0 != 0
    Abort "Failed to execute: $1 (exit code: $0)"
  ${EndIf}

  Pop $1
FunctionEnd

;--------------------------------
;Post-compilation steps

; Sign the installer.
; See http://stackoverflow.com/a/29073957 for more information.
; This is disabled for now as we do not have a valid code signing
; certificate (yet)
;!finalize `osslsigncode sign ...`
