Use Windows.pkg
Use Dfclient.pkg
Use cRDCDbView.pkg
Use MSSqldrv.pkg 
Use db2_drv.pkg
Use odbc_drv.pkg
Use seq_chnl.pkg
Use File_dlg.pkg
Use cRDCForm.pkg
Use cRDCButton.pkg
Use cDbUpdateFunctionLibrary.pkg
Use cRDCComboForm.pkg
Use cRDCCheckbox.pkg
Use cDUFNumForm.pkg
Use cDUFRichEdit.pkg
Use vWin32fh.pkg
Use DriverIntFileSettings.dg
Use SQLDatabaseBackup.dg
Use SQLCollations.sl

// The repair work, the ghoDUF handle and the CS_ Defines of the view are in cDUFFilelistRepair.pkg.
Use cDUFFilelistRepair.pkg

Register_Object oConnIDErrors_edt
Register_Function BackupStoppedText String sDone Integer iDone Returns String

Activate_View Acivate_oFileListFixerView for oFileListFixerView
Object oFilelistFixerView is a cRDCDbView 
    Set Location to 2 1
    Set Size to 452 691
    Set pbAutoActivate to True

    Set phoFilelistFixerView of ghoApplication to Self
    
    Property String psFileList ""
    Property String psBackupFolder ""
    // Why the last backup copy could not be made, or "". A run that needs one stops when it is not "".
    Property String psBackupError ""
    Property String psConnId   ""
    Property String psConnIdFile ""
    Property Boolean pbOpenLogFile False
    Property Integer piChannel -1  
    // The errors written to the log file since the last button was clicked (WriteError counts them).
    Property Integer piLoggedErrors 0
    
    Object oFilelist_fm is a cRDCForm
        Set Size to 12 382
        Set Location to 14 82
        Set Label to "Filelist.cfg:" 
        Set Prompt_Object to Self 
        
        Property Boolean pbFirst True
        
        Procedure Prompt
            String sFileName sPath sFileMask sRetval
            Get Value to sFileName
            Get ParseFolderName sFileName to sPath
            Move "Filelist.cfg files (*.cfg)|*.cfg" to sFileMask
            Get vSelect_File sFileMask "Please select a Filelist.cfg file" sPath to sRetval
            If (sRetval <> "") Begin
                Delegate Send ClearData
                Set Value to sRetval
            End
        End_Procedure
        
        Procedure Set Value Integer iItem String sValue
            Forward Set Value iItem to sValue
            Set psFileList to sValue
        End_Procedure

        Procedure OnChange
            String sFileList sPath sHome sChar sDatabase
            Boolean bExists bCfgFile bOK
            Handle hoLocalError_Object_Id hoOrgError_Object_Id
            
            // The local handler is put back at the end in any case. (It was set only when the Filelist existed: an
            // empty or mistyped path made the error object 0.)
            Move (oLocalError_Info_Object(Self)) to hoLocalError_Object_Id
            Get Value to sFileList
            Get vFilePathExists sFileList to bExists
            Move (Lowercase(sFileList) contains ".cfg") to bCfgFile
            If (bExists = True and bCfgFile = True) Begin
                // We need to reroute the error_info_object to the original one, before
                // changing filelist paths, as that involves a new login if SQL.
                // So we temporarily re-initialize the original error handler, and
                // reset it to our own, when filelist path has been changed.
                Move (oLocalError_Info_Object(Self)) to hoLocalError_Object_Id
                Get phoOrgError_Object_Id of hoLocalError_Object_Id to hoOrgError_Object_Id
                Move hoOrgError_Object_Id to Error_Object_Id
                
                Get ChangeFilelistPathing of ghoApplication sFileList to bOK
                If (bOK = True) Begin
                    Set psFilelistFrom of ghoApplication to sFileList
                    Send UpdateConnIdData of oConnidInfo_edt
                    Send UpdateDriverIniFile of oDriver_fm
                    // The collation of the database is read once here, after the login.
                    Get psDatabase of ghoDUF to sDatabase
                    Send UpdateCollatingSequence of oCurrentCollatingSequence_fm sDatabase
                    Get ParseFolderName sFileList to sPath
                    Move (Right(sPath, 1)) to sChar
                    If (sChar = "\") Begin
                        Move (Left(sPath, Length(sPath) -1)) to sHome
                        Get ParseFolderName sHome to sHome
                    End
                    Get vFolderFormat sPath to sPath
                    Get ParseFolderName sHome to sHome
                    Set Value of oLogFile_fm to (sHome + CS_ReportFileName)
                End
            End
            Else Begin
                Send UnRegisterAllConnections of ghoConnection 
                Set psDriverID of ghoDUF to DATAFLEX_ID
                Set psDatabase of ghoDUF to ""
                Send ClearData of oConnidInfo_edt
                Set Value of oDriver_fm to ""
                Set Value of oCurrentCollatingSequence_fm to ""
            End

            Move hoLocalError_Object_Id to Error_Object_Id
            Send ShowSQLTablesCount
        End_Procedure

        Procedure Page Integer iPageObject
            String sFileName
            
            Forward Send Page iPageObject
            Get psFilelistFrom of ghoApplication to sFileName
            If (sFileName = "") Begin
                Get psFileList of (phoWorkspace(ghoApplication)) to sFileName
            End
            Set Value to sFileName
            Set pbFirst to False
        End_Procedure
        
    End_Object

    Object oSelectFilelist_btn is a cRDCButton
        Set Size to 12 50
        Set Location to 14 470
        Set Label to "Select"
        Set peAnchors to anNone
        Set psImage to "ActionOpen.ico"
        Set psToolTip to "Select a Filelist.cfg file from a Data folder."
        
        Procedure OnClick
            Send Prompt of oFilelist_fm
        End_Procedure
    
    End_Object

    Object oConnIDErrors_btn is a cRDCButton
        Set Size to 30 61
        Set Location to 3 549
        Set Label to "Make all .int files use DFConnid"
        Set psToolTip to "Changes or updates all .int files in the Data folder - except for DAW driver .int files (MSSQL_DRV.int, DB2_DRV.int & ODBC_DRV.int) - to use 'SERVER_NAME DFCONNID=xxx', where xxx is the 'id=' of the DFConnid.ini file displayed to the left."
        Set peAnchors to anNone
        Set MultiLineState to True
        Set psImage to "ChangeToDFConnid.ico"
        Set piImageSize to 24
        Set pbAutoEnable to True
        
        // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
        Procedure OnClick
            Send ResetLoggedErrors
            Send DoClick
            Send OfferErrorLog
        End_Procedure

        Procedure DoClick
            String sDataPath sConnectionID
            String[] asFileChanges
            Boolean bActive
            Integer iRetval iSize iCount 
            Handle ho

            Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
            Get psConnId to sConnectionID
            Get YesNo_Box ("Do you want to change all .int files in folder:\n" + sDataPath + "\n\nTo use 'DFCONNID=" + sConnectionID +"' ?") to iRetval
            If (iRetval <> MBR_Yes) Begin
                Procedure_Return
            End
            
            Move 0 to iCount
            Set Value of oConnIDErrors_fm to 0
            Move (oConnIDErrors_edt(Self)) to ho     
            Send Delete_Data of ho
            Send StartStatusPanel "Changing to Connection ID's in .int files" "" -1

            Get SqlUtilChangeIntFilesToConnectionIDs of ghoDUF sDataPath sConnectionID True to asFileChanges

            Send UpdateStatusPanel ""
            Get Active_State of ghoStatusPanel to bActive
            If (bActive = False) Begin
                Send StopStatusPanel
                Send Info_Box "Process interrupted..."
                Procedure_Return
            End

            Move (SizeOfArray(asFileChanges)) to iSize
            Set Value of oConnIDErrors_fm to (iSize max 0)
            Send StopStatusPanel
            If (SizeOfArray(asFileChanges) <> 0) Begin
                Decrement iSize
                For iCount from 0 to iSize
                    Send AppendTextLn of ho asFileChanges[iCount]
                Loop       
                Send Beginning_of_Data of ho
                // Note: Remove all cache-files:
                Send EraseCacheFiles
                Send RefreshData
                Send Info_Box ("Ready!" * String(iSize + 1) * ".int files contained errors and were changed to be using DFConnID's.")
            End
            Else Begin
                Send Info_Box "Ready! No problems found."    
            End
        End_Procedure 
        
        Function IsEnabled Returns Boolean
            Boolean bExists
            String sFileName
            Get psConnIdFile to sFileName
            File_Exist sFileName bExists
            Function_Return bExists
        End_Function

    End_Object

    Object oRefresh_btn is a cRDCButton
        Set Size to 30 61
        Set Location to 3 615
        Set Label to "Refresh Data!"
        Set Default_State to True
        Set Form_FontWeight to fw_Bold
        Set psToolTip to "Refreshes all data by reading the Filelist.cfg and SQL database tables (F5)" 
        Set psImage to "ActionRefresh.ico"
        Set piImageSize to 32
        Set MultiLineState to True
        Set pbAutoEnable to True
        Set peAnchors to anNone
        
        // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
        Procedure OnClick
            Send ResetLoggedErrors
            Send DoClick
            Send OfferErrorLog
        End_Procedure

        Procedure DoClick
            Send RefreshData
        End_Procedure
    
        Function IsEnabled Returns Boolean
            Boolean bExists
            String sFileName
            Get Value of oFilelist_fm to sFileName
            File_Exist sFileName bExists
            Function_Return bExists
        End_Function

    End_Object

    Object oSQL_grp is a Group
        Set Size to 175 673
        Set Location to 47 12
        Set Label to "SQL Settings:"
        Set peAnchors to anTopLeftRight

        Object oConnidInfo_edt is a cDUFRichEdit
            Set Size to 75 448
            Set Location to 23 5
            Set peAnchors to anNone
            Set Skip_State to True
            Set pbUseSpellChecker to False
            
            Procedure Page Integer iPageObject
                Forward Send Page iPageObject
                Send UpdateConnIdData
            End_Procedure
            
            // The connection string with "***" for the value of PWD= and PASSWORD=. (The password was shown.)
            Function ConnectionStringWithoutPassword String sConnection Returns String
                String sUpper sRest
                String[] asKeys
                Integer iKey iStart iEnd

                Move "PWD=" to asKeys[0]
                Move "PASSWORD=" to asKeys[1]
                For iKey from 0 to 1
                    Move (Uppercase(sConnection)) to sUpper
                    Move (Pos(asKeys[iKey], sUpper)) to iStart
                    If (iStart > 0) Begin
                        // the first character of the value, and the ";" after it, if any
                        Move (iStart + Length(asKeys[iKey])) to iStart
                        Move (Mid(sConnection, Length(sConnection), iStart)) to sRest
                        Move (Pos(";", sRest)) to iEnd
                        If (iEnd > 0) Begin
                            Move (Mid(sRest, Length(sRest), iEnd)) to sRest
                        End
                        Else Begin
                            Move "" to sRest
                        End
                        Move (Left(sConnection, (iStart - 1)) + "***" + sRest) to sConnection
                    End
                Loop
                Function_Return sConnection
            End_Function

            Procedure UpdateConnIdData
                String sDFConnidFile sDatapath sServer sDatabase
                Boolean bExists
                tConnection[] Connections
                
                If (ghoConnection = 0) Begin
                    Procedure_Return
                End
                
                Send Delete_Data
                Set Label to ""
                Get psDataPath of (phoWorkspace(ghoApplication)) to sDatapath
                File_Exist (sDatapath + "\" + String(C_ConnectionIniFileName)) bExists
                If (bExists = True) Begin
                    Move (sDatapath + "\" + String(C_ConnectionIniFileName)) to sDFConnidFile
                End
                Else Begin
                    Procedure_Return
                End
                
                Get ConnectionIDs of ghoConnection to Connections
                If (SizeOfArray(Connections) <> 0) Begin
                    Set psConnId to Connections[0].sId
                    Set psConnIdFile to sDFConnidFile
                    Set Label to ("DFConnId File=" + String(sDFConnidFile))  
                    Send AppendTextLn ""
                    Send AppendTextLn ("id=" + String(Connections[0].sId))
                    Send AppendTextLn ("driver=" + String(Connections[0].sDriver))
                    Send AppendTextLn ("connection=" + ConnectionStringWithoutPassword(Self, Connections[0].sString))
                    Send AppendTextLn ("trusted_connection=" + String(Connections[0].bTrustedConnection))
                    Send AppendTextLn ("disabled=" + String(Connections[0].bDisabled)) 
                    Send Beginning_of_Data
                    Get psServer of ghoduf to sServer
                    Set Value of oServer_fm to sServer
                    Get psDatabase of ghoDUF to sDatabase
                    Set Value of oDatabase_fm to sDatabase
                End   
                Else Begin
                    Send AppendTextLn "No DFConnid.ini file found, or no active connection."
                End
            End_Procedure  
            
            Procedure ClearData
                Forward Send ClearData
                Set Label to ""
            End_Procedure
    
        End_Object
        
        Object oEditDFConnIt_btn is a cRDCButton
            Set Size to 12 50
            Set Location to 23 458
            Set Label to "Edit"
            Set peAnchors to anNone
            Set psImage to "ActionEdit.ico"
            Set pbAutoEnable to True
            Set psToolTip to "Edit the SQL connection file."
            
            Procedure OnClick
                String sFileName
                Get psConnIdFile to sFileName
                Runprogram Shell Background sFileName
            End_Procedure
        
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object
        
        Object oDriver_fm is a cRDCForm
            Set Size to 12 378
            Set Location to 103 76
            Set Label to "Driver .int file:"
            Set pbAutoEnable to True
            Set peAnchors to anNone
            
            Procedure Page Integer iPageObject
                Forward Send Page iPageObject 
                Send UpdateDriverIniFile
            End_Procedure
            
            Procedure UpdateDriverIniFile
                String sFileName sPath sDriver
                Boolean bExists
                Integer iPos
                
                Get psDataPath of (phoWorkspace(ghoApplication)) to sPath
                Get vFolderFormat sPath to sPath
                Get psDriverID of ghoDUF to sDriver
                Set Enabled_State to (sDriver <> DATAFLEX_ID) 
                Set Enabled_State of oViewDriverProperties_btn to (sDriver <> DATAFLEX_ID) 
                If (sDriver = DATAFLEX_ID) Begin 
                    Set Value to ""
                    Procedure_Return    
                End 
                // The driver id - MSSQLDRV - names the file; a name with an extension is cut there. (Without a "." in
                // the id the name was "", and ".int" was looked for.)
                Move sDriver to sFileName
                Move (Pos(".", sDriver)) to iPos
                If (iPos > 0) Begin
                    Move (Left(sDriver, iPos -1)) to sFileName
                End
                Move (sFileName + ".int") to sFileName
                
                File_Exist (sPath + sFileName) bExists
                If (bExists = False) Begin
                    Get_File_Path sFileName to sFileName   
                End
                Else Begin
                    Move (sPath + sFileName) to sFileName
                End
                Set Value to sFileName
            End_Procedure
            
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object    
        
        Object oViewDriverProperties_btn is a cRDCButton
            Set Size to 12 50
            Set Location to 103 458
            Set Label to "View"
            Set peAnchors to anNone
            Set psImage to "View.ico"
            Set pbAutoEnable to True
            Set psToolTip to "View the content of the driver .ini file."
            
            Procedure OnClick
                String sFileName
                Get Value of oDriver_fm to sFileName
                Send ActivateDriverIntSettingsDialog sFileName     
            End_Procedure
        
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object
        
        Object oServer_fm is a cRDCForm
            Set Label to "SQL Server name:"
            Set Size to 12 157
            Set Location to 119 76
            Set pbAutoEnable to True

            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
        
        End_Object

        Object oDatabase_fm is a cRDCForm
            Set Label to "Database name:"
            Set Size to 12 154
            Set Location to 119 298
            Set pbAutoEnable to True

            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object

        Object oBackupSQLDatabase_btn is a cRDCButton
            Set Size to 12 50
            Set Location to 119 458
            Set Label to "Backup"
            Set psImage to "DbBackup.ico"
            Set pbAutoEnable to True
            Set psToolTip to "Make a backup copy of the SQL database. The file will be created in the SQL Server standard Backup folder, with a file name that is the database name followed by the todays date and time."
            
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Boolean bOK

                // Show SQLDatabaseBackup dialog:
                Get MakeSQLDatabaseBackup to bOK

                If (bOK = True) Begin
                    Send Info_Box "The backup of the database was successful!"
                End
            End_Procedure

            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object

        Object oCurrentCollatingSequence_fm is a cRDCForm
            Set Size to 13 378
            Set Location to 135 76
            Set pbAutoEnable to True 
            Set Label to "MS-SQL collating:"
            
            Procedure UpdateCollatingSequence String sDatabase
                String sCollatingSequence
                // No database (a Filelist without SQL): the field is cleared, so no old value stays.
                If (sDatabase = "") Begin
                    Set Value to ""
                    Procedure_Return
                End
                Get SqlDatabaseCollationQuery of ghoDUF sDatabase True to sCollatingSequence
                Set Value to sCollatingSequence
            End_Procedure
            
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sDatabase sFileName

                // No query here: IsEnabled runs on every idle event. The collation is read by RefreshData and after a
                // change. (It connected to the server and queried on every idle event.)
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Get psDatabase of ghoDUF to sDatabase
                Function_Return (sDatabase <> "" and bExists = True)
            End_Function
    
        End_Object

        Object oCollatingSequenceHelp_btn is a cRDCButton
            Set Size to 12 50
            Set Location to 135 458
            Set Label to "Help"
            Set psImage to "ActionHelp.ico"
            Set psToolTip to "Help about using collations for a MS-SQL database."
        
            Procedure OnClick
                Runprogram Shell Background "https://learn.microsoft.com/en-us/sql/relational-databases/collations/collation-and-unicode-support?view=sql-server-ver16#SQL-collations"
            End_Procedure
        
        End_Object

        Object oSelectCollationHelp_btn is a cRDCButton
            Set Size to 12 124
            Set Location to 135 515
            Set Label to "How to select a MS-SQL Collation"
            Set psToolTip to "Help on selecting the Right SQL Collation"
            Set peAnchors to anNone
            Set psImage to "ActionHelp.ico"
        
            Procedure OnClick
                Runprogram Shell Background "https://learn.microsoft.com/en-us/sql/relational-databases/collations/collation-and-unicode-support?view=sql-server-ver16"
            End_Procedure
        
        End_Object  

        Object oCollatingSequence_fm is a cRDCForm
            Set Size to 13 378
            Set Location to 152 76
            Set Label to "Select new collating:" 
            Set psToolTip to "This is for MS-SQL only. The T-SQL script used for the background process is currently only adapted for MS-SQL."
            Set pbAutoEnable to True
            Set Entry_State to True
            Set Prompt_Object to (oSQLCollations(Self))
            Set Prompt_Button_Mode to PB_PromptOn
            
            Procedure Prompt
                tSQLCollation[] aCollations
                tSQLCollation Collation
                String sDriverID sCollation
                
                Get psDriverID of ghoDUF to sDriverID
                Get _SqlEnumerateDatabaseCollations of ghoDUF sDriverID to aCollations
                Get Value to Collation.sCollation
                Get psToolTip to Collation.sDescription
                Get ActivateSQLCollations Collation aCollations to Collation
                Get Value to sCollation
                If (sCollation <> "" and Collation.sCollation = "") Begin
                    Set psToolTip to ""
                    Procedure_Return
                End
                Set Value to Collation.sCollation
                Set psToolTip to Collation.sDescription
            End_Procedure
    
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object

        Object oCollatingSequence_btn is a cRDCButton
            Set Size to 12 50
            Set Location to 152 458
            Set Label to "Change"
            Set psImage to "ActionSort.ico"
            Set pbAutoEnable to True
            Set psToolTip to "To change the collating sequence for the SQL database to use a new collating sequence."

            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                String sDatabase sCurrentCollatingSequence sCollatingSequence sSteps
                Integer iRetval
                Boolean bOK bBackup
                tSQLLoggedInUser[] aUsers
                String sUsers
                Integer iUser
                
                Get Checked_State of oMakeBackup_cb to bBackup
                Get psDatabase of ghoDUF to sDatabase   
                Get Value of oCurrentCollatingSequence_fm to sCurrentCollatingSequence
                Get Value of oCollatingSequence_fm to sCollatingSequence              
                If (sCollatingSequence = "") Begin
                    Send Info_Box "Nope that won't work. You need to specify a collating sequence to change to, first."
                    Procedure_Return
                End
                If (sCurrentCollatingSequence = sCollatingSequence) Begin
                    Send Info_Box "Nope that won't work. The database is already using the selected collating sequence."
                    Procedure_Return
                End
                
                Get HoToStepsText bBackup to sSteps
                Get YesNo_Box ("Are you sure you want to change the collating sequence for database:" * sDatabase * "\nTo use the new collating sequence:\n" + sCollatingSequence + "\n\n" + sSteps + "\n\nStart making changes now?") to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return
                End
                Send StartStatusPanel "Checking that nobody is using the database..." "" -1
                
                Get IsDatabaseInUse of ghoDUF to bOK
                If (bOK = False) Begin
                    Send StopStatusPanel
                    Send Info_Box "Not all tables could be opened exclusivly, which indicates that somebody else is using the database. It is therefor not advised to try to change the collating sequence at current."
                    Procedure_Return
                End
                // IsDatabaseInUse sees embedded tables only: the sessions on the SQL database are listed, and the
                // user decides. This program's own sessions are among them.
                Get SqlUtilEnumerateLoggedInUsers of ghoDUF MSSQLDRV_ID sDatabase to aUsers
                If (SizeOfArray(aUsers) > 1) Begin
                    Move "" to sUsers
                    For iUser from 0 to (SizeOfArray(aUsers) - 1)
                        Move (sUsers + "\n" + aUsers[iUser].sUser * "(" + aUsers[iUser].sProgram + ")") to sUsers
                    Loop
                    Send StopStatusPanel
                    Get YesNo_Box ("These sessions are connected to database" * sDatabase + ":" + sUsers + "\n\nThe collation is changed in single-user mode: what they have not saved is rolled back. Continue?") to iRetval
                    If (iRetval <> MBR_Yes) Begin
                        Procedure_Return
                    End
                    Send StartStatusPanel "Changing the collating sequence..." "" -1
                End
                Set Title_Text of ghoStatusPanel to "Running SQL script to change collating sequence." 
                Set Message_Text of ghoStatusPanel to ("For database:" * String(sDatabase))

                // Note: For unknown reason the result variable cannot be trusted. Instead it is 
                //       checked if the collation was actually changed or not.
                Get SqlDatabaseCollationChange of ghoDUF sDatabase sCollatingSequence False bBackup True to bOK

                Get SqlDatabaseCollationQuery of ghoDUF sDatabase to sCurrentCollatingSequence                
                Move (sCurrentCollatingSequence = sCollatingSequence) to bOK
                Send StopStatusPanel
                Send UpdateCollatingSequence of (oCurrentCollatingSequence_fm(Self)) sDatabase
                If (bOK = True) Begin
                    Send Info_Box ("Success! The collating sequence was changed for database:" * sDatabase)
                End
                Else Begin
                    Send Info_Box "The change of collating sequence failed, and was *not* changed."
                End
            End_Procedure
            
            Function HoToStepsText Boolean bBackup Returns String
                String sSteps
                If (bBackup = False) Begin
                    Append sSteps "NOTE: You have not selected the 'Create Database Backup' checkbox. Ensure you have a full database backup before proceeding!" CS_CRLF CS_CRLF
                End
                Append sSteps "The SQL script will do the following:" CS_CRLF
                //
                Append sSteps "-- Step 1:  Create temporary table for variables" CS_CRLF
                Append sSteps "-- Step 2:  Backup database w todays date-time added to the name" CS_CRLF
                Append sSteps "-- Step 3:  Backup schema-bound objects" CS_CRLF 
                Append sSteps "-- Step 4:  Drop dependencies and schema-bound objects" CS_CRLF
                Append sSteps "-- Step 5:  Backup all index information" CS_CRLF 
                Append sSteps "-- Step 6:  Drop all dependent indexes and constraints" CS_CRLF
                Append sSteps "-- Step 7:  Backup/drop computed- and backup regular-columns" CS_CRLF
                Append sSteps "-- Step 8:  Drop other schema-bound objects" CS_CRLF
                Append sSteps "-- Step 9:  Change database collation" CS_CRLF 
                Append sSteps "-- Step 10: Recreate computed columns" CS_CRLF
                Append sSteps "-- Step 11: Recreate indexes and constraints" CS_CRLF 
                Append sSteps "-- Step 12: Recreate schema-bound objects" CS_CRLF 
                Append sSteps "-- Step 13: Cleanup temporary tables" CS_CRLF 
                Function_Return sSteps
            End_Function
                
            Function IsEnabled Returns Boolean
                String sCollation
                Get value of oCollatingSequence_fm to sCollation
                Function_Return (sCollation <> "")
            End_Function
    
        End_Object

        Object oMakeBackup_cb is a cRDCCheckBox
            Set Size to 12 55
            Set Location to 154 515
            Set Label to "Create database backup"
            Set psToolTip to "If checked, a database backup with a name that ends with todays date and time, is created in the standard SQL Server Backup folder, before attempting to change the database collation."
            Set Checked_State to True
            
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object

        Object oConnIDErrors_edt is a cDUFRichEdit
            Set Size to 74 77
            Set Location to 23 557
            Set Label to "Connection ID changes:"
            Set peAnchors to anTopLeftRight
            Set Label_Col_Offset to -5
        End_Object

        Object oConnIDErrors_fm is a cDUFNumForm
            Set Size to 12 34
            Set Location to 103 600
            Set Label to "Counter:"
            Set peAnchors to anTopRight
        End_Object

        Object oNumberOfSQLTables_fm is a cDUFNumForm
            Set Label to "Tot SQL tables:"
            Set Size to 12 34
            Set Location to 119 600
            Set peAnchors to anTopRight
        End_Object
    
    End_Object

    Object oCount_grp is a Group
        Set Size to 137 673
        Set Location to 231 12
        Set Label to "Filelist.cfg:"
        Set peAnchors to anAll

        Object oDatTables_edt is a cDUFRichEdit
            Set Size to 79 104
            Set Location to 29 6
            Set Label to "RootName *.Dat"
            Set psExtension to ".dat"
            Set peAnchors to anTopBottom
        End_Object

        Object oDatTables_fm is a cDUFNumForm
            Set Size to 12 34
            Set Location to 111 76
            Set Label to "Counter:"
            Set peAnchors to anBottomRight
            Procedure OnChange
                String sVal
                Get Value to sVal
                Set Value of oNoOfDatTables2_fm to sVal
            End_Procedure
        End_Object

        Object oAliasErrors_edt is a cDUFRichEdit
            Set Size to 79 104
            Set Location to 29 113
            Set Label to "Alias table errors"
            Set psExtension to ".int"
            Set peAnchors to anTopBottom
        End_Object

        Object oAliasErrors_fm is a cDUFNumForm
            Set Size to 12 34
            Set Location to 111 183
            Set Label to "Counter:"
            Set peAnchors to anBottomRight
        End_Object

        Object oRootNameIntTables_edt is a cDUFRichEdit
            Set Size to 79 104
            Set Location to 29 220
            Set Label to "RootName *.int"
            Set psExtension to ".int"
            Set peAnchors to anTopBottom
        End_Object

        Object oRootNameIntTables_fm is a cDUFNumForm
            Set Size to 12 34
            Set Location to 111 290
            Set Label to "Counter:"
            Set peAnchors to anBottomRight
        End_Object

        Object oOpenErrorTables_edt is a cDUFRichEdit
            Set Size to 79 125
            Set Location to 29 327
            Set Label to "Open table errors"
            Set peAnchors to anTopBottom
            Set psExtension to ".int"
        End_Object

        Object oOpenErrorTables_fm is a cDUFNumForm
            Set Size to 12 34
            Set Location to 111 418
            Set Label to "Counter:"
            Set peAnchors to anBottomRight
        End_Object

        Object oFileList_grp is a Group
            Set Size to 103 209
            Set Location to 25 459
            Set Label to "FileList.cfg counters:"
            Set peAnchors to anTopBottomRight

            Object oNoOfSystemTables_fm is a cDUFNumForm
                Set Size to 12 34
                Set Location to 10 142
                Set Label to "System tables"
            End_Object

            Object oNumberOfMasterFileListSQLTables_fm is a cDUFNumForm
                Set Size to 12 34
                Set Location to 32 142
                Set Label to "Master tables and SQL prefix:"
            End_Object
            
            Object oNoOfAliasSQLTables_fm is a cDUFNumForm
                Set Size to 12 34
                Set Location to 47 142
                Set Label to "Alias tables:"
            End_Object

            Object oNoOfDatTables2_fm is a cDUFNumForm
                Set Size to 12 34
                Set Location to 62 142
                Set Label to "RootName *.Dat tables:"
            End_Object
            
            Object oNumberOfFileListTables_fm is a cDUFNumForm
                Set Size to 12 34
                Set Location to 77 142
                Set Label to "Total Filelist tables:"
            End_Object

        End_Object
        
    End_Object

    Object oFixProblemsPreUpdate_grp is a Group
        Set Size to 64 340
        Set Location to 381 12
        Set Label to "Prepare for DUF Database Update Actions:"
        Set peAnchors to anBottomLeft

        // Will remove non Alias Filelist entries that:
        //   - Does not have a corresponding .Dat file, 
        Object oFixFileListErrors_btn is a cRDCButton
            Set Size to 32 61
            Set Location to 12 8
            Set Label to "1. Fix 'RootName .Dat errors'"
            Set peAnchors to anTopRight
            Set MultiLineState to True
            Set pbAutoEnable to True
            Set psToolTip to "The fix will spin through the Filelist and \n1. Removes non Alias entries that does not have a corresponding .Dat file.\nNote:This only applies to non Alias tables."
        
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Integer iRetval iCounter
                Get YesNo_Box "The fix will spin through the Filelist and \n1. Removes non Alias entries that does not have a corresponding .Dat file.\nNote:This only applies to non Alias tables.\n\nA backup copy of the Filelist.cfg file is made first.\n\nContinue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                
                Get FixFileListErrors to iCounter
                If (iCounter < 0) Begin
                    Send Stop_Box (BackupStoppedText(Self, "", 0))
                    Procedure_Return
                End
                If (iCounter <> 0) Begin
                    Send Info_Box ("Ready! Removed" * String(iCounter) * "Filelist.cfg entries that pointed to a .dat file but the .dat file was missing, and the table was not an Alias. See: Log file!")
                End
                Else Begin
                    Send Info_Box "Ready! No problems found."
                End
            End_Procedure
                          
            // Also for embedded tables: the Filelist is enough. (It needed DFConnId.ini, so it was off without SQL.)
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get Value of oFilelist_fm to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function

        End_Object

        Object oFixAliasProblems_btn is a cRDCButton
            Set Size to 32 61
            Set Location to 11 74
            Set Label to "2. Fix 'Alias table errors'"
            Set peAnchors to anTopRight
            Set MultiLineState to True
            Set pbAutoEnable to True
            Set psToolTip to "The fix will spin through Filelist.cfg and \n1. either add or remove driver prefixes for ALIAS rootnames, depending on the Master RootName\n2. Change all ALIAS table Descriptions to the ROOTNAME + 'ALIAS'"
        
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Integer iRetval iCounter
                Get YesNo_Box "The fix will spin through Filelist.cfg and \n1. either add or remove driver prefixes for ALIAS rootnames, depending on the Master RootName\n2. Change all ALIAS table Descriptions to the ROOTNAME + 'ALIAS'\n\nA backup copy of the Filelist.cfg file is made first.\n\nContinue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                
                Get FixFileListAliasProblems to iCounter
                If (iCounter < 0) Begin
                    Send Stop_Box (BackupStoppedText(Self, "", 0))
                    Procedure_Return
                End
                
                If (iCounter <> 0) Begin 
                    Send RefreshData
                    Send Info_Box ("Ready!" * String(iCounter) * "Alias problems fixed in Filelist.cfg. See Also: Logfile")
                End
                Else Begin
                    Send Info_Box "Ready! NO Alias problems found in Filelist.cfg."
                End
            End_Procedure
                          
            // Also for embedded tables: the Filelist is enough. (It needed DFConnId.ini, so it was off without SQL.)
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get Value of oFilelist_fm to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function

        End_Object

        Object oFixFileListSQLMissingTables_btn is a cRDCButton
            Set Size to 32 63
            Set Location to 12 139
            Set Label to "3. Make Filelist RootNames equal to SQL database"
            Set peAnchors to anTopRight
            Set MultiLineState to True
            Set pbAutoEnable to True
            Set psToolTip to "The fix will spin through Filelist.cfg and \n1. Remove all driver prefixes for Master tables that does NOT exist in the SQL Database\n2. OR Add driver prefix for Master filelist entries that are missing a driver prefix."
        
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Integer iRetval iCounter
                Get YesNo_Box "The fix will spin through Filelist.cfg and \n1. Remove all driver prefixes for tables that does NOT exist in the SQL Database\n2. OR Add driver prefix for Master filelist entries that are missing a driver prefix.\n\nA backup copy of the Filelist.cfg file is made first.\n\nContinue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                Get FixFileListSQLMissingTables to iCounter               
                If (iCounter = -2) Begin
                    Send Stop_Box "The list of the tables of the SQL database could not be read, so nothing was changed.\n\nCheck the connection: 'Tot SQL tables' shows how many tables were read. Then click 'Refresh Data!' and try again."
                    Procedure_Return
                End
                If (iCounter < 0) Begin
                    Send Stop_Box (BackupStoppedText(Self, "", 0))
                    Procedure_Return
                End
                If (iCounter <> 0) Begin
                    Send Info_Box ("Ready!" * String(iCounter) * "RootName entries in Filelist.cfg that pointed to SQL tables that doesn't exist in the SQL database, were adjusted.\n\nTop tip: If tables were added to the ''Open Table Errors', check the list 'RootName *.int' for a match. The odds are high that there is something wrong with the .int file.")
                End
                Else Begin
                    Send Info_Box "Ready! No problems found."    
                End
            End_Procedure
                          
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function

        End_Object

        Object oFixFileListOpenErrors_btn is a cRDCButton
            Set Size to 32 61
            Set Location to 12 206
            Set Label to "4. Fix Filelist: 'Open table errors'"
            Set peAnchors to anTopRight
            Set MultiLineState to True
            Set pbAutoEnable to True
            Set psToolTip to "The fix will spin through the Filelist and \n1. Try to fix or removes Non SQL entries for tables that cannot be opened."
        
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Integer iRetval iCounter iOpenErrors
                
                Get YesNo_Box "The fix will spin through the Filelist and: \n- Try to fix or remove Non SQL Filelist entries for tables that cannot be opened.\n\nA backup copy of the Filelist.cfg file is made first\n\nContinue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End

                Get FixFileListOpenErrors to iCounter
                If (iCounter < 0) Begin
                    Send Stop_Box (BackupStoppedText(Self, "", 0))
                    Procedure_Return
                End
                Get _CountFileListOpenErrors of ghoDUF to iOpenErrors
                
                If (iOpenErrors <> 0 and iCounter = 0) Begin 
                    Send RefreshData
                    Send Info_Box ("Ready! No Errors were fixed. NOTE:" * String(iOpenErrors) * "Open errors still exists and needs your attention. Please use the button '5. Recreate *.int files for Open table errors'.")
                End
                Else If (iOpenErrors <> 0 and iCounter <> 0) Begin
                    Send RefreshData
                    Send Info_Box ("Ready!" * String(iCounter) * "RootName entries were changed. See: Log file!")
                End
                // Every error fixed is no "no problems". (It said so.)
                Else If (iCounter <> 0) Begin
                    Send RefreshData
                    Send Info_Box ("Ready!" * String(iCounter) * "RootName entries were changed; no open errors are left. See: Log file!")
                End
                Else Begin
                    Send Info_Box "Ready! No problems found."
                End
            End_Procedure
                          
            // Also for embedded tables: the Filelist is enough. (It needed DFConnId.ini, so it was off without SQL.)
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get Value of oFilelist_fm to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function

        End_Object

        Object oFixIntFileError_btn is a cRDCButton
            Set Size to 32 61
            Set Location to 12 272
            Set Label to "5. Recreate *.int files for 'Open table errors'"
            Set peAnchors to anTopRight
            Set MultiLineState to True
            Set psToolTip to "This will try recreate the .int files listed in the 'Open Table Errors' list."
            Set pbAutoEnable to True
            
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Integer iRetval iCounter 
                Boolean bExtractRelations bRemoveUCol
                
                Get YesNo_Box "This will recreate the .int files listed in the 'Open Table Errors' list.\n\nContinue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                Get YesNo_Box "Would you like to extract relation ships from the current .int file, and add that info to the new .int file?" to iRetval
                Move (iRetval = MBR_Yes) to bExtractRelations
                Get YesNo_Box "Would you also like to remove the uppercased (U_) columns of these tables? Each table that has them is restructured on the SQL server." to iRetval
                Move (iRetval = MBR_Yes) to bRemoveUCol
                
                Get FixAllIntFileErrors bExtractRelations bRemoveUCol to iCounter
                If (psBackupError(Self) <> "") Begin
                    Send Stop_Box (BackupStoppedText(Self, ".int files recreated", iCounter))
                    Procedure_Return
                End
                If (iCounter > 0) Begin
                    Send Info_Box ("Ready! Update to:" * String(iCounter) * ".int files done.")
                End
                Else If (iCounter = 0) Begin
                    Send Info_Box "Ready! No problems found."
                End
                Else Begin
                    Send Info_Box "No 'Open Table Errors' found."
                End
            End_Procedure
            
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function

        End_Object

    End_Object

    Object oFixExtraProblems_grp is a Group
        Set Size to 64 323
        Set Location to 381 362
        Set Label to "More Database Actions:"
        Set peAnchors to anBottomLeftRight

        Object oExtract_Relationships_cb is a cRDCCheckBox
            Set Size to 10 50
            Set Location to 16 6
            Set Label to "Extract relationships"
            Set Checked_State to True   
            Set psToolTip to "Check this if you would like to extract relationships from the current .int file, and add that info to the new .int file."
            Set pbCreateInfoItem to False

            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object

        Object oRemoveUColumns_cb is a cRDCCheckBox
            Set Size to 10 50
            Set Location to 31 6
            Set Label to "Remove U_ columns"
            Set Checked_State to True
            Set psToolTip to "Check the box if you would like to Remove Uppercased Columns. It is strongly suggested to do so IF you have applied an General Insensitive collation like 'Latin1_General_CI_AS'. Please read the help about the subject first, by clicking the help button 'Remove Uppercased Columns'"
            Set pbCreateInfoItem to False

            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function
    
        End_Object

        Object oUColHelp_btn is a cRDCButton
            Set Size to 12 147
            Set Location to 45 5
            Set Label to "Why remove uppercased columns?"
            Set psToolTip to "Help on selecting the Right SQL Collation and removing uppercased columns"
            Set peAnchors to anNone
            Set psImage to "ActionHelp.ico"
        
            Procedure OnClick
                Runprogram Shell Background "https://docs.dataaccess.com/dataflexhelp/index.htm#t=mergedProjects%2FDevelopmentGuide%2FIgnore_Case_Support_and_Uppercase_Columns.htm"
            End_Procedure
        
        End_Object  

        Object oRecreateAllIntFiles_btn is a cRDCButton
            Set Size to 32 61
            Set Location to 11 91
            Set Label to "Recreate all *.int files"
            Set MultiLineState to True
            Set psToolTip to "This will recreate all .int files."
            Set psImage to "RecreateIntFiles.ico"
            Set piImageSize to 24
            Set pbAutoEnable to True
            
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Integer iRetval iCounter
                Boolean bExtractRelations bRemoveUCol
                String sDataPath sBackup
                
                Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
                Get vFolderFormat sDataPath to sDataPath
                Move (sDataPath + CS_BackupFolder) to sBackup
                Get YesNo_Box ("This will recreate all .int files. Relations from the current .int file will be preserved, if exists. A backup of .int files and the Filelist.cfg will be made in a new folder, named" * CS_BackupFolder * "and the date and time, in:\n" + String(sDataPath) + "\n\nContinue?") to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                Get Checked_State of oExtract_Relationships_cb to bExtractRelations
                Get Checked_State of oRemoveUColumns_cb        to bRemoveUCol
                
                Get RecreateAllIntFiles bExtractRelations bRemoveUCol to iCounter
                If (psBackupError(Self) <> "") Begin
                    Send Stop_Box (BackupStoppedText(Self, ".int files recreated", iCounter))
                    Procedure_Return
                End
                If (iCounter > 0) Begin
                    Send Info_Box ("Ready!" * String(iCounter) * ".int files recreated.")
                End
                Else If (iCounter = 0) Begin
                    Send Info_Box "Ready! No .int files found to recreate."
                End
            End_Procedure
            
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function

        End_Object

        Object oRemove_U_Columns_btn is a cRDCButton
            Set Size to 32 61
            Set Location to 11 159
            Set Label to "Remove uppercased columns"
            Set MultiLineState to True
            Set psToolTip to "This will remove Uppercased (U_) columns from all tables. This will also be done when the 'Recreate All .int files' button is clicked while the 'Remove U_ Columns' checkbox is selected, but with this button Only the columns are being removed."
            Set psImage to "TableColumnDelete.ico"
            Set piImageSize to 24
            Set pbAutoEnable to True
            
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Integer iRetval iCounter
                Boolean bBackup
                String sDataPath sBackup
                
                Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
                Get vFolderFormat sDataPath to sDataPath
                Move (sDataPath + CS_BackupFolder) to sBackup
                Get YesNo_Box ("This will remove all uppercased columns (U_ computed columns). A backup of .int files and the Filelist.cfg will be made in a new folder, named" * CS_BackupFolder * "and the date and time, in:\n" + String(sDataPath) + "\n\nContinue?") to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                Get YesNo_Box "Would you like to make a backup copy of the SQL database and .int files?" to iRetval
                Move (iRetval = MBR_Yes) to bBackup
                
                Get FindAllUColumnsFiles bBackup to iCounter
                If (psBackupError(Self) <> "") Begin
                    Send Stop_Box (BackupStoppedText(Self, "tables searched for uppercased columns", iCounter))
                    Procedure_Return
                End
                If (iCounter > 0) Begin
                    Send Info_Box ("Ready!" * "Uppercased columns for:" * String(iCounter) * "tables were removed.")
                End
                Else If (iCounter = 0) Begin
                    Send Info_Box "Ready! No changes made."
                End
            End_Procedure
            
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function

        End_Object

        Object oMoveUnusedDatFiles_btn is a cRDCButton
            Set Size to 32 61
            Set Location to 11 257
            Set Label to "Move *.Dat files to backup"
            Set MultiLineState to True
            Set psToolTip to "This will move all *.dat related files, that does not exist in the Filelist, to the workspace's '.\Data\Backup' folder."
            Set psImage to "MoveFiles.ico"
            Set piImageSize to 24
            Set pbAutoEnable to True
            
            // The work is DoClick; when it wrote errors to the log file, the log is offered after it.
            Procedure OnClick
                Send ResetLoggedErrors
                Send DoClick
                Send OfferErrorLog
            End_Procedure

            Procedure DoClick
                Integer iRetval iCounter 
                
                Get YesNo_Box "Move all *.dat related files that is not in the 'Rootname *.dat' list, to the workspace's '.\Data\Backup' folder.\n\nContinue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                
                Get MoveUnusedDatFileToBackupFolder CS_BackupFolder to iCounter
                
                If (iCounter = -1) Begin
                    Send Info_Box ("The backup folder:\n" + CS_BackupFolder + "\nCould not be created! No *.dat related files were moved.")
                End
                Else If (iCounter > 0) Begin
                    Send Info_Box ("Ready! Moved:" * String(iCounter) * ".dat related files to the folder" * CS_BackupFolder * "of the data folder.")
                End
                Else Begin
                    Send Info_Box "Ready! No files moved."
                End
            End_Procedure  
            
            // Also for embedded tables: the Filelist is enough. (It needed DFConnId.ini, so it was off without SQL.)
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get Value of oFilelist_fm to sFileName
                File_Exist sFileName bExists
                Function_Return bExists
            End_Function

        End_Object
        
    End_Object

    Object oLocalError_Info_Object is a cObject
        Property Handle phoOrgError_Object_Id
        Property Boolean pbErrorProcessingState
        Property Integer piErrNum
        Property Integer piErrLine
        Property String  psErrText
        
        Procedure OnCreate
            // The program's own handler is kept; a second OnCreate - ShowFileListData sends it again - finds this
            // object as the error object. (It kept this object as the "original" then.)
            If (Error_Object_Id <> Self) Begin
                Set phoOrgError_Object_Id to Error_Object_Id
            End
            Move Self to Error_Object_Id 
#IF (!@ > 210)
            Move Self to ghoErrorHandler
#ENDIF
        End_Procedure
        Send OnCreate

        Procedure Error_Report Integer iErrNum Integer iErrLine String sTxt
            String sErrText
            If (pbErrorProcessingState(Self) = True) ; 
                Procedure_Return 
            Set pbErrorProcessingState to True 
            If (num_arguments = 2 or sTxt = "") Begin
                Move (Trim(Error_Text(DESKTOP, iErrNum))) to sErrText
            End
            Else Begin
                Move sTxt to sErrText
            End
                
            Move Self to ghoErrorSource 
            Set piErrNum  to iErrNum
            Set piErrLine to iErrLine
            Set psErrText to sErrText  
            // Err, LastErr and ErrLine stay as the runtime set them, before it sent this message: the code that met
            // the error checks them. (They were cleared here, and that reached the caller: a failed Open or
            // restructure looked like a success - measured 2026-10-18.)
            Send WriteError of (Parent(Self)) ("Error:" * String(iErrNum) * "at line:" * String(iErrLine) * "Text:" * String(sErrText))
            Set pbErrorProcessingState to False 
        End_Procedure

        Function Extended_Error_Message Returns String
            Integer iErrNum iErrLine
            String sErrText
        
            Get piErrNum  to iErrNum
            Get piErrLine to iErrLine
            Get psErrText to sErrText
            Send WriteError ("Error:" * String(iErrNum) * "at line:" * String(iErrLine) * "Text:" * String(sErrText))
        
            Function_Return sErrText
        End_Function
        
        Procedure UnhandledErrorDisplay Integer iErrNum String sMessage
            Send WriteError ("Error:" * String(iErrNum) * "at line:" * String(iErrNum) * "Text:" * String(sMessage))
        End_Procedure            

        Procedure Ignore_Error Integer iError
        End_Procedure
        
        Procedure Trap_Error Integer iError
        End_Procedure
        
        Procedure Ignore_All
        End_Procedure
        
        Procedure Trap_All
        End_Procedure   
        
    End_Object
    
    // Dummy message that shows as delimiter in the Studio's Code Explorer:
    Procedure COMMON_MESSAGES
    End_Procedure

    Procedure ShowSQLTablesCount
        String[] asSQLTables
        Send UtilFillSQLTables of ghoDUF
        Get pasSQLDataTables   of ghoDUF to asSQLTables
        Set Value of oNumberOfSQLTables_fm to (String(SizeOfArray(asSQLTables))) 
    End_Procedure

    Procedure ShowFileListData
        Integer iCount
        String sDataPath
        tFilelist[] FileListArray
        Boolean bCancel
        
        Send OnCreate of oLocalError_Info_Object
        Get _UtilNumberOfFileListTables of ghoDUF to iCount
        Send StartStatusPanel "Filling Filelist Struct Array" ("Number of tables:" * String(iCount)) iCount
        
        // Note: Removes all cached files, else we don't open what we think we are.
        Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
        Send EraseCacheFiles
        
        Move False to bCancel
        Send UtilFillFileListStruct of ghoDUF (&bCancel)
        If (bCancel = True) Begin
            Procedure_Return
        End
        Get pFileListArray of ghoDUF to FileListArray
        Set Value of oNumberOfFileListTables_fm to (SizeOfArray(FileListArray))
        Send ListRootDatFiles
        Send ListRootIntFiles
        Send ListOpenErrorFiles
        
        Get _CountFileListMasterTables of ghoDUF to iCount
        Set Value of oNumberOfMasterFileListSQLTables_fm to iCount
        Get _CountFileListAliasTables of ghoDUF to iCount
        Set Value of oNoOfAliasSQLTables_fm to iCount
        Get _CountFilelistSystemTables of ghoDUF to iCount
        Set Value of oNoOfSystemTables_fm to iCount
        Get _CountFileListOpenErrors of ghoDUF to iCount
        Set Value of oOpenErrorTables_fm to iCount
        Send ListAliasErrorFiles
        
        Send StopStatusPanel
    End_Procedure

    // Removes the cache files (.cch) from each folder of the data path. (The whole data path was taken for one
    // folder name: with two folders no file was removed.)
    Procedure EraseCacheFiles
        String sDataPath sFolder
        Integer iPaths iPath

        Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
        Get CountOfPaths of (phoWorkspace(ghoApplication)) sDataPath to iPaths
        For iPath from 1 to iPaths
            Get PathAtIndex of (phoWorkspace(ghoApplication)) sDataPath iPath to sFolder
            If (Trim(sFolder) <> "") Begin
                Get vFolderFormat sFolder to sFolder
                EraseFile (sFolder + "*.cch")
            End
        Loop
    End_Procedure

    // Fills list of "RootName *.dat Files" with tables that are not Alias and does
    // not have a driver prefix or contains ".int".
    Procedure ListRootDatFiles
        Handle ho
        String[] asFiles
        Integer iSize iCount iCounter
        
        Move 0 to iCounter
        Move oDatTables_edt to ho
        Send Delete_Data of ho
        Get InUseDatFiles to asFiles
        If (SizeOfArray(asFiles) <> 0) Begin
            Move (SortArray(asFiles, Desktop, (RefFunc(DFSTRICMP)))) to asFiles
            Move (SizeOfArray(asFiles)) to iSize
            Decrement iSize
            For iCount from 0 to iSize
                Send AppendTextLn of ho asFiles[iCount]
                Increment iCounter
            Loop
        End
        Set Value of oDatTables_fm to iCounter
        Send Beginning_of_Data of ho
    End_Procedure

    Procedure ListAliasErrorFiles
        tFilelist[] FileListArray
        Integer iSize iCount
        Handle ho
        
        Move (oAliasErrors_edt(Self)) to ho
        Send Delete_Data of ho
        Set Value of oAliasErrors_fm to 0
        Get _CountFileListAliasErrors of ghoDUF to FileListArray
        Move (SizeOfArray(FileListArray)) to iSize
        If (iSize = 0) Begin
            Procedure_Return
        End
        Decrement iSize
        For iCount from 0 to iSize
            Send AppendTextLn of ho (FileListArray[iCount].sRootName * "(" + String(FileListArray[iCount].hTable) + ")")
        Loop
        Set Value of oAliasErrors_fm to (iSize + 1)
        Send Beginning_of_Data of ho
    End_Procedure

    Procedure ListRootIntFiles
        Handle ho
        tFilelist[] FilelistTables
        Boolean bIsIntTable
        Integer iSize iCount iCounter
        
        Move 0 to iCounter
        Get pFileListArray of ghoDUF to FileListTables
        Move oRootNameIntTables_edt to ho
        Send Delete_Data of ho
        Move (SizeOfArray(FilelistTables)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Get _IsIntEntry of ghoDUF FilelistTables[iCount].hTable to bIsIntTable
            If (bIsIntTable = True) Begin
                Send AppendTextLn of ho FilelistTables[iCount].sRootName
                Increment iCounter
            End
        Loop
        Set Value of oRootNameIntTables_fm to iCounter
        Send Beginning_of_Data of ho
    End_Procedure

    Procedure ListOpenErrorFiles
        Handle ho hTable
        tFilelist[] FilelistTables
        tFilelist[] ErrorFilesArray
        Integer iSize iCount
        String sVal
        
        Get pFileListArray of ghoDUF to FileListTables
        Move oOpenErrorTables_edt to ho
        Send Delete_Data of ho
        Move (SizeOfArray(FilelistTables)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            If (FilelistTables[iCount].bErrorOpening = True) Begin
                Move (FilelistTables[iCount].sRootName * ("(" + String(FilelistTables[iCount].hTable) + ")")) to sVal
                Send AppendTextLn of ho sVal
                Move FilelistTables[iCount] to ErrorFilesArray[SizeOfArray(ErrorFilesArray)]
            End
        Loop
        Set Value of oOpenErrorTables_fm to (SizeOfArray(ErrorFilesArray))
        Set pErrorTables of ghoDUF to ErrorFilesArray
        Send Beginning_of_Data of ho
    End_Procedure

    // *** The repair work: oFilelistRepair (cDUFFilelistRepair.pkg) does it; the buttons' messages are relayed ***
    Object oFilelistRepair is a cDUFFilelistRepair
    End_Object

    Function FixFileListErrors Returns Integer
        Integer iRetval
        Get FixFileListErrors of (oFilelistRepair(Self)) to iRetval
        Function_Return iRetval
    End_Function

    Function FixFileListAliasProblems Returns Integer
        Integer iRetval
        Get FixFileListAliasProblems of (oFilelistRepair(Self)) to iRetval
        Function_Return iRetval
    End_Function

    Function FixFileListSQLMissingTables Returns Integer
        Integer iRetval
        Get FixFileListSQLMissingTables of (oFilelistRepair(Self)) to iRetval
        Function_Return iRetval
    End_Function

    Function FixFileListOpenErrors Returns Integer
        Integer iRetval
        Get FixFileListOpenErrors of (oFilelistRepair(Self)) to iRetval
        Function_Return iRetval
    End_Function

    Function FixAllIntFileErrors Boolean bExtractRelations Boolean bRemoveUCol Returns Integer
        Integer iRetval
        Get FixAllIntFileErrors of (oFilelistRepair(Self)) bExtractRelations bRemoveUCol to iRetval
        Function_Return iRetval
    End_Function

    Function RecreateAllIntFiles Boolean bExtractRelations Boolean bRemoveUCol Returns Integer
        Integer iRetval
        Get RecreateAllIntFiles of (oFilelistRepair(Self)) bExtractRelations bRemoveUCol to iRetval
        Function_Return iRetval
    End_Function

    Function FindAllUColumnsFiles Boolean bBackup Returns Integer
        Integer iRetval
        Get FindAllUColumnsFiles of (oFilelistRepair(Self)) bBackup to iRetval
        Function_Return iRetval
    End_Function

    Function BackupStoppedText String sDone Integer iDone Returns String
        String sRetval
        Get BackupStoppedText of (oFilelistRepair(Self)) sDone iDone to sRetval
        Function_Return sRetval
    End_Function

    Function MoveUnusedDatFileToBackupFolder String sBackupFolder Returns Integer
        Integer iRetval
        Get MoveUnusedDatFileToBackupFolder of (oFilelistRepair(Self)) sBackupFolder to iRetval
        Function_Return iRetval
    End_Function

    Function InUseDatFiles Returns String[]
        String[] asRetval
        Get InUseDatFiles of (oFilelistRepair(Self)) to asRetval
        Function_Return asRetval
    End_Function

    // Helper procedures for status panel/progress bar
    Procedure StartStatusPanel String sMessage String sMessage2 Integer iSize
        If (sMessage = "") Begin
            Move "The Database Update Framework" to sMessage
        End
        Send StartStatusPanel of ghoStatusPanel sMessage sMessage2 iSize
        Set Progress_Bar_Overall_Visible_State of ghoStatusPanel to False
    End_Procedure
    
    Procedure StopStatusPanel
        Send Stop_StatusPanel of ghoStatusPanel 
        Send Reset_StatusPanel of ghoStatusPanel
    End_Procedure

    Procedure UpdateStatusPanel String sMessage
        Send Update_StatusPanel of ghoStatusPanel sMessage
    End_Procedure
    
    Procedure ResetLoggedErrors
        Set piLoggedErrors to 0
    End_Procedure

    // When errors were written to the log file during the run, a question offers to show it.
    Procedure OfferErrorLog
        Integer iErrors iRetval
        String sLogFile

        Get piLoggedErrors to iErrors
        Set piLoggedErrors to 0
        If (iErrors = 0) Begin
            Procedure_Return
        End
        // Closed first, so that all that was written is in the file.
        Send CloseLogFile
        Get Value of oLogFile_fm to sLogFile
        Get YesNo_Box (String(iErrors) * "error message(s) were written to the log file:\n" + sLogFile + "\n\nWould you like to see the log file?") to iRetval
        If (iRetval = MBR_Yes) Begin
            Runprogram Shell Background sLogFile
        End
    End_Procedure

    // F5: Refresh Data, with the log offered as after a button.
    Procedure RefreshDataByKey
        Send ResetLoggedErrors
        Send RefreshData
        Send OfferErrorLog
    End_Procedure

    Procedure WriteError String sErrorText
        Integer iCh
        Boolean bOpenLogFile
        
        Set piLoggedErrors to (piLoggedErrors(Self) + 1)
        Get pbOpenLogFile to bOpenLogFile
        If (bOpenLogFile = False) Begin
            Send OpenLogFile
        End
        Get piChannel to iCh
        If (iCh < 0) Begin
            Procedure_Return
        End
        Writeln channel iCh sErrorText 
        // Flush_Output is a DataFlex 20 command.
        #IF (!@ > 191)
            Flush_Output channel iCh
        #ENDIF
    End_Procedure

    Procedure OpenLogFile
        String sLogFile sTimeStamp sFilelist
        Integer iCh
        Boolean bOpenLogFile
        
        Get Value of oFilelist_fm to sFilelist
        If (sFilelist = "") Begin
            Procedure_Return
        End
        Get pbOpenLogFile to bOpenLogFile
        If (bOpenLogFile = True) Begin
            Procedure_Return
        End
        Get Value of oLogFile_fm to sLogFile
        Get piChannel to iCh
        If (iCh >= 0) Begin
            Send Seq_Close_Channel iCh
        End
        Get Seq_Append_Output_Channel sLogFile to iCh
        If (iCh < 0) Begin
            Error DFERR_PROGRAM ("No free channel to write logfile:" * String(sLogFile))
            Procedure_Return
        End
        Set piChannel to iCh
        Set pbOpenLogFile to True
        Move (CurrentDateTime()) to sTimeStamp  
        Writeln channel iCh ""
        Writeln channel iCh "Log file Opened date/time: " (String(sTimeStamp))
    End_Procedure

    Procedure CloseLogFile
        String sTimeStamp
        Integer iCh
        Boolean bOpenLogFile
        
        Get pbOpenLogFile to bOpenLogFile
        If (bOpenLogFile = False) Begin
            Procedure_Return
        End

        Get piChannel to iCh  
        If (iCh >= 0) Begin
            Move (CurrentDateTime()) to sTimeStamp
            Writeln channel iCh "Log file closed date/time: " (String(sTimeStamp))
            // Flush_Output is a DataFlex 20 command; Close_Output writes what is left on every version.
            #IF (!@ > 191)
                Flush_Output channel iCh
            #ENDIF
            Close_Output channel iCh
            Send Seq_Close_Channel iCh
        End
        Set piChannel to -1  
        Set pbOpenLogFile to False
    End_Procedure
                
    Procedure WriteToLogFile Boolean bIsAlias Handle hTable String sLogicalNameOrg String sRootNameOrg String sRootNameNew String sDisplayNameOrg String sDisplayNameNew
        Integer iCh

        Send OpenLogFile
        Get piChannel to iCh
        Writeln channel iCh "File Number       = " hTable
        Writeln channel iCh "Alias RootName    = " sRootNameOrg
        If (sRootNameNew <> "") Begin
            Writeln channel iCh "NEW RootName      = " sRootNameNew
        End
        Writeln channel iCh "Alias LogicalName = " sLogicalNameOrg
        Writeln channel iCh "Alias DisplayName = " sDisplayNameOrg 
        If (sDisplayNameNew <> "") Begin
            Writeln channel iCh "NEW DisplayName   = " sDisplayNameNew
        End
        Writeln channel iCh ""
        Send CloseLogFile            
    End_Procedure   
    
    Procedure RefreshData
        String sFileList sDatabase
        Get psFileList to sFileList
        If (sFileList = "") Begin
            Procedure_Return
        End
        Send ShowSQLTablesCount 
        Get psDatabase of ghoDUF to sDatabase
        Send UpdateCollatingSequence of (oCurrentCollatingSequence_fm(oSQL_grp(Self))) sDatabase
        // This is to make sure the uppercase support for the driver is set properly.
        Send SetupIgnoreUcaseSupport
        Send ShowFileListData
    End_Procedure  
    
    Procedure SetupIgnoreUcaseSupport
        String sDriver
        Integer iDriver
        Get psDriverID of ghoDUF to sDriver
        // Not for embedded tables, nor for a driver that could not be loaded (driver 0).
        If (sDriver = DATAFLEX_ID or sDriver = "") Begin
            Procedure_Return
        End
        Get DriverIndex of ghoDUF sDriver to iDriver
        If (iDriver = 0) Begin
            Procedure_Return
        End
        // Note: If Ignore_Ucase_Support is set to false, the Connectivity Kit will 
        //       behave the same as earlier driver versions.
        //       This means that "U_" columns will be kept during a restructure.
        Set_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to True
    End_Procedure
    
    Procedure ClearData
        // The log file of the Filelist before is closed: its channel was dropped open, and the file stayed locked.
        Send CloseLogFile
        Set psConnId to ""
        Set psConnIdFile to ""
        Set psBackupFolder to ""
        Set pbOpenLogFile to False
        Set piChannel to -1  
        Set psDriverID of ghoDUF to DATAFLEX_ID
        Set psDatabase of ghoDUF to ""
        Broadcast Recursive Send ClearData of (oFilelistFixerView(Self))
    End_Procedure  
    
    // To automatically maximize the view size.
    // Way more complicated than it should be!
    Procedure Page Integer iPageObject
        Forward Send Page iPageObject
        Set View_Mode to Viewmode_Zoom 
        Set Maximize_Icon to False     
        Set Minimize_Icon to False     
        Set Sysmenu_Icon to False
        // This is the crucial bit:
        Set Border_Style of (Client_Id(ghoCommandBars)) to Border_None
    End_Procedure

    Object oLogFile_fm is a cRDCForm
        Set Size to 12 382
        Set Location to 29 82
        Set Enabled_State to False
        Set Label to "Log file:"
        Set peAnchors to anNone

        Procedure Page Integer iPageObject
            String sFileName sHomePath
            Forward Send Page iPageObject
            Get psHome of (phoWorkspace(ghoApplication)) to sHomePath
            Move CS_ReportFileName to sFileName
            Set Value to (sHomePath + sFileName)
        End_Procedure
        
    End_Object
    Object oOpenLogFile_btn is a cRDCButton
        Set Size to 12 50
        Set Location to 29 470
        Set Label to "View"
        Set peAnchors to anNone
        Set psImage to "View.ico"
        Set pbAutoEnable to True
        Set psToolTip to "View the content of the log file."
    
        Procedure OnClick
            String sFileName
            Boolean bExists
            Get Value of oLogFile_fm to sFileName
            File_Exist sFileName bExists
            If (bExists = False) Begin
                Send Info_Box ("The log file hasn't been created yet:\n" + sFileName)
                Procedure_Return
            End
            Runprogram Shell Background sFileName
        End_Procedure
    
        Function IsEnabled Returns Boolean
            Boolean bExists
            String sFileName
            Get psConnIdFile to sFileName
            File_Exist sFileName bExists
            Function_Return bExists
        End_Function

    End_Object  

    On_Key kClear Send RefreshDataByKey
End_Object    
