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

// Just to get a shorter handle name
Global_Variable Handle ghoDUF 
Move ghoDbUpdateFunctionLibrary to ghoDUF

Define CS_ReportFileName for "FileListFixes.txt"
Define CS_BackupFolder   for "Backup"
Define CS_CRLF           for (Character(13) + Character(10))

Register_Object oConnIDErrors_edt
Register_Function BackupStoppedText String sDone Integer iDone Returns String

Struct tBlock
    Integer iFieldNumber
    String[] asLines    
End_Struct

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
            String sFileList sPath sHome sChar
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
                    Get ChangeFilelistPathing of ghoApplication sFileList to bOK
                    Send UpdateDriverIniFile of oDriver_fm
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
        
        Procedure OnClick
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
                EraseFile (sDataPath + "\*.cch")
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
        
        Procedure OnClick
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
                    Send AppendTextLn ("connection=" + String(Connections[0].sString))
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
                Move (Pos(".", sDriver)) to iPos
                Move (Left(sDriver, iPos -1)) to sFileName
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
            
            Procedure OnClick
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
                If (sDatabase = "") Begin
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

            Procedure OnClick
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
        
            Procedure OnClick
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
                          
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
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
        
            Procedure OnClick
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
                          
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
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
        
            Procedure OnClick
                Integer iRetval iCounter
                Get YesNo_Box "The fix will spin through Filelist.cfg and \n1. Remove all driver prefixes for tables that does NOT exist in the SQL Database\n2. OR Add driver prefix for Master filelist entries that are missing a driver prefix.\n\nA backup copy of the Filelist.cfg file is made first.\n\nContinue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                Get FixFileListSQLMissingTables to iCounter               
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
        
            Procedure OnClick
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
                          
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
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
            
            Procedure OnClick
                Integer iRetval iCounter 
                Boolean bExtractRelations
                
                Get YesNo_Box "This will recreate the .int files listed in the 'Open Table Errors' list.\n\nContinue?" to iRetval
                If (iRetval <> MBR_Yes) Begin
                    Procedure_Return    
                End
                Get YesNo_Box "Would you like to extract relation ships from the current .int file, and add that info to the new .int file?" to iRetval
                Move (iRetval = MBR_Yes) to bExtractRelations
                
                Get FixAllIntFileErrors bExtractRelations to iCounter
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
            
            Procedure OnClick
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
            
            Procedure OnClick
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
            
            Procedure OnClick
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
            
            Function IsEnabled Returns Boolean
                Boolean bExists
                String sFileName
                Get psConnIdFile to sFileName
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
            Move False to Err
            Move 0 to LastErr
            Move 0 to ErrLine
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
        EraseFile (sDataPath + "\*.cch") 
        
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

    Function FixFileListErrors Returns Integer
        Integer hTable iSize iCount iCh iCounter
        tFilelist[] FileListArray
        String sRootName sLogicalName sDisplayName sFileList
        Boolean bIsAlias bIsDatEntry bExists bOK bCancel
        
        Move 0 to iCounter 
        Move 0 to hTable

        Get pFileListArray of ghoDUF to FileListArray
        If (SizeOfArray(FileListArray) = 0) Begin
            Send RefreshData
            Get pFileListArray of ghoDUF to FileListArray
        End    
        Send OpenLogFile
        Get piChannel to iCh
        Move (SizeOfArray(FileListArray)) to iSize
        Send StartStatusPanel "Fixing Filelist RootName .dat Errors" "" iSize
        Get psFileList of (phoWorkspace(ghoApplication)) to sFileList
        Get BackupAnyFileToBackupFolder sFileList to bOK
        // Nothing is changed without the backup copy that the question promised.
        If (bOK = False) Begin
            Send CloseLogFile
            Send StopStatusPanel
            Function_Return -1
        End
        
        Decrement iSize
        For iCount from 0 to iSize
            Move FileListArray[iCount].hTable to hTable 
            Send UpdateStatusPanel FileListArray[iCount].sLogicalName
            // 50 is FlexErrs.
            If (FileListArray[iCount].bIsAlias = False and hTable <> 50) Begin
                Get _IsDatEntry of ghoDUF hTable to bIsDatEntry
                If (bIsDatEntry = True) Begin 
                    Get _DatFileExists of ghoDUF hTable to bExists
                    If (bExists = False) Begin
                        Set_Attribute DF_FILE_ROOT_NAME    of hTable to ""
                        Set_Attribute DF_FILE_LOGICAL_NAME of hTable to ""
                        Set_Attribute DF_FILE_DISPLAY_NAME of hTable to ""
                        Writeln channel iCh "File Number     = " hTable
                        Writeln channel iCh "RootName        = " FileListArray[iCount].sRootName
                        Writeln channel iCh "LogicalName     = " FileListArray[iCount].sLogicalName
                        Writeln channel iCh "DisplayName     = " FileListArray[iCount].sDisplayName
                        Writeln channel iCh "Removed Filelist.cfg entry that was not an Alias file, pointed to a .dat file but the .Dat file was missing."
                        Writeln channel iCh ""
                        Increment iCounter
                    End
                End
            End 
            Get Check_StatusPanel of ghoStatusPanel to bCancel
            If (bCancel = True) Begin
                // Cancelled: the clean-up below runs, and the answer is what was done. (It returned at once.)
                Break
            End
        Loop
        
        Send CloseLogFile
        Send StopStatusPanel
        If (iCounter <> 0) Begin
            Send RefreshData
        End     
        Function_Return iCounter
    End_Function

    Function FixFileListAliasProblems Returns Integer
        Integer iCounter iIntError iSize
        Handle hTable hMasterTable
        String sLogicalNameOrg sRootNameOrg sDisplayNameOrg sFileList
        String sNoDriverRootname sRootNameNew sLogicalNameNew sDisplayNameNew sMasterRootName sMasterDriver
        Boolean bIsAlias bIsIntTable bIsAliasSQL bIsMasterSQL bOK bCancel
        tFilelist[] FilelistArray
        
        Get _CountFileListAliasErrors of ghoDUF to FileListArray
        Move (SizeOfArray(FileListArray)) to iSize
        If (iSize = 0) Begin
            Function_Return 0
        End
        Get psFileList of (phoWorkspace(ghoApplication)) to sFileList
        Get BackupAnyFileToBackupFolder sFileList to bOK
        // Nothing is changed without the backup copy that the question promised.
        If (bOK = False) Begin
            Function_Return -1
        End
                
        Send StartStatusPanel "Fixing Alias Filelist Errors" "" iSize
        Move 0 to iCounter 
        Move 0 to hTable

        Repeat
            Get_Attribute DF_FILE_NEXT_USED of hTable to hTable
            // Table 50 is FlexErrs
            If (hTable <> 0 and hTable <> 50) Begin
                Get_Attribute DF_FILE_ROOT_NAME    of hTable to sRootNameOrg
                Get_Attribute DF_FILE_LOGICAL_NAME of hTable to sLogicalNameOrg
                Send UpdateStatusPanel sLogicalNameOrg
                Get_Attribute DF_FILE_DISPLAY_NAME of hTable to sDisplayNameOrg 
                Get _TableNameOnly of ghoDUF sRootNameOrg to sNoDriverRootname 
                Get _IsAliasTable of ghoDUF hTable to bIsAlias  
                If (bIsAlias = True) Begin
                    Get _IsIntEntry of ghoDUF hTable to bIsIntTable
                    Get UtilAliasToMasterTableHandle of ghoDUF hTable to hMasterTable
                    If (hMasterTable <> 0) Begin
                        Get _IsSQLEntry of ghoDUF hTable       to bIsAliasSQL
                        Get _IsSQLEntry of ghoDUF hMasterTable to bIsMasterSQL
                        Get _FindAliasEntryError of ghoDUF hTable to iIntError
                        // The driver of the master table's root name, else the driver of the library's connection.
                        // (This used to be MSSQLDRV always, also on a DB2 or ODBC workspace.)
                        Get_Attribute DF_FILE_ROOT_NAME of hMasterTable to sMasterRootName
                        Move "" to sMasterDriver
                        Get _RemoveDriverFromRootName of ghoDUF sMasterRootName (&sMasterDriver) to sMasterRootName
                        If (sMasterDriver = "") Begin
                            Get psDriverID of ghoDUF to sMasterDriver
                        End
                        If (iIntError = 1) Begin
                            If ((bIsAliasSQL = False and bIsIntTable = False) and bIsMasterSQL = True) Begin
                                Move (sMasterDriver + ":" + sNoDriverRootname) to sRootNameNew
                                Set_Attribute DF_FILE_ROOT_NAME of hTable to sRootNameNew
                            End
                            Else If ((bIsAliasSQL = True or bIsIntTable = True) and bIsMasterSQL = False) Begin
                                Set_Attribute DF_FILE_ROOT_NAME of hTable to sNoDriverRootname
                            End 
                            Else If ((bIsAliasSQL = True or bIsIntTable = True) and bIsMasterSQL = True) Begin
                                // The name without the driver or ".int" it may have, so that no second prefix is put in front.
                                Move (sMasterDriver + ":" + sNoDriverRootname) to sRootNameNew
                                Set_Attribute DF_FILE_ROOT_NAME of hTable to sRootNameNew                                
                            End
                            Move (sNoDriverRootname * "ALIAS") to sDisplayNameNew
                            Set_Attribute DF_FILE_DISPLAY_NAME of hTable to sDisplayNameNew
                            Send WriteToLogFile True hTable sLogicalNameOrg sRootNameOrg sRootNameNew sDisplayNameOrg sDisplayNameNew
                            Increment iCounter
                        End
                    End
                    
                    Else If (hMasterTable = 0) Begin
                        Set_Attribute DF_FILE_ROOT_NAME    of hTable to ""
                        Set_Attribute DF_FILE_LOGICAL_NAME of hTable to ""
                        Set_Attribute DF_FILE_DISPLAY_NAME of hTable to ""
                        Send WriteToLogFile True hTable sLogicalNameOrg sRootNameOrg "" sDisplayNameOrg "Alias Filelist entry removed: it has no master table."
                        Increment iCounter
                    End
                    // An entry that was removed gets no display name back. (It did, and was counted twice.)
                    Get_Attribute DF_FILE_DISPLAY_NAME of hTable to sDisplayNameNew
                    Get_Attribute DF_FILE_LOGICAL_NAME of hTable to sLogicalNameNew
                    If (hMasterTable <> 0 and not(Lowercase(sDisplayNameNew) contains "alias")) Begin
                        Move (sLogicalNameNew * "(" + sNoDriverRootname * "ALIAS)") to sDisplayNameNew
                        Set_Attribute DF_FILE_DISPLAY_NAME of hTable to sDisplayNameNew
                        Send WriteToLogFile True hTable sLogicalNameOrg sRootNameOrg sRootNameNew sDisplayNameOrg sDisplayNameNew
                        Increment iCounter
                    End
                End
                // Adjust DisplayName?
                If (bIsAlias = False and Lowercase(sDisplayNameOrg) contains "alias") Begin
                    Get RemoveDisplayNameAlias hTable sDisplayNameOrg to sDisplayNameNew
                    Send WriteToLogFile False hTable sLogicalNameOrg sRootNameOrg sRootNameNew sDisplayNameOrg sDisplayNameNew
                    Increment iCounter
                End
            End
            Get Check_StatusPanel of ghoStatusPanel to bCancel
            If (bCancel = True) Begin
                // Cancelled: the clean-up below runs, and the answer is what was done. (It returned at once.)
                Break
            End
        Until (hTable = 0)
        Send StopStatusPanel
        Function_Return iCounter
    End_Function

    Function FixFileListSQLMissingTables Returns Integer
        Integer hTable iSize iCount iItem iCh iCounter
        String[] asSQLTables
        tFilelist[] FileListArray
        String sNoDriverRootname sDriver sRootName sRootNameNew sDatabase sLogicalName sDisplayName sFileList
        Boolean bIsIntTable bExists bOK bCancel
        
        Move 0 to iCounter 
        Move 0 to hTable
        Get pasSQLDataTables of ghoDUF to asSQLTables
        If (SizeOfArray(asSQLTables) = 0) Begin
            Send UtilFillSQLTables of ghoDUF
            Get pasSQLDataTables of ghoDUF to asSQLTables
        End
        Get pFileListArray of ghoDUF to FileListArray
        If (SizeOfArray(FileListArray) = 0) Begin
            Send RefreshData
            Get pFileListArray of ghoDUF to FileListArray
        End    
        
        Send OpenLogFile
        Get piChannel to iCh
        Get psDatabase of ghoDUF to sDatabase
        Writeln channel iCh ("Adjustment of RootNames for tables that exists in the SQL database:" * String(sDatabase))
        
        Move (SizeOfArray(FileListArray)) to iSize 
        Get psFileList of (phoWorkspace(ghoApplication)) to sFileList
        Get BackupAnyFileToBackupFolder sFileList to bOK
        // Nothing is changed without the backup copy that the question promised.
        If (bOK = False) Begin
            Send CloseLogFile
            Function_Return -1
        End
        
        Send StartStatusPanel "Enumerating SQL Tables" "" iSize
        Decrement iSize
        
        For iCount from 0 to iSize
            Move FileListArray[iCount].hTable to hTable
            Move FileListArray[iCount].sRootName to sRootName
            Get _RemoveDriverFromRootName of ghoDUF sRootName (&sDriver) to sNoDriverRootname
            Send UpdateStatusPanel sNoDriverRootname
            Get _IsIntEntry of ghoDUF hTable to bIsIntTable
            // 50 is FlexErrs.
            If (hTable <> 50) Begin
                Move (SearchArray(sNoDriverRootname, asSQLTables, Desktop , (RefFunc(DFSTRICMP)))) to iItem
                // If the Table name in Filelist.cfg points to an SQL table, but that table doesn't
                // exist in the SQL database, remove the driver prefix from Filelist.cfg.
                If (iItem = -1) Begin
                    Move sNoDriverRootname to sRootNameNew
                End
                Else Begin
                    Get _IntFileExists of ghoDUF hTable to bExists
                    If (bExists = True) Begin
                        // The driver the root name had, else the driver of the library's connection - the one the
                        // list of SQL tables came from. (This used to be MSSQLDRV always.)
                        If (sDriver = "") Begin
                            Get psDriverID of ghoDUF to sDriver
                        End
                        Move (sDriver + ":" + sNoDriverRootname) to sRootNameNew
                    End
                    Else Begin
                        // If the .int file wasn't found, we will not make a filelist change.
                        Move sNoDriverRootname to sRootNameNew
                    End
                End
                If (sRootName <> sRootNameNew) Begin
                    Set_Attribute DF_FILE_ROOT_NAME of hTable to sRootNameNew
                    Writeln channel iCh "File Number     = " hTable
                    Writeln channel iCh "RootName        = " FileListArray[iCount].sRootName
                    Writeln channel iCh "NEW RootName    = " sRootNameNew
                    Writeln channel iCh "LogicalName     = " FileListArray[iCount].sLogicalName
                    Writeln channel iCh "DisplayName     = " FileListArray[iCount].sDisplayName
                    Writeln channel iCh "RootName Error fixed!"
                    Writeln channel iCh ""
                    Increment iCounter
                End
            End
            Get Check_StatusPanel of ghoStatusPanel to bCancel
            If (bCancel = True) Begin
                // Cancelled: the clean-up below runs, and the answer is what was done. (It returned at once.)
                Break
            End
        Loop

        Send CloseLogFile
        Send StopStatusPanel
        If (iCounter <> 0) Begin
            Send RefreshData
        End
        Function_Return iCounter
    End_Function

    Function FixFileListOpenErrors Returns Integer        
        Integer hTable iSize iCount iCh iCounter
        tFilelist[] FileListArray
        String sNoDriverRootname sDriver sRootName sDatabase sLogicalName sDisplayName sDataPath sFileList
        Boolean bChange bFirst bIsSQLTable bIsIntTable bOK bCancel
        
        Move False to bFirst
        Move 0 to iCounter 
        Move 0 to hTable
        Get pFileListArray of ghoDUF to FileListArray
        If (SizeOfArray(FileListArray) = 0) Begin
            Send RefreshData
            Get pFileListArray of ghoDUF to FileListArray
        End    
        
        Send StartStatusPanel "Fixing Filelist Open Errors" "" iSize
        Get psFileList of (phoWorkspace(ghoApplication)) to sFileList
        Get BackupAnyFileToBackupFolder sFileList to bOK
        // Nothing is changed without the backup copy that the question promised.
        If (bOK = False) Begin
            Send StopStatusPanel
            Function_Return -1
        End
        Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
        Send OpenLogFile
        Get piChannel to iCh
        Get psDatabase of ghoDUF to sDatabase
        Move (SizeOfArray(FileListArray)) to iSize
        Decrement iSize
        
        For iCount from 0 to iSize
            Move False to bChange
            Move FileListArray[iCount].hTable to hTable 
            Send UpdateStatusPanel FileListArray[iCount].sLogicalName
            // Table 50 is FlexErrs
            If (FileListArray[iCount].bErrorOpening = True and hTable <> 50) Begin
                Get _IsSQLEntry of ghoDUF hTable to bIsSQLTable
                Get _IsIntEntry of ghoDUF hTable to bIsIntTable
                If (bIsSQLTable = True and bIsIntTable = True) Begin
                    Move FileListArray[iCount].sRootName to sRootName 
                    Get _RemoveDriverFromRootName of ghoDUF sRootName (&sDriver) to sNoDriverRootname
                    If (sRootName <> (sDriver + ":" + sNoDriverRootname) or (sRootName contains ":" and Lowercase(sRootName) contains ".int")) Begin
                        Set_Attribute DF_FILE_ROOT_NAME of hTable to (sDriver + ":" + sNoDriverRootname)
                        Writeln channel iCh "File Number     = " hTable
                        Writeln channel iCh "RootName        = " FileListArray[iCount].sRootName
                        Writeln channel iCh "NEW RootName    = " (sDriver + ":" + sNoDriverRootname)
                        Increment iCounter
                    End
                End
                Else If (bIsSQLTable = False) Begin
                    Set_Attribute DF_FILE_ROOT_NAME    of hTable to ""
                    Set_Attribute DF_FILE_LOGICAL_NAME of hTable to ""
                    Set_Attribute DF_FILE_DISPLAY_NAME of hTable to ""
                    If (bFirst = False) Begin
                        Writeln channel iCh "Removed Filelist.cfg entries for tables that could not be opened."
                        Move True to bFirst
                    End
                    Writeln channel iCh "File Number     = " hTable
                    Writeln channel iCh "RootName        = " FileListArray[iCount].sRootName
                    Writeln channel iCh "LogicalName     = " FileListArray[iCount].sLogicalName
                    Writeln channel iCh "DisplayName     = " FileListArray[iCount].sDisplayName
                    Writeln channel iCh "FileList entry was removed because the Table could not be opened"
                    Writeln channel iCh ""
                    Increment iCounter
                End
            End
            Get Check_StatusPanel of ghoStatusPanel to bCancel
            If (bCancel = True) Begin
                // Cancelled: the clean-up below runs, and the answer is what was done. (It returned at once.)
                Break
            End
        Loop

        Send CloseLogFile
        Send StopStatusPanel
        If (iCounter <> 0) Begin
            Send RefreshData
        End     
        Function_Return iCounter
    End_Function

    Function FixAllIntFileErrors Boolean bExtractRelations Returns Integer
        Integer iSize iCount iCounter iDriver
        tFilelist[] ErrorFilesArray FileListArray
        String sDriver sRootName sIntFileName sConnectionID
        Boolean bOK bIsSystem bCurrentUcaseMode bCancel
        Handle hTable

        Get pFileListArray of ghoDUF to FileListArray
        If (SizeOfArray(FileListArray) = 0) Begin
            Send RefreshData
            Get pFileListArray of ghoDUF to FileListArray
        End    

        Set psBackupError to ""
        Get pErrorTables of ghoDUF to ErrorFilesArray
        If (SizeOfArray(ErrorFilesArray) = 0) Begin
            Function_Return -1
        End
        
        Send OpenLogFile
        Get psDriverID of ghoDUF to sDriver
        Get DriverIndex of ghoDUF sDriver to iDriver
        // Note: If Ignore_Ucase_Support is set to false, the Connectivity Kit will 
        //       behave the same as earlier driver versions.
        //       This means that "U_" columns will be kept during a restructure.
        Get_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to bCurrentUcaseMode
        Set_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to True
        Move (SizeOfArray(ErrorFilesArray)) to iSize
        Get psConnId to sConnectionID
        Set psBackupFolder to ""
        Send StartStatusPanel "Fixing Int File Errors" ""     
    
        For iCount from 0 to (iSize - 1)
            Move ErrorFilesArray[iCount].sDriver to sDriver
            If (sDriver = "") Begin
                Get _RemoveDriverFromRootName of ghoDUF ErrorFilesArray[iCount].sRootName (&sDriver) to sRootName
                If (sDriver = "") Begin
                    Get psDriverID of ghoDUF to sDriver
                End
            End

            If (sDriver <> DATAFLEX_ID) Begin
                Move (ErrorFilesArray[iCount].sNoDriverRootname + ".int") to sIntFileName
                Move ErrorFilesArray[iCount].hTable to hTable
                Get _IsSystemFile of ghoDUF hTable to bIsSystem
                Send UpdateStatusPanel ("Fixing .int file problems for table:" * String(ErrorFilesArray[iCount].sNoDriverRootname))
    
                Get CreateSingleIntFile hTable sDriver sConnectionID bIsSystem sIntFileName bExtractRelations True to bOK
                
                Close hTable
                If (bOK) Begin
                    Increment iCounter
                    Set_Attribute DF_FILE_ROOT_NAME of hTable to (sDriver + ":" + ErrorFilesArray[iCount].sNoDriverRootname)
                End
                Else Begin
                    Send WriteError ("The recreation of the.int file:" * String(sIntFileName) * "failed.") 
                End
                // A backup copy that could not be made stops the run: the next file would be changed without one.
                If (psBackupError(Self) <> "") Begin
                    Break
                End
            End
            Get Check_StatusPanel of ghoStatusPanel to bCancel
            If (bCancel = True) Begin
                // Cancelled: the clean-up below runs, and the answer is what was done. (It returned at once.)
                Break
            End
        Loop
    
        Set psBackupFolder to ""
        Set_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to bCurrentUcaseMode
        Send CloseLogFile
        Send StopStatusPanel
        If (iCounter <> 0) Begin
            Send RefreshData
        End
    
        Function_Return iCounter
    End_Function

    Procedure GENERATE_ALL_INT_FILES_CODE_STARTS_HERE
    End_Procedure

    Function RecreateAllIntFiles Boolean bExtractRelations Boolean bRemoveUCol Returns Integer
        Integer iSize iCount iCounter iDriver iLastErr iErrLine
        tFilelist[] FileListArray
        String sDriver sIntFileName sConnectionID sDataPath
        Boolean bOK bIsSystem bAnsi bIsAlias bIsSQL bCurrentUcaseMode bErr bCancel
        Handle hTable
    
        Get pFileListArray of ghoDUF to FileListArray
        If (SizeOfArray(FileListArray) = 0) Begin
            Send RefreshData
            Get pFileListArray of ghoDUF to FilelistArray
        End
    
        Move 0 to iCounter
        Move Err to bErr
        Move LastErr to iLastErr
        Move ErrLine to iErrLine
        Move False to Err
        Move 0 to LastErr
        Move 0 to ErrLine
        
        Send OpenLogFile
        Get psDriverID of ghoDUF to sDriver
        Get DriverIndex of ghoDUF sDriver to iDriver
        // Note: If Ignore_Ucase_Support is set to false, the Connectivity Kit will 
        //       behave the same as earlier driver versions.
        //       This means that "U_" columns will be kept during a restructure.
        Get_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to bCurrentUcaseMode
        Set_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to bRemoveUCol
        Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
        Get psConnId to sConnectionID 
        Get pbToANSI of ghoDUF to bAnsi 
        Move (SizeOfArray(FileListArray)) to iSize     
        Decrement iSize
        Set psBackupFolder to ""
        Set psBackupError to ""
        
        // Each Start_Restructure/End_Restructure calls the "Callback" message 3 times,
        // and each one does a "Send DoAdvance" to the ghoProgressBar...
        Send StartStatusPanel "Recreating .int Files" "" (iSize * 3)
    
        For iCount from 0 to iSize
            Move FileListArray[iCount].sDriver  to sDriver
            Move FileListArray[iCount].hTable   to hTable
            Get _IsSQLEntry of ghoDUF hTable    to bIsSQL
            Move FileListArray[iCount].bIsAlias to bIsAlias                   
            Set Message_Text of ghoStatusPanel to ("Table number:" * String(hTable))
            If (bIsSQL = True and bIsAlias = False) Begin
                Move (FileListArray[iCount].sNoDriverRootname + ".int") to sIntFileName
                If (sDriver <> DATAFLEX_ID) Begin
                    Open hTable
                    Get _IsSystemFile of ghoDUF hTable to bIsSystem
                    Send UpdateStatusPanel ("Recreating file:" * String(FileListArray[iCount].sNoDriverRootname) + ".int")
                    
                    Get CreateSingleIntFile hTable sDriver sConnectionID bIsSystem sIntFileName bExtractRelations bRemoveUCol to bOK
                    
                    Close hTable
                    If (bOK) Begin 
                        Increment iCounter
                        Set_Attribute DF_FILE_ROOT_NAME of hTable to (sDriver + ":" + FileListArray[iCount].sNoDriverRootname)
                    End
                    Else Begin
                        Send WriteError ("The recreation of the.int file:" * String(sIntFileName) * "failed.") 
                    End
                    // A backup copy that could not be made stops the run: the next file would be changed without one.
                    If (psBackupError(Self) <> "") Begin
                        Break
                    End
                End
            End                              
            Get Check_StatusPanel of ghoStatusPanel to bCancel
            If (bCancel = True) Begin
                // Cancelled: the clean-up below runs, and the answer is what was done. (It returned at once.)
                Break
            End
            Send DoAdvance of ghoStatusPanel 
        Loop
    
        Set_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to bCurrentUcaseMode
        Set psBackupFolder to ""
        Send CloseLogFile
        Send StopStatusPanel
        Move bErr to Err
        Move iLastErr to LastErr
        Move iErrLine to ErrLine
        If (iCounter > 0) Begin
            Send RefreshData
        End
    
        Function_Return iCounter
    End_Function

    // Helper function to recreate a single .int file
    Function CreateSingleIntFile Handle hTable String sDriver String sConnectionID Boolean bIsSystem String sIntFileName Boolean bExtractRelations Boolean bRemoveUCol Returns Boolean
        Boolean bOK bAnsi bIsHidden
        String[] asIntFieldsData asFullIntFileData
    
        Get pbToANSI of ghoDUF to bAnsi 
        
        // 1. Backup the .int file (also backs-up Filelist.cfg). Without the backup the file is not touched.
        Get BackupIntFile sIntFileName to bOK
        If (bOK = False) Begin
            Send WriteError ("The .int file" * sIntFileName * "was not recreated:" * psBackupError(Self))
            Function_Return False
        End
        // 2. Collect relation and index info from old .ini file:
        If (bExtractRelations = True) Begin
            Get CollectTableRelations sIntFileName to asIntFieldsData
        End
        // 3. Tell driver to create a new .int file.
        Get CreateNewIntFile hTable sDriver sConnectionID bAnsi bIsSystem False to bOK
        If (bOK = False) Begin
            // The error will have been written to the log file.
            Function_Return False
        End
        // 4. Add DATETIME attributes from the data table.
        Get CollectDateTimeAttributes hTable sDriver asIntFieldsData to asIntFieldsData
        // 5. Add "NEXT_COLUMN_HIDDEN UPPERCASED" attributes from the SQL back-end.
        Get CollectHiddenAttributes   hTable sDriver asIntFieldsData (&bIsHidden) to asIntFieldsData
        // 6. Merge the new .int file with collected data:
        Get MergeIntFileData hTable sIntFileName asIntFieldsData to asFullIntFileData
        // 7. Write the updated .int file to disk:
        Get WriteArrayToFile sIntFileName asFullIntFileData to bOK 
        
        // 8. Restructure to remove U_ columns
        If (bRemoveUCol = True and bOK = True and bIsHidden = True) Begin
            Get RemoveU_Columns hTable sDriver to bOK
        End
        Function_Return bOK
    End_Function 
    
    Function FindAllUColumnsFiles Boolean bBackup Returns Integer
        Integer iSize iCount iCounter iDriver iLastErr iErrLine iResult
        tFilelist[] FileListArray
        String sDriver sIntFileName sConnectionID sDataPath
        Boolean bOK bIsSystem bAnsi bIsAlias bIsSQL bCurrentUcaseMode bErr bCancel
        Handle hTable
    
        Get pFileListArray of ghoDUF to FileListArray
        If (SizeOfArray(FileListArray) = 0) Begin
            Send RefreshData
            Get pFileListArray of ghoDUF to FilelistArray
        End
    
        Move 0 to iCounter
        Move Err to bErr
        Move LastErr to iLastErr
        Move ErrLine to iErrLine
        Move False to Err
        Move 0 to LastErr
        Move 0 to ErrLine 
        
        Set psBackupError to ""
        If (bBackup = True) Begin
            Get MakeSQLDatabaseBackup to bOK
            // Without the backup that was asked for, nothing is changed.
            If (bOK = False) Begin
                Set psBackupError to "The backup of the SQL database was not made."
                Move bErr to Err
                Move iLastErr to LastErr
                Move iErrLine to ErrLine
                Function_Return 0
            End
        End
        
        Send OpenLogFile
        Get psDriverID of ghoDUF to sDriver
        Get DriverIndex of ghoDUF sDriver to iDriver
        // Note: If Ignore_Ucase_Support is set to false, the Connectivity Kit will 
        //       behave the same as earlier driver versions.
        //       This means that "U_" columns will be kept during a restructure.
        Get_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to bCurrentUcaseMode
        Set_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to True
        Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
        Get psConnId to sConnectionID 
        Get pbToANSI of ghoDUF to bAnsi 
        Move (SizeOfArray(FileListArray)) to iSize     
        Decrement iSize
        Set psBackupFolder to ""
        
        // Each Start_Restructure/End_Restructure calls the "Callback" message 3 times,
        // and each one does a "Send DoAdvance" to the ghoProgressBar...
        Send StartStatusPanel "Finding and removing 'U_' columns" "" (iSize * 3)
    
        For iCount from 0 to iSize
            Move FileListArray[iCount].sDriver  to sDriver
            Move FileListArray[iCount].hTable   to hTable
            Get _IsSQLEntry of ghoDUF hTable    to bIsSQL
            Move FileListArray[iCount].bIsAlias to bIsAlias                   
            Set Message_Text of ghoStatusPanel to ("Table number:" * String(hTable))
            If (bIsSQL = True and bIsAlias = False) Begin
                Move (FileListArray[iCount].sNoDriverRootname + ".int") to sIntFileName
                If (sDriver <> DATAFLEX_ID) Begin
                    Open hTable
                    Get _IsSystemFile of ghoDUF hTable to bIsSystem
                    Send UpdateStatusPanel ("Searching Table:" * String(FileListArray[iCount].sNoDriverRootname))
                    
                    Get FindSingleUColumnsFile hTable sDriver sConnectionID bIsSystem sIntFileName bBackup to iResult
                    
                    Close hTable
                    // Only a table whose columns were removed counts.
                    If (iResult = 1) Begin
                        Increment iCounter
                    End
                    Else If (iResult = -1) Begin
                        Send WriteError ("Searching for 'U_' columns for table:" * String(FileListArray[iCount].sNoDriverRootname) * "failed.") 
                    End
                    // A backup copy that could not be made stops the run: the next file would be changed without one.
                    If (psBackupError(Self) <> "") Begin
                        Break
                    End
                End
            End
            Get Check_StatusPanel of ghoStatusPanel to bCancel
            If (bCancel = True) Begin
                // Cancelled: the clean-up below runs, and the answer is what was done. (It returned at once.)
                Break
            End
            Send DoAdvance of ghoStatusPanel 
        Loop
    
        Set_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to bCurrentUcaseMode
        Set psBackupFolder to ""
        Send CloseLogFile
        Send StopStatusPanel
        Move bErr to Err
        Move iLastErr to LastErr
        Move iErrLine to ErrLine
        If (iCounter > 0) Begin
            Send RefreshData
        End
    
        Function_Return iCounter
    End_Function

    // Removes the uppercased (U_) columns of one table: 1 when columns were removed, 0 when the table had none, -1
    // when it failed - the reason is in the log. (It answered the result of the backup or of the last step: with a
    // backup every table without U_ columns counted as "removed", without one as "failed".)
    Function FindSingleUColumnsFile Handle hTable String sDriver String sConnectionID Boolean bIsSystem String sIntFileName Boolean bBackup Returns Integer
        Boolean bOK bAnsi bIsHidden
        String[] asIntFieldsData asFullIntFileData

        Get pbToANSI of ghoDUF to bAnsi
        // 1. Backup the .int file (also backs-up Filelist.cfg). Without the backup the file is not touched.
        If (bBackup = True) Begin
            Get BackupIntFile sIntFileName to bOK
            If (bOK = False) Begin
                Send WriteError ("The uppercased columns of" * sIntFileName * "were not removed:" * psBackupError(Self))
                Function_Return -1
            End
        End
        // 2. Find "NEXT_COLUMN_HIDDEN UPPERCASED" attributes from the SQL back-end.
        Get CollectHiddenAttributes hTable sDriver asIntFieldsData (&bIsHidden) to asIntFieldsData
        If (bIsHidden = False) Begin
            Function_Return 0
        End
        // 3. Merge the new .int file with collected data:
        Get MergeIntFileData hTable sIntFileName asIntFieldsData to asFullIntFileData
        // 4. Write the updated .int file to disk:
        Get WriteArrayToFile sIntFileName asFullIntFileData to bOK
        If (bOK = False) Begin
            Send WriteError ("The .int file" * sIntFileName * "could not be written.")
            Function_Return -1
        End
        // 5. Restructure to remove U_ columns
        Get RemoveU_Columns hTable sDriver to bOK
        If (bOK = False) Begin
            Function_Return -1
        End
        Function_Return 1
    End_Function
    
    Function RemoveU_Columns Handle hTable String sDriver Returns Boolean
        Boolean bErr bOK
        Integer iColumn
        String sNewFieldName
        
        Move Err to bErr
        Move False to Err
        // We need to close the table permanently, then re-open it, for the
        // Structure_Start/End to work properly.
        Close hTable DF_PERMANENT
        Open hTable Mode DF_EXCLUSIVE
        Move "DUFTEMP2024" to sNewFieldName
        Structure_Start hTable sDriver
            // This command creates a new column. If {column-num} is omitted or 0,
            // the column will be appended to the end of the existing record 
            Move 0 to iColumn
            Create_Field hTable at iColumn
            Set_Attribute DF_FIELD_NAME of hTable iColumn to sNewFieldName
            Set_Attribute DF_FIELD_TYPE of hTable iColumn to DF_DATE
            Delete_Field hTable iColumn            
        Structure_End hTable DF_STRUCTEND_OPT_FORCE "." ghoDbUpdateHandler

        Move (not(Err)) to bOK
        Move bErr to Err
        Function_Return bOK
    End_Function
    
    Function CreateNewIntFile Handle hTable String sDriver String sConnectionID Boolean bAnsi Boolean bIsSystem Boolean bBackup Returns Boolean
        Boolean bOK
        Get _SqlUtilCreateIntFile of ghoDUF hTable sDriver sConnectionID bAnsi bIsSystem False to bOK
        Function_Return bOK
    End_Function

    Function CollectTableRelations String sIntFile Returns String[]
        Integer iSize iCount
        String[] asIntFile asData
        String sLine sFieldTxt
        
        Get FullDataPathFileName sIntFile to sIntFile
        Get ReadFileToArray sIntFile to asIntFile
        Move (SizeOfArray(asIntFile)) to iSize
        Decrement iSize
        
        For iCount from 0 to iSize
            Move (Trim(asIntFile[iCount])) to sLine  
            If (Uppercase(Left(sLine, 13)) = "FIELD_NUMBER ") Begin
                Move sLine to sFieldTxt
                Repeat
                    If (iCount < iSize) Begin
                        Increment iCount               
                        // Try to find both: FIELD_RELATED_FILE & FIELD_RELATED_FIELD
                        // Note that we can't be sure in whitch order they are in.
                        If (Uppercase(Left(asIntFile[iCount], 14)) = "FIELD_RELATED_") Begin
                            If (sFieldTxt <> "") Begin  
                                Move ""    to asData[-1]
                                Move sLine to asData[-1]
                                Move "" to sFieldTxt
                            End
                            Move asIntFile[iCount] to asData[-1]
                        End
                    End
                Until (Trim(asIntFile[iCount] = "") or iCount >= iSize)
            End
            
        Loop
        Function_Return asData
    End_Function
    
    // The column names without RECNUM and the uppercased (U_) columns. (It removed while counting up, so the
    // column after a removed one was never looked at.)
    Function SanitizeColumnNames String[] asColumns Returns String[]
        Integer iCount
        String sColName

        Move (SizeOfArray(asColumns) - 1) to iCount
        While (iCount >= 0)
            Move asColumns[iCount] to sColName
            If (Left(Uppercase(sColName), 2) = "U_" or Uppercase(sColName) = "RECNUM") Begin
                Move (RemoveFromArray(asColumns, iCount)) to asColumns
            End
            Decrement iCount
        Loop
        Function_Return asColumns
    End_Function

    Function IsDuplicateAttribute String[] asIntFileData String sFieldNoText String sAttribute Returns Boolean
        Integer iSize iIndex
        String sLine
        
        Move (SearchArray(sFieldNoText, asIntFileData, Desktop, (RefFunc(DFSTRICMP)))) to iIndex
        If (iIndex = -1) Begin
            Function_Return False
        End
        If (Trim(sAttribute) = "") Begin
            Function_Return
        End
        Move (SizeOfArray(asIntFileData)) to iSize
        Increment iIndex
        Repeat
            Move (Uppercase(Trim(asIntFileData[iIndex]))) to sLine
            If (sLine = Uppercase(Trim(sAttribute))) Begin
                Function_Return True
            End
            Increment iIndex
        Until (sLine = "" or iIndex >= iSize)
        
        Function_Return False
    End_Function              
    
    // To add FIELD_NUMBER DATETIME attributes.
    Function CollectDateTimeAttributes Handle hTable String sDriver String[] asIntFileData Returns String[]
        Integer iSize iCount iDbType
        String sFieldNoTxt sFieldDateTxt
        Boolean bFound bOpen
        String[] asColumnsNames asFieldTimeDates

        Open hTable
        Get_Attribute DF_FILE_OPENED of hTable to bOpen
        If (bOpen = False) Begin
            Function_Return asIntFileData
        End
        
        Get piDbType of ghoDUF to iDbType
        Get _SqlUtilEnumerateColumnsByHandle of ghoDUF sDriver hTable to asColumnsNames
        Get SanitizeColumnNames asColumnsNames to asColumnsNames

        // 1. Find "DATETIME" fields:
        Move (SizeOfArray(asColumnsNames)) to iSize
        For iCount from 1 to iSize
            Move ("FIELD_NUMBER" * String(iCount)) to sFieldNoTxt 
            Get FieldNumberToDataTimeText hTable sFieldNoTxt sDriver iDbType to sFieldDateTxt   
            Get IsDuplicateAttribute asIntFileData sFieldNoTxt sFieldDateTxt to bFound
            If (sFieldDateTxt <> "" and bFound = False) Begin
                Move ""            to asFieldTimeDates[-1]
                Move sFieldNoTxt   to asFieldTimeDates[-1] 
                Move sFieldDateTxt to asFieldTimeDates[-1]
            End
        Loop
        If (SizeOfArray(asFieldTimeDates) <> 0) Begin
            Get CombineArrays asIntFileData asFieldTimeDates to asIntFileData      
        End
        
        Function_Return asIntFileData
    End_Function

    // To add HIDDEN FIELD_NUMBER settings.
    Function CollectHiddenAttributes Handle hTable String sDriver String[] asIntFileData Boolean ByRef bIsHidden Returns String[]
        Integer iSize iCount iField iDbType
        String sFieldNoTxt sLine sFieldHiddenTxt sFieldName
        Boolean bFound
        String[] asColumnsNamesOrg asColumnsNames asFieldHidden
        
        Move False to bIsHidden
        Get piDbType of ghoDUF to iDbType
        Get _SqlUtilEnumerateColumnsByHandle of ghoDUF sDriver hTable to asColumnsNamesOrg
        Get SanitizeColumnNames asColumnsNamesOrg to asColumnsNames

        Move (SizeOfArray(asColumnsNamesOrg)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Move "" to sFieldHiddenTxt
            If (iCount <= iSize) Begin
                Move (Trim(Uppercase(asColumnsNamesOrg[iCount]))) to sLine
                If (Left(sLine, 2) = "U_") Begin
                    Move (Replace("U_", sLine, "")) to sFieldName
                    Move (SearchArray(sFieldName, asColumnsNames, Desktop, (RefFunc(DFSTRICMP)))) to iField
                    Move ("FIELD_NUMBER" * String(iField +1)) to sFieldNoTxt
                    Move "NEXT_COLUMN_HIDDEN UPPERCASED"      to sFieldHiddenTxt
                    Get IsDuplicateAttribute asIntFileData sFieldNoTxt sFieldHiddenTxt to bFound
                    If (iField <> -1 and bFound = False) Begin
                        Move ""              to asFieldHidden[-1]
                        Move sFieldNoTxt     to asFieldHidden[-1]
                        Move sFieldHiddenTxt to asFieldHidden[-1]
                    End
                End
            End
        Loop
        If (SizeOfArray(asFieldHidden) <> 0) Begin
            Get CombineArrays asIntFileData asFieldHidden to asIntFileData      
            Move True to bIsHidden
        End

        Function_Return asIntFileData
    End_Function

    Function ParseBlocks String[] sSourceArray Returns tBlock[]
        Integer iCount iSize iFieldNumber
        tBlock[] aBlocks
        tBlock CurrentBlock
        String sLine
        Boolean bInBlock
        
        Move False to bInBlock
        Move (ResizeArray(aBlocks, 0)) to aBlocks
        Move (SizeOfArray(sSourceArray)) to iSize
        Decrement iSize
        
        // Loop through each line in the string array
        For iCount from 0 to iSize
            Move sSourceArray[iCount] to sLine
    
            // Check if the line starts with "FIELD_NUMBER"
            If (Left(sLine, 12) = "FIELD_NUMBER") Begin
                // If we're already in a block, finish the current block
                If (bInBlock = True) Begin
                    Move CurrentBlock to aBlocks[-1]
                End
                Get ExtractFieldNumber sLine to iFieldNumber
    
                // Start a new block
                Move (ResizeArray(CurrentBlock.asLines, 0)) to CurrentBlock.asLines
                Move iFieldNumber to CurrentBlock.iFieldNumber
                Move (ResizeArray(CurrentBlock.asLines, 0)) to CurrentBlock.asLines
                Move True to bInBlock
            End
            // End of current block (empty line)
            Else If (sLine = "") Begin
                If (bInBlock = True) Begin
                    Move CurrentBlock to aBlocks[-1]
                    Move False to bInBlock
                End
            End
            Else Begin
                // Add the line to the current block
                If (bInBlock) Begin
                    Move sLine to CurrentBlock.asLines[-1]
                End
            End
        Loop
    
        // Add the last block (if any)
        If (bInBlock = True) Begin
            Move CurrentBlock to aBlocks[-1]
        End
        Function_Return aBlocks
    End_Function

    Function CombineBlocks tBlock[] aBlocks1 tBlock[] aBlocks2 Returns tBlock[]
        tBlock[] aCombinedBlocks
        Integer iCount iSize
    
        // Initialize the combined blocks with the first array
        Move aBlocks1 to aCombinedBlocks
    
        // Process each block in the second array
        Move (SizeOfArray(aBlocks2)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Get FindAndMergeBlock aCombinedBlocks aBlocks2[iCount] to aCombinedBlocks
        Loop
    
        Function_Return aCombinedBlocks
    End_Function
    
    // Finds a block with the same FIELD_NUMBER in the combined array and merges the asLines arrays
    Function FindAndMergeBlock tBlock[] aCombinedBlocks tBlock BlockToMerge Returns tBlock[]
        Integer iCount iSize
        Boolean bFound
    
        // Initialize flags
        Move False to bFound
    
        // Check for existing FIELD_NUMBER
        Move (SizeOfArray(aCombinedBlocks)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            If (aCombinedBlocks[iCount].iFieldNumber = BlockToMerge.iFieldNumber) Begin
                Move True to bFound
    
                // Merge unique lines
                Get MergeUniqueLines aCombinedBlocks[iCount].asLines BlockToMerge.asLines to aCombinedBlocks[iCount].asLines
    
                // Exit loop by updating the loop index
                Move iSize to iCount
            End
        Loop
    
        // If FIELD_NUMBER not found, add the block to the combined array
        If (bFound = False) Begin
            Move BlockToMerge to aCombinedBlocks[-1]
        End
    
        Function_Return aCombinedBlocks
    End_Function
    
    // Merges two string arrays, retaining only unique values
    Function MergeUniqueLines String[] aExistingLines String[] aNewLines Returns String[]
        String[] aMergedLines
        Integer iCount iSize iExistingIndex
        Boolean bIsDuplicate
    
        // Start with the existing lines
        Move aExistingLines to aMergedLines
    
        // Add only unique lines from the new array
        Move (SizeOfArray(aNewLines)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Move False to bIsDuplicate
    
            // Check for duplicates in the existing array
            For iExistingIndex from 0 to (SizeOfArray(aMergedLines) - 1)
                If (aNewLines[iCount] = aMergedLines[iExistingIndex]) Begin
                    Move True to bIsDuplicate
                    Move (SizeOfArray(aMergedLines)) to iExistingIndex // Exit loop
                End
            Loop
    
            // Append the line if it's unique
            If (bIsDuplicate = False) Begin
                Move aNewLines[iCount] to aMergedLines[-1]
            End
        Loop
    
        Function_Return aMergedLines
    End_Function

    Function BlocksToStringArray tBlock[] aBlocks Returns String[]
        Integer iCount jCount iSize
        String[] sResult
        String sBlockHeader
    
        // Sort by FIELD_NUMBER
        Move (SortArray(aBlocks)) to aBlocks
        // Loop through each block
        Move (SizeOfArray(aBlocks)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            // Add the FIELD_NUMBER header
            Move ("FIELD_NUMBER " + String(aBlocks[iCount].iFieldNumber)) to sBlockHeader
            Move sBlockHeader to sResult[-1]
    
            // Add all lines in the block
            For jCount from 0 to (SizeOfArray(aBlocks[iCount].asLines) - 1)
                Move aBlocks[iCount].asLines[jCount] to sResult[-1]
            Loop
    
            // Add an empty line to separate blocks
            Move "" to sResult[-1]
        Loop
    
        Function_Return sResult
    End_Function
    
    Function CombineArrays String[] asData1 String[] asData2 Returns String[]
        tBlock[] aBlocks1 aBlocks2 aCombinedBlocks
        String[] asCombinedArray
    
        // Parse input arrays into blocks
        Get ParseBlocks asData1 to aBlocks1
        Get ParseBlocks asData2 to aBlocks2
    
        // Combine the blocks
        Get CombineBlocks aBlocks1 aBlocks2 to aCombinedBlocks
    
        // Convert combined blocks back into a string array
        Get BlocksToStringArray aCombinedBlocks to asCombinedArray
    
        Function_Return asCombinedArray
    End_Function
    
    // Extracts the top part of the string array that preceeds all
    // "FIELD_NUMBER xx" data, and stops does not include IntFileIndexPart.
    Function IntFileTopPart String[] ByRef asIntFile Returns String[]
        String[] asResult
        String sLine
        Integer iSize iCount iFieldNumber

        Move (SizeOfArray(asIntFile)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Move asIntFile[iCount] to sLine    
            Get ExtractFieldNumber sLine to iFieldNumber
            If (iFieldNumber = -1) Begin
                Move asIntFile[iCount] to asResult[-1]
                Move (RemoveFromArray(asIntFile, iCount)) to asIntFile
                Decrement iCount
                Decrement iSize
            End
            Else Begin
                Move iSize to iCount
            End
        Loop
        Function_Return asResult
    End_Function

    // Extracts the bottom part of the string array, that deals
    // with index information.
    Function IntFileIndexPart String[] ByRef asIntFile Returns String[]
        String[] asResult
        String sLine
        Integer iSize iCount
        Boolean bFound
        
        Move False to bFound
        Move (SizeOfArray(asIntFile)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Move (Trim(Uppercase(asIntFile[iCount]))) to sLine
            // INDEX_NUMBER 1    
            If (bFound = False) Begin
                Move (Left(sLine, 12) = "INDEX_NUMBER") to bFound
            End
            If (bFound = True) Begin
                Move asIntFile[iCount] to asResult[-1]
                Move (RemoveFromArray(asIntFile, iCount)) to asIntFile
                Decrement iCount
                Decrement iSize
            End
        Loop
        Function_Return asResult
    End_Function

    // Adds previously gathered data (asIntFileData) from a current/old .int file, to be added/inserted into
    // a newly created .int file (sIntFile).
    // The gather of data should be made with CollectTableRelations
    Function MergeIntFileData Handle hTable String sIntFile String[] asIntFileData Returns String[]
        String[] asIntfile asFieldsData asTopData asBottomData asResultData
        
        // Read the newly created .int file:
        Get ReadFileToArray sIntFile to asIntfile  
        
        If (SizeOfArray(asIntfile) <> 0 and SizeOfArray(asIntFileData) <> 0) Begin
            // Get top part of .int file:
            Get IntFileTopPart (&asIntfile)                to asTopData
            // Get the bottom "INDEX_NUMBER xx" data from .int file:
            Get IntFileIndexPart (&asIntfile)             to asBottomData
            // Combine the "FIELD_NUMBER xx" data from the two arrays:
            Get CombineArrays asIntfile asIntFileData      to asFieldsData
            Move (AppendArray(asTopData, asFieldsData))    to asResultData
            Move (AppendArray(asResultData, asBottomData)) to asResultData
        End
        Else Begin
            Move asIntfile to asResultData
        End
        
        Function_Return asResultData
    End_Function
    
    // Returns the field number from an .int file's line.
    // sLine = "FIELD_NUMBER 2" returns a 2.
    // If no "FIELD_NUMBER" keyword found, or no integer was found
    // after that keyword, a -1 is returned.
    Function ExtractFieldNumber String sLine Returns Integer
        Integer iFieldNumber
        Move (Trim(Uppercase(sLine))) to sLine
        If (not(Left(sLine, 12) = "FIELD_NUMBER")) Begin
            Function_Return -1
        End
        Move (Integer(Mid(sLine, (Length(sLine) - 12), 13))) to iFieldNumber
        If (iFieldNumber = 0) Begin
            Move -1 to iFieldNumber 
        End
        Function_Return iFieldNumber
    End_Function

    // Reads a file from disk and returns it as a string array.
    // Note: If the sFileName param does not contain a path,
    //       it is assumed the file resides in the Data folder.
    //       Reads a file and returns it as a string array.
    Function ReadFileToArray String sFileName Returns String[]
        String[] asData
        Integer iCh
        
        Get Seq_New_Channel to iCh
        If (iCh < 0) Begin 
            Error DFERR_PROGRAM "No free channel to read file into string array."
            Function_Return asData
        End
        
        Get FullDataPathFileName sFileName to sFileName
        Direct_Input channel iCh sFileName
        While (not(SeqEof))
            Readln channel iCh asData[-1]
        Loop
        Close_Input channel iCh
        Send Seq_Release_Channel iCh
        
        Function_Return asData
    End_Function

    Function WriteArrayToFile String sFileName String[] asResultData Returns Boolean
        Boolean bStart bFound
        Integer iSize iCount iCh
        String sLine
        String[] asKept
        
        Get Seq_New_Channel to iCh
        If (iCh < 0) Begin 
            Error DFERR_PROGRAM "No Free channel for writing .int file"
            Function_Return False
        End 

        // From the first field on, no two empty lines in a row; no empty line at the end. (The loop tested one element
        // and removed another, and removed while counting up, so lines were dropped or left.)
        Move False to bStart
        For iCount from 0 to (SizeOfArray(asResultData) - 1)
            Move asResultData[iCount] to sLine
            If (bStart = False) Begin
                Move (Left(Uppercase(sLine), 12) = "FIELD_NUMBER") to bStart
            End
            Move True to bFound
            If (bStart = True and Trim(sLine) = "" and SizeOfArray(asKept) > 0) Begin
                If (Trim(asKept[SizeOfArray(asKept) - 1]) = "") Begin
                    Move False to bFound
                End
            End
            If (bFound = True) Begin
                Move sLine to asKept[SizeOfArray(asKept)]
            End
        Loop
        If (SizeOfArray(asKept) > 0) Begin
            If (Trim(asKept[SizeOfArray(asKept) - 1]) = "") Begin
                Move (ResizeArray(asKept, (SizeOfArray(asKept) - 1))) to asKept
            End
        End
        Move asKept to asResultData
        
        // Write the updated .int file:
        Move False to Err
        Get FullDataPathFileName sFileName to sFileName
        Move (SizeOfArray(asResultData)) to iSize
        Decrement iSize
        Direct_Output channel iCh sFileName
            For iCount from 0 to iSize
                Writeln channel iCh asResultData[iCount]
            Loop        
        // Flush_Output is a DataFlex 20 command; Close_Output writes what is left on every version.
        #IF (!@ > 191)
            Flush_Output channel iCh
        #ENDIF
        Close_Output channel iCh
        Send Seq_Release_Channel iCh
        
        Function_Return (not(Err))
    End_Function
    
    Function FullDataPathFileName String sFileName Returns String
        String sPath
        Boolean bFound
        Get ParseFolderName sFileName to sPath
        If (sPath <> "") Begin
            Get vFolderExists sPath to bFound
        End
        If (bFound = False) Begin
            Get psDataPath of (phoWorkspace(ghoApplication)) to sPath
        End
        Get vFolderFormat sPath to sPath
        Get ParseFileName sFileName to sFileName
        Move (sPath + sFileName) to sFileName
        Function_Return sFileName
    End_Function

    // To get the DataFlex type from a SQL column DateTime(x) data type, as a text string
    // For usage in .int files.
    // Note: The hTable needs to be open before calling this function.
    Function FieldNumberToDataTimeText Handle hTable String sFieldNoTxt String sDriver Integer iDbType Returns String
        String sDataType sTableName sColumnName
        String[] asColumns
        Integer iFieldNumber iType
        Boolean bIsSQLTable bOpen
        
        Get ExtractFieldNumber sFieldNoTxt to iFieldNumber
        If (iFieldNumber = -1) Begin
            Function_Return "" 
        End

        Get _IsSQLEntry of ghoDUF hTable to bIsSQLTable
        If (bIsSQLTable = True) Begin 
            Get_Attribute DF_FILE_ROOT_NAME of hTable to sTableName
            Get _TableNameOnly of ghoDUF sTableName to sTableName
            // The DataFlex field number counts the columns without RECNUM and the uppercased (U_) columns. (It was
            // used as an index into the server's own list, which holds them: off by one without RECNUM, and past
            // every U_ column.)
            Get _SqlUtilEnumerateColumns of ghoDUF sDriver sTableName to asColumns
            Get SanitizeColumnNames asColumns to asColumns
            Move "" to sColumnName
            If (iFieldNumber > 0 and iFieldNumber <= SizeOfArray(asColumns)) Begin
                Move asColumns[iFieldNumber - 1] to sColumnName
            End
            Get SqlColumnType of ghoDUF sDriver hTable sTableName sColumnName to iType
        End
                
        Else Begin
            Get_Attribute DF_FILE_OPENED of hTable to bOpen
            If (bOpen = False) Begin
                Open hTable
                Get_Attribute DF_FILE_OPENED of hTable to bOpen
                If (bOpen = False) Begin
                    Function_Return ""
                End
            End
            Get_Attribute DF_FIELD_TYPE of hTable iFieldNumber to iType
        End

        Get UtilColumnTypeToString of ghoDUF sDriver iDbType iType to sDataType
        If (not(Uppercase(sDataType) contains "TIME")) Begin
            Move "" to sDataType
        End
        Else Begin
            Move (Replace("DF_", sDataType, "")) to sDataType
            Move ("FIELD_TYPE " + Uppercase(sDataType)) to sDataType
        End
        
        Function_Return sDataType
    End_Function

    // The sFileName should not contain any path. Creates a backup copy of the passed sFileName
    // in the sBackup folder with a "sFileDateExt" file name suffix (prior to the file name extension).
    // Example: A passed sFileName of "register.int" will become: "register.2024-11-06__21_34_42.int"
    //          So "register.YYYY-MM-DD__HH_MM_SS.int 
    //          Note: The "YYYY-MM-DD" format depends on your Windows local date settings.
    // Copies an .int file of the first data folder into the backup folder of this run. The first call of a run
    // makes the folder and copies Filelist.cfg into it as well. An .int file that is not there yet - the one that
    // is to be made - needs no copy. Returns False when the folder or a copy cannot be made; psBackupError then
    // says which. (A Filelist.cfg that could not be copied went unnoticed, and no caller looked at the result.)
    Function BackupIntFile String sFileName Returns Boolean
        String sDataPath sBackupFolder sFileDateExt sFileList sFileListName
        Integer iRetval
        Boolean bExists
        
        Set psBackupError to ""
        Get psDataPath  of (phoWorkspace(ghoApplication)) to sDataPath
        Get PathAtIndex of (phoWorkspace(ghoApplication)) sDataPath 1 to sDataPath
        Get vFolderFormat sDataPath to sDataPath
        Get psBackupFolder to sBackupFolder
        Get vFolderExists sBackupFolder to bExists
        If (bExists = False) Begin
            Get FileDatePrefix to sFileDateExt
            Move (sDataPath + String(CS_BackupFolder) + String(sFileDateExt)) to sBackupFolder
            Get vCreateDirectory sBackupFolder to iRetval
            Get vFolderFormat sBackupFolder to sBackupFolder
            If (iRetval <> 0) Begin 
                Set psBackupError to ("The backup folder" * sBackupFolder * "could not be made.")
                Function_Return False
            End
            Get psFileList of (phoWorkspace(ghoApplication)) to sFileList
            Get ExtractFileName sFileList to sFileListName
            Get vCopyFile sFileList (sBackupFolder + sFileListName) to iRetval
            If (iRetval <> 0) Begin
                Set psBackupError to (sFileList * "could not be copied to the backup folder" * sBackupFolder + ".")
                Function_Return False
            End
            Set psBackupFolder to sBackupFolder
        End
        Get vFolderFormat sBackupFolder to sBackupFolder
        Get vFilePathExists (sDataPath + sFileName) to bExists
        If (bExists = False) Begin
            Function_Return True
        End
        Get vCopyFile (sDataPath + sFileName) (sBackupFolder + String(sFileName)) to iRetval
        If (iRetval <> 0) Begin
            Set psBackupError to (sDataPath + sFileName * "could not be copied to the backup folder" * sBackupFolder + ".")
            Function_Return False
        End
        Function_Return True
    End_Function

    // Copies a file into a new backup folder of the first data folder, named with the date and time. A name with a
    // folder is copied from that folder, a bare name from the first data folder. Returns False when the folder or
    // the copy cannot be made; psBackupError then says which.
    Function BackupAnyFileToBackupFolder String sFileName Returns Boolean
        String sDataPath sBackupFolder sFileDateExt sSource
        Integer iRetval
        Boolean bExists
        
        Set psBackupError to ""
        Get psDataPath  of (phoWorkspace(ghoApplication)) to sDataPath
        Get PathAtIndex of (phoWorkspace(ghoApplication)) sDataPath 1 to sDataPath
        Get vFolderFormat sDataPath to sDataPath
        Get FileDatePrefix to sFileDateExt
        Move (sDataPath + String(CS_BackupFolder) + String(sFileDateExt)) to sBackupFolder
        Get vFolderExists sBackupFolder to bExists
        If (bExists = False) Begin
            Get vCreateDirectory sBackupFolder to iRetval
            If (iRetval <> 0) Begin 
                Set psBackupError to ("The backup folder" * sBackupFolder * "could not be made.")
                Function_Return False
            End
        End
        Get vFolderFormat sBackupFolder to sBackupFolder
        Move sFileName to sSource
        If (not(sFileName contains "\")) Begin
            Move (sDataPath + sFileName) to sSource
        End
        Get ExtractFileName sFileName to sFileName
        Get vCopyFile sSource (sBackupFolder + String(sFileName)) to iRetval
        If (iRetval <> 0) Begin
            Set psBackupError to (sSource * "could not be copied to the backup folder" * sBackupFolder + ".")
            Function_Return False
        End
        Function_Return True
    End_Function

    // The message of a run that stopped because a backup copy could not be made: why, and what the run had done
    // before that - iDone times sDone - or that nothing was changed.
    Function BackupStoppedText String sDone Integer iDone Returns String
        String sText

        Get psBackupError to sText
        If (iDone > 0) Begin
            Function_Return (sText + "\n\nThe run stopped there. Done before that:" * String(iDone) * sDone + ".")
        End
        Function_Return (sText + "\n\nNothing was changed.")
    End_Function

    Function FileDatePrefix Returns String
        String sDateTime
        DateTime dDateTime
        Integer iPos
        
        Move (CurrentDateTime()) to dDateTime
        Move dDateTime to sDateTime
        Move (Replaces("/", sDateTime, "-"))  to sDateTime
        Move (Replaces(" ", sDateTime, "__")) to sDateTime
        Move (Replaces(":", sDateTime, "_"))  to sDateTime
        Move (Pos(",", sDateTime)) to iPos
        If (iPos <> 0) Begin
            Move (Left(sDateTime, (iPos -1))) to sDateTime
        End
        Else Begin
            Move (Pos(".", sDateTime)) to iPos
            If (iPos <> 0) Begin
                Move (Left(sDateTime, (iPos -1))) to sDateTime
            End
        End
        Function_Return sDateTime 
    End_Function

    Procedure GENERATE_ALL_INT_FILES_CODE_ENDS_HERE
    End_Procedure

    // To move all *.dat related files to a Data subfolder (sBackupFolder)
    // Returns -1 if it failed
    // Returns a positive integer with number of moved files if successful.
    // Note: The sBackupFolder should *not* contain a path, just a folder name.
    Function MoveUnusedDatFileToBackupFolder String sBackupFolder Returns Integer
        Integer iSize iCount iRetval iCounter
        String sDataPath sFilter
        String[] asFiles asInUseDatFiles
        Boolean bExists bCancel
        
        Get psDataPath of (phoWorkspace(ghoApplication)) to sDataPath
        Get vFolderFormat sDataPath to sDataPath
        Move (sDataPath + sBackupFolder) to sBackupFolder
        Get vFolderExists sBackupFolder to bExists
        If (bExists = False) Begin
            Get vCreateDirectory sBackupFolder to iRetval
            If (iRetval <> 0) Begin
                Function_Return -1
            End
        End
        Send StartStatusPanel "Moving *.dat files to backup folder:" sBackupFolder 1

        Move "dat,hdr,vld,k1,k2,k3,k4,k5,k6,k7,k8,k9,k10,k11,k12,k13,k14,k15,k16,k17,k18,k19,k20" to sFilter
        Get CollectFilteredFiles sDataPath sFilter to asFiles 
        Set piMaximum of ghoStatusPanel to (SizeOfArray(asFiles))
        Get InUseDatFiles to asInUseDatFiles
        Get SanitizeDatRelatedFiles asFiles asInUseDatFiles to asFiles
        Move (SizeOfArray(asFiles)) to iSize
        If (iSize = 0) Begin
            Send StopStatusPanel
            Function_Return 0
        End
        Move 0 to iCounter
        Decrement iSize
        For iCount from 0 to iSize
            Set Action_Text of ghoStatusPanel to (sDataPath + asFiles[iCount]) 
            Get vMoveFile (sDataPath + asFiles[iCount]) sBackupFolder to iRetval 
            If (iRetval = 0) Begin
                Increment iCounter
            End
            Get Check_StatusPanel of ghoStatusPanel to bCancel
            If (bCancel = True) Begin
                // Cancelled: the clean-up below runs, and the answer is what was done. (It returned at once.)
                Break
            End
            Send DoAdvance of ghoStatusPanel
        Loop
        
        Send StopStatusPanel
        Function_Return iCounter
    End_Function

    // Returns a string array with all *.dat related files from the passed sPath parameter,
    // as a string array.
    Function CollectFilteredFiles String sPath String sFilter Returns String[]
        Integer iCh iItem
        String sLine sExt 
        String[] asFiles asExt
        
        Get Seq_New_Channel to iCh
        If (iCh < 1) Begin
            Error DFERR_PROGRAM "No free channel to read *.dat files to string array."
            Function_Return asFiles
        End
        
        Move (StrSplitToArray(sFilter, ",")) to asExt
        Direct_Input channel iCh ("dir:" * String(sPath))
        Repeat
            Readln sLine
            Get ParseFileExtension sLine to sExt
            Move (SearchArray(sExt, asExt, Desktop, (RefFunc(DFSTRICMP)))) to iItem
            If (iItem <> -1) Begin
                Move sLine to asFiles[-1]
            End
        Until (SeqEof)
        Close_Input channel iCh
        Send Seq_Release_Channel iCh
        
        Function_Return asFiles
    End_Function

    Function SanitizeDatRelatedFiles String[] asFiles String[] asDatFilesInUse Returns String[]
        Integer iSize iCount iItem
        
        // We add these files to the .dat files array as we don't want them to be moved:
        Move "dbversion.dat" to asDatFilesInUse[-1]
        Move "flexerrs.dat"  to asDatFilesInUse[-1]
        Move "dferr001.dat"  to asDatFilesInUse[-1]
        Move "dferr002.dat"  to asDatFilesInUse[-1]
        Move "dferr003.dat"  to asDatFilesInUse[-1]  
        Move (SizeOfArray(asDatFilesInUse)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Move (SearchArray(asDatFilesInUse[iCount], asFiles, Desktop, (RefFunc(DFSTRICMP)))) to iItem
            If (iItem <> -1) Begin
                Get RemoveArrayDatRelatedFiles asFiles asDatFilesInUse[iCount] to asFiles
            End
        Loop
        
        Function_Return asFiles
    End_Function

    // Removes all files with the same name as param sFileName, without the extension,
    // from the passed asFiles string array.
    Function RemoveArrayDatRelatedFiles String[] asFiles String sFileName Returns String[]
        String sExt sFileNameShortOrg sFileNameShortNew
        Integer iSize iItem
        
        Move (SizeOfArray(asFiles)) to iSize
        If (iSize = 0) Begin
            Function_Return asFiles
        End

        Get ParseFileExtension sFileName to sExt
        Move (Replace("." + sExt, sFileName, "")) to sFileNameShortOrg
        Move (SearchArray(sFileName, asFiles, Desktop, (RefFunc(DFSTRICMP)))) to iItem
        If (iItem = -1) Begin
            Function_Return asFiles
        End
        Repeat
            Move (RemoveFromArray(asFiles, iItem)) to asFiles
            If (iItem < SizeOfArray(asFiles)) Begin
                Get ParseFileExtension asFiles[iItem] to sExt
                Move (Replace("." + sExt, asFiles[iItem], "")) to sFileNameShortNew 
            End
        Until (Lowercase(sFileNameShortOrg) <> Lowercase(sFileNameShortNew) or iItem >= SizeOfArray(asFiles))
        
        Function_Return asFiles    
    End_Function

    Function InUseDatFiles Returns String[]
        tFilelist[] FilelistTables 
        String[] asFiles
        Integer iSize iCount
        Boolean bIsIntTable
        
        Get pFileListArray of ghoDUF to FileListTables
        If (SizeOfArray(FilelistTables) = 0) Begin
            Send RefreshData
            Get pFileListArray of ghoDUF to FileListTables
        End
        Move (SizeOfArray(FilelistTables)) to iSize
        Decrement iSize
        For iCount from 0 to iSize
            Get _IsIntEntry of ghoDUF FilelistTables[iCount].hTable to bIsIntTable
            If (bIsIntTable = False and FilelistTables[iCount].bIsAlias = False and FilelistTables[iCount].sDriver = DATAFLEX_ID) Begin
                Move (FilelistTables[iCount].sRootName + ".dat") to asFiles[-1]
            End
        Loop
        Function_Return asFiles
    End_Function
                
    // To remove any "Alias" word from the DisplayName
    Function RemoveDisplayNameAlias Handle hTable String sDisplayNameOrg Returns String
        Integer iPos
        String sDisplayNameNew
        Move sDisplayNameOrg to sDisplayNameNew
        If (Lowercase(sDisplayNameOrg) contains "alias") Begin
            Move (Pos("alias", Lowercase(sDisplayNameOrg))) to iPos
            Move (Overstrike("XXXXXXX", sDisplayNameOrg, iPos -1)) to sDisplayNameNew
            Move (Replace("XXXXXXX", sDisplayNameNew, "")) to sDisplayNameNew
            Set_Attribute DF_FILE_DISPLAY_NAME of hTable to sDisplayNameNew
        End
        Function_Return sDisplayNameNew
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
    
    Procedure WriteError String sErrorText
        Integer iCh
        Boolean bOpenLogFile
        
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
        Get DriverIndex of ghoDUF sDriver to iDriver
        // Note: If Ignore_Ucase_Support is set to false, the Connectivity Kit will 
        //       behave the same as earlier driver versions.
        //       This means that "U_" columns will be kept during a restructure.
        Set_Attribute DF_DRIVER_IGNORE_UCASE_SUPPORT of iDriver to True
    End_Procedure
    
    Procedure ClearData
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

    On_Key kClear Send RefreshData
End_Object    
