# fixed KSS File Extraction Kit for Rune Worth (MSX2) Complete Sound Tracks

[Japanese Version](../)

**I used Google Translate. It may not be accurate.**

This is a toolkit for creating KSS files from Runeworth (MSX2 version) disk images.

Due to the batch files and tools used, a Windows environment is required.  
If you want to run it in another environment, please refer to the contents and try something.  
(There are probably equivalent tools available for other environments.)

## Music List

This includes all the Musics from the soundtrack.

35 soundtrack Musics + 4 jingle-type Musics.

Each is available in OPLL and PSG versions.

01. The Downfall of Saris
02. Theme of Rune Worth
03. Departure
04. Zamba Fortress
05. Holy Saia Kingdom
06. Weidenitz Principality
07. Bahaman Divine Kingddom
08. Shatapartha Commonwealth
09. Wedel Mountains
10. His Majesty
11. Prayer
12. Wasteful
13. For the men in the bar
14. He Died
15. Sadness
16. More Sadness
17. Happiness
18. Mirim is a Grown-up
19. U-Ro-Wa-Ba!
20. Griping of the Gods
21. Look out, it's Dangerous
22. Permafrost
23. Oorumamu's Ambition
24. The Dread Wizard
25. Specter's Tower
26. Revelation of Sartarus
27. Outrageous Town
28. Lumaskaeru Burns
29. Tear of Eris
30. Assassin Magic Troupe Vifo
31. Escape from the Darkness
32. The never ending battle
33. Revival of the Evil God
34 Peaceful
35. Tomorrow will Come Back

36. (Jingle) Game Over
37. (Jingle) Get Treasure
38. (Jingle) Fanfare
39. (Jingle) Ricart's Lyre


## Required

- `RuneWorth_S.dsk` ... Start Disk Disk-image
- `RuneWorth_A.dsk` ... Game Disk A Disk-image
- `RuneWorth_B.dsk` ... Game Disk B Disk-image
- `bincut2.exe`
  ... Binary Cutter  
  ..... https://nezplug.sourceforge.net/  
  ..... https://www.purose.net/befis/download/nezplug/oldsite.shtml
- `AILZ80ASM.exe`
  ... useful Z80 Assembler
  ..... https://github.com/AILight/AILZ80ASM

Please prepare these yourself and place them all in the same folder.

## Extracting MDT files (for playing on MSX)

### MDT Extraction Batch File

- `RuneWorth_extract_mdt.bat`

### List of required files

- `RuneWorth_extract_mdt.bat`
- `RuneWorth_S.dsk`
- `RuneWorth_A.dsk`
- `RuneWorth_B.dsk`
- `bincut2.exe`

### Execute extraction

Place all files in the same folder and run `RuneWorth_extract_mdt.bat`.

It will be created subfolder `RuneWorh_mdt` and extract mdt file. 

- OPLL mdt file in `RuneWorth_OPLL` folder
- PSG mdt file in `RuneWorth_PSG` folder

You can listen to it at the following sites:

- PSG.COM
- OPLL.COM

Included in the [Undead Line BGM Tool Set in the June 1995 issue of MSXFAN](#undead-line-bgm-collection--mml-development-kit).

When extracting mdt files with `RuneWorth_extract_mdt.bat`,
the batch files `PLAY-P.BAT` and `PLAY-O.BAT` for previewing are also generated.

`PLAY-P.BAT` is for PSG Musics,
`PLAY-O.BAT` is for OPLL Musics.

> [!CAUTION]
>   [**OPLL.COM will play abnormally in R800 mode.**](#notice-for-oplcom)  

## Extracting KSS files (for playing on devices other than MSX)

### KSS creation batch file

`RuneWorth_kss_maker.bat`

Place all files in the same folder and run `RuneWorth_kss_maker.bat`.

If successful, `Rune Worth (MSX).kss` should be created.

### List of required files

- `RuneWorth_kss_maker.bat`
- `RuneWorth_kss_head.bin`
- `RuneWorth_S.dsk`
- `RuneWorth_A.dsk`
- `RuneWorth_B.dsk`
- `bincut2.exe`

If successful, `Rune Worth (MSX).kss` should be created.

## How to listen to KSS files

KSS alone is difficult to use because it does not provide Music information, 
so we have prepared a playlist.

### kbMediaPlayer / WINAMP / foobar2000 Play list

#### Play lists

- Soundtrack ordered  
  (All FM sound sources => All PSG sound sources)
  - Rune Worth (MSX).m3u
  - Rune Worth (MSX).m3u8

- Binary data ordered
  (FM and PSG sound sources are lined up next to each other)
  - Rune Worth (MSX) RAW.m3u
  - Rune Worth (MSX) RAW.m3u8

Please place the playlist in the same folder as `Rune Worth (MSX).kss`.

- kbMediaPlayer

  - You can use either m3u or m3u8 files.
  - The kss-compatible MSXPlug is included from the install.

- WINAMP

  - You can use either m3u or m3u8 files.
  - MSXPlug(in_msx) is required.
    https://github.com/digital-sound-antiques/in_msx  

- foobar2000

  - Open `Rune Worth (MSX).kss` instead of the playlist.  
    It will automatically load the m3u playlist of the same name in the same folder. 

  - Requires GameEmuPlayer(foo_gep) plugin or NPNEZ(foo_npnez) plugin.
  
    - GameEmuPlayer(foo_gep)
      https://www.foobar2000.org/components/view/foo_gep  

    - NPNEZ(foo_npnez)
      https://ux.getuploader.com/foobar2000/
      You will need npnez.dll, which is included with nezplug++.
	  Place it in the same location as foo_npnez.dll.
      (See the included documentation for details.)


## About Runeworth MSX sound

The MSX version of Runeworth has great sound in both the PSG and OPLL versions.
The BGM has been adjusted to suit the characteristics of PSG and OPLL.
It has a quality that is different from other sound sources.

The Runeworth sound is the final product of the technology honed through Psy-o-blade, Laydock2, and Undead Line.

There was no soundtrack for the MSX sound source, and only a very small number of people owned the Music discs, so it was difficult to listen to all the Musics at your leisure.

There has long been a demand for people to easily enjoy classical game Music with sound that is as close to the real thing as possible.

As a result, a system was devised that would extract the sound data and drivers from the game image and run them on a virtual machine.
One of them is the KSS file, which has undergone various extensions to become compatible with MSX.

Creating a KSS requires analysis and extraction, but our great predecessors have created toolkits that allow us to create KSS.

However, in the case of the Runeworth MSX version, the analysis was incomplete, and the KSS created using the KSS creation toolkit did not include all the Musics.

Fatal issues include no opening theme Music, and one missing field Music. 
(Also, there's no Music for when you open a treasure chest.)

So I reanalyzed it myself, found the missing songs and added them.

I also added support for whether or not to loop.  
I also created a playlist and adjusted the playing time.


## "Undead Line" BGM Collection & MML Development Kit


**"Undead Line" BGM Collection & MML Development Kit** is **UNDEAD.LZH**, that is included in **MSXFAN June 1995' Append Disk #32-1**.

UNDEAD.LZH contains MML compiler, DOS command line player, MML, and BGM binaries.

> ** Extract mdt: [RuneWorth_extract_mdt.bat](#extracting-mdt-files-for-playing-on-msx)

### MML Compiler

  - Bulk compilation
    - CMP-O.BAT
    - CMP-P.BAT
  
  - Comliler binary
    - MDC3A.COM
    - MDC.COM
    
  - Compile one and play
    - O.BAT
    - P.BAT

### BGM(mdt) Player

  - Play all Music
    - PLAY-O.BAT
    - PLAY-P.BAT
  
  - Player binary
    - OPLL.COM
    - PSG.COM

  ** Drivers for embedded games are not available

#### Notice for OPL.COM
  
> [!CAUTION]
>   **OPLL.COM does not work properly on R800 mode.**  
>   For Turbo R, switch to Z80 and play.  
>   e.g.)  
> [CHGCPU.COM by Hra](https://github.com/hra1129/msx_tools/tree/main/chgcpu)  
> `> CHGCPU 0`

#### MML

MML for PSG

| File         | Contents                 |
|--------------|-------------------------|
| OP1-P.PSG    | Opening                 |
| OPEN-P.PSG   | Opening                 |
| MENU1-P.PSG  | Title                   |
| MENU2-P.PSG  | Character, stage select |
| DEMO-P.PSG   | Intermediate demo       |
| BGM1-P.PSG   | FOREST stage            |
| BGM2-P.PSG   | CEMETERY stage          |
| BGM3-P.PSG   | RUINS stage             |
| BGM4-P.PSG   | ROCKS stage             |
| BGM5-P.PSG   | CAVERN stage            |
| BGM6-P.PSG   | DUNGEON stage           |
| BGM7-P.PSG   | FORTRESS stage          |
| BOSS1-P.PSG  | Boss                    |
| BOSS2-P.PSG  | Final boss              |
| CLEAR-P.PSG  | Stage clear             |
| OVER-P.PSG   | Game over               |

MML for OPLL

| File         | Contents                   |
|--------------|----------------------------|
| OP1-O.OPL    | Opening                    |
| OPEN-O.OPL   | Opening                    |
| MENU1.OPL    | Title                      |
| MENU2.OPL    | Character, stage selection |
| DEMO.OPL     | Intermediate demo          |
| CONFI.OPL    | High score display         |
| BGM1.OPL     | FOREST stage               |
| BGM2.OPL     | CEMETERY stage             |
| BGM3.OPL     | RUINS stage                |
| BGM4.OPL     | ROCKS stage                |
| BGM5.OPL     | CAVERN stage               |
| BGM6.OPL     | DUNGEON stage              |
| BGM7.OPL     | FORTRESS stage             |
| BOSS1.OPL    | Boss                       |
| BOSS2.OPL    | Final boss                 |
| END1.OPL     | Ending                     |
| ENDING.OPL   | Ending                     |
| CLEAR.OPL    | Stage clear                |
| OVER.OPL     | Game over                  |
| MATUSI-1.OPL | ?                          |
| MATUSI-2.OPL | ?                          |

#### Compiled BGM data binary

- *.MDT

Same format as Runeworth.

#### MML function (incomplete version)

Since it was published in a magazine quite some time after development,
they said they had forgotten the details.

The message was for people to analyze it and play with it on their own.

##### basics

- First line of mml file
  - `.rhythm`  ... use rhythm
  - `.psg`     ... for PSG

- Last line of mml file
  - `.end`

- Write each channel in ""
  - PSG:3 Channels
  - OPLL:7 Channels
  - Write blocks enclosed in "" in a row for the number of channels.
  - After entering the number of channels, the specification will return to ch1.

- PSG tones and OPLL user tones are written last.
  - Details of PSG tone definition unknown

A rough example)  
```
.psg
--- intro ---
"1ch" "2ch" "3ch" 
--- loop A ---
"1ch" "2ch" "3ch" 
--- loop B ---
"1ch" "2ch" "3ch" 
--- end ---
";" ";" ";" 

--- voice data ---
data1	$dc,$ba,$86,$41,$11,$11,$11,
    	$11,$11,$11,$11,$11,$11,$11;

.end
```

##### Special MML symbols

| MML symbol       | function |
|------------------|----------|
| [ _1 ]0 _2 ]1 _3 | loop（_1→_2→_1→_3）|
| (n)              | If you enclose the note length in parentheses, it will be in 1/60 second units. |
| @ (@ only)       | Wait until all channels are available |
| $n               | Use PSG voixce #n  |
| @n               | Use OPLL voice #n  |
| un               | Write OPLL user tone data |
| {label}          | Subroutine call |
| /label/          | Melody subroutine label |
| \|label\|        | Rhythm subroutine label |
| %                | Return from subroutine |
| ;                | Exit |
| i                | Detune |
| M                | Vibrato (parameter unknown) |
| p                | Portamento? |
| -                | Comment out symbol |
| *                | Mysterious command |

- When using a user tone,
  you write the user tone data
  and then switch to the user tone, so write it like this:
  `u0@0`.

## Source Code: Binaries for KSS headers

- `RuneWorth_kss_head.asm`  

  `RuneWorth_kss_head.bin` source file. 
  Assembled with AILZ80ASM.

## Acknowledgment

The bridge to the sound source driver is possible thanks to the analysis information of our predecessors.

I would like to take this opportunity to express my gratitude.
