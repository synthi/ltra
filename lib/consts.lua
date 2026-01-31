-- code/ltra/lib/consts.lua | v1.0
local Consts = {}

Consts.BRIGHT = {
    OFF = 0,
    BG_MATRIX_A = 1,   -- Pitch/Morph cols
    BG_MATRIX_B = 3,   -- Amp/FX cols
    BG_DASHBOARD = 4,
    BG_TRIGGERS = 5,
    BG_NAV = 2,
    VAL_LOW = 5,
    VAL_MED = 8,
    VAL_HIGH = 11,
    VAL_PEAK = 13,
    TOUCH = 15
}

Consts.MATRIX_CYCLES = {1.0, 0.66, 0.33, 0.0}

Consts.SOURCES = { LFO1=1, LFO2=2, CHAOS=3, OUTLINE=4, ARP=5 }
Consts.DESTINATIONS = {
    PITCH1=1, PITCH2=2, PITCH3=3, PITCH4=4,
    AMP1=5,   AMP2=6,   AMP3=7,   AMP4=8,
    MORPH1=9, MORPH2=10, MORPH3=11, MORPH4=12,
    FILT1=13, FILT2=14, DELAY_T=15, DELAY_F=16
}

Consts.MENU = {
    NONE=0, OSC=1, LFO=2, FILTER=3, 
    DELAY=4, REVERB=5, LOOPER=6, MATRIX=7
}

Consts.LOOPER_PAIRS = { {1,2}, {3,4}, {5,6} }
Consts.LOOPER_BOUNDS = { {min=0, max=40}, {min=40, max=80}, {min=80, max=120} }

-- Filtro para Snapshots (Fila 7)
-- Solo guardamos parámetros de sonido, no globales de sistema
Consts.SNAPSHOT_PATTERNS = {
    "^osc", "^filt", "^lfo", "^chaos", "^delay", "^reverb", "^tape", "^system", "^dust", "^mat_", "^loop"
}

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
