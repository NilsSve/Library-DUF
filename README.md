### DUF - Database Update Framework for DataFlex

The Database Update Framework (DUF) is a code-based solution designed for automating database updates. It streamlines the process of updating databases at customer sites, particularly when installing a new software version that requires prior changes to the database.

[Click here to see the Introduction Video on YouTube](https://www.youtube.com/watch?v=D2o0zjPEr_I)

[Watch a more in-depth video about the framework](https://www.youtube.com/watch?v=VD4eN9oP0_U)

### Programs to Compile and Use

To implement the framework, you will need to compile and use two programs:
- **DUFCodeGenerator**
- **DUFFileListRepair**

Additionally, you need to integrate a piece of code into your program to facilitate the automated database update. This can be done by selecting a `cDbUpdateHandler` object from the Studio's Class Palette and dragging it into your main program.

It is recommended to add the `DUFCodeGenerator.exe` and `DUFFileListRepair.exe` programs to the Studio’s Tools menu. You can do this by executing the programs and clicking the “Add To Studio” button.

### Important Information

Before proceeding, please read the following help sections:
- “Welcome to the Database Update Framework”
- “Workspace Setup”
- “How to Use It”

These sections can be found in the `Developer5.chm` Help file located in the `/Help` folder. Alternatively, you can press F1 while running one of the programs for assistance.

![This is how the DUFCodeGenerator.src program looks:](Bitmaps/DUFCodeGenerator.png)

![This is what the DUFFileListRepair.src program looks like:](Bitmaps/DUFFilelistRepairer.png)

The workspace also utilizes other libraries available on Nils Sve's GitHub page. You typically won’t need to worry about this, as it should all be handled automatically when you clone the repository. These libraries are included as submodules in Git.
