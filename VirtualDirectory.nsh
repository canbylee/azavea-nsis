;c-style prevention of duplicate imports.
!IFNDEF VIRTUAL_DIR_IMPORT
!DEFINE VIRTUAL_DIR_IMPORT "yup"

; Includes this for doing the virtual directory creation/deletion.
!INCLUDE "AzaveaUtils.nsh"


;------------------------------------------------------------------------------
; This macro is easier than calling the function, plus it handles the permissions
; (well, almost).
; 
; DEST_REAL    - The destination "real" directory, I.E. $APPLICATION_DIR\Web
; DEST_VIRT    - The destination virtual directory, I.E. "MyApplication" (http://localhost/MyApplication)
; DISPLAY_NAME - The display name of the virtual directory, visible in IIS administrator(?)
; DEFAULT_DOC  - The default document, such as "default.asmx".
!MACRO CreateVirtualDir DEST_REAL DEST_VIRT DISPLAY_NAME DEFAULT_DOC
  ; Create the virtual directory
  StrCpy $CVDIR_VIRTUAL_NAME "${DEST_VIRT}"
  StrCpy $CVDIR_REAL_PATH "${DEST_REAL}"
  StrCpy $CVDIR_PRODUCT_NAME "${DISPLAY_NAME}"
  StrCpy $CVDIR_DEFAULT_DOC "${DEFAULT_DOC}"
  Call CreateVDir
  !INSERTMACRO SetPermissions "${DEST_REAL}" "ASPNET" "R"
  !INSERTMACRO SetPermissions "${DEST_REAL}" "NETWORK SERVICE" "R"
  Call GetIUSRAccount
  !INSERTMACRO AvLog "IUSR Account = $IUSR_ACCT_USERNAME"
  !INSERTMACRO SetPermissions "${DEST_REAL}" "$IUSR_ACCT_USERNAME" "R"
!MACROEND

;------------------------------------------------------------------------------
; This macro is easier than calling the function
; 
; DEST_VIRT    - The destination virtual directory, I.E. "MyApplication" (http://localhost/MyApplication)
; DISPLAY_NAME - The display name of the virtual directory, visible in IIS administrator(?)
!MACRO DeleteVirtualDir DEST_VIRT DISPLAY_NAME
  ; Remove the virtual directory
  StrCpy $DVDIR_VIRTUAL_NAME "${DEST_VIRT}"
  StrCpy $DVDIR_PRODUCT_NAME "${DISPLAY_NAME}"
  Call un.DeleteVDir
!MACROEND

;--------------------------------
; CreateVDir Function
Var CVDIR_VIRTUAL_NAME
Var CVDIR_REAL_PATH
Var CVDIR_PRODUCT_NAME
Var CVDIR_DEFAULT_DOC
Function CreateVDir
Push $0
Push $1 
!INSERTMACRO AvLog "Creating virtual directory '$CVDIR_VIRTUAL_NAME' at '$CVDIR_REAL_PATH'";
;Open a VBScript File in the temp dir for writing
!INSERTMACRO AvLog "Creating $TEMP\createVDir.vbs";
FileOpen $0 "$TEMP\createVDir.vbs" w
 
;Write the script:
;Create a virtual dir named $CVDIR_VIRTUAL_NAME pointing to $CVDIR_REAL_PATH with proper attributes
FileWrite $0 "On Error Resume Next$\n"
FileWrite $0 "Set Root = GetObject($\"IIS://LocalHost/W3SVC/1/ROOT$\")$\n"
FileWrite $0 "Set Dir = Root.Create($\"IIsWebVirtualDir$\", $\"$CVDIR_VIRTUAL_NAME$\")$\n"
FileWrite $0 "If (Err.Number <> 0) Then$\n"
FileWrite $0 "  If (Err.Number <> -2147024713) Then$\n"
FileWrite $0 "    message = $\"Error $\" & Err.Number$\n"
FileWrite $0 "    message = message & $\" trying to create IIS virtual directory.$\" & chr(13)$\n"
FileWrite $0 "    message = message & $\"Please check your IIS settings (inetmgr).$\"$\n"
${If} ${Silent}
  FileWrite $0 "    WScript.Echo message$\n"
${Else}
  FileWrite $0 "    MsgBox message, vbCritical, $\"$CVDIR_PRODUCT_NAME$\"$\n"
${EndIf}
FileWrite $0 "    WScript.Quit (Err.Number)$\n"
FileWrite $0 "  End If$\n"
FileWrite $0 "  ' Error -2147024713 means that the virtual directory already exists.$\n"
FileWrite $0 "  ' We will check if the parameters are the same: if so, then OK.$\n"
FileWrite $0 "  ' If not, then fail and display a message box.$\n"
FileWrite $0 "  Set Dir = GetObject($\"IIS://LocalHost/W3SVC/1/ROOT/$CVDIR_VIRTUAL_NAME$\")$\n"
FileWrite $0 "  If (Dir.Path <> $\"$CVDIR_REAL_PATH$\") Then$\n"
FileWrite $0 "    message = $\"Virtual Directory $CVDIR_VIRTUAL_NAME already exists pointing at a different folder ($\" + Dir.Path + $\").$\" + chr(13)$\n"
FileWrite $0 "    message = message + $\"Please delete the virtual directory using the IIS console (inetmgr), and install again.$\"$\n"
${If} ${Silent}
  FileWrite $0 "    WScript.Echo message$\n"
${Else}
  FileWrite $0 "    MsgBox message, vbCritical, $\"$CVDIR_PRODUCT_NAME$\"$\n"
${EndIf}
FileWrite $0 "    Wscript.Quit (Err.Number)$\n"
FileWrite $0 "  End If$\n"
FileWrite $0 "  If (Dir.AspAllowSessionState <> True  Or  Dir.AccessScript <> True) Then$\n"
FileWrite $0 "    message = $\"Virtual Directory $CVDIR_VIRTUAL_NAME already exists and has incompatible parameters.$\" + chr(13)$\n"
FileWrite $0 "    message = message + $\"Please delete the virtual directory using the IIS console (inetmgr), and install again.$\"$\n"
${If} ${Silent}
  FileWrite $0 "    WScript.Echo message$\n"
${Else}
  FileWrite $0 "    MsgBox message, vbCritical, $\"$CVDIR_PRODUCT_NAME$\"$\n"
${EndIf}
FileWrite $0 "    Wscript.Quit (Err.Number)$\n"
FileWrite $0 "  End If$\n"
FileWrite $0 "  Wscript.Quit (0)$\n"
FileWrite $0 "End If$\n"
FileWrite $0 "Dir.Path = $\"$CVDIR_REAL_PATH$\"$\n"
FileWrite $0 "Dir.AccessRead = True$\n"
FileWrite $0 "Dir.AccessWrite = False$\n"
FileWrite $0 "Dir.AccessScript = True$\n"
FileWrite $0 "Dir.AppFriendlyName = $\"$CVDIR_VIRTUAL_NAME$\"$\n"
FileWrite $0 "Dir.EnableDirBrowsing = False$\n"
FileWrite $0 "Dir.ContentIndexed = False$\n"
FileWrite $0 "Dir.DontLog = True$\n"
FileWrite $0 "Dir.EnableDefaultDoc = True$\n"
FileWrite $0 "Dir.DefaultDoc = $\"$CVDIR_DEFAULT_DOC$\"$\n"
FileWrite $0 "Dir.AspBufferingOn = True$\n"
FileWrite $0 "Dir.AspAllowSessionState = True$\n"
FileWrite $0 "Dir.AspSessionTimeout = 30$\n"
FileWrite $0 "Dir.AspScriptTimeout = 900$\n"
FileWrite $0 "Dir.SetInfo$\n"
FileWrite $0 "Set IISObject = GetObject($\"IIS://LocalHost/W3SVC/1/ROOT/$CVDIR_VIRTUAL_NAME$\")$\n"
FileWrite $0 "IISObject.AppCreate2(2) 'Create a process-pooled web application$\n"
FileWrite $0 "If (Err.Number <> 0) Then$\n"
FileWrite $0 " message = $\"Error $\" & Err.Number$\n"
FileWrite $0 " message = message & $\" trying to create the virtual directory at 'IIS://LocalHost/W3SVC/1/ROOT/$CVDIR_VIRTUAL_NAME'$\" & chr(13)$\n"
FileWrite $0 " message = message & $\"Please check your IIS settings (inetmgr).$\"$\n"
${If} ${Silent}
  FileWrite $0 "    WScript.Echo message$\n"
${Else}
  FileWrite $0 " MsgBox message, vbCritical, $\"$CVDIR_PRODUCT_NAME$\"$\n"
${EndIf}
FileWrite $0 " WScript.Quit (Err.Number)$\n"
FileWrite $0 "End If$\n"
 
FileClose $0
 
!INSERTMACRO AvExec '"$SYSDIR\cscript.exe" "$TEMP\createVDir.vbs"'
!INSERTMACRO AvLog "Successfully created IIS virtual directory"
Delete "$TEMP\createVDir.vbs"
 
Pop $1
Pop $0
FunctionEnd

Var IUSR_ACCT_USERNAME
Function GetIUSRAccount
	!INSERTMACRO AvLog "Getting IIS Anonymous Username"
	!INSERTMACRO AvLog "Creating $TEMP\iisAnon.vbs"
	; Save the old value of $0 on the stack.
	Push $0
	FileOpen $0 "$TEMP\iisAnon.vbs" w
	
	FileWrite $0 "Function AnonymousUser()$\n"
	FileWrite $0 "Dim FullPath, IISObj, IISObj1$\n"
	FileWrite $0 "On Error Resume Next$\n"
	FileWrite $0 "FullPath = $\"IIS://$\" & $\"localhost$\" & $\"/$\" & $\"W3SVC$\"$\n"
	FileWrite $0 "Set IISObj = GetObject(FullPath)$\n"
	FileWrite $0 "If (err <> 0) Then$\n"
	FileWrite $0 "WScript.Echo $\"Unable to access object : $\" & $\"W3SVC$\" & $\" on computer: $\" & $\"localhost$\" & vbctrlf$\n"
	FileWrite $0 "Exit Function$\n"
	FileWrite $0 "Else$\n"
	FileWrite $0 "For Each Server In IISObj$\n"
	FileWrite $0 "If (Server.Class = $\"IIsWebServer$\") Then$\n"
	FileWrite $0 "FullPath = $\"IIS://$\" & $\"localhost$\" & $\"/$\" & $\"W3SVC$\" & $\"/$\" & Server.Name & $\"/Root$\"$\n"
	FileWrite $0 "Else$\n"
	FileWrite $0 "FullPath = $\"IIS://$\" & $\"localhost$\" & $\"/$\" & $\"W3SVC$\" & $\"/$\" & Server.Name$\n"
	FileWrite $0 "End If$\n"
	FileWrite $0 "Set IISObj1 = GetObject(FullPath)$\n"
	FileWrite $0 "AnonymousUser = IISObj1.AnonymousUserName$\n"
	FileWrite $0 "Next$\n"
	FileWrite $0 "End If$\n"
	FileWrite $0 "Set IISObj = Nothing$\n"
	FileWrite $0 "End Function$\n"

	FileWrite $0 "Dim anonymousUserName$\n"
	FileWrite $0 "anonymousUserName = AnonymousUser()$\n"
	FileWrite $0 "WScript.Echo anonymousUserName"

	FileClose $0
	
	!INSERTMACRO AvExecIntoVariable '"$SYSDIR\cscript.exe" //Nologo "$TEMP\iisAnon.vbs"' $IUSR_ACCT_USERNAME
	!INSERTMACRO EnsureEndsWithout $IUSR_ACCT_USERNAME "$\r$\n"

	; Restore the old value of $0
	Pop $0
	Delete "$TEMP\iisAnon.vbs"
FunctionEnd
 
;--------------------------------
; DeleteVDir Function
Var DVDIR_VIRTUAL_NAME
Var DVDIR_PRODUCT_NAME
Function un.DeleteVDir
Push $0 
Push $1
!INSERTMACRO AvLog "Deleting virtual directory '$DVDIR_VIRTUAL_NAME'";
;Open a VBScript File in the temp dir for writing
!INSERTMACRO AvLog "Creating $TEMP\deleteVDir.vbs";
FileOpen $0 "$TEMP\deleteVDir.vbs" w
 
;Write the script:
;Remove a virtual dir named $DVDIR_VIRTUAL_NAME
FileWrite $0 "On Error Resume Next$\n$\n"
;Delete the application object
FileWrite $0 "Set IISObject = GetObject($\"IIS://LocalHost/W3SVC/1/ROOT/$DVDIR_VIRTUAL_NAME$\")$\n$\n"
FileWrite $0 "IISObject.AppDelete 'Delete the web application$\n"
FileWrite $0 "If (Err.Number <> 0) Then$\n"
FileWrite $0 "    message = $\"Error trying to delete the application at [IIS://LocalHost/W3SVC/1/ROOT/$DVDIR_VIRTUAL_NAME]$\"$\n"
${If} ${Silent}
  FileWrite $0 "    WScript.Echo message$\n"
${Else}
  FileWrite $0 "    MsgBox message, vbCritical, $\"$DVDIR_PRODUCT_NAME$\"$\n"
${EndIf}
FileWrite $0 " WScript.Quit (Err.Number)$\n"
FileWrite $0 "End If$\n$\n"
 
FileWrite $0 "Set IISObject = GetObject($\"IIS://LocalHost/W3SVC/1/ROOT$\")$\n$\n"
FileWrite $0 "IIsObject.Delete $\"IIsWebVirtualDir$\", $\"$DVDIR_VIRTUAL_NAME$\"$\n"
FileWrite $0 "If (Err.Number <> 0) Then$\n"
FileWrite $0 "    message = $\"Error trying to delete the virtual directory '$DVDIR_VIRTUAL_NAME' at 'IIS://LocalHost/W3SVC/1/ROOT'$\"$\n"
${If} ${Silent}
  FileWrite $0 "    WScript.Echo message$\n"
${Else}
  FileWrite $0 "    MsgBox message, vbCritical, $\"$DVDIR_PRODUCT_NAME$\"$\n"
${EndIf}
FileWrite $0 " Wscript.Quit (Err.Number)$\n"
FileWrite $0 "End If$\n$\n"
 
FileClose $0
 
!INSERTMACRO AvExecIgnoreErrors '"$SYSDIR\cscript.exe" "$TEMP\deleteVDir.vbs"'
Delete "$TEMP\deleteVDir.vbs"
Pop $1
Pop $0
FunctionEnd

!ENDIF ;VIRTUAL_DIR_IMPORT
