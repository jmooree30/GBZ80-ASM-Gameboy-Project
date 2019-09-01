SECTION "Stack", WRAM0

; In theory, 32 bytes may suffice, but 64 is more or less guaranteed to work right
    ds 64
wStackBottom::

SECTION "Shadow OAM",WRAM0,ALIGN[8]

wShadowOAM::
    ds 40 * 4
