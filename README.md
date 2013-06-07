memguard
============

This is a very simple tool to stop programs using too much memory on Linux (Unix?).

If you have only a few GB memory, a program suddenly allocating half a TB, might cause serious performance drops, when all other programs are moved to the swap partition. (i.e. effectively stopping everything for 15min, on my laptop at least).  
If memguard is running, it will stop the offending program, before this happens, and you can either kill it (when the program was not supposed to use that much) or continue it with SIGCONT.

A list of programs can be set to be allowed to use more memory (by editing the lpr before compiling).

Not really tested.

