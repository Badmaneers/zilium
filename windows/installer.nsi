; Zilium Super Compactor - NSIS Installer Script
; Creates a Windows installer for Zilium

!include "MUI2.nsh"
!include "x64.nsh"

; ========================================
; Configuration
; ========================================

!define PRODUCT_NAME "Zilium Super Compactor"
!define PRODUCT_VERSION "1.0.0"
!define PRODUCT_PUBLISHER "Badmaneers"
!define PRODUCT_WEB_SITE "https://github.com/Badmaneers/zilium"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\zilium-gui.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"

; ========================================
; General Settings
; ========================================

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "..\dist-windows\Zilium-Setup-v${PRODUCT_VERSION}.exe"
InstallDir "$PROGRAMFILES64\Zilium"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show
RequestExecutionLevel admin

; ========================================
; Version Information
; ========================================

VIProductVersion "${PRODUCT_VERSION}.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} Installer"
VIAddVersionKey "LegalCopyright" "© 2024-2025 ${PRODUCT_PUBLISHER}"

; ========================================
; Interface Settings
; ========================================

!define MUI_ABORTWARNING
!define MUI_ICON "zilium.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\modern-uninstall.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\nsis3-grey.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\nsis3-grey.bmp"

; ========================================
; Pages
; ========================================

; Installer Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_RUN "$INSTDIR\zilium-gui.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch Zilium Super Compactor"
!insertmacro MUI_PAGE_FINISH

; Uninstaller Pages
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; ========================================
; Languages
; ========================================

!insertmacro MUI_LANGUAGE "English"

; ========================================
; Installer Sections
; ========================================

Section "Core Files" SecCore
  SectionIn RO  ; Read-only, always installed
  
  SetOutPath "$INSTDIR"
  
  ; Main executables
  File "..\build-windows\gui\Release\zilium-gui.exe"
  File "..\build-windows\Release\zilium-super-compactor.exe"
  
  ; Qt dependencies (deployed by windeployqt)
  File /r "..\dist-windows\Zilium-Windows\*.dll"
  File /r "..\dist-windows\Zilium-Windows\platforms"
  File /r "..\dist-windows\Zilium-Windows\styles"
  File /r "..\dist-windows\Zilium-Windows\qml"
  
  ; Documentation
  File "..\README.md"
  File "..\LICENSE"
  
  ; Create docs directory
  SetOutPath "$INSTDIR\docs"
  File /r "..\docs\*.md"
  
  ; Registry entries
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\zilium-gui.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninstall.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\zilium-gui.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
  
  ; Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "LP Tools" SecLPTools
  SetOutPath "$INSTDIR\lptools"
  
  ; Check if LP tools exist
  IfFileExists "..\lpunpack_and_lpmake\windows\lpmake.exe" 0 +4
    File "..\lpunpack_and_lpmake\windows\lpmake.exe"
    File "..\lpunpack_and_lpmake\windows\lpunpack.exe"
    File "..\lpunpack_and_lpmake\windows\lpdump.exe"
SectionEnd

Section "Start Menu Shortcuts" SecStartMenu
  CreateDirectory "$SMPROGRAMS\Zilium"
  CreateShortCut "$SMPROGRAMS\Zilium\Zilium Super Compactor.lnk" "$INSTDIR\zilium-gui.exe"
  CreateShortCut "$SMPROGRAMS\Zilium\Zilium CLI.lnk" "cmd.exe" '/k "$INSTDIR\zilium-super-compactor.exe" --help'
  CreateShortCut "$SMPROGRAMS\Zilium\Uninstall.lnk" "$INSTDIR\uninstall.exe"
  CreateShortCut "$SMPROGRAMS\Zilium\Documentation.lnk" "$INSTDIR\docs"
SectionEnd

Section "Desktop Shortcut" SecDesktop
  CreateShortCut "$DESKTOP\Zilium.lnk" "$INSTDIR\zilium-gui.exe"
SectionEnd

Section "Add to PATH" SecPath
  ; Add installation directory to system PATH
  EnVar::SetHKLM
  EnVar::AddValue "PATH" "$INSTDIR"
SectionEnd

; ========================================
; Section Descriptions
; ========================================

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecCore} "Core application files (required)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecLPTools} "Android LP partition tools (lpmake, lpunpack, lpdump)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartMenu} "Create Start Menu shortcuts"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "Create Desktop shortcut"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecPath} "Add Zilium to system PATH for command-line access"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ========================================
; Installer Functions
; ========================================

Function .onInit
  ; Check if running on 64-bit Windows
  ${IfNot} ${RunningX64}
    MessageBox MB_ICONSTOP "This application requires 64-bit Windows. Installation will now exit."
    Quit
  ${EndIf}
  
  ; Check if already installed
  ReadRegStr $0 ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString"
  ${If} $0 != ""
    MessageBox MB_YESNO|MB_ICONQUESTION \
      "Zilium is already installed. Do you want to uninstall the previous version first?" \
      IDNO done
    
    ; Run uninstaller
    ExecWait '$0 _?=$INSTDIR'
    Delete $0
    RMDir $INSTDIR
  ${EndIf}
  done:
FunctionEnd

Function .onInstSuccess
  MessageBox MB_OK "Zilium Super Compactor has been successfully installed!"
FunctionEnd

; ========================================
; Uninstaller Section
; ========================================

Section "Uninstall"
  ; Remove files
  Delete "$INSTDIR\zilium-gui.exe"
  Delete "$INSTDIR\zilium-super-compactor.exe"
  Delete "$INSTDIR\*.dll"
  Delete "$INSTDIR\README.md"
  Delete "$INSTDIR\LICENSE"
  Delete "$INSTDIR\uninstall.exe"
  
  ; Remove directories
  RMDir /r "$INSTDIR\platforms"
  RMDir /r "$INSTDIR\styles"
  RMDir /r "$INSTDIR\qml"
  RMDir /r "$INSTDIR\docs"
  RMDir /r "$INSTDIR\lptools"
  RMDir "$INSTDIR"
  
  ; Remove shortcuts
  Delete "$DESKTOP\Zilium.lnk"
  Delete "$SMPROGRAMS\Zilium\*.*"
  RMDir "$SMPROGRAMS\Zilium"
  
  ; Remove from PATH
  EnVar::SetHKLM
  EnVar::DeleteValue "PATH" "$INSTDIR"
  
  ; Remove registry keys
  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  
  SetAutoClose true
SectionEnd

; ========================================
; Uninstaller Functions
; ========================================

Function un.onInit
  MessageBox MB_YESNO|MB_ICONQUESTION \
    "Are you sure you want to completely remove Zilium Super Compactor and all of its components?" \
    IDYES +2
  Abort
FunctionEnd

Function un.onUninstSuccess
  MessageBox MB_OK "Zilium Super Compactor has been successfully removed from your computer."
FunctionEnd
