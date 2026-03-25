-- lib/consts.lua | v2.0.0
-- FIX: Added POLY_MODES

local Consts = {}

Consts.BRIGHT = {
    OFF = 0,
    BG_MATRIX_A = 1, BG_MATRIX_B = 3,
    BG_DASHBOARD = 4, BG_TRIGGERS = 5, BG_NAV = 2,
    VAL_LOW = 5, VAL_MED = 8, VAL_HIGH = 11, VAL_PEAK = 13, TOUCH = 15
}

Consts.MATRIX_CYCLES = {1.0, 0.66, 0.33, 0.0}

Consts.SOURCES = { MOD1=1, MOD2=2, MOD3=3, OUTLINE=4, ARP=5 }
Consts.DESTINATIONS = {
    PITCH1=1, PITCH2=2, PITCH3=3, PITCH4=4,
    AMP1=5,   AMP2=6,   AMP3=7,   AMP4=8,
    MORPH1=9, MORPH2=10, MORPH3=11, MORPH4=12,
    FILT1=13, FILT2=14, DELAY_T=15, DELAY_F=16
}

Consts.COL_TO_DEST_NAMES = {
    [1]="PITCH1", [2]="PITCH2", [3]="PITCH3", [4]="PITCH4",
    [5]="AMP1",   [6]="AMP2",   [7]="AMP3",   [8]="AMP4",
    [9]="MORPH1",[10]="MORPH2",[11]="MORPH3",[12]="MORPH4",
    [13]="FILT1", [14]="FILT2",[15]="DELAY_T",[16]="DELAY_F"
}

Consts.MENU = {
    NONE=0, OSC=1, MOD=2, OUTLINE=4, 
    FILTER=5, DELAY=6, REVERB=7, LOOPER=8, MATRIX=9, ARP=10, ENV=11
}

Consts.SYNC_DIVS = {
    {name="4 bars", v=16}, {name="3 bars", v=12}, {name="2 bars", v=8}, {name="1.5 bars", v=6},
    {name="1 bar", v=4}, {name="1/2 D", v=3}, {name="1/2", v=2}, {name="1/2 T", v=1.3333},
    {name="1/4 D", v=1.5}, {name="1/4", v=1}, {name="1/4 T", v=0.6667},
    {name="1/8 D", v=0.75}, {name="1/8", v=0.5}, {name="1/8 T", v=0.3333},
    {name="1/16 D", v=0.375}, {name="1/16", v=0.25}, {name="1/16 T", v=0.1667},
    {name="1/32", v=0.125}, {name="1/64", v=0.0625}
}

Consts.POLY_MODES = {"Round Robin", "Reset", "Unison"}

Consts.NOTE_NAMES = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

Consts.SCALES_A = {
    {name="Major", intervals={0,2,4,5,7,9,11}},
    {name="Minor", intervals={0,2,3,5,7,8,10}},
    {name="Dorian", intervals={0,2,3,5,7,9,10}},
    {name="Phrygian", intervals={0,1,3,5,7,8,10}},
    {name="Lydian", intervals={0,2,4,6,7,9,11}},
    {name="Mixolydian", intervals={0,2,4,5,7,9,10}},
    {name="Locrian", intervals={0,1,3,5,6,8,10}},
    {name="Pent Maj", intervals={0,2,4,7,9}},
    {name="Pent Min", intervals={0,3,5,7,10}},
    {name="Blues", intervals={0,3,5,6,7,10}},
    {name="Whole Tone", intervals={0,2,4,6,8,10}},
    {name="Chromatic", intervals={0,1,2,3,4,5,6,7,8,9,10,11}}
}

Consts.SCALES_B = {
    {name="JI Ptolemy", type="JI", intervals={1/1, 16/15, 9/8, 6/5, 5/4, 4/3, 45/32, 3/2, 8/5, 5/3, 9/5, 15/8}},
    {name="JI 7-Limit", type="JI", intervals={1/1, 8/7, 9/7, 21/16, 4/3, 3/2, 32/21, 12/7, 7/4}},
    {name="Pyth Major", type="JI", intervals={1/1, 9/8, 81/64, 4/3, 3/2, 27/16, 243/128}},
    {name="Pelog", intervals={0,1,3,7,8}},
    {name="Slendro", intervals={0,2,5,7,10}},
    {name="Hirajoshi", intervals={0,2,3,7,8}},
    {name="Kumoi", intervals={0,1,5,7,8}},
    {name="Iwato", intervals={0,1,5,6,10}},
    {name="Inosen", intervals={0,1,5,7,10}}
}

return Consts
