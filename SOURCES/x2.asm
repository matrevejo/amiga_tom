START: 
;...beginning of the program
; initializing bitplans pointers in the copperlist
move.l #Screen,d1
move.w d1,CLplan1+6 ; low bits
swap d1
move.w d1,CLplan1+2 ; high bits
swap d1
add.l #265*(1024/8),d1 ; point to the 2nd bitplan
;add.l #1024/8 ; Interlaced mode Iff
move.w d1,CLplan2+6
swap d1
move.w d1,CLplan2+2

move.w #%0000000000100000,$dff096 ; sprites off
move.w #%1000001110000000,$dff096 ; dma
move.l #copperlist,$dff080
move.w #0,$dff088 ; restart the copper
;...
rts

copperlist:
dc.w $0100,$A200 ; resolution, nb bitplan
dc.w $0180,$0000 ; color 0
dc.w $0182,$0F00 ; color 1 (red)
dc.w $0184,$00F0 ; color 2 (green)
dc.w $0186,$000F ; color 3 (blue)
dc.w $008E,$2069 ; DIWSTRT $20
dc.w $0090,$29C9 ; DIWSTOP $129-$20=265
dc.w $0092,$0030 ; DDFSTRT
dc.w $0094,$00D8 ; DDFSTOP
dc.w $0108,$0028 ; odd modulo 40 (+$80 Iff mode)
dc.w $010A,$0028 ; even modulo
CLplan1:
dc.w $00E0,$0000 ; BPL1PTH bitplan 1
dc.w $00E2,$0000 ; BPL1PTL
CLplan2:
dc.w $00E4,$0000 ; bitplan 2
dc.w $00E6,$0000
dc.w $FFFF,$FFFE ; -2 end of copperlist

Screen:
dcb.b 265*(1024/8),$F0 ; bitplan 1 strips
dcb.b 265*(1024/8),$0F ; bitplan 2 inverted strips"