Use cRDCModalPanel.pkg
Use DFClient.pkg
Use cCJGridColumnRowIndicator.pkg 
Use cRDCCJGrid.pkg
Use cCJGridColumn.pkg
Use cDbUpdateFunctionLibrary.h.pkg
Use cRDCCJGridColumnSuggestion.pkg
Use cRDCRichEditor.pkg

Object oSQLCollations is a cRDCModalPanel
    Set Size to 251 384
    Set Location     to 4 5
    Set Border_Style to Border_Thick
    Set Label to "SQL Collations Available on the Current SQL Server"
    Set Icon to "ActionSort.ico"

    Property tSQLCollation[] paCollations
    Property tSQLCollation psSelectedCollation
    Property Boolean pbOkButton False
    
    Object oSelList is a cRDCCJGrid
        Set Size to 216 372
        Set Location  to 6 6
        Set pbHeaderPrompts to False
        Set pbAllowInsertRow to False
        Set pbAllowAppendRow to False
        Set pbEditOnClick to False

        Object oCJGridColumnRowIndicator is a cCJGridColumnRowIndicator
            Set piWidth to 5
        End_Object

        Object oCollate_col is a cRDCCJGridColumnSuggestion
            Set piWidth to 45
            Set psCaption to "Collation Name (Suggestion List)"
            Set piStartAtChar to 3
        End_Object         
        
        Object oDescript_col is a cCJGridColumn
            Set piWidth to 50
            Set psCaption to "Description"
            Set pbMultiLine to True
            Set pbEditable to False
            Set pbVDFEditControl to False
        End_Object         
        
        Procedure DoFillGrid
            Integer iSize iCount iCol1 iCol2 iIndex
            tSQLCollation[] aCollations 
            tSQLCollation Collation
            Handle hoDataSource 
            tDataSourceRow[] TheData
            
            Get phoDataSource               to hoDataSource
            Get DataSource of hoDataSource  to TheData
            Get piColumnId of oCollate_col  to iCol1
            Get piColumnId of oDescript_col to iCol2

            Get paCollations                to aCollations
            Move (SizeOfArray(aCollations)) to iSize
            Decrement iSize
            For iCount from 0 to iSize
                Move aCollations[iCount].sCollation   to TheData[iCount].sValue[iCol1]
                Move aCollations[iCount].sDescription to TheData[iCount].sValue[iCol2]
            Loop
            
            // Initialize Grid with new data
            Get psSelectedCollation to Collation
            Send InitializeData TheData

            Move (SearchArray(Collation, aCollations)) to iIndex
            If (iIndex <> -1) Begin
                Send MoveToRow iIndex
            End
            Else Begin
                Send MovetoFirstRow
            End
        End_Procedure

        Procedure OnRowChanged Integer iOldRow Integer iNewRow
            tSQLCollation collation
            Get SelectedRowValue of oCollate_col  to Collation.sCollation
            Get SelectedRowValue of oDescript_col to Collation.sDescription
            Set psSelectedCollation to Collation    
        End_Procedure
    
        Procedure Activating
            Forward Send Activating
            Send Cursor_Wait of Cursor_Control
            Send DoFillGrid
            Send Cursor_Ready of Cursor_Control
        End_Procedure
        
        On_Key kEnter Send KeyAction of oOK_bn
    End_Object

    Object oOK_bn is a Button
        Set Label     to "&OK"
        Set Location to 229 273
        Set peAnchors to anBottomRight
        Set Default_State to True

        Procedure OnClick
            Set pbOkButton to True
            Send Close_Panel
        End_Procedure

    End_Object

    Object oCancel_bn is a Button
        Set Label     to "&Cancel"
        Set Location to 229 328
        Set peAnchors to anBottomRight

        Procedure OnClick
            Set pbOkButton to False
            Send Close_Panel
        End_Procedure

    End_Object

    Procedure Deactivating
        Boolean bOkButton
        tSQLCollation Collation
        
        Get pbOkButton to bOkButton
        If (bOkButton = False) Begin
            Move "" to Collation.sCollation
            Move "" to Collation.sDescription
            Set psSelectedCollation to Collation
        End
        Forward Send Deactivating
    End_Procedure

    Procedure Activate_Dialog tSQLCollation Collation tSQLCollation[] aCollations
        Set psSelectedCollation to Collation
        Set paCollations to aCollations
        Set pbOkButton to False
        Send Popup
    End_Procedure

    On_Key Key_Alt+Key_O Send KeyAction of oOk_bn
    On_Key Key_Alt+Key_C Send KeyAction of oCancel_bn 
    On_Key kCancel       Send KeyAction of oCancel_bn
End_Object

Function ActivateSQLCollations tSQLCollation Collation tSQLCollation[] aCollations Returns tSQLCollation
    Handle ho
    
    Move (oSQLCollations(Self)) to ho
    Send Activate_Dialog of ho Collation aCollations
    Get psSelectedCollation of ho to Collation
    
    Function_Return Collation
End_Function
