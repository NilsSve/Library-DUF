// *** The Database Update Framework Include file for Languages ***
// Language constant declarations for all classes included in "DUF - The Database Update Framework"
// They have all been placed in this central spot to make translations to various languages more convenient.
//
Use LanguageText.pkg

#IFSAME Language$Current Language$English
    // *** cSQLConnectionsIniFile.pkg Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Cannot register connection ID"
    Define CS_DUF_DuplicateConnectionIDPost for "This ID already exists."
    // *** cSQLConnectionsHandler.pkg Class Language Constants ***
    Define CS_DUF_SetupErrorcConnection     for "Cannot login to the database server as the cConnection hasn't been setup properly. Can't continue. Program will now exit."
    Define CS_DUF_CannotLoginToServer       for "Could not login to the database server. Can't continue. Program will now exit."
    Define CS_DUF_ErrorText                 for "\n\nError Text:"
    // *** cDbUpdateFunctionLibrary.pkg Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL error. Could not connect to the SQL database manager"
    Define CS_DUF_AttachError               for "Could not attach to the database:"
    Define CS_DUF_DeletingIndex             for "Deleting index"
    Define CS_DUF_CopyingData               for "Copying data"
    Define CS_DUF_CreatingIndex             for "Creating index"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"  
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion.pkg Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Updating database"
    Define CS_DUF_UpdateFromVersion         for "from version"
    Define CS_DUF_UpdateToVersion           for "to version:"
    Define CS_DUF_DbUpdateTableMissing      for "Cannot open the 'DbVersion' table that is used when updating the database! Cannot continue!"
    // *** cDbUpdateHandler.h.pkg Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("The database needs to be updated." + "\n\nATTENTION! The database may not be in use while this work is performed. Make sure that nobody else is using the application before clicking 'Yes' below.\n\n" + "Start update now?")
    Define CS_DUF_HeaderUpdateText          for "Important!"
    Define CS_DUF_DatabaseInUseText         for "There are others using the application/database or at least one table could NOT be opened exclusively. Please close all other applications using the database and try again. The Application will now close."
    Define CS_DUF_WorkingHeaderText         for "Working!"
    Define CS_DUF_WorkingUpdateText         for "The database is being updated. Please wait..."
    Define CS_DUF_DatabaseUpdatedText       for "Ready! The database was updated."
    Define CS_DUF_DatabaseCheckedText       for "Ready! The database was checked but no updates was needed."
    Define CS_DUF_DbUpdatedErrorText        for "One or more errors occured while the database was updated. Please check the logfile in the data-folder.\n\nThe program will now close."
    Define CS_DUF_UpdateInProgressTxt       for ("System locked!\n\nThe database is being updated. Please try again later...\n\n" * "The program will now close.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Nederlands
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Kan de connection ID niet registreren"
    Define CS_DUF_DuplicateConnectionIDPost for "Deze ID bestaat al."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Kan niet inloggen op de databaseserver, omdat cConnection niet correct is ingesteld. Kan niet doorgaan. Het programma wordt beëindigd."
    Define CS_DUF_CannotLoginToServer       for "Kan niet inloggen op de databaseserver. Kan niet doorgaan. Het programma wordt beëindigd."
    Define CS_DUF_ErrorText                 for "\n\nFoutmelding:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL fout. Kon geen verbinding maken met de SQL database manager"
    Define CS_DUF_AttachError               for "Kan niet aan de database koppelen:"
    Define CS_DUF_DeletingIndex             for "Verwijderen index"
    Define CS_DUF_CopyingData               for "Kopiëren data"
    Define CS_DUF_CreatingIndex             for "Aanmaken index"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Bijwerken database"
    Define CS_DUF_UpdateFromVersion         for "van versie"
    Define CS_DUF_UpdateToVersion           for "naar versie:"
    Define CS_DUF_DbUpdateTableMissing for "Kan de 'DbVersion' tabel niet openen, die wordt gebruikt bij het bijwerken van de database! Kan niet doorgaan!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("De database moet worden bijgewerkt." + "\n\nNB! De database mag niet in gebruik zijn, terwijl deze bewerking wordt uitgevoerd. Zorg ervoor dat niemand anders de toepassing gebruikt voordat u hieronder 'Ja' klikt.\n\n" + "Beginnen met bijwerken?")
    Define CS_DUF_HeaderUpdateText          for "Belangrijk!"
    Define CS_DUF_DatabaseInUseText         for "Er zijn anderen die de applicatie / database gebruiken of tenminste één tabel kan NIET exclusief geopend worden. Sluit alstublieft alle andere applicaties met behulp van de database en probeer het opnieuw. De applicatie zal nu sluiten."
    Define CS_DUF_WorkingHeaderText         for "Bezig!"
    Define CS_DUF_WorkingUpdateText         for "De database wordt bijgewerkt. Even geduld a.u.b. ..."
    Define CS_DUF_DatabaseUpdatedText       for "Klaar! De database is bijgewerkt."
    Define CS_DUF_DatabaseCheckedText       for "Klaar! De database is gecontroleerd, maar er waren geen updates nodig."
    Define CS_DUF_DbUpdatedErrorText        for "Er zijn één of meerdere fouten opgetreden tijdens het bijwerken van de database. Controleer het logbestand.\n\nHet programma wordt nu beëindigd."
    Define CS_DUF_UpdateInProgressTxt       for ("Het systeem is vergrendeld!\n\nDe database wordt bijgewerkt. Probeer het later nogmaals...\n\n" * "Het programma wordt nu beëindigd.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Svenska
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Kan inte registrera anslutnings-ID"
    Define CS_DUF_DuplicateConnectionIDPost for "Detta ID finns redan."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Kan inte logga in på databasservern därför att en 'cConnection' inte har konfigurerats. Kan ej fortsätta. Programmet kommer nu att avbrytas."
    Define CS_DUF_CannotLoginToServer       for "Kunde ej logga in till databasservern. Kan ej fortsätta. Programmet kommer nu att avslutas."
    Define CS_DUF_ErrorText                 for "\n\nError Text:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL Fel. Kunde ej få kontakt med SQL Database Manager"
    Define CS_DUF_AttachError               for "Fick ej kontakt med databasen:"
    Define CS_DUF_DeletingIndex             for "Tar bort index"
    Define CS_DUF_CopyingData               for "Kopierar data"
    Define CS_DUF_CreatingIndex             for "Skapar index"
    Define CS_DUF_LoginToDbServerFailed     for "Login till databaservern misslyckades. Följande inloggningssträng användes vid försöket:\n"
    Define CS_DUF_DoYouWantToExit           for "Vill du avbryta databasuppdateringen och avsluta programmet?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Uppdaterar databas"
    Define CS_DUF_UpdateFromVersion         for "från version"
    Define CS_DUF_UpdateToVersion           for "till version:"
    Define CS_DUF_DbUpdateTableMissing      for "Kan inte öppna 'DbVersion' tabellen som används då databasen ska uppdateras! Kan inte fortsätta!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("Databasen behöver uppdateras." + "\n\nOBS! Databasen får ej användas medan detta arbete sker. Var god och säkerställ att ingen annan kör programmet eller på annat sätt använder databasen som används för programmet innan du klicka på 'Ja' nedan.\n\n" + "Starta uppdateringen nu?")
    Define CS_DUF_HeaderUpdateText          for "Viktigt!"
    Define CS_DUF_DatabaseInUseText         for "Det verkar finnas andra personer som kör programmet eller använder databasen, eftersom åtminstone en tabell ej kunde öppnas exklusivt. Var vänlig stäng alla andra applikationer som kan använda databasen och försök igen. Programmet kommer nu att avslutas."
    Define CS_DUF_WorkingHeaderText         for "Arbetar!"
    Define CS_DUF_WorkingUpdateText         for "Databasen håller på att uppdateras. Var god vänta..."
    Define CS_DUF_DatabaseUpdatedText       for "Klart! Databasen är nu uppdaterad."
    Define CS_DUF_DatabaseCheckedText       for "Ready! The database was checked but no updates was needed."
    Define CS_DUF_DbUpdatedErrorText        for "Ett eller flera fel uppstod tyvärr under uppdateringen av databasen. Var god kontrollera fel-loggen i data-katalogen.\n\nProgrammet kommer nu att avslutas."
    Define CS_DUF_UpdateInProgressTxt       for ("Systemet är låst!\n\nDatabasen håller på att uppdateras. Var god vänta och försök åter senare...\n\n" * "Programmet kommer nu att avslutas.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Deutsch
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Kann Connection ID nicht registrieren"
    Define CS_DUF_DuplicateConnectionIDPost for "Dieses ID existiert schon."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Anmeldung am Datenbank-Server nicht möglich, die cConnection ist nicht richtig eingerichtet. Fortfahren nicht möglich. Das Programm wird beendet."
    Define CS_DUF_CannotLoginToServer       for "Anmeldung am Datenbank-Server nicht möglich. Fortfahren nicht möglich. Das Programm wird beendet."
    Define CS_DUF_ErrorText                 for "\n\nFehler Text:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL Fehler. Verbindung zum SQL Datenbank Manager nicht möglich."
    Define CS_DUF_AttachError               for "Verbindung zur Datenbank fehlgeschlagen:"
    Define CS_DUF_DeletingIndex             for "Index löschen"
    Define CS_DUF_CopyingData               for "Daten kopieren"
    Define CS_DUF_CreatingIndex             for "Index erstellen"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Datenbank aktualisieren"
    Define CS_DUF_UpdateFromVersion         for "von Version"
    Define CS_DUF_UpdateToVersion           for "auf Version:"
    Define CS_DUF_DbUpdateTableMissing      for "Kann die Tabelle 'DbVersion' nicht öffnen, die zum Aktualisieren der Datenbank benutzt wird! Fortfahren nicht möglich!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("Die Datenbank muss aktualisiert werden." + "\n\nNB! Die Datenbank darf während dieses Prozesses nicht in Benutzung sein. Stellen Sie sicher, dass niemand das Programm benutzt, bevor Sie unten 'Ja' klicken.\n\n" + "Jetzt starten?")
    Define CS_DUF_HeaderUpdateText          for "Wichtig!"
    Define CS_DUF_DatabaseInUseText         for "Andere Benutzer benutzen das Programm/die Datenbank. Zumindest eine Tabelle konnte nicht EXCLUSIV geöffnet werden. Bitte schliessen Sie alle anderen Programme, die die Datenbank benutzen und versuchen Sie es erneut. Das Programm wir jetzt beendet."
    Define CS_DUF_WorkingHeaderText         for "Arbeite!"
    Define CS_DUF_WorkingUpdateText         for "Die Datenbank wird aktualisiert. Bitte warten..."
    Define CS_DUF_DatabaseUpdatedText       for "Fertig! Die Datenbank ist aktualisiert."
    Define CS_DUF_DatabaseCheckedText       for "Fertig! Die Datenbank wurde überprüft, es ist aber keine Aktualisierung notwendig."
    Define CS_DUF_DbUpdatedErrorText        for "Ein oder mehrere Fehler sind während der Aktualisierung aufgetreten. Bitte schauen Sie in die Log-Datei.\n\nDas Programm wird jetzt beendet."
    Define CS_DUF_UpdateInProgressTxt       for ("System gesperrt!\n\nDie Datenbank wird aktualisiert. Bitte versuchen Sie es später wieder...\n\n" * "Das Programm wird jetzt beendet.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Dansk
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Cannot register connection ID"
    Define CS_DUF_DuplicateConnectionIDPost for "This ID already exists."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Cannot login to the database server as the cConnection hasn't been setup properly. Can't continue. Program will now exit."
    Define CS_DUF_CannotLoginToServer       for "Could not login to the database server. Can't continue. Program will now exit."
    Define CS_DUF_ErrorText                 for "\n\nError Text:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL error. Could not connect to the SQL database manager"
    Define CS_DUF_AttachError               for "Could not attach to the database:"
    Define CS_DUF_DeletingIndex             for "Deleting index"
    Define CS_DUF_CopyingData               for "Copying data"
    Define CS_DUF_CreatingIndex             for "Creating index"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Updating database"
    Define CS_DUF_UpdateFromVersion         for "from version"
    Define CS_DUF_UpdateToVersion           for "to version:"
    Define CS_DUF_DbUpdateTableMissing      for "Cannot open the 'DbVersion' table that is used when updating the database! Cannot continue!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("The database needs to be updated." + "\n\nATTENTION! The database may not be in use while this work is performed. Make sure that nobody else is using the application before clicking 'Yes' below.\n\n" + "Start update now?")
    Define CS_DUF_HeaderUpdateText          for "Important!"
    Define CS_DUF_DatabaseInUseText         for "There are others using the application/database or at least one table could NOT be opened exclusively. Please close all other applications using the database and try again. The Application will now close."
    Define CS_DUF_WorkingHeaderText         for "Working!"
    Define CS_DUF_WorkingUpdateText         for "The database is being updated. Please wait..."
    Define CS_DUF_DatabaseUpdatedText       for "Ready! The database was updated."
    Define CS_DUF_DatabaseCheckedText       for "Ready! The database was checked but no updates was needed."
    Define CS_DUF_DbUpdatedErrorText        for "One or more errors occured while the database was updated. Please check the logfile in the data-folder.\n\nThe program will now close."
    Define CS_DUF_UpdateInProgressTxt       for ("System locked!\n\nThe database is being updated. Please try again later...\n\n" * "The program will now close.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Portugues
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "NÒo p¶de registar o ID de conexÒo"
    Define CS_DUF_DuplicateConnectionIDPost for "Este ID jß existe."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "NÒo p¶de conectar-se ao servidor de banco de dados, pois o objeto cConnetion nÒo fora configurado adequadamente. ImpossÝvel continuar. Programa serß encerrado."
    Define CS_DUF_CannotLoginToServer       for "NÒo p¶de conectar-se ao servidor de banco de dados. ImpossÝvel continuar. Programa serß encerrado."
    Define CS_DUF_ErrorText                 for "\n\nDescriþÒo do Erro:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "Erro SQL. NÒo foi possÝvel conectar-se ao gerenciador de banco de dados SQL"
    Define CS_DUF_AttachError               for "NÒo foi possÝvel anexar-se ao banco de dados:"
    Define CS_DUF_DeletingIndex             for "Excluindo Ýndice"
    Define CS_DUF_CopyingData               for "Copiando dados"
    Define CS_DUF_CreatingIndex             for "Criando Ýndice"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Atualizando banco de dados"
    Define CS_DUF_UpdateFromVersion         for "da versÒo"
    Define CS_DUF_UpdateToVersion           for "para a versÒo:"
    Define CS_DUF_DbUpdateTableMissing      for "NÒo foi possiel abrir a tabela 'DbVersion' que Ú utilizada durante o processo de atualizaþÒo do banco de dados.! ImpossÝvel continuar!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("O banco de dados precisa ser atualizado." + "\n\nAtenþÒo! O banco de dados nÒo pode ser utilizado enquanto essa tarefa Ú executada. Certifique-se de que ninguÚm mais esteja utilizando a aplicaþÒo antes de clicar em 'Sim' abaixo.\n\n" + "Iniciar a atualizaþÒo agora?")
    Define CS_DUF_HeaderUpdateText          for "Importante!"
    Define CS_DUF_DatabaseInUseText         for "Existem outros usußrios usando a aplicaþÒo/banco de dados ou pelo menos uma tabela nÒo p¶de ser aberta em modo exclusivo. Por favor, encerre todas as aplicaþ§es que usam esse banco de dados e tente novamente. Esse Aplicativo serß encerrado agora."
    Define CS_DUF_WorkingHeaderText         for "Trabalhando!"
    Define CS_DUF_WorkingUpdateText         for "O banco de dados estß sendo atualizado. Por favor aguarde ..."
    Define CS_DUF_DatabaseUpdatedText       for "Pronto! O banco de dados foi atualizado."
    Define CS_DUF_DatabaseCheckedText       for "Pronto! O banco de dados foi verificado mas nenhuma atualizaþÒo era necessßria."
    Define CS_DUF_DbUpdatedErrorText        for "Um ou mais erros aconteceram enquanto o banco de dados era atualizado. Por favor verifique o arquivo de log.\n\nO programa serß encerrado."
    Define CS_DUF_UpdateInProgressTxt       for ("Sistema bloqueado!\n\nO banco de dados estß sendo atualizado. Por favor tente novamente mais tarde...\n\n" * "O programa serß encerrado.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Francais
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Cannot register connection ID"
    Define CS_DUF_DuplicateConnectionIDPost for "This ID already exists."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Cannot login to the database server as the cConnection hasn't been setup properly. Can't continue. Program will now exit."
    Define CS_DUF_CannotLoginToServer       for "Could not login to the database server. Can't continue. Program will now exit."
    Define CS_DUF_ErrorText                 for "\n\nError Text:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL error. Could not connect to the SQL database manager"
    Define CS_DUF_AttachError               for "Could not attach to the database:"
    Define CS_DUF_DeletingIndex             for "Deleting index"
    Define CS_DUF_CopyingData               for "Copying data"
    Define CS_DUF_CreatingIndex             for "Creating index"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Updating database"
    Define CS_DUF_UpdateFromVersion         for "from version"
    Define CS_DUF_UpdateToVersion           for "to version:"
    Define CS_DUF_DbUpdateTableMissing      for "Cannot open the 'DbVersion' table that is used when updating the database! Cannot continue!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("The database needs to be updated." + "\n\nATTENTION! The database may not be in use while this work is performed. Make sure that nobody else is using the application before clicking 'Yes' below.\n\n" + "Start update now?")
    Define CS_DUF_HeaderUpdateText          for "Important!"
    Define CS_DUF_DatabaseInUseText         for "There are others using the application/database or at least one table could NOT be opened exclusively. Please close all other applications using the database and try again. The Application will now close."
    Define CS_DUF_WorkingHeaderText         for "Working!"
    Define CS_DUF_WorkingUpdateText         for "The database is being updated. Please wait..."
    Define CS_DUF_DatabaseUpdatedText       for "Ready! The database was updated."
    Define CS_DUF_DatabaseCheckedText       for "Ready! The database was checked but no updates was needed."
    Define CS_DUF_DbUpdatedErrorText        for "One or more errors occured while the database was updated. Please check the logfile in the data-folder.\n\nThe program will now close."
    Define CS_DUF_UpdateInProgressTxt       for ("System locked!\n\nThe database is being updated. Please try again later...\n\n" * "The program will now close.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Italiano
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Cannot register connection ID"
    Define CS_DUF_DuplicateConnectionIDPost for "This ID already exists."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Cannot login to the database server as the cConnection hasn't been setup properly. Can't continue. Program will now exit."
    Define CS_DUF_CannotLoginToServer       for "Could not login to the database server. Can't continue. Program will now exit."
    Define CS_DUF_ErrorText                 for "\n\nError Text:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL error. Could not connect to the SQL database manager"
    Define CS_DUF_AttachError               for "Could not attach to the database:"
    Define CS_DUF_DeletingIndex             for "Deleting index"
    Define CS_DUF_CopyingData               for "Copying data"
    Define CS_DUF_CreatingIndex             for "Creating index"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Updating database"
    Define CS_DUF_UpdateFromVersion         for "from version"
    Define CS_DUF_UpdateToVersion           for "to version:"
    Define CS_DUF_DbUpdateTableMissing      for "Cannot open the 'DbVersion' table that is used when updating the database! Cannot continue!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("The database needs to be updated." + "\n\nATTENTION! The database may not be in use while this work is performed. Make sure that nobody else is using the application before clicking 'Yes' below.\n\n" + "Start update now?")
    Define CS_DUF_HeaderUpdateText          for "Important!"
    Define CS_DUF_DatabaseInUseText         for "There are others using the application/database or at least one table could NOT be opened exclusively. Please close all other applications using the database and try again. The Application will now close."
    Define CS_DUF_WorkingHeaderText         for "Working!"
    Define CS_DUF_WorkingUpdateText         for "The database is being updated. Please wait..."
    Define CS_DUF_DatabaseUpdatedText       for "Ready! The database was updated."
    Define CS_DUF_DatabaseCheckedText       for "Ready! The database was checked but no updates was needed."
    Define CS_DUF_DbUpdatedErrorText        for "One or more errors occured while the database was updated. Please check the logfile in the data-folder.\n\nThe program will now close."
    Define CS_DUF_UpdateInProgressTxt       for ("System locked!\n\nThe database is being updated. Please try again later...\n\n" * "The program will now close.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Espanol
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "No se puede registrar conexión ID"
    Define CS_DUF_DuplicateConnectionIDPost for "Este ID ya existe."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "No se puede iniciar sesión en el servidor de base de datos ya que la conexión no se ha configurado correctamente. No se puede continuar. El programa será cerrado."
    Define CS_DUF_CannotLoginToServer       for "No se puede iniciar sesión en el servidor de base de datos. No se puede continuar. El programa será cerrado."
    Define CS_DUF_ErrorText                 for "\n\nTexto del error:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "Error SQL. No se puede conectar al administrador de base de datos SQL"
    Define CS_DUF_AttachError               for "No se puede adjuntar a la base de datos"
    Define CS_DUF_DeletingIndex             for "Eliminando índice"
    Define CS_DUF_CopyingData               for "Copiando datos"
    Define CS_DUF_CreatingIndex             for "Creando índice"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Actualizando base de datos"
    Define CS_DUF_UpdateFromVersion         for "desde versión"
    Define CS_DUF_UpdateToVersion           for "hasta versión:"
    Define CS_DUF_DbUpdateTableMissing      for "No se puede abrir la tabla 'DbVersion' que se utiliza al actualizar la base de datos! No se puede continuar!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("La base de datos necesita ser actualizada." + "\n\nNB! La base datos no puede estar en uso mientras se ejecuta esta tarea. Asegúrese de que nadie más esté usando la aplicación antes de hacer clic en 'Sí'.\n\n" + "Iniciar actualización ahora")
    Define CS_DUF_HeaderUpdateText          for "Importante!"
    Define CS_DUF_DatabaseInUseText         for "Hay otros utilizando la aplicación / base de datos o por lo menos una tabla. No se pudo abrir exclusivamente. Cierre todas las demás aplicaciones que utilizan la base de datos y vuelva a intentarlo. La aplicación se cerrará ahora."
    Define CS_DUF_WorkingHeaderText         for "Trabajando!"
    Define CS_DUF_WorkingUpdateText         for "a base de datos se esta actualizando. Por favor espere..."
    Define CS_DUF_DatabaseUpdatedText       for "Listo! La base de datos fue actualizada."
    Define CS_DUF_DatabaseCheckedText       for "Listo! Se verificó la base de datos y no fue necesario actualizar."
    Define CS_DUF_DbUpdatedErrorText        for "Uno o más errores ocurrieron mientras se actualizaba la base de datos. Por favor verifique el archivo de registro.\n\nEl programa será cerrado ahora."
    Define CS_DUF_UpdateInProgressTxt       for ("Sistema bloqueado!\n\nLa base de datos está siendo actualizada. Por favor, inténtelo de nuevo más tarde...\n\n" * "El programa será cerrado ahora.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSAME Language$Current Language$Norsk
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Kan ikke registrere tilkoblings-ID"
    Define CS_DUF_DuplicateConnectionIDPost for "Denne ID-en eksisterer allerede."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Kan ikke logge p├Ñ databasetjener, for cConnection er ikke riktig satt opp. Kan ikke fortsette. Programmet avsluttes."
    Define CS_DUF_CannotLoginToServer       for "Kan ikke logge p├Ñ databasetjener. Kan ikke fortsette. Programmet avsluttes."
    Define CS_DUF_ErrorText                 for "\n\nFeilbeskrivelse:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL-feil. Kunne ikke koble til SQL-databasebehandler"
    Define CS_DUF_AttachError               for "Kunne ikke koble til database:"
    Define CS_DUF_DeletingIndex             for "Sletter indeks"
    Define CS_DUF_CopyingData               for "Kopierer data"
    Define CS_DUF_CreatingIndex             for "Oppretter indeks"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Oppdaterer database"
    Define CS_DUF_UpdateFromVersion         for "fra versjon"
    Define CS_DUF_UpdateToVersion           for "til versjon:"
    Define CS_DUF_DbUpdateTableMissing      for "Kan ikke ├Ñpne 'DbVersion'-tabellen som brukes ved oppdatering av databasen! Kan ikke fortsette!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("Database m├Ñ oppdateres." + "\n\nNB! Databasen m├Ñ ikke v├ªre i bruk mens dette p├Ñg├Ñr. P├Ñse at ingen andre bruker databasen/programmet f├©r du velger 'Ja' nedenfor.\n\n" + "Starte oppdatering n├Ñ?")
    Define CS_DUF_HeaderUpdateText          for "Viktig!"
    Define CS_DUF_DatabaseInUseText         for "Andre bruker programmet/databasen, eller minst en tabell kunne IKKE ├Ñpnes eksklusivt. Steng alle andre programmer som bruker databasen og fors├©k igjen. Programmet avsluttes n├Ñ."
    Define CS_DUF_WorkingHeaderText         for "Arbeider!"
    Define CS_DUF_WorkingUpdateText         for "Databasen oppdateres. Vennligst vent..."
    Define CS_DUF_DatabaseUpdatedText       for "Klar! Databasen ble oppdatert."
    Define CS_DUF_DatabaseCheckedText       for "Klar! Database ble sjekket, men ingen oppdatering var n├©dvendig."
    Define CS_DUF_DbUpdatedErrorText        for "En eller flere feil oppsto under oppdatering av databasen. Sjekk loggfil i data-kataloge.\n\nProgrammet avsluttes."
    Define CS_DUF_UpdateInProgressTxt       for ("System l├Ñst!\n\nDatabasen blir oppdatert. Pr├©v igjen senere...\n\n" * "Programmet avsluttes.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSame Language$Current = Language$Russian
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Cannot register connection ID"
    Define CS_DUF_DuplicateConnectionIDPost for "This ID already exists."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Cannot login to the database server as the cConnection hasn't been setup properly. Can't continue. Program will now exit."
    Define CS_DUF_CannotLoginToServer       for "Could not login to the database server. Can't continue. Program will now exit."
    Define CS_DUF_ErrorText                 for "\n\nError Text:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL error. Could not connect to the SQL database manager"
    Define CS_DUF_AttachError               for "Could not attach to the database:"
    Define CS_DUF_DeletingIndex             for "Deleting index"
    Define CS_DUF_CopyingData               for "Copying data"
    Define CS_DUF_CreatingIndex             for "Creating index"
    Define CS_DUF_LoginToDbServerFailed     for "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Updating database"
    Define CS_DUF_UpdateFromVersion         for "from version"
    Define CS_DUF_UpdateToVersion           for "to version:"
    Define CS_DUF_DbUpdateTableMissing      for "Cannot open the 'DbVersion' table that is used when updating the database! Cannot continue!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("The database needs to be updated." + "\n\nATTENTION! The database may not be in use while this work is performed. Make sure that nobody else is using the application before clicking 'Yes' below.\n\n" + "Start update now?")
    Define CS_DUF_HeaderUpdateText          for "Important!"
    Define CS_DUF_DatabaseInUseText         for "There are others using the application/database or at least one table could NOT be opened exclusively. Please close all other applications using the database and try again. The Application will now close."
    Define CS_DUF_WorkingHeaderText         for "Working!"
    Define CS_DUF_WorkingUpdateText         for "The database is being updated. Please wait..."
    Define CS_DUF_DatabaseUpdatedText       for "Ready! The database was updated."
    Define CS_DUF_DatabaseCheckedText       for "Ready! The database was checked but no updates was needed."
    Define CS_DUF_DbUpdatedErrorText        for "One or more errors occured while the database was updated. Please check the logfile in the data-folder.\n\nThe program will now close."
    Define CS_DUF_UpdateInProgressTxt       for ("System locked!\n\nThe database is being updated. Please try again later...\n\n" * "The program will now close.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSame Language$Current = Language$Polish
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Cannot register connection ID"
    Define CS_DUF_DuplicateConnectionIDPost for "This ID already exists."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Cannot login to the database server as the cConnection hasn't been setup properly. Can't continue. Program will now exit."
    Define CS_DUF_CannotLoginToServer       for "Could not login to the database server. Can't continue. Program will now exit."
    Define CS_DUF_ErrorText                 for "\n\nError Text:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL error. Could not connect to the SQL database manager"
    Define CS_DUF_AttachError               for "Could not attach to the database:"
    Define CS_DUF_DeletingIndex             for "Deleting index"
    Define CS_DUF_CopyingData               for "Copying data"
    Define CS_DUF_CreatingIndex             for "Creating index"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Updating database"
    Define CS_DUF_UpdateFromVersion         for "from version"
    Define CS_DUF_UpdateToVersion           for "to version:"
    Define CS_DUF_DbUpdateTableMissing      for "Cannot open the 'DbVersion' table that is used when updating the database! Cannot continue!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("The database needs to be updated." + "\n\nATTENTION! The database may not be in use while this work is performed. Make sure that nobody else is using the application before clicking 'Yes' below.\n\n" + "Start update now?")
    Define CS_DUF_HeaderUpdateText          for "Important!"
    Define CS_DUF_DatabaseInUseText         for "There are others using the application/database or at least one table could NOT be opened exclusively. Please close all other applications using the database and try again. The Application will now close."
    Define CS_DUF_WorkingHeaderText         for "Working!"
    Define CS_DUF_WorkingUpdateText         for "The database is being updated. Please wait..."
    Define CS_DUF_DatabaseUpdatedText       for "Ready! The database was updated."
    Define CS_DUF_DatabaseCheckedText       for "Ready! The database was checked but no updates was needed."
    Define CS_DUF_DbUpdatedErrorText        for "One or more errors occured while the database was updated. Please check the logfile in the data-folder.\n\nThe program will now close."
    Define CS_DUF_UpdateInProgressTxt       for ("System locked!\n\nThe database is being updated. Please try again later...\n\n" * "The program will now close.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF

#IFSame Language$Current = Language$Hungarian
    // *** cSQLConnectionsIniFile Class Language Constants ***
    Define CS_DUF_DuplicateConnectionIDPre  for "Cannot register connection ID"
    Define CS_DUF_DuplicateConnectionIDPost for "This ID already exists."
    // *** cSQLConnectionsHandler Class Language Constants ***
    Define CS_DUF_CannotLogincConnection    for "Cannot login to the database server as the cConnection hasn't been setup properly. Can't continue. Program will now exit."
    Define CS_DUF_CannotLoginToServer       for "Could not login to the database server. Can't continue. Program will now exit."
    Define CS_DUF_ErrorText                 for "\n\nError Text:"
    // *** cDbUpdateFunctionLibrary Class Language Constants ***
    Define CS_DUF_ConnectError              for "SQL error. Could not connect to the SQL database manager"
    Define CS_DUF_AttachError               for "Could not attach to the database:"
    Define CS_DUF_DeletingIndex             for "Deleting index"
    Define CS_DUF_CopyingData               for "Copying data"
    Define CS_DUF_CreatingIndex             for "Creating index"
    Define CS_DUF_LoginToDbServerFailed     for  "Login failed to the database server. The following connect string was used:\n"
    Define CS_DUF_DoYouWantToExit           for "Do you want to stop the database update and exit?"
    Define CS_DUF_NoIntFilesFound           for "No .int files found! Nothing was changed."
    // *** cDbUpdateVersion Class Language Constants ***
    Define CS_DUF_UpdateVersion             for "Updating database"
    Define CS_DUF_UpdateFromVersion         for "from version"
    Define CS_DUF_UpdateToVersion           for "to version:"
    Define CS_DUF_DbUpdateTableMissing      for "Cannot open the 'DbVersion' table that is used when updating the database! Cannot continue!"
    // *** cDbUpdateHandler.h.pkg Class Language Constants ***
    Define CS_DUF_DatabaseInUseShort        for "There are others using the application/database. Are you sure you still want to update the database?"
    Define CS_DUF_DatabaseNeedsUpdate       for ("The database needs to be updated." + "\n\nATTENTION! The database may not be in use while this work is performed. Make sure that nobody else is using the application before clicking 'Yes' below.\n\n" + "Start update now?")
    Define CS_DUF_HeaderUpdateText          for "Important!"
    Define CS_DUF_DatabaseInUseText         for "There are others using the application/database or at least one table could NOT be opened exclusively. Please close all other applications using the database and try again. The Application will now close."
    Define CS_DUF_WorkingHeaderText         for "Working!"
    Define CS_DUF_WorkingUpdateText         for "The database is being updated. Please wait..."
    Define CS_DUF_DatabaseUpdatedText       for "Ready! The database was updated."
    Define CS_DUF_DatabaseCheckedText       for "Ready! The database was checked but no updates was needed."
    Define CS_DUF_DbUpdatedErrorText        for "One or more errors occured while the database was updated. Please check the logfile in the data-folder.\n\nThe program will now close."
    Define CS_DUF_UpdateInProgressTxt       for ("System locked!\n\nThe database is being updated. Please try again later...\n\n" * "The program will now close.")
    // *** cDbUpdateHandler.pkg Class Language Constants ***
    Define CS_DUF_DatabaseConnStringSpec    for "The database specified in the connection string: '"
    Define CS_DUF_DatabaseDoesntExist       for "' doesn't exist!\n\nYou need to create it with a database management software or by using the 'SqlDatabaseCreate' function, which can be used in the 'OnPreUpdate' event of the cDbUpdateHandler object.\n\nThe program will now exit."
    // *** cDbUpdateLogFile.pkg Class Language Constants ***   
    Define CS_DUF_LogFileNotFound           for "Could not locate the log file:\n\n"
#ENDIF
