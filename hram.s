SECTION "HRAM", HRAM

; Buttons being pressed on this frame (= this is the first frame they are pressed)
hPressedButtons::
    db


; These shadow registers get copied to the actual registers on each VBlank

hLCDC:: db ; These two shadow registers must not be cleared!
hBGP:: db
;; Variables between this and the end of HRAM will be set to 0 on init
;; Place variables that will be initialized otherwise before this
;; It's important in order to have BGB efficiently trap reading to uninitialized memory!
hClearStart::
hOBP0:: db
hOBP1:: db
hSCY:: db
hSCX:: db
hWY:: db
hWX:: db

; Set to non-zero to have the VBlank handler run fully.
; This includes updating the joypad registers, and returning
; from WaitVBlank. This should not be touched outside of that function!
hVBlankFlag::
    db


; Buttons being held on this frame
hHeldButtons::
    db
