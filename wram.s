SECTION "Stack", WRAM0

; In theory, 32 bytes may suffice, but 64 is more or less guaranteed to work right
    ds 64
wStackBottom::

SECTION "OAM Vars",WRAM0[$C100]

playerSprite:: DS 4
