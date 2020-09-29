2019/04/09 23:02 by: Ziya Mete Demircan.

a Litte bug on Romen-Numaral-Chord-Mode is fixwd.
This version doesn't have crashes or freezes.
The source code has been revised and edited.
****************************************************************
Note for V3: After running the plug-in, run command "Reset Style" from the Format menu. This will allow the chords to be displayed with the correct font.
****************************************************************
There are no "new score generation" feature in this version. 
If you need this feature, please see other versions.
****************************************************************
If you are using the color option:
Description of colors:
red                : root note
green              : 3th
olive/dark-yellow  : 5th
purple             : 7th
blue/lightblue/pink: 9, 11, 13th
black              : N/A
****************************************************************

Recognized Chord-Types:
Type   :    Example:
--------    --------
Major       C
Maj7        CMaj7
Maj7#11     CMaj7#11
add9        Cadd9
Maj7(9)     CMaj7(9)
aug         Caug
m           Cm
m7          Cm7
m7b5        Cm7b5
madd9       Cmadd9
m7(9)       Cm7(9)
m7(11)      Cm7(11)
m9(Maj7)    Cm9(Maj7)
dim         Cdim
dim7        Cdim7
7           C7
7sus4       C7sus4
7(b5)       C7(b5)
7(9)        C7(9)
7(#11)      C7(#11)
7(13)       C7(13)
7(b9)       C7(b9)
7(b13)      C7(b13)
7(#9)       C7(#9)
Maj7(aug)   CMaj7(aug)
7(aug)      C7(aug)
sus4        Csus4
m11         Cm11
9(#11)      C9(#11)
9(13)       C9(13)
7(b9/b13)   C7(b9/b13)
11(b9/b13)  C11(b9/b13)
m11         Cm11
        
Not possible:
Type   :    Assumed: Recognized as   :   Example :  Notes             :
--------    -------  -----------------   ---------  -------------------
6           C6       //VIm7/I            Am7/C 
6/9         C6/9     //VIm7(11)          Am7(11)/C
m6          Cm6      //VIm7b5/I          Am7(b5)/C
sus2        Csus2    //Vsus4/I           Gsus4/C
1+5         C1+5     //Vsus4/I           Gsus4/C    // (no 3th) 
1+8         C1+8     //not recognized    N.A.       //(no 3th, no 5th)

