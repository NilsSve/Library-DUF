# DUF - DbUpdateFramework
 Database Update Framework for DataFlex

<a href="https://www.youtube.com/watch?v=D2o0zjPEr_I" target="_blank">Click here to see the Introduction Video at Youtube</a>

<a href="https://www.youtube.com/watch?v=VD4eN9oP0_U" target="_blank">This is a more in depth video about the framework</a>

The Database Update Framework is a code based framework for making automated database updates. It is designed to make it easy to update databases at customer site when e.g. installing a new revision of a software that depends on changes have been made to the database before the new software version can run.

There are two programs you need to compile and use: "DUFCodeGenerator" and "DUFFileListRepair". You just need to add a bit of code to your own program that makes the automated database update. You do this in the Studio by adding a cDbUpdateHandler object from the Studio's Class Palette, by dragging it to your main program.

It is suggesed to add the "DUFCodeGenerator.exe" and "DUFFileListRepair.exe" programs to the Studio’s Tools menu, by running them and pressing the “Add To Studio” button.

IMPORTANT:
It is suggested to read the following help sections; “Welcome to the Database Update Framework”, “Workspace Setup” and “How to Use It” in the Developer5.chm Help file (/Help folder).

![This is how the DUFCodeGenerator.src program looks like:](Bitmaps/DUFCodeGenerator.png)

![This is what the DUFFilelistRepair.src program looks like:](Bitmaps/DUFFilelistRepairer.png)

The workspace also uses other libraries that are published at 'NilsSve's GitHub page. This should not be of any concern to you as this should all be automatic when cloning this repository. Those libraries are used as submodules in git.
