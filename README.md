### DUF - Database Update Framework for DataFlex

It is highly recommended to download and install the GitHub Desktop app, as it will significantly simplify your work. You can download it via this link: https://desktop.github.com/download/.

Once installed, click the "<> Code" button at this GitHub page and select "Open with GitHub Desktop." This will install the complete repository in your chosen download location.

Note: Do not select "Download ZIP," as GitHub will not include the libraries used by the workspace, and you would need to download them manually, which can be cumbersome!

The Database Update Framework (DUF) is a code-based solution designed for automating database updates. It streamlines the process of updating databases at customer sites, particularly when installing a new software version that requires prior changes to the database.

[Click here to see the Introduction Video on YouTube](https://www.youtube.com/watch?v=D2o0zjPEr_I)

[Watch a more in-depth video about the framework](https://www.youtube.com/watch?v=VD4eN9oP0_U)

### Programs to Compile and Use

To implement the framework, you will need to compile and use two programs:
- **DUFCodeGenerator**
- **DUFSQLRepairUtility**

Additionally, you need to integrate a piece of code into your program to facilitate the automated database update. This can be done by selecting a `cDbUpdateHandler` object from the Studio's Class Palette and dragging it into your main program.

It is recommended to add the `DUFCodeGenerator.exe` and `DUFSQLRepairUtility.exe` programs to the Studio’s Tools menu. You can do this by executing the programs and clicking the “Add To Studio” button.

### Important Information

Before proceeding, please read the following help sections:
- “Welcome to the Database Update Framework”
- “Workspace Setup”
- “How to Use It”

These sections can be found in the `Developer5.chm` Help file located in the `/Help` folder. Alternatively, you can press F1 while running one of the programs for assistance.

![This is how the DUFCodeGenerator.src program looks:](Bitmaps/DUFCodeGenerator.png)

![This is what the DUFSQLRepairUtility.src program looks like:](Bitmaps/DUFFilelistRepairer.png)

The workspace also uses three other libraries from Nils Sve's GitHub page — DFAbout, RDCToolsLib and vwin32fh. As of the flattening described below, they are **no longer nested submodules of DUF**; they are separate sibling libraries. See the Dependencies section for why, and what a consuming application must do.

## What is new in 1.0.5

The review findings that 1.0.4 left for later, and a fix for the SQL Repair Utility on DataFlex 19.1 and 20.1.

The SQL Repair Utility:

- On DataFlex 19.1 and 20.1, recreating .int files and removing uppercased columns wrote an EMPTY .int file over
  the one the driver had just made; only the backup copy made before kept the old one. Relations and the DATETIME
  and hidden-column settings were not collected, and "Move *.Dat files to backup" moved nothing. The cause: an
  append written `arr[-1]` adds nothing before DataFlex 23. DUF writes every append the long way now.

The update run:

- `ApiColumnsUpdate` makes all the column changes of a table in one restructure, or none. Each step (renames,
  removals, inserts, moves) was a restructure of its own, so an update that failed half way left the table half
  changed: a removed column stayed removed. A column that is to become a Date while it holds other values stops
  the update before anything is changed.

The answers of the function library:

- A function that finds its work done already answers True, with a line in the update log: `ApiColumnAdd`,
  `ApiColumnInsert`, `ApiColumnRemove`, `ApiColumnRename`, `ApiColumnChange`, `ApiTableCreate`, `SqlTableCreate`
  and `ApiTableAttachToSql`. They answered False, as for a failure. Code that reads that False as "nothing to do"
  needs a look.
- `ApiColumnRename` with both names in the table, or neither, answers False. With neither it answered True.
- `ApiColumnChange` of a column that is not in the table is an error. It changed column 0.
- `SqlDatabaseBackupToDisk` and `SqlDatabaseDrop` raise an error for a driver they have no code for. They showed a
  message box.
- `SqlUtilEnumerateServers` shows no message box when it finds no server; a program can show
  `SqlUtilNoServersFoundText`, as the two dialogs that list servers do. `SqlUtilChangeIntFilesToConnectionIDs`
  says "no .int files" only when `bShowResult` is True.
- Root names are read one way. A root name with a drive in it (`C:\Data\Customer`) is an embedded table; it was
  looked for on the server, with an error. `Customer.int` is a table of a database driver; it was taken for an
  embedded table that is not there.
- The messages of an SQL script are logged with their numbers. Each showed number 0.
- The Microsoft SQL handler leaves out an Encrypt option it does not know. It wrote "Encrypt=;".
- `IsIntFileTable` of the update handler answers for the table it is asked about. It asked about table 0.

The programs:

- Code Generator and Test Program: Shift+Ctrl+Tab goes to the previous view. It went to the next one.
- The four selection dialogs (database, schema, server, table space) are one class, `cDUFSelectionDialog`. Three
  of them place their grid and buttons a few units differently.
- The menu items About, Ko-fi, Suggest, Help and Exit are classes in `cDUFMenuItems.pkg`. Suggest opens the same
  page in all four programs.

Inside DUF:

- The .int file backup of the update handler is a class of its own, `cDbUpdateIntFileBackup`. The handler relays
  its 16 messages, so code that sends them to the handler works as before.
- The repair work of the SQL Repair Utility is a class of its own, `cDUFFilelistRepair`, out of its view.
- `ApiTableUpdate` and the column plan are in smaller parts. Code that was written more than once is written once:
  the test for a missing SQL connection handler, the look in the server's list of tables, the script runner, the
  word of an Encrypt option (`SQLEncryptOptionWord`) and the writing of the .fd file.
- A language without texts of its own (Dansk, Francais, Italiano, Russian, Polish, Hungarian) takes the English
  texts from one place. The programs show the same texts as before.

Removed:

- `UtilColumnsCheckForInserts`, `UtilColumnsInsert`, `UtilColumnsMove`, `UtilColumnsRenameByNeighbours`,
  `UtilColumnRemoveByName` and `UtilColumnsRename`, the steps of `ApiColumnsUpdate` that each made a restructure
  of their own; and `_SqlUtilCreateMySQLDatabaseByScript` and `_SqlUtilCreatePostGreSQLDatabaseByScript`, which
  are `_SqlUtilCreateDatabaseByScript` now. A program that calls one of them no longer compiles.

121 unit tests now.

## What is new in 1.0.4

The fixes of a review of the whole source, and of a check of the SQL functions against Microsoft SQL Server.

The update run:

- A table whose logical name is not its root name was taken for an alias, and so left out of the conversion to
  SQL, the date fixing, the repair and reindex, and the test that nobody has the database open. An entry is an
  alias only when another entry with its root name is the master.
- The database version is read from a version table that is no system file too. It stayed 0, and every update
  ran at every start.
- `RestoreIntFiles` works for tables that have a cache file.
- New `pbExitOnErrorInSilentMode`: True ends the program after a failed update in silent mode. False, the
  default, goes on as before.
- The Filelist clean-up (`UtilTableFixALLBogusFilelistEntries`) empties only the slots of tables that are gone
  for sure, and names each one in the log. It emptied every slot a quick test did not find.

Connections to the database server:

- A value with "=" in it, a password above all, keeps it. A keyword counts only at the start of a part of the
  connection string; "FILEDSN=" was read as "DSN=".
- `pbSilentLogin` no longer turns a login with user and password into a Windows login.
- The Encrypt option is kept when the connections file is saved. A port, as in `SERVER=host,1433`, is no longer
  taken for the silent-login flag.
- `DriverIndex` answers 0 for a driver that is not loaded, and a connection with no driver needs no login.

The function library:

- About 30 functions that answered wrong or did nothing are repaired, among them `ApiColumnChangeByColumnNumber`,
  `SqlColumnRename`, `SqlDatabaseDrop`, `ApiTableRemove`, `ApiIndexInsertSegment`, `ApiIndexDeleteSegment` and
  the compare of version strings ("6.3" counted higher than "20.1").
- For Microsoft SQL Server, names in the SQL statements of the column functions are in brackets: a blank or a
  reserved word in a name works. A value with a quote in it is written as it is. A collation name must be one
  word; anything typed after it was run on the server.
- `SqlColumnChange` works on Microsoft SQL Server; the server refused every change. A column with a blank in its
  name gets its first value and can be removed, and `SqlColumnAdd` answers False when it cannot write the first
  value.
- The SQL script cleaner keeps the code around a comment; a line with "*/" in it was dropped whole.
- DUF uses the `MSSqldrv.pkg` of the DataFlex version again. Its own copy replaced the package of every
  DataFlex version with the one of 26.0. What it added is in `cDUFMSSQLHandler.pkg`.
- The DB2 queries read the DB2 catalogue. They are not run against a DB2 server.

The programs:

- SQL Repair Utility: Cancel tidies up; the removal of uppercased (U_) columns counts and reports right; the
  four Filelist fixes change nothing when their backup copy cannot be made.
- Code Generator: a name or default value with a double quote gives code that compiles.
- SQL Connections: Test Login, the Connection ID prompt and the collation change are repaired.
- `setup.bat` leaves sibling libraries that are there already as they are; `setup.bat /pull` updates them.

Removed, because nothing used them or they never worked:

- The stubs `SqlTableRecreateConstraints` and `SqlUtilCheckIfIndexNameExists`; `DoCheckUserCount`,
  `IsProgramRunning` and `ReadUserCountFile` of `cDbUpdateUserCount`; `NumberOfIniFileConnections` and
  `IsConnectionIDDuplicate` of `cSQLConnectionIniFile`; the class `cDbUpdatePSQLDriver`. A program that calls
  one of them no longer compiles.
- DUF's own copies of `MSSqldrv.pkg`, `Base64Functions.pkg` and `Working.pkg` (RDCToolsLib has the last one),
  and `cConnectionDUF.pkg`.
- The programs `DUFCreateDbVersionTable`, `AnalyzeTableMemoryUsage` and `StatusPanelExample`, the two generated
  test programs, and files and code that nothing used.

105 unit tests now.

## What is new in 1.0.3

- `ApiTableUpdate` leaves the framework's `DbVersion` table alone, the table whose version number decides which
  updates still run. A `DbVersion` description in the update code is skipped with a line in the update log. The
  check for it was there, but it compared a name that was never filled in, so the table was changed like any
  other. An application table that holds the version number in one of its columns (`pbUseCustomDbVersion`) is
  updated as before.

## What is new in 1.0.2

The update of a table (`ApiTableUpdate`):

- An SQL table stays on SQL when the update code was made from an embedded table, and gets its changes. It was
  turned into an embedded table, and the SQL table was left behind on the server. Set `pbApiTableUpdateAuto` to
  True for the old behaviour, or call `SqlTableConvertToEmbedded` in an update of its own. Columns that such an
  update adds or changes get the SQL type the driver picks; they arrived as `char` or `numeric`.
- A text column that the update code makes a Date column becomes one when it holds dates only, written the way
  the program writes dates. Otherwise it keeps its type, and an error names the column and its first value: the
  restructure would have emptied the other values or made them into other dates, without a word. Before,
  nothing happened at all.
- A new index gets the uppercase and descending segments of the update code, also with the two compare
  switches off.
- A renamed embedded table keeps its data when the copy to the new name fails, and it is renamed in the folder
  of the data path that holds it. The old files were deleted whether the copy was made or not.
- The update of a table stops at the first step that fails. A later step covered the failure.

Connections to the database server:

- A failed login is reported where it happens. A connection ID that DUF made itself was reported as "could not
  be created", and a good login counted as failed after an earlier error.
- No password in error messages, in the update log or on screen: the value of PWD and Password shows as ***.
- A password, a database name or a user name with a space in it keeps the space. For the SQL Server client 18
  and later every space was taken out of the connection string.
- Manage SQL Connections: the field "Additional Connect String Options" is hidden. It showed the password, and
  could write an old password back over a new one.

The rest:

- Version objects in the wrong order, such as 1.2 before 1.1, stop the program with a message. The 1.1 update
  was skipped for good. These and the other set-up mistakes that end with "Program will now exit!" are shown on
  screen as well as logged, unless `pbSilentMode` is True.
- With `pbUseIntFilesBackup` True, the Filelist.cfg compiled into the program is written only when there is no
  Filelist.cfg. It replaced the live one after every update.
- SQL Repair Utility: the Filelist repair writes the prefix of the table's own driver, not MSSQLDRV always.
- A column added on SQL is entered in the .tag file once. It was added again on every call.
- Compare Databases says "Ascending: Yes" for ascending index segments. It said so for descending ones.
- More unit tests, 56 in all.

## What is new in 1.0.1

Fixes, most of them in the update run: the part that changes the tables at a customer's site.

The update of a table (`ApiTableUpdate`), measured on DataFlex 19.1 to 26, on embedded tables and, where it
applies, on Microsoft SQL:

- A changed index is changed. The table kept its old index: an embedded table got a second one at every run,
  and on Microsoft SQL the program stopped at every start. An index removed from the middle no longer takes
  the wrong one with it, an index that gained or lost a segment counts as changed, and the indexes are
  compared after the columns have changed, not before.
- A Date column that gets a new number keeps its type and its dates. It came back as text of length 0.
- A column removed from the middle works at the first start, however many columns stand behind it.
- A new column beside a column of the same type and length is a new column. It was taken for that column
  under a new name, and values ended up under other names.
- A column renamed and made longer in the same update keeps its values. One column gone and one new between
  the same two neighbours, of the same type and with room for every value, is the same column under a new
  name; the log names both. Update code can say it outright, in front of `ApiTableUpdate`: `ApiColumnRename`
  for a rename, `ApiColumnRemove` for a column that is to go. A column renamed and made shorter, or given
  another type, is still a new column and starts empty.
- A table is found when the data path names several folders, and a data file that lost its Filelist entry is
  entered in the Filelist again. Both were created anew, empty, over the file.

The rest:

- The update lock is released when the update is over. It was held until the program closed, and every other
  start of the program showed "update in progress" for that long.
- `pbCheckDataFlexUserCount = False` switches off the count of DataFlex licence users and nothing else. It
  also switched off the test for an exclusive open and the count of running programs. An application that
  sets it to False can now stop with "database in use" where it started its update before.
- A `cDbUpdateVersion` object whose `pnVersionNumber` was never set stops the program. Its `OnUpdate` was
  skipped and nothing said so.
- Columns added through `SqlColumnAdd` no longer use up the sequential channels, one for each column.
- SQL Repair Utility: a ticked "Create database backup" makes the backup when a collation is changed. It was
  the other way round. "Recreate all *.int files" saves every .int file first, not just one.
- Compare Databases lists an index whose two sides differ in their number of segments.
- More unit tests: `oDbUpdateTableUpdate-Tests.pkg` runs `ApiTableUpdate` against real embedded tables in a
  temp folder, and `oDbUpdateUserCount-Tests.pkg` tests the update lock.

## Setup after cloning

**Building DUF on its own** (working on the framework itself): after cloning, run **`setup.bat`**
once from the repository root. It clones DFAbout, RDCToolsLib, vwin32fh and DFUnit as **siblings** of the
DUF folder — the layout the `DUFDev*.sws` workspaces expect (19.1, 20.1, 23.0, 24.0, 25.0 and 26.0). Open the one
of your DataFlex version to build. Re-run `setup.bat` when a sibling folder is missing; it leaves the ones that are
there as they are. `setup.bat /pull` also updates those.

There is no plain `DUF25.0.sws`. The two workspace files are named for their role, so it is
always clear which to use:

| File | Role | `[Libraries]` |
|---|---|---|
| `DUFDev19.1.sws` / `20.1` / `23.0` / `24.0` / `25.0` / `26.0` | Open this to **develop** DUF | the `..\` siblings |
| `DUFLibrary19.1.sws` / `20.1` / `23.0` / `24.0` / `25.0` | A consumer **references** this | none — deliberately empty |

On DataFlex 19.1 three of the five programs build: `DUFTestProgram`, `ReadDFDriverDefXML` and
`DUFSQLRepairUtility`. `DUFCodeGenerator` needs DataFlex 20.1 or later, and `DUFSQLConnections` needs the
icon `TagRemove.ico`, which DataFlex ships from version 20.

### What the programs save

The Compare Databases view remembers the `Filelist.cfg` paths entered before. They are kept in
`Programs\DUFSettings.ini`, which git ignores, and no longer in the workspace's `Config.ws`. A list still found
in `Config.ws` is moved over the first time the view reads it. This needs RDCToolsLib 1.0.11 or later.

### Unit tests

`AppSrc\UnitTests.src` is the unit-test program of the workspace, built on
[DFUnit](https://github.com/NilsSve/Library-DFUnit). The tests are in `AppSrc\o<Subject>-Tests.pkg`, one file
per subject, and `AppSrc\oUnit_Tests.pkg` lists them. The first file, `oDbUpdateFunctionLibrary-Tests.pkg`,
covers helper functions that need no database.

- **DataFlex 26:** `DUFDev26.0.sws` takes DFUnit as a package.
- **DataFlex 19.1 to 25:** `DUFDev<version>.sws` takes it from the sibling folder `..\DFUnit`, which
  `setup.bat` clones.

Compile `UnitTests` and run it: the test-runner window opens. `UnitTests64.exe -c` runs the tests without a
window and ends with exit code 0 when all passed; `-o result.xml` adds a JUnit file. On DataFlex 19.1 the
program is `UnitTests.exe`.

`DUFLibrary*.sws` declaring no libraries is the point: when DUF is used as a library inside
another application, that application supplies the four-library flat set itself (see below), and
DUF must not drag its own copies onto the path. (The old single `DUF25.0.sws` had the empty
consumer file wearing the plain, inviting name — so it was the one people opened to work on DUF,
found no libraries, and hit a wall. Two role-named files remove that trap.)

That is the only setup step. In particular `Help\About.rtf` now ships with the repository — it
used to be gitignored, which meant a fresh clone could not compile at all until someone worked
out that `DfAbout.pkg` embeds that file as a program resource. What is committed is a minimal
placeholder; replace its text with whatever the About dialog should show, but do not delete the
file. Editing it in Word rewrites the whole thing, so expect whole-file diffs.

## Dependencies

DUF requires **RDCToolsLib**, **vwin32fh** and **DFAbout**. What each is actually for:

| Library | Why DUF needs it |
|---|---|
| RDCToolsLib | The `cRDC*` control classes and `RDCStatusPanel.pkg`, used throughout the dialogs and `cBaseDbUpdateFuncLib`. |
| vwin32fh | `vWin32fh.pkg`, used directly by `cBaseDbUpdateFuncLib` — and required by RDCToolsLib in its own right. |
| DFAbout | One class: `SysInfoDialog`, shown by `DriverSettings.dg`. Nothing else in DUF touches DFAbout. |

Note the shape of that last row. DUF is a database library, and its entire dependency on the
About-dialog library is a single System Information popup in one dialog. If DUF's dependency
list ever needs to get shorter, extracting `SysInfoDialog` into RDCToolsLib is the move.

### DataFlex 26: DUF as a package, and its programs

On DataFlex 26 DUF can be added to a workspace as a package (`RDC-DUF-Library.sws`). DFAbout, RDCToolsLib and
vwin32fh come with it. A package brings the sources of DUF's programs, but no programs.

Add it with the version after a `#`:

```
https://github.com/NilsSve/Library-DUF.git/RDC-DUF-Library.sws#1.0.5
```

Each release has a version tag (`1.0.0`, `1.0.1`, `1.0.2`, `1.0.3`, `1.0.4`, `1.0.5`, ...), listed under Tags on
GitHub. Without the `#` part the workspace gets a commit. A workspace that also names RDCToolsLib or DFAbout
itself lists them before DUF, in a version DUF accepts: RDCToolsLib 1.0.11 or later, DFAbout 1.0.2 or later.

The package puts **`BuildDUFUtilities.bat`** into the workspace folder. Start it there. It compiles
`DUFCodeGenerator` and `DUFSQLRepairUtility` into the workspace's `Programs` folder:

- with the login key of that workspace (`AppSrc\LoginEncryptionKey.inc`), which a program built somewhere
  else does not have;
- with the DataFlex version the workspace file names, 64-bit, with icon and manifest as the Studio builds them.

`BuildDUFUtilities.bat /all` also builds `DUFSQLConnections`. With several workspace files in the folder, name
the one to build for: `BuildDUFUtilities.bat MyApp.sws`. Run it again after the package is updated.

It is a plain batch file and needs only Windows and DataFlex. It finds `df-cli.exe` on the PATH or through the
registry, or takes its path from the variable `DFCLI`. It writes to `Programs` and to a folder
`DUFUtilitiesBuild` in the workspace, which holds the compiler's listings and can be deleted. The package
folder in `DfPkg` is only read.

If the script cannot run on a machine, this is what it does for each program, from the workspace folder:

```
"C:\Program Files\DataFlex 26.0\Bin64\df-cli.exe" build-file "DfPkg\NilsSve_RDC_DUF_Library-<version>\AppSrc\DUFCodeGenerator.src" --workspace MyApp.sws --output-dir Programs --toolchain 26.0.0+windows-64
```

That one command builds the program without its icon and manifest; the script adds both.

**Moving to a newer release.** Let df-cli do it, from the workspace folder:

```
df-cli package upgrade MyApp.sws NilsSve/RDC-DUF-Library
```

That takes the workspace to the newest release and replaces `BuildDUFUtilities.bat` in the workspace folder
with the new one. An exact version in the workspace file is rewritten to the new version; a range such as
`^1.0.0` stays. Then run the script again, so the programs are built from the new sources. A workspace that
has DUF by commit counts as up to date: change its version to `1.0.0` in the workspace file first, then run
the command.

Do not move by changing the version in the workspace file alone. df-cli does not replace a script it
installed earlier when the new release's script has another text. `df-cli config` then reports "Installed
file ... BuildDUFUtilities.bat has been modified" and still calls the workspace OK, but a build stops with
"Failed to load workspace configuration". The way out: delete `BuildDUFUtilities.bat` from the workspace
folder and run `df-cli config MyApp.sws`, which installs the new script. This was measured with the df-cli
of DataFlex 26.0.

### DataFlex 19.1 to 25: the programs with the application's login key

DUF's programs can be compiled in DUF's own workspace, as described above. A program built there carries the
login key of DUF's workspace. It reads an application's `SQLConnections.ini` on a development machine, where
the application's key file is beside it, but not at a customer's.

`BuildDUFUtilities.bat` builds the programs for an application instead. Start it from the folder of the
application's workspace, or hand it the workspace file:

```
..\Libraries\DUF\BuildDUFUtilities.bat
BuildDUFUtilities.bat C:\Projects\MyApp\MyApp.sws
```

It compiles `DUFCodeGenerator` and `DUFSQLRepairUtility` with that DataFlex version's own compiler and with the
application's `AppSrc\LoginEncryptionKey.inc`, into the application's `Programs` folder. `/all` adds
`DUFSQLConnections`, and `/32` builds 32-bit programs on DataFlex 20 to 25. On DataFlex 19.1 it builds
`DUFSQLRepairUtility`, 32-bit. `ReadDFDriverDefXML` is built in the Studio, as a 32-bit program: the XML object
it uses is 32-bit.

The workspace file has to name `DUFLibrary<version>.sws` among its libraries, beside RDCToolsLib, DFAbout and
vwin32fh. The script finds the compiler through the registry, or takes its path from the variable
`DFCOMPILER`. It does not compile in the application's workspace itself: a utility needs DUF's own folders. It
writes a workspace file of its own into `DUFUtilitiesBuild`, with DUF's folders, a copy of the application's
key file first on the source path, and the application's `Programs` folder. The copy of the key file is
removed again when the script is done. The DUF folder is only read.

### Passwords in SQLConnections.ini

DUF encrypts the passwords in its `SQLConnections.ini` file with the login key of the workspace: the file
`AppSrc\LoginEncryptionKey.inc`, which the Studio makes once for each workspace. It is the key DataFlex itself
uses for `DFConnId.ini`. `cSQLConnectionIniFile` takes the key from the first of these that gives one:

1. `psHashString`, when the program has set it. It is empty by default.
2. `AppSrc\LoginEncryptionKey.inc` of the workspace the ini file is in, read when the program runs. That file
   is there on a development machine, so a DUF utility built in another workspace reads an application's file
   with the application's key.
3. The login key the program was compiled with.

Three things follow:

- Every program that uses `cSQLConnectionIniFile` needs `AppSrc\LoginEncryptionKey.inc` when it is compiled.
- **Existing files:** passwords stored before this change were encrypted with a fixed value in the class.
  They are not read any more. Enter them again, with the connections manager or the application's dialog.
- On a machine without the application's source, a customer's for one, only a program built with the
  application's login key reads its file. Build a utility that goes there with `BuildDUFUtilities.bat`,
  which takes the application's key on every DataFlex version from 19.1.

### If you are consuming DUF from an application

Add all four — DUF, RDCToolsLib, vwin32fh and DFAbout — as submodules under your application's
`Libraries\`, and declare them as a flat sibling list in your application workspace's
`[Libraries]`. Do not rely on reaching the three through DUF; DUF's consumer `.sws` declares no
libraries precisely so that it cannot.

There are two reasons, and both are things this project has actually been bitten by:

1. **Version drift.** DataFlex resolves the compiler search path first-match-wins, with no version
   arbitration. If a library reached the path from two different checkouts, list order alone would
   decide which won, silently. One library, one checkout, declared by the application, is the only
   arrangement that cannot drift.

2. **The Studio navigates by disk, not by the path.** Even when the *build* is unambiguous, a
   second physical copy of a package on disk means Go-to-Definition and Find-in-Files can land on
   the wrong file — and you can edit one copy while the build compiles the other. Flat siblings
   mean exactly one physical copy of each library, so that cannot happen.

This is why DUF stopped nesting the three: nesting guaranteed a second physical copy inside every
consumer that also declared them as siblings. **Migrating a consumer:** add the three as siblings,
list all four flat in the workspace, and confirm there is no longer a
`Libraries\DUF\Libraries\` folder shadowing them.
