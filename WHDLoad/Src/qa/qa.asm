;*---------------------------------------------------------------------------
;  :History.	23.01.13 _blitline* checks deactivated for 68030 because not implemented in WHDLoad
;		24.03.13 PL_IF... added
;		14.03.14 WHDLTAG_CUSTOM_DISABLE/READ/WRITE added
;		17.04.16 more checks for fc/dc, dc-slave added
;---------------------------------------------------------------------------*

	INCDIR	Includes:
	INCLUDE	whdload.i
	INCLUDE	whdmacros.i
	INCLUDE	dos/dos.i

	IFND DC
	OUTPUT	"QA.Slave"
	ELSE
	OUTPUT	"QADC.Slave"
	ENDC
	BOPT	O+			;enable optimizing
	BOPT	OG+			;enable optimizing
	BOPT	ODg-			;disable jsr+rts optimizing
	BOPT	w4-			;disable 64k warnings
	BOPT	wm-			;disable move16 warnings
	BOPT	wo-			;disable optimize warnings
	SUPER
	MC68040

BASEMEM	= $40000
;BASEMEMREAL = $41000
;BASEMEMREAL = $80000	;required for hrtmon
;BASEMEMREAL = $200000
	IFND BASEMEMREAL
BASEMEMREAL = BASEMEM
	ENDC
EXPMEM	= $10000

SAVREG	= $200		;memory to save registers for modified check
HRTMON			;remove write protection from whdload

;======================================================================

_base		SLAVE_HEADER			;ws_Security + ws_ID
		dc.w	15			;ws_Version
	IFND DC
		dc.w	WHDLF_NoError		;ws_flags
	ELSE
		dc.w	WHDLF_NoError!WHDLF_Examine	;ws_flags
	ENDC
		dc.l	BASEMEMREAL		;ws_BaseMemSize
		dc.l	0			;ws_ExecInstall
		dc.w	_start-_base		;ws_GameLoader
		dc.w	0			;ws_CurrentDir
		dc.w	0			;ws_DontCache
_keydebug	dc.b	0			;ws_keydebug
_keyexit	dc.b	$59			;ws_keyexit = F10
_expmem		dc.l	EXPMEM			;ws_ExpMem
		dc.w	_name-_base		;ws_name
		dc.w	_copy-_base		;ws_copy
		dc.w	_info-_base		;ws_info

_name		dc.b	"Quality Assurance Slave"
	IFD DC
		dc.b	" - DC"
	ENDC
		dc.b	0
_copy		dc.b	"Wepl",0
_info		dc.b	"done by Wepl "
	;DOSCMD	"WDate >T:date"
	INCBIN	"T:date"
		dc.b	0
_badcustom1	dc.b	"value of Custom1/N is invalid",0
_t_badchksum	dc.b	"checksum incorrect",0
_t_badfilesize	dc.b	"returned filesize incorrect",0
_t_badioerr	dc.b	"returned error code (IoErr) incorrect",0
_t_baddecsize	dc.b	"decrunched length incorrect",0
_t_baddecdata	dc.b	"decrunched data corrupt",0
_t_baddecsrc	dc.b	"source data corrupt after decrunching",0
_t_patch	dc.b	"incorrectly patched",0
_t_badloadlen	dc.b	"loading filesize incorrect",0
_t_badcrc	dc.b	"crc mismatch on loaded file",0
_t_getfilesize	dc.b	"size/doscode mismatch",0
_filename_100		dc.b	"100",0
_filename_100_crm1	dc.b	"100.crm1",0
_filename_100_crm1s	dc.b	"100.crm1s",0
_filename_100_crm2	dc.b	"100.crm2",0
_filename_100_crm2s	dc.b	"100.crm2s",0
_filename_100_im	dc.b	"100.im",0
_filename_100_rnc1	dc.b	"100.rn1",0
_filename_100_rnc2	dc.b	"100.rn2",0
_filename_crm1_g	dc.b	"good.crm1",0
_filename_crm1_b	dc.b	"bad.crm1",0
_filename_crm1s_g	dc.b	"good.crm1s",0
_filename_crm1s_b	dc.b	"bad.crm1s",0
_filename_crm2_g	dc.b	"good.crm2",0
_filename_crm2_b	dc.b	"bad.crm2",0
_filename_crm2s_g	dc.b	"good.crm2s",0
_filename_crm2s_b	dc.b	"bad.crm2s",0
_filename_im_g		dc.b	"good.im",0
_filename_im_b		dc.b	"bad.im",0
_filename_rnc1_g	dc.b	"good.rn1",0
_filename_rnc1_b	dc.b	"bad.rn1",0
_filename_rnc2_g	dc.b	"good.rn2",0
_filename_rnc2_b	dc.b	"bad.rn2",0
_filename_rnc1old	dc.b	"alien.rnc1old",0
_filename_tpwm		dc.b	"alien.tpwm",0
_filename_iname_0	dc.b	"/test",0
_filename_iname_1	dc.b	"test/",0
_filename_iname_2	dc.b	"te//st",0
_filename_iname_3	dc.b	"t:est",0
_filename_save		dc.b	"save",0
_filename_protwrt	dc.b	"protected_write",0
_filename_protdel	dc.b	"protected_delete",0
_filename_dir		dc.b	"dir",0
_filename_notexist	dc.b	"notexist",0
	EVEN

_tags		dc.l	WHDLTAG_CUSTOM1_GET
_custom1	dc.l	0
		dc.l	WHDLTAG_Private6
_afa		dc.l	0
	IFD HRTMON
		dc.l	WHDLTAG_Private4
		dc.l	-1
	ENDC
		dc.l	0
_resload	dc.l	0

;======================================================================
_start	;	A0 = resident loader
;======================================================================

		move.l	a0,a4			;A4 = resload
		lea	(_resload),a0
		move.l	a4,(a0)
		lea	(_ciaa),a5		;A5 = ciaa
		lea	(_custom),a6		;A6 = custom
	;ssp in fast but not on first or last page because
	;resload_Protect
		move.l	(_expmem),a0
		add.l	#EXPMEM-$2000,a0
		move.l	a0,a7

	;init memory at upper chipmem bound because written by WHDLoad
	;during calling the slave
		lea	BASEMEMREAL-128,a0
		moveq	#128/4-2,d0
		move.l	(a0)+,d1
.clr		move.l	d1,(a0)+
		dbf	d0,.clr
		sub.l	a0,a0
		move.l	d1,(a0)+
		move.l	d1,(a0)+

		bsr	_SetupKeyboard

		lea	_tags,a0
		jsr	(resload_Control,a4)

		move.l	_custom1,d0
		beq	.bad
		lea	_table,a0
.loop		move.l	(a0)+,d1
		move.w	(a0)+,d2
		cmp.l	d0,d1
		beq	.found
		tst.w	d2
		bne	.loop

.bad		pea	_badcustom1
		pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a4)

.found		jsr	(_table,pc,d2.w)

		pea	TDREASON_OK
		jmp	(resload_Abort,a4)

;======================================================================

TAB	MACRO
	IFND DC
	dc.l	\1
	dc.w	\2-_table
	ENDC
	ENDM

TDC	MACRO			;only for directory cache
	IFD DC
	dc.l	\1
	dc.w	\2-_table
	ENDC
	ENDM

; numbers:
;	 xxxx all cpu
;	3xxxx only 68030 with MMU
;	4xxxx only 68040
;	6xxxx only 68060
;	8xxxx any cpu with MMU
;	9xxxx any cpu with MMU and Protect/Snoop supported
;      10xxxx only in debug mode

_table		; first line without TAB because perl parsing!

				;TDREASON_#?,search patterns,... ;options for WHDLoad

 TAB 91000,_bltsiz_0		;OK		;SnoopOCS ChkBltSize
 TAB 91001,_bltsiz_1a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91002,_bltsiz_2a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91003,_bltsiz_3a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91004,_bltsiz_4a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91005,_bltsiz_5a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91006,_bltsiz_6a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91007,_bltsiz_7a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91008,_bltsiz_8a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91009,_bltsiz_9a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91010,_bltsiz_10a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91011,_bltsiz_11a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91012,_bltsiz_12a		;BLITSIZE,DMA-A	;SnoopOCS ChkBltSize
 TAB 91021,_bltsiz_1b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91022,_bltsiz_2b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91023,_bltsiz_3b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91024,_bltsiz_4b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91025,_bltsiz_5b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91026,_bltsiz_6b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91027,_bltsiz_7b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91028,_bltsiz_8b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91029,_bltsiz_9b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91030,_bltsiz_10b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91031,_bltsiz_11b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91032,_bltsiz_12b		;BLITSIZE,DMA-B	;SnoopOCS ChkBltSize
 TAB 91041,_bltsiz_1c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91042,_bltsiz_2c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91043,_bltsiz_3c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91044,_bltsiz_4c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91045,_bltsiz_5c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91046,_bltsiz_6c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91047,_bltsiz_7c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91048,_bltsiz_8c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91049,_bltsiz_9c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91050,_bltsiz_10c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91051,_bltsiz_11c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91052,_bltsiz_12c		;BLITSIZE,DMA-C	;SnoopOCS ChkBltSize
 TAB 91061,_bltsiz_1d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91062,_bltsiz_2d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91063,_bltsiz_3d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91064,_bltsiz_4d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91065,_bltsiz_5d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91066,_bltsiz_6d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91067,_bltsiz_7d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91068,_bltsiz_8d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91069,_bltsiz_9d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91070,_bltsiz_10d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91071,_bltsiz_11d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91072,_bltsiz_12d		;BLITSIZE,DMA-D	;SnoopOCS ChkBltSize
 TAB 91100,_bltsiz_0		;OK		;SnoopOCS ChkBltSize ChkBltWait
 TAB 91200,_bltsizprot_0	;OK		;SnoopOCS ChkBltSize
 TAB 91201,_bltsizprot_1	;OK		;SnoopOCS ChkBltSize
 TAB 91202,_bltsizprot_2	;OK		;SnoopOCS ChkBltSize
 TAB 91203,_bltsizprot_3	;OK		;SnoopECS ChkBltSize
 TAB 91204,_bltsizprot_4	;OK		;SnoopECS ChkBltSize
 TAB 91205,_bltsizprot_5	;OK		;SnoopECS ChkBltSize
 TAB 91206,_bltsizprot_0	;OK		;SnoopOCS ChkBltSize ChkBltWait
 TAB 91207,_bltsizprot_1	;OK		;SnoopOCS ChkBltSize ChkBltWait
 TAB 91208,_bltsizprot_2	;OK		;SnoopOCS ChkBltSize ChkBltWait
 TAB 91209,_bltsizprot_3	;OK		;SnoopECS ChkBltSize ChkBltWait
 TAB 91210,_bltsizprot_4	;OK		;SnoopECS ChkBltSize ChkBltWait
 TAB 91211,_bltsizprot_5	;OK		;SnoopECS ChkBltSize ChkBltWait
 TAB 91220,_bltsizprot_20	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 91221,_bltsizprot_21	;BLITSIZE,Long Write,custom.bltdptl	;SnoopOCS ChkBltSize
 TAB 31222,_bltsizprot_22	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 41222,_bltsizprot_22	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 61222,_bltsizprot_22	;BLITSIZE,Word Write,custom.bltdptl	;SnoopOCS ChkBltSize
 TAB 91223,_bltsizprot_23	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize
 TAB 91224,_bltsizprot_24	;BLITSIZE,Long Write,custom.bltsizv	;SnoopECS ChkBltSize
 TAB 31225,_bltsizprot_25	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize
 TAB 41225,_bltsizprot_25	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize
 TAB 61225,_bltsizprot_25	;BLITSIZE,Word Write,custom.bltsizv	;SnoopECS ChkBltSize
 TAB 91226,_bltsizprot_20	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91227,_bltsizprot_21	;BLITSIZE,Long Write,custom.bltdptl	;SnoopOCS ChkBltSize ChkBltWait
 TAB 31228,_bltsizprot_22	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize ChkBltWait
 TAB 41228,_bltsizprot_22	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize ChkBltWait
 TAB 61228,_bltsizprot_22	;BLITSIZE,Word Write,custom.bltdptl	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91229,_bltsizprot_23	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize ChkBltWait
 TAB 91230,_bltsizprot_24	;BLITSIZE,Long Write,custom.bltsizv	;SnoopECS ChkBltSize ChkBltWait
 TAB 31231,_bltsizprot_25	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize ChkBltWait
 TAB 41231,_bltsizprot_25	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize ChkBltWait
 TAB 61231,_bltsizprot_25	;BLITSIZE,Word Write,custom.bltsizv	;SnoopECS ChkBltSize ChkBltWait
 TAB 91240,_bltsizprot_40	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 91241,_bltsizprot_41	;BLITSIZE,Long Write,custom.bltdptl	;SnoopOCS ChkBltSize
 TAB 31242,_bltsizprot_42	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 41242,_bltsizprot_42	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 61242,_bltsizprot_42	;BLITSIZE,Word Write,custom.bltdptl	;SnoopOCS ChkBltSize
 TAB 91243,_bltsizprot_43	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize
 TAB 91244,_bltsizprot_44	;BLITSIZE,Long Write,custom.bltsizv	;SnoopECS ChkBltSize
 TAB 31245,_bltsizprot_45	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize
 TAB 41245,_bltsizprot_45	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize
 TAB 61245,_bltsizprot_45	;BLITSIZE,Word Write,custom.bltsizv	;SnoopECS ChkBltSize
 TAB 91246,_bltsizprot_40	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91247,_bltsizprot_41	;BLITSIZE,Long Write,custom.bltdptl	;SnoopOCS ChkBltSize ChkBltWait
 TAB 31248,_bltsizprot_42	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize ChkBltWait
 TAB 41248,_bltsizprot_42	;BLITSIZE,Word Write,custom.bltsize	;SnoopOCS ChkBltSize ChkBltWait
 TAB 61248,_bltsizprot_42	;BLITSIZE,Word Write,custom.bltdptl	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91249,_bltsizprot_43	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize ChkBltWait
 TAB 91250,_bltsizprot_44	;BLITSIZE,Long Write,custom.bltsizv	;SnoopECS ChkBltSize ChkBltWait
 TAB 31251,_bltsizprot_45	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize ChkBltWait
 TAB 41251,_bltsizprot_45	;BLITSIZE,Word Write,custom.bltsizh	;SnoopECS ChkBltSize ChkBltWait
 TAB 61251,_bltsizprot_45	;BLITSIZE,Word Write,custom.bltsizv	;SnoopECS ChkBltSize ChkBltWait
 TAB 91260,_bltsizprot_d0	;OK					;SnoopECS ChkBltSize
 TAB 91261,_bltsizprot_d1	;BLITSIZE,Word Write,custom.bltsize	;SnoopECS ChkBltSize
 TAB 91262,_bltsizprot_d2	;BLITSIZE,Word Write,custom.bltsize	;SnoopECS ChkBltSize
 TAB 91300,_bltline_0	;OK						;SnoopOCS ChkBltSize
 TAB 91301,_bltline_1	;BLITLINE,width not equal,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 91302,_bltline_2	;BLITLINE,bltdpt outside,custom.bltsize		;SnoopOCS ChkBltSize
 TAB 91303,_bltline_3	;BLITLINE,bltcpt not equal,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 91304,_bltline_4	;BLITLINE,bltadat not equal,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 91305,_bltline_5	;BLITLINE,bltcon0 invalid,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 91306,_bltline_6	;BLITLINE,bltcon1 invalid,custom.bltsize	;SnoopOCS ChkBltSize
 TAB 91811,_bltwait_11t	;ACCESSFAULT,custom.bltsizv	;SnoopOCS
 TAB 91821,_bltsizprot_21t	;BLITSIZE,Long Write,custom.bltdptl	;SnoopOCS
 TAB 91830,_bltwait_16t	;ACCESSFAULT,custom.bltsize	;SnoopECS
 TAB 91899,_bltwait_0b	;OK		;SnoopECS ChkBltWait
 TAB 91900,_bltwait_0w	;OK		;SnoopECS ChkBltWait
 TAB 91901,_bltwait_1	;BLITWAIT,custom.bltcon0l	;SnoopECS ChkBltWait
 TAB 91902,_bltwait_1	;BLITWAIT,custom.bltcon0l	;SnoopECS ChkBltSize ChkBltWait
 TAB 91903,_bltwait_3	;BLITWAIT,custom.bltafwm	;SnoopOCS ChkBltWait
 TAB 91904,_bltwait_4	;BLITWAIT,custom.bltafwm	;SnoopOCS ChkBltWait
 TAB 91905,_bltwait_5	;BLITWAIT,custom.bltafwm	;SnoopOCS ChkBltWait
 TAB 91906,_bltwait_6	;BLITWAIT,custom.bltafwm	;SnoopOCS ChkBltWait
 TAB 31907,_bltwait_7	;ACCESSFAULT,custom.bltcon0l	;SnoopOCS ChkBltWait
 TAB 41907,_bltwait_7	;ACCESSFAULT,custom.bltcon0l	;SnoopOCS ChkBltWait
 TAB 61907,_bltwait_7	;ACCESSFAULT,custom.bltdpt	;SnoopOCS ChkBltWait
 TAB 31908,_bltwait_8	;ACCESSFAULT,custom.bltsize	;SnoopOCS ChkBltWait
 TAB 41908,_bltwait_8	;ACCESSFAULT,custom.bltsize	;SnoopOCS ChkBltWait
 TAB 61908,_bltwait_8	;ACCESSFAULT,custom.bltdpt	;SnoopOCS ChkBltWait
 TAB 91909,_bltwait_9	;ACCESSFAULT,custom.bltsizv	;SnoopOCS ChkBltWait
 TAB 91910,_bltwait_10	;ACCESSFAULT,custom.bltsizv	;SnoopOCS ChkBltWait
 TAB 91911,_bltwait_11	;ACCESSFAULT,custom.bltsizv	;SnoopOCS ChkBltWait
 TAB 91912,_bltwait_9	;BLITWAIT,custom.bltafwm	;SnoopECS ChkBltWait
 TAB 91913,_bltwait_10	;BLITWAIT,custom.bltafwm	;SnoopECS ChkBltWait
 TAB 91914,_bltwait_11	;BLITWAIT,custom.bltafwm	;SnoopECS ChkBltWait
 TAB 91915,_bltwait_15	;ACCESSFAULT,custom.bltcon0l	;SnoopECS ChkBltWait
 TAB 91916,_bltwait_16	;ACCESSFAULT,custom.bltsize	;SnoopECS ChkBltWait
 TAB 91917,_bltwait_3	;BLITWAIT,custom.bltafwm	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91918,_bltwait_4	;BLITWAIT,custom.bltafwm	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91919,_bltwait_5	;BLITWAIT,custom.bltafwm	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91920,_bltwait_6	;BLITWAIT,custom.bltafwm	;SnoopOCS ChkBltSize ChkBltWait
 TAB 31921,_bltwait_7	;ACCESSFAULT,custom.bltcon0l	;SnoopOCS ChkBltSize ChkBltWait
 TAB 41921,_bltwait_7	;ACCESSFAULT,custom.bltcon0l	;SnoopOCS ChkBltSize ChkBltWait
 TAB 61921,_bltwait_7	;ACCESSFAULT,custom.bltdpt	;SnoopOCS ChkBltSize ChkBltWait
 TAB 31922,_bltwait_8	;ACCESSFAULT,custom.bltsize	;SnoopOCS ChkBltSize ChkBltWait
 TAB 41922,_bltwait_8	;ACCESSFAULT,custom.bltsize	;SnoopOCS ChkBltSize ChkBltWait
 TAB 61922,_bltwait_8	;ACCESSFAULT,custom.bltdpt	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91923,_bltwait_9	;ACCESSFAULT,custom.bltsizv	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91924,_bltwait_10	;ACCESSFAULT,custom.bltsizv	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91925,_bltwait_11	;ACCESSFAULT,custom.bltsizv	;SnoopOCS ChkBltSize ChkBltWait
 TAB 91926,_bltwait_9	;BLITWAIT,custom.bltafwm	;SnoopECS ChkBltSize ChkBltWait
 TAB 91927,_bltwait_10	;BLITWAIT,custom.bltafwm	;SnoopECS ChkBltSize ChkBltWait
 TAB 91928,_bltwait_11	;BLITWAIT,custom.bltafwm	;SnoopECS ChkBltSize ChkBltWait
 TAB 91929,_bltwait_15	;ACCESSFAULT,custom.bltcon0l	;SnoopECS ChkBltSize ChkBltWait
 TAB 91930,_bltwait_16	;ACCESSFAULT,custom.bltsize	;SnoopECS ChkBltSize ChkBltWait
 TAB 92000,_copcon_0	;ACCESSFAULT			;SnoopOCS ChkCopCon
 TAB 92001,_copcon_1	;ACCESSFAULT			;SnoopOCS ChkCopCon
 TAB 92002,_copcon_2	;ACCESSFAULT			;SnoopOCS ChkCopCon
 TAB 92003,_copcon_3	;ACCESSFAULT			;SnoopOCS ChkCopCon
 TAB 92004,_copcon_4	;OK				;SnoopOCS
 TAB 92101,_cia_1	;OK				;SnoopOCS
 TAB 92102,_cia_2	;OK				;SnoopOCS
 TAB 92103,_cia_3	;ACCESSFAULT,ciaa.pra		;Snoop
 TAB 92104,_cia_4	;OK				;SnoopOCS
 TAB 92105,_cia_5	;ACCESSFAULT,ciaa.ddra		;SnoopOCS
 TAB 92106,_cia_6	;OK				;SnoopOCS
 TAB 92107,_cia_7	;OK				;SnoopOCS
 TAB 62108,_cia_8	;ACCESSFAULT,ciaa.todlow	;SnoopECS
 TAB 92109,_cia_9	;OK				;SnoopOCS
 TAB 92110,_cia_10	;OK				;SnoopOCS
 TAB 92111,_cia_11	;OK				;SnoopOCS
 TAB 92112,_cia_12	;ACCESSFAULT,ciab.prb		;SnoopAGA
 TAB 92113,_cia_13	;OK				;SnoopOCS
 TAB 92114,_cia_14	;ACCESSFAULT,ciab.ddra		;SnoopOCS
 TAB 92115,_cia_15	;OK				;SnoopOCS
 TAB 92116,_cia_16	;ACCESSFAULT,ciab.ddrb		;SnoopOCS
 TAB 92117,_cia_17	;OK				;SnoopOCS
 TAB 92118,_cia_18	;OK				;SnoopOCS
 TAB 92201,_cust_1	;OK				;SnoopOCS
 TAB 92202,_cust_2	;OK				;SnoopOCS
 TAB 92203,_cust_3	;OK				;SnoopOCS
 TAB 92204,_cust_4	;OK				;Snoop
 TAB 92205,_cust_5	;OK				;Snoop
 TAB 92206,_cust_4	;ACCESSFAULT,custom.intreqr	;SnoopOCS
 TAB 92207,_cust_5	;ACCESSFAULT,custom.bltcon0	;SnoopOCS
 TAB 92208,_cust_8	;OK				;Snoop
 TAB 92209,_cust_9	;OK				;Snoop
 TAB 92210,_cust_10	;OK				;Snoop
 TAB 92211,_cust_8	;ACCESSFAULT,Byte Write,custom.dmaconr	;SnoopOCS
 TAB 92212,_cust_9	;ACCESSFAULT,Word Write,custom.dmaconr	;SnoopOCS
 TAB 92213,_cust_10	;ACCESSFAULT,Long Write,custom.dmaconr	;SnoopOCS
 TAB 92214,_cust_14	;OK				;SnoopAGA
 TAB 92215,_cust_14	;ACCESSFAULT			;SnoopECS
 TAB 92216,_cust_16	;OK				;SnoopECS
 TAB 92217,_cust_16	;ACCESSFAULT			;SnoopOCS
 TAB 92218,_cust_18	;ACCESSFAULT			;SnoopOCS
 TAB 92219,_cust_19	;OK				;SnoopOCS
 TAB 92220,_cust_20	;OK				;Snoop
 TAB 32221,_cust_21	;OK				;Snoop
 TAB 42221,_cust_21	;OK				;Snoop
 TAB 62221,_cust_21	;SNOOPSSPMODI			;Snoop
 TAB 92222,_cust_22	;ACCESSFAULT			;SnoopOCS ChkAudPt
 TAB 92223,_cust_23	;ACCESSFAULT			;SnoopOCS ChkAudPt
 TAB 92224,_cust_22	;OK				;SnoopOCS 
 TAB 92225,_cust_25	;ACCESSFAULT			;SnoopOCS ChkColBst
 TAB 92226,_cust_26	;ACCESSFAULT			;SnoopOCS
 TAB 92227,_cust_27	;ACCESSFAULT			;SnoopOCS
 TAB 92228,_cust_28	;ACCESSFAULT			;SnoopOCS
 TAB 92229,_cust_29	;ACCESSFAULT			;SnoopOCS
 TAB 92234,_cust_34	;OK				;SnoopOCS
 TAB 92235,_cust_34	;ACCESSFAULT			;SnoopOCS ChkBltHog
 TAB 92236,_cust_36	;ACCESSFAULT			;SnoopOCS ChkCopCon
 TAB 92237,_cust_37	;ACCESSFAULT			;SnoopOCS ChkCopCon
 TAB 92238,_cust_38	;ACCESSFAULT			;SnoopOCS ChkCopCon
 TAB 92239,_cust_36	;OK				;SnoopOCS
 TAB 92240,_cust_37	;OK				;SnoopOCS
 TAB 92241,_cust_38	;OK				;SnoopOCS
 TAB 92242,_cust_42	;ACCESSFAULT			;SnoopOCS
 TAB 92243,_cust_42	;ACCESSFAULT			;SnoopOCS ChkBltWait
 TAB 92244,_cust_42	;ACCESSFAULT			;SnoopOCS ChkBltWait ChkBltSize
 TAB 92245,_cust_42	;ACCESSFAULT			;SnoopOCS ChkBltSize
 TAB 92246,_cust_46	;ACCESSFAULT			;SnoopOCS Chk
 TAB 92247,_cust_47	;ACCESSFAULT,custom.bltsize	;SnoopECS
 TAB 92248,_cust_48	;ACCESSFAULT,custom.bltsizh	;SnoopECS
 TAB 92260,_cust_60	;OK				;SnoopOCS
 TAB 92261,_cust_612	;ACCESSFAULT,custom.bpl1pt	;SnoopOCS
 TAB 92262,_cust_612	;OK				;Snoop
 TAB 92263,_cust_634	;ACCESSFAULT,custom.bpl8pt	;SnoopAGA
 TAB 92265,_cust_65	;ACCESSFAULT,custom.bpl2pt	;SnoopECS
 TAB 92267,_cust_67	;ACCESSFAULT,			;SnoopAGA
 TAB 92268,_cust_68	;ACCESSFAULT,custom.bpl1ptl	;SnoopAGA
 TAB 92269,_cust_69	;ACCESSFAULT,custom.bpl8ptl	;SnoopAGA
 TAB 92300,_cop_0	;OK				;SnoopECS
 TAB 92301,_cop_1	;BADCOP				;SnoopOCS
 TAB 92302,_cop_2	;BADCOP				;SnoopOCS
 TAB 92303,_cop_3	;OK				;SnoopOCS
 TAB 92304,_cop_3	;BADCOP				;SnoopOCS ChkColBst
 TAB 92305,_cop_3	;BADCOP				;SnoopOCS Chk
 TAB 92306,_cop_6	;BADCOP				;SnoopOCS
 TAB 92307,_cop_6	;OK				;SnoopECS
 TAB 92308,_cop_8	;BADCOP				;SnoopOCS
 TAB 92309,_cop_8	;OK				;SnoopECS
 TAB 92310,_cop_10	;OK				;Snoop
 TAB 92311,_cop_10	;BADCOP				;SnoopOCS
 TAB 92312,_cop_12	;BADCOP				;SnoopOCS
 TAB 92313,_cop_13	;BADCOP				;SnoopOCS
 TAB 92320,_cop_20	;BADCOP,invalid copperlist,$5004,Long Write to $DFF080	;SnoopOCS
 TAB 92321,_cop_21	;BADCOP,invalid copperlist,$5004,Long Write to $DFF084	;SnoopOCS
 TAB 92322,_cop_22	;BADCOP,invalid copperlist,$5004,Word Write to $DFF082	;SnoopOCS
 TAB 92323,_cop_23	;BADCOP,invalid copperlist,$5004,Word Write to $DFF086	;SnoopOCS
 TAB 92324,_cop_24	;BADCOP,invalid copperlist,$15000,Word Write to $DFF080	;SnoopOCS
 TAB 92325,_cop_25	;BADCOP,invalid copperlist,$15000,Word Write to $DFF084	;SnoopOCS
 TAB 92400,_custtag_0	;OK				;SnoopOCS
 TAB 92401,_custtag_1	;ACCESSFAULT			;SnoopOCS
 TAB 92402,_custtag_2	;ACCESSFAULT			;SnoopOCS
 TAB 92403,_custtag_3	;OK				;SnoopOCS
 TAB 92404,_custtag_4	;ACCESSFAULT			;SnoopOCS
 TAB 92405,_custtag_5	;ACCESSFAULT			;SnoopOCS
 TAB 92406,_custtag_6	;OK				;SnoopOCS
 TAB 92407,_custtag_7	;OK				;SnoopOCS
 TAB 92408,_custtag_8	;ACCESSFAULT			;SnoopOCS
 TAB 83000,_af_inst_0		;ACCESSFAULT,Instruction stream,$A0000000	;
 TAB 93001,_af_inst_1		;ACCESSFAULT,Word Read,$0			;
 TAB 93002,_af_inst_2		;ACCESSFAULT,Word Read,$1000			;
 TAB 33003,_af_inst_330		;ACCESSFAULT,Word Read,$3FFFC			;
 TAB 43003,_af_inst_330		;ACCESSFAULT,Word Read,$3FFFC			;
 TAB 63003,_af_inst_360		;ACCESSFAULT,Word Read,$3FFFE			;
 TAB 93004,_af_inst_4		;ACCESSFAULT,Word Read,(ExpMem $0)		;
 TAB 93005,_af_inst_5		;ACCESSFAULT,Word Read,(ExpMem $100)		;
 TAB 33006,_af_inst_630		;ACCESSFAULT,Word Read,(ExpMem $FFFC)		;
 TAB 43006,_af_inst_630		;ACCESSFAULT,Word Read,(ExpMem $FFFC)		;
 TAB 63006,_af_inst_660		;ACCESSFAULT,Word Read,(ExpMem $FFFE)		;
 TAB 93007,_af_inst_7		;ACCESSFAULT,Word Read,$1000			;
 TAB 93008,_af_inst_8		;ACCESSFAULT,Long Read,$1000			;
 TAB 33009,_af_inst_9		;ACCESSFAULT,Word Read,$1100			;
 TAB 43009,_af_inst_9		;OK		;
 TAB 63009,_af_inst_9		;OK		;
 TAB 33010,_af_inst_10		;ACCESSFAULT,Long Read,$1100			;
 TAB 43010,_af_inst_9		;OK		;
 TAB 63010,_af_inst_9		;OK		;
 TAB 93011,_af_inst_11		;ACCESSFAULT,Word Read,$1000			;
 TAB 33012,_af_inst_12		;ACCESSFAULT,Word Read,$1100			;
 TAB  3020,_af_inst_20		;EXCEPTION,Address Error			;
 TAB 43030,_af_30		;ACCESSFAULT,Move16 Read			;
 TAB 63030,_af_30		;ACCESSFAULT,Move16 Read			;
 TAB 33031,_af_31		;ACCESSFAULT,Long Read,$40000			;
 TAB 43031,_af_31		;ACCESSFAULT,Long Read,$40000			;
 TAB 63031,_af_31_60		;ACCESSFAULT,Long Read,$40000			;
 TAB  3051,_fullchip_1		;FULLCHIP,$40002 and $40003			;FullChip
 TAB  3052,_fullchip_2		;FULLCHIP,$1FF002 and $1FF003			;FullChip
 TAB  3053,_fullchip_3		;FULLCHIP,$100002 and $110003			;FullChip
 TAB 93100,_af_smc_ok		;OK,						;
 TAB 93101,_af_smc_1		;SMC,address $1002 has				;
 TAB 93110,_af_smc_ba1		;PROTECTSMC,already				;
 TAB 93111,_af_smc_ba2		;ILLEGALARGS,TC =				;
 TAB 93200,_af_cbaf_0		;ACCESSFAULT,$1000				;
 TAB 93201,_af_cbaf_1		;OK		;
 TAB 33202,_af_cbaf_230		;OK		;
 TAB 43202,_af_cbaf_240		;OK		;
 TAB 63202,_af_cbaf_260		;OK		;
 TAB 33203,_af_cbaf_330		;OK		;
 TAB 43203,_af_cbaf_340		;OK		;
 TAB 63203,_af_cbaf_360		;OK		;
 TAB 94000,_af_prot_rlok	;OK		;
 TAB 94001,_af_prot_wlok	;OK		;
 TAB 94002,_af_prot_rwok	;OK		;
 TAB 94003,_af_prot_wwok	;OK		;
 TAB 94004,_af_prot_rbok	;OK		;
 TAB 94005,_af_prot_wbok	;OK		;
 TAB 94010,_af_prot_rll		;ACCESSFAULT,Long Read from $10FD		;
 TAB 94011,_af_prot_rlu		;ACCESSFAULT,Long Read from $1103		;
 TAB 94012,_af_prot_wll		;ACCESSFAULT,Long Write to $10FD		;
 TAB 94013,_af_prot_wlu		;ACCESSFAULT,Long Write to $1103		;
 TAB 34014,_af_prot_mll		;ACCESSFAULT,Long Read from $10FD		;
 TAB 34015,_af_prot_mlu		;ACCESSFAULT,Long Read from $1103		;
 TAB 44014,_af_prot_mll		;ACCESSFAULT,Long Read from $10FD		;
 TAB 44015,_af_prot_mlu		;ACCESSFAULT,Long Read from $1103		;
 TAB 64014,_af_prot_mll		;ACCESSFAULT,Long Read-Modify-Write on $10FD	;
 TAB 64015,_af_prot_mlu		;ACCESSFAULT,Long Read-Modify-Write on $1103	;
 TAB 94020,_af_prot_rwl		;ACCESSFAULT,Word Read from $10FF		;
 TAB 94021,_af_prot_rwu		;ACCESSFAULT,Word Read from $1103		;
 TAB 94022,_af_prot_wwl		;ACCESSFAULT,Word Write to $10FF		;
 TAB 94023,_af_prot_wwu		;ACCESSFAULT,Word Write to $1103		;
 TAB 34024,_af_prot_mwl		;ACCESSFAULT,Word Read from $10FF		;
 TAB 34025,_af_prot_mwu		;ACCESSFAULT,Word Read from $1103		;
 TAB 44024,_af_prot_mwl		;ACCESSFAULT,Word Read from $10FF		;
 TAB 44025,_af_prot_mwu		;ACCESSFAULT,Word Read from $1103		;
 TAB 64024,_af_prot_mwl		;ACCESSFAULT,Word Read-Modify-Write on $10FF	;
 TAB 64025,_af_prot_mwu		;ACCESSFAULT,Word Read-Modify-Write on $1103	;
 TAB 94030,_af_prot_rbl		;ACCESSFAULT,Byte Read from $1100		;
 TAB 94031,_af_prot_rbu		;ACCESSFAULT,Byte Read from $1103		;
 TAB 94032,_af_prot_wbl		;ACCESSFAULT,Byte Write to $1100		;
 TAB 94033,_af_prot_wbu		;ACCESSFAULT,Byte Write to $1103		;
 TAB 34034,_af_prot_mbl		;ACCESSFAULT,Byte Read from $1100		;
 TAB 34035,_af_prot_mbu		;ACCESSFAULT,Byte Read from $1103		;
 TAB 44034,_af_prot_mbl		;ACCESSFAULT,Byte Read from $1100		;
 TAB 44035,_af_prot_mbu		;ACCESSFAULT,Byte Read from $1103		;
 TAB 64034,_af_prot_mbl		;ACCESSFAULT,Byte Read-Modify-Write on $1100	;
 TAB 64035,_af_prot_mbu		;ACCESSFAULT,Byte Read-Modify-Write on $1103	;
 TAB 94040,_af_prot_tas		;ACCESSFAULT,locked Byte Read-Modify-Write on $1100;
 TAB 94041,_af_prot_cas		;ACCESSFAULT,locked Long Read-Modify-Write on $1100;
 TAB 34101,_af_prot_bf1		;ACCESSFAULT,Byte Read from $2000;
 TAB 44101,_af_prot_bf1		;ACCESSFAULT,Byte Read from $2000;
 TAB 64101,_af_prot_bf1		;ACCESSFAULT,Long Read from $2000;
 TAB 94102,_af_prot_bf2		;OK;
 TAB 34103,_af_prot_bf3		;ACCESSFAULT,Byte Write to $2000;
 TAB 44103,_af_prot_bf3		;ACCESSFAULT,Byte Write to $2000;
 TAB 64103,_af_prot_bf3		;ACCESSFAULT,Long Read-Modify-Write on $2000;
 TAB 34104,_af_prot_bf4		;ACCESSFAULT,Long Read from $2000;
 TAB 44104,_af_prot_bf4		;ACCESSFAULT,Long Read from $2000;
 TAB 64104,_af_prot_bf4		;ACCESSFAULT,Long Read-Modify-Write on $2000;
 TAB 4900,_emul_sr		;OK;
 TAB 5000,_patch_ok		;OK;
 TAB 5001,_patch_1		;PATCHDATA,reference to address $FFFFFFFE;
 TAB 5002,_patch_2		;PATCHDATA,reference to address $FFFFFFFF;
 TAB 5003,_patch_3		;PATCHDATA,reference to address $40001;
 TAB 5004,_patch_4		;PATCHDEST;
 TAB 5005,_patch_5		;PATCHALIGN;
 TAB 5006,_patch_6		;PATCHALIGN;
 TAB 5007,_patch_71		;OK;
 TAB 5008,_patch_72		;OK;ButtonWait Custom2=1 Custom3=-1 Custom4=128 Custom5=7
 TAB 5009,_patch_9		;PATCHIF,command PLCMD_ELSE;
 TAB 5010,_patch_10		;PATCHIF,command PLCMD_ENDIF;
 TAB 5011,_patch_11		;PATCHIF,command PLCMD_END ;
 TAB 5012,_patch_12		;PATCHIF,command PLCMD_NEXT;
 TAB 5013,_patch_13		;PATCHIFBITS;
 TAB 5014,_patch_14		;PATCHIFBITS;
 TAB 5099,_patch_ff		;PATCHCMD,invalid command PLCMD_255 $1234;
 TAB 5100,_patchseg_ok		;OK;
 TAB 5101,_patchseg_1		;PATCHDATA,reference to address $1FFE;
 TAB 5102,_patchseg_2		;PATCHDATA,reference to address $1FFE;
 TAB 5103,_patchseg_3		;PATCHDATA,reference to address $3000;
 TAB 5104,_patchseg_4		;PATCHDATA,reference to address $3006;
 TAB 5105,_patchseg_5		;PATCHDATA,reference to address $4008;
 TAB 5106,_patchseg_6		;PATCHDATA,reference to address $1FFF;
 TAB 5107,_patchseg_7		;PATCHDATA,reference to address $3001;
 TAB 5108,_patchseg_8		;PATCHSEGOFF,outside the segment list ($2000 bytes);
 TAB 5109,_patchseg_9		;PATCHBADSEG;
 TAB 5199,_patchseg_ff		;PATCHCMD,invalid command PLCMD_255 $1234;
 TAB 5200,_loadoffset_0		;OK				;Data=data PreLoad
 TAB 5201,_loadoffset_1		;OK				;Data=data PreLoad
 TAB 5202,_loadoffset_2		;OK				;Data=data PreLoad
 TAB 5203,_loadoffset_3		;OK				;Data=data PreLoad
 TAB 5204,_loadoffset_4		;OK				;Data=data PreLoad
 TAB 5205,_loadoffset_5		;OK				;Data=data PreLoad
 TAB 5206,_loadoffset_6		;OK				;Data=data PreLoad
 TAB 5207,_loadoffset_7		;OK				;Data=data PreLoad
 TAB 5208,_loadoffset_8		;OK				;Data=data PreLoad
 TAB 5209,_loadoffset_9		;OK				;Data=data PreLoad
 TAB 5210,_loadoffset_10	;OK				;Data=data PreLoad
 TAB 5211,_loadoffset_11	;OK				;Data=data PreLoad
 TAB 5212,_loadoffset_12	;OK				;Data=data PreLoad
 TAB 5220,_loadoffset_20	;ILLEGALARGS,A1 = $FFFFFFFF	;Data=data PreLoad
 TAB 5221,_loadoffset_21	;ILLEGALARGS,D0 = $100		;Data=data PreLoad
 TAB 5222,_loadoffset_22	;ILLEGALARGS,A1 = $		;Data=data PreLoad
 TAB 5223,_loadoffset_23	;ILLEGALARGS,D0 = $2		;Data=data PreLoad
 TAB 5224,_loadoffset_24	;ILLEGALARGS,A1 = $		;Data=data PreLoad
 TAB 5225,_loadoffset_25	;ILLEGALARGS,D0 = $2		;Data=data PreLoad
 TAB 5226,_loadoffset_26	;ILLEGALARGS,SSP = $		;Data=data PreLoad
 TAB 5227,_loadoffset_27	;ILLEGALARGS,SSP = $		;Data=data PreLoad
 TAB 5228,_loadoffset_28	;ILLEGALARGS,USP = $		;Data=data PreLoad
 TAB 5229,_loadoffset_29	;ILLEGALARGS,USP = $		;Data=data PreLoad
 TAB 5230,_loadoffset_30	;ILLEGALARGS,SSP = $		;Data=data PreLoad
 TAB 5231,_loadoffset_31	;ILLEGALARGS,SSP = $		;Data=data PreLoad
 TAB 5232,_loadoffset_32	;ILLEGALARGS,D0 = $FFFFFFFF	;Data=data PreLoad
 TAB 5233,_loadoffset_33	;ILLEGALARGS,D1 = $FFFFFFFF	;Data=data PreLoad
 TAB 5300,_loadfile_0		;OK				;Data=data
 TAB 5301,_loadfile_0		;OK				;Data=data PreLoad
 TAB 5302,_loadfile_0		;OK				;Data=data NoFileCache
 TAB 5303,_loadfile_0		;OK				;Data=data PreLoad NoFileCache
 TAB 5310,_loadfileoff_0	;OK				;Data=data
 TAB 5311,_loadfileoff_0	;OK				;Data=data PreLoad
 TAB 5312,_loadfileoff_0	;OK				;Data=data NoFileCache
 TAB 5313,_loadfileoff_0	;OK				;Data=data PreLoad NoFileCache
 TAB 5320,_diskload_0		;OK				;Data=data
 TAB 5321,_diskload_0		;OK				;Data=data PreLoad
 TAB 5322,_diskload_0		;OK				;Data=data NoFileCache
 TAB 5323,_diskload_0		;OK				;Data=data PreLoad NoFileCache
 TAB 5330,_getfilesize_0	;OK				;Data=data
 TAB 5331,_getfilesize_0	;OK				;Data=data PreLoad
 TAB 5332,_getfilesize_0	;OK				;Data=data NoFileCache
 TAB 5333,_getfilesize_0	;OK				;Data=data PreLoad NoFileCache
 TAB 5340,_getfilesizedec_0	;OK				;Data=data
 TAB 5341,_getfilesizedec_0	;OK				;Data=data PreLoad
 TAB 5342,_getfilesizedec_0	;OK				;Data=data NoFileCache
 TAB 5343,_getfilesizedec_0	;OK				;Data=data PreLoad NoFileCache
 TAB 5345,_getfilesizedec_4	;OK				;Data=data
 TAB 5346,_getfilesizedec_4	;OK				;Data=data PreLoad
 TAB 5347,_getfilesizedec_4	;OK				;Data=data NoFileCache
 TAB 5348,_getfilesizedec_4	;OK				;Data=data PreLoad NoFileCache
 TAB 5350,_illegalname_0	;ILLEGALNAME			;
 TAB 5351,_illegalname_1	;ILLEGALNAME			;
 TAB 5352,_illegalname_2	;ILLEGALNAME			;
 TAB 5353,_illegalname_3	;ILLEGALNAME			;
 TAB 5360,_loadfiledec_0	;OK				;Data=data
 TAB 5361,_loadfiledec_1	;OK				;Data=data
 TAB 5362,_loadfiledec_2	;OK				;Data=data
 TAB 5363,_loadfiledec_3	;OK				;Data=data
 TAB 5364,_loadfiledec_4	;OK				;Data=data
 TAB 5365,_loadfiledec_5	;OK				;Data=data
 TAB 5366,_loadfiledec_6	;OK				;Data=data
 TAB 5370,_loadfiledec_0	;OK				;Data=data PreLoad
 TAB 5371,_loadfiledec_1	;OK				;Data=data PreLoad
 TAB 5372,_loadfiledec_2	;OK				;Data=data PreLoad
 TAB 5373,_loadfiledec_3	;OK				;Data=data PreLoad
 TAB 5374,_loadfiledec_4	;OK				;Data=data PreLoad
 TAB 5375,_loadfiledec_5	;OK				;Data=data PreLoad
 TAB 5376,_loadfiledec_6	;OK				;Data=data PreLoad
 TAB 5380,_loadfiledec_0	;OK				;Data=data NoFileCache
 TAB 5381,_loadfiledec_1	;OK				;Data=data NoFileCache
 TAB 5382,_loadfiledec_2	;OK				;Data=data NoFileCache
 TAB 5383,_loadfiledec_3	;OK				;Data=data NoFileCache
 TAB 5384,_loadfiledec_4	;OK				;Data=data NoFileCache
 TAB 5385,_loadfiledec_5	;OK				;Data=data NoFileCache
 TAB 5386,_loadfiledec_6	;OK				;Data=data NoFileCache
 TAB 5390,_loadfiledec_0	;OK				;Data=data PreLoad NoFileCache
 TAB 5391,_loadfiledec_1	;OK				;Data=data PreLoad NoFileCache
 TAB 5392,_loadfiledec_2	;OK				;Data=data PreLoad NoFileCache
 TAB 5393,_loadfiledec_3	;OK				;Data=data PreLoad NoFileCache
 TAB 5394,_loadfiledec_4	;OK				;Data=data PreLoad NoFileCache
 TAB 5395,_loadfiledec_5	;OK				;Data=data PreLoad NoFileCache
 TAB 5396,_loadfiledec_6	;OK				;Data=data PreLoad NoFileCache
; decrunching inplace (src=dest) align=long
 TAB 5400,_decrunch0_crm1_g	;OK				;Data=data PreLoad
 TAB 5401,_decrunch0_crm1s_g	;OK				;Data=data PreLoad
 TAB 5402,_decrunch0_crm2_g	;OK				;Data=data PreLoad
 TAB 5403,_decrunch0_crm2s_g	;OK				;Data=data PreLoad
 TAB 5404,_decrunch0_im_g	;OK				;Data=data PreLoad
 TAB 5405,_decrunch0_rnc1_g	;OK				;Data=data PreLoad
 TAB 5406,_decrunch0_rnc2_g	;OK				;Data=data PreLoad
 TAB 5407,_decrunch0_rnc1o	;OK				;Data=data PreLoad
 TAB 5408,_decrunch0_tpwm	;OK				;Data=data PreLoad
; decrunching inplace (src=dest) align=long+1
 TAB 5414,_decrunch1_im_g	;OK				;Data=data PreLoad
 TAB 5415,_decrunch1_rnc1_g	;OK				;Data=data PreLoad
 TAB 5416,_decrunch1_rnc2_g	;OK				;Data=data PreLoad
 TAB 5417,_decrunch1_rnc1o	;OK				;Data=data PreLoad
 TAB 5418,_decrunch1_tpwm	;OK				;Data=data PreLoad
; decrunching inplace (src=dest) align=long+2
 TAB 5420,_decrunch2_crm1_g	;OK				;Data=data PreLoad
 TAB 5421,_decrunch2_crm1s_g	;OK				;Data=data PreLoad
 TAB 5422,_decrunch2_crm2_g	;OK				;Data=data PreLoad
 TAB 5423,_decrunch2_crm2s_g	;OK				;Data=data PreLoad
 TAB 5424,_decrunch2_im_g	;OK				;Data=data PreLoad
 TAB 5425,_decrunch2_rnc1_g	;OK				;Data=data PreLoad
 TAB 5426,_decrunch2_rnc2_g	;OK				;Data=data PreLoad
 TAB 5427,_decrunch2_rnc1o	;OK				;Data=data PreLoad
 TAB 5428,_decrunch2_tpwm	;OK				;Data=data PreLoad
; decrunching inplace (src=dest) align=long+3
 TAB 5434,_decrunch3_im_g	;OK				;Data=data PreLoad
 TAB 5435,_decrunch3_rnc1_g	;OK				;Data=data PreLoad
 TAB 5436,_decrunch3_rnc2_g	;OK				;Data=data PreLoad
 TAB 5437,_decrunch3_rnc1o	;OK				;Data=data PreLoad
 TAB 5438,_decrunch3_tpwm	;OK				;Data=data PreLoad
; decrunching without overlap
 TAB 5440,_decrunch4_crm1_g	;OK				;Data=data PreLoad
 TAB 5441,_decrunch4_crm1s_g	;OK				;Data=data PreLoad
 TAB 5442,_decrunch4_crm2_g	;OK				;Data=data PreLoad
 TAB 5443,_decrunch4_crm2s_g	;OK				;Data=data PreLoad
 TAB 5444,_decrunch4_im_g	;OK				;Data=data PreLoad
 TAB 5445,_decrunch4_rnc1_g	;OK				;Data=data PreLoad
 TAB 5446,_decrunch4_rnc2_g	;OK				;Data=data PreLoad
 TAB 5447,_decrunch4_rnc1o	;OK				;Data=data PreLoad
 TAB 5448,_decrunch4_tpwm	;OK				;Data=data PreLoad
; decrunching with overlap, destination after source
 TAB 5450,_decrunch5_crm1_g	;OK				;Data=data PreLoad
 TAB 5451,_decrunch5_crm1s_g	;OK				;Data=data PreLoad
 TAB 5452,_decrunch5_crm2_g	;OK				;Data=data PreLoad
 TAB 5453,_decrunch5_crm2s_g	;OK				;Data=data PreLoad
 TAB 5454,_decrunch5_im_g	;OK				;Data=data PreLoad
 TAB 5455,_decrunch5_rnc1_g	;OK				;Data=data PreLoad
 TAB 5456,_decrunch5_rnc2_g	;OK				;Data=data PreLoad
 TAB 5457,_decrunch5_rnc1o	;OK				;Data=data PreLoad
 TAB 5458,_decrunch5_tpwm	;OK				;Data=data PreLoad
; decrunching with overlap, source after destination
 TAB 5460,_decrunch6_crm1_g	;OK				;Data=data PreLoad
 TAB 5461,_decrunch6_crm1s_g	;OK				;Data=data PreLoad
 TAB 5462,_decrunch6_crm2_g	;OK				;Data=data PreLoad
 TAB 5463,_decrunch6_crm2s_g	;OK				;Data=data PreLoad
 TAB 5465,_decrunch6_rnc1_g	;OK				;Data=data PreLoad
 TAB 5466,_decrunch6_rnc2_g	;OK				;Data=data PreLoad
 TAB 5467,_decrunch6_rnc1o	;OK				;Data=data PreLoad
 TAB 5468,_decrunch6_tpwm	;OK				;Data=data PreLoad
; decrunching inplace (src=dest) align=long
 TAB 5500,_decrunch0_crm1_b	;OK				;Data=data PreLoad
 TAB 5501,_decrunch0_crm1s_b	;OK				;Data=data PreLoad
 TAB 5502,_decrunch0_crm2_b	;OK				;Data=data PreLoad
 TAB 5503,_decrunch0_crm2s_b	;OK				;Data=data PreLoad
 TAB 5504,_decrunch0_im_b	;OK				;Data=data PreLoad
 TAB 5505,_decrunch0_rnc1_b	;OK				;Data=data PreLoad
 TAB 5506,_decrunch0_rnc2_b	;OK				;Data=data PreLoad
; decrunching inplace (src=dest) align=long+1
 TAB 5514,_decrunch1_im_b	;OK				;Data=data PreLoad
 TAB 5515,_decrunch1_rnc1_b	;OK				;Data=data PreLoad
 TAB 5516,_decrunch1_rnc2_b	;OK				;Data=data PreLoad
; decrunching inplace (src=dest) align=long+2
 TAB 5520,_decrunch2_crm1_b	;OK				;Data=data PreLoad
 TAB 5521,_decrunch2_crm1s_b	;OK				;Data=data PreLoad
 TAB 5522,_decrunch2_crm2_b	;OK				;Data=data PreLoad
 TAB 5523,_decrunch2_crm2s_b	;OK				;Data=data PreLoad
 TAB 5524,_decrunch2_im_b	;OK				;Data=data PreLoad
 TAB 5525,_decrunch2_rnc1_b	;OK				;Data=data PreLoad
 TAB 5526,_decrunch2_rnc2_b	;OK				;Data=data PreLoad
; decrunching inplace (src=dest) align=long+3
 TAB 5534,_decrunch3_im_b	;OK				;Data=data PreLoad
 TAB 5535,_decrunch3_rnc1_b	;OK				;Data=data PreLoad
 TAB 5536,_decrunch3_rnc2_b	;OK				;Data=data PreLoad
; decrunching without overlap
 TAB 5540,_decrunch4_crm1_b	;OK				;Data=data PreLoad
 TAB 5541,_decrunch4_crm1s_b	;OK				;Data=data PreLoad
 TAB 5542,_decrunch4_crm2_b	;OK				;Data=data PreLoad
 TAB 5543,_decrunch4_crm2s_b	;OK				;Data=data PreLoad
 TAB 5544,_decrunch4_im_b	;OK				;Data=data PreLoad
 TAB 5545,_decrunch4_rnc1_b	;OK				;Data=data PreLoad
 TAB 5546,_decrunch4_rnc2_b	;OK				;Data=data PreLoad
; decrunching with overlap, destination after source
 TAB 5550,_decrunch5_crm1_b	;OK				;Data=data PreLoad
 TAB 5551,_decrunch5_crm1s_b	;OK				;Data=data PreLoad
 TAB 5552,_decrunch5_crm2_b	;OK				;Data=data PreLoad
 TAB 5553,_decrunch5_crm2s_b	;OK				;Data=data PreLoad
 TAB 5554,_decrunch5_im_b	;OK				;Data=data PreLoad
 TAB 5555,_decrunch5_rnc1_b	;OK				;Data=data PreLoad
 TAB 5556,_decrunch5_rnc2_b	;OK				;Data=data PreLoad
; decrunching with overlap, source after destination
 TAB 5560,_decrunch6_crm1_b	;OK				;Data=data PreLoad
 TAB 5561,_decrunch6_crm1s_b	;OK				;Data=data PreLoad
 TAB 5562,_decrunch6_crm2_b	;OK				;Data=data PreLoad
 TAB 5563,_decrunch6_crm2s_b	;OK				;Data=data PreLoad
 TAB 5565,_decrunch6_rnc1_b	;OK				;Data=data PreLoad
 TAB 5566,_decrunch6_rnc2_b	;OK				;Data=data PreLoad
 TAB 5600,_savefile0		;OK				;Data=data PreLoad
 TAB 5610,_savefileoffset0	;OK				;Data=data PreLoad
 TAB 5700,_filecache0		;DOSWRITE,#223			;Data=data
 TAB 5701,_filecache0		;OK				;Data=data PreLoad SavePath=T:
 TAB 5710,_filecache1		;FCFLUSH,#222			;Data=data PreLoad
 TAB 5711,_filecache1		;OK				;Data=data PreLoad SavePath=T: SaveDir=NewSav
 TAB 5720,_filecache2		;DELETEFILE,#222		;Data=data
 TAB 5721,_filecache2		;FCFLUSH,#222			;Data=data PreLoad
 TAB 5722,_filecache2		;FCFLUSH,#205			;Data=data PreLoad SavePath=T:
 TAB 5723,_filecache2		;OK				;Data=data PreLoad SavePath=T: SaveDir=NewDel
 TDC 5724,_filecache2		;DELETEFILE,#222		;Data=data
 TDC 5725,_filecache2		;FCFLUSH,#222			;Data=data PreLoad
 TDC 5726,_filecache2		;DELETEFILE,#222		;Data=data PreLoad NoWriteCache
 TDC 5730,_filecache3		;OK				;Data=data
 TAB 5731,_filecache3		;OK				;Data=data
 TAB 5732,_filecache3		;OK				;Data=data PreLoad
 TDC 5740,_filecache4		;DOSREAD,#212			;Data=data
 TAB 5741,_filecache4		;DOSREAD,#212			;Data=data
 TAB 5742,_filecache4		;OK				;Data=data PreLoad
 TDC 5750,_filecache5		;OK				;Data=data
 TAB 5751,_filecache5		;OK				;Data=data
 TAB 5752,_filecache5		;OK				;Data=data PreLoad
 TDC 5760,_filecache6		;DELETEFILE,#216		;Data=data
 TAB 5761,_filecache6		;DELETEFILE,#212		;Data=data

		dc.l	0	;end

;======================================================================
;		111111
;		5432109876543210
; bltcon0	SSSSABCDMMMMMMMM S = shift for channel A
;				 ABCD = enable for dma channel ABCD
;				 M = miniterm
; bltcon1	SSSS       EICDL E = exclusive fill enable
;				 I = inclusive fill enable
;				 C = fill carry in
;				 D = descending mode
;				 L = line mode
; bltsize	HHHHHHHHHHWWWWWW height = 1..1024 lines
;				 width = 1..64 words

_bltsiz_0	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
	IFEQ 1
	;testing to see how blitter works
		move.w	#%0000000100000000,(bltcon0,a6)	;only DMA-D
		move.w	#%0000000000000000,(bltcon1,a6)	;ascending
		move.w	#10,(bltdmod,a6)		;mod > -wid
		move.l	#$1000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-6,(bltdmod,a6)		;mod = -wid
		move.l	#$2000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-22,(bltdmod,a6)		;mod < -wid
		move.l	#$3000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#%0000000000000010,(bltcon1,a6)	;descending
		move.w	#10,(bltdmod,a6)		;mod > -wid
		move.l	#$4000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-6,(bltdmod,a6)		;mod = -wid
		move.l	#$5000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-22,(bltdmod,a6)		;mod < -wid
		move.l	#$6000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		bra	_debug
	ENDC
		move.w	#%0000111100000000,(bltcon0,a6)	;all channels
	;ascending
		move.w	#%0000000000000000,(bltcon1,a6)
	;ascending, modulo > -width, lower bound
		move.w	#10,(bltcmod,a6)
		move.w	#10,(bltbmod,a6)
		move.w	#10,(bltamod,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#0,(bltcpt,a6)
		move.l	#0,(bltbpt,a6)
		move.l	#0,(bltapt,a6)
		move.l	#0,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#11,(bltcmod,a6)
		move.w	#11,(bltbmod,a6)
		move.w	#11,(bltamod,a6)
		move.w	#11,(bltdmod,a6)
		move.l	#1,(bltcpt,a6)
		move.l	#1,(bltbpt,a6)
		move.l	#1,(bltapt,a6)
		move.l	#1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;ascending, modulo > -width, upper bound
		move.w	#10,(bltcmod,a6)
		move.w	#10,(bltbmod,a6)
		move.w	#10,(bltamod,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#BASEMEM-$30+10,(bltcpt,a6)
		move.l	#BASEMEM-$30+10,(bltbpt,a6)
		move.l	#BASEMEM-$30+10,(bltapt,a6)
		move.l	#BASEMEM-$30+10,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#11,(bltcmod,a6)
		move.w	#11,(bltbmod,a6)
		move.w	#11,(bltamod,a6)
		move.w	#11,(bltdmod,a6)
		move.l	#BASEMEM-$30+11,(bltcpt,a6)
		move.l	#BASEMEM-$30+11,(bltbpt,a6)
		move.l	#BASEMEM-$30+11,(bltapt,a6)
		move.l	#BASEMEM-$30+11,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;ascending, modulo == -width, lower bound
		move.w	#-6,(bltcmod,a6)
		move.w	#-6,(bltbmod,a6)
		move.w	#-6,(bltamod,a6)
		move.w	#-6,(bltdmod,a6)
		move.l	#0,(bltcpt,a6)
		move.l	#0,(bltbpt,a6)
		move.l	#0,(bltapt,a6)
		move.l	#0,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-6!1,(bltcmod,a6)
		move.w	#-6!1,(bltbmod,a6)
		move.w	#-6!1,(bltamod,a6)
		move.w	#-6!1,(bltdmod,a6)
		move.l	#1,(bltcpt,a6)
		move.l	#1,(bltbpt,a6)
		move.l	#1,(bltapt,a6)
		move.l	#1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;ascending, modulo == -width, upper bound
		move.w	#-6,(bltcmod,a6)
		move.w	#-6,(bltbmod,a6)
		move.w	#-6,(bltamod,a6)
		move.w	#-6,(bltdmod,a6)
		move.l	#BASEMEM-6,(bltcpt,a6)
		move.l	#BASEMEM-6,(bltbpt,a6)
		move.l	#BASEMEM-6,(bltapt,a6)
		move.l	#BASEMEM-6,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-6!1,(bltcmod,a6)
		move.w	#-6!1,(bltbmod,a6)
		move.w	#-6!1,(bltamod,a6)
		move.w	#-6!1,(bltdmod,a6)
		move.l	#BASEMEM-6!1,(bltcpt,a6)
		move.l	#BASEMEM-6!1,(bltbpt,a6)
		move.l	#BASEMEM-6!1,(bltapt,a6)
		move.l	#BASEMEM-6!1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;ascending, modulo < -width, lower bound
		move.w	#-16-6,(bltcmod,a6)
		move.w	#-16-6,(bltbmod,a6)
		move.w	#-16-6,(bltamod,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$20,(bltcpt,a6)
		move.l	#$20,(bltbpt,a6)
		move.l	#$20,(bltapt,a6)
		move.l	#$20,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-16-6!1,(bltcmod,a6)
		move.w	#-16-6!1,(bltbmod,a6)
		move.w	#-16-6!1,(bltamod,a6)
		move.w	#-16-6!1,(bltdmod,a6)
		move.l	#$21,(bltcpt,a6)
		move.l	#$21,(bltbpt,a6)
		move.l	#$21,(bltapt,a6)
		move.l	#$21,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;ascending, modulo < -width, upper bound
		move.w	#-16-6,(bltcmod,a6)
		move.w	#-16-6,(bltbmod,a6)
		move.w	#-16-6,(bltamod,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#BASEMEM-6,(bltcpt,a6)
		move.l	#BASEMEM-6,(bltbpt,a6)
		move.l	#BASEMEM-6,(bltapt,a6)
		move.l	#BASEMEM-6,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-16-6!1,(bltcmod,a6)
		move.w	#-16-6!1,(bltbmod,a6)
		move.w	#-16-6!1,(bltamod,a6)
		move.w	#-16-6!1,(bltdmod,a6)
		move.l	#BASEMEM-6!1,(bltcpt,a6)
		move.l	#BASEMEM-6!1,(bltbpt,a6)
		move.l	#BASEMEM-6!1,(bltapt,a6)
		move.l	#BASEMEM-6!1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;descending
		move.w	#%0000000000000010,(bltcon1,a6)
	;descending, modulo > -width, lower bound
		move.w	#10,(bltcmod,a6)
		move.w	#10,(bltbmod,a6)
		move.w	#10,(bltamod,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#$20+4,(bltcpt,a6)
		move.l	#$20+4,(bltbpt,a6)
		move.l	#$20+4,(bltapt,a6)
		move.l	#$20+4,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#11,(bltcmod,a6)
		move.w	#11,(bltbmod,a6)
		move.w	#11,(bltamod,a6)
		move.w	#11,(bltdmod,a6)
		move.l	#$20+5,(bltcpt,a6)
		move.l	#$20+5,(bltbpt,a6)
		move.l	#$20+5,(bltapt,a6)
		move.l	#$20+5,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;descending, modulo > -width, upper bound
		move.w	#10,(bltcmod,a6)
		move.w	#10,(bltbmod,a6)
		move.w	#10,(bltamod,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#BASEMEM-2,(bltcpt,a6)
		move.l	#BASEMEM-2,(bltbpt,a6)
		move.l	#BASEMEM-2,(bltapt,a6)
		move.l	#BASEMEM-2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#11,(bltcmod,a6)
		move.w	#11,(bltbmod,a6)
		move.w	#11,(bltamod,a6)
		move.w	#11,(bltdmod,a6)
		move.l	#BASEMEM-1,(bltcpt,a6)
		move.l	#BASEMEM-1,(bltbpt,a6)
		move.l	#BASEMEM-1,(bltapt,a6)
		move.l	#BASEMEM-1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;descending, modulo == -width, lower bound
		move.w	#-6,(bltcmod,a6)
		move.w	#-6,(bltbmod,a6)
		move.w	#-6,(bltamod,a6)
		move.w	#-6,(bltdmod,a6)
		move.l	#4,(bltcpt,a6)
		move.l	#4,(bltbpt,a6)
		move.l	#4,(bltapt,a6)
		move.l	#4,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-6!1,(bltcmod,a6)
		move.w	#-6!1,(bltbmod,a6)
		move.w	#-6!1,(bltamod,a6)
		move.w	#-6!1,(bltdmod,a6)
		move.l	#5,(bltcpt,a6)
		move.l	#5,(bltbpt,a6)
		move.l	#5,(bltapt,a6)
		move.l	#5,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;descending, modulo == -width, upper bound
		move.w	#-6,(bltcmod,a6)
		move.w	#-6,(bltbmod,a6)
		move.w	#-6,(bltamod,a6)
		move.w	#-6,(bltdmod,a6)
		move.l	#BASEMEM-2,(bltcpt,a6)
		move.l	#BASEMEM-2,(bltbpt,a6)
		move.l	#BASEMEM-2,(bltapt,a6)
		move.l	#BASEMEM-2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-6!1,(bltcmod,a6)
		move.w	#-6!1,(bltbmod,a6)
		move.w	#-6!1,(bltamod,a6)
		move.w	#-6!1,(bltdmod,a6)
		move.l	#BASEMEM-2!1,(bltcpt,a6)
		move.l	#BASEMEM-2!1,(bltbpt,a6)
		move.l	#BASEMEM-2!1,(bltapt,a6)
		move.l	#BASEMEM-2!1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;descending, modulo < -width, lower bound
		move.w	#-16-6,(bltcmod,a6)
		move.w	#-16-6,(bltbmod,a6)
		move.w	#-16-6,(bltamod,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#4,(bltcpt,a6)
		move.l	#4,(bltbpt,a6)
		move.l	#4,(bltapt,a6)
		move.l	#4,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-16-6!1,(bltcmod,a6)
		move.w	#-16-6!1,(bltbmod,a6)
		move.w	#-16-6!1,(bltamod,a6)
		move.w	#-16-6!1,(bltdmod,a6)
		move.l	#5,(bltcpt,a6)
		move.l	#5,(bltbpt,a6)
		move.l	#5,(bltapt,a6)
		move.l	#5,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
	;descending, modulo < -width, upper bound
		move.w	#-16-6,(bltcmod,a6)
		move.w	#-16-6,(bltbmod,a6)
		move.w	#-16-6,(bltamod,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#BASEMEM-$20-2,(bltcpt,a6)
		move.l	#BASEMEM-$20-2,(bltbpt,a6)
		move.l	#BASEMEM-$20-2,(bltapt,a6)
		move.l	#BASEMEM-$20-2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		move.w	#-16-6!1,(bltcmod,a6)
		move.w	#-16-6!1,(bltbmod,a6)
		move.w	#-16-6!1,(bltamod,a6)
		move.w	#-16-6!1,(bltdmod,a6)
		move.l	#BASEMEM-$20-2!1,(bltcpt,a6)
		move.l	#BASEMEM-$20-2!1,(bltbpt,a6)
		move.l	#BASEMEM-$20-2!1,(bltapt,a6)
		move.l	#BASEMEM-$20-2!1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw
		rts

	;ascending, modulo > -width, lower bound
_bltsiz_1a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltamod,a6)
		move.l	#-1,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo > -width, upper bound
_bltsiz_2a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltamod,a6)
		move.l	#BASEMEM-$30+10+2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo == -width, lower bound
_bltsiz_3a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-6,(bltamod,a6)
		move.l	#-1,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo == -width, upper bound
_bltsiz_4a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-6,(bltamod,a6)
		move.l	#BASEMEM-6+2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo < -width, lower bound
_bltsiz_5a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-16-6,(bltamod,a6)
		move.l	#$20-2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo < -width, upper bound
_bltsiz_6a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-16-6,(bltamod,a6)
		move.l	#BASEMEM-6+2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo > -width, lower bound
_bltsiz_7a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltamod,a6)
		move.l	#$20+4-2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo > -width, upper bound
_bltsiz_8a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltamod,a6)
		move.l	#BASEMEM-2+2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo == -width, lower bound
_bltsiz_9a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-6,(bltamod,a6)
		move.l	#4-2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo == -width, upper bound
_bltsiz_10a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-6,(bltamod,a6)
		move.l	#BASEMEM-2+2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo < -width, lower bound
_bltsiz_11a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltamod,a6)
		move.l	#4-2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo < -width, upper bound
_bltsiz_12a	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000100011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltamod,a6)
		move.l	#BASEMEM-$20-2+2,(bltapt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts

	;ascending, modulo > -width, lower bound
_bltsiz_1b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltbmod,a6)
		move.l	#-1,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo > -width, upper bound
_bltsiz_2b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltbmod,a6)
		move.l	#BASEMEM-$30+10+2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo == -width, lower bound
_bltsiz_3b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-6,(bltbmod,a6)
		move.l	#-1,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo == -width, upper bound
_bltsiz_4b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-6,(bltbmod,a6)
		move.l	#BASEMEM-6+2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo < -width, lower bound
_bltsiz_5b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-16-6,(bltbmod,a6)
		move.l	#$20-2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo < -width, upper bound
_bltsiz_6b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-16-6,(bltbmod,a6)
		move.l	#BASEMEM-6+2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo > -width, lower bound
_bltsiz_7b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltbmod,a6)
		move.l	#$20+4-2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo > -width, upper bound
_bltsiz_8b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltbmod,a6)
		move.l	#BASEMEM-2+2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo == -width, lower bound
_bltsiz_9b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-6,(bltbmod,a6)
		move.l	#4-2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo == -width, upper bound
_bltsiz_10b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-6,(bltbmod,a6)
		move.l	#BASEMEM-2+2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo < -width, lower bound
_bltsiz_11b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltbmod,a6)
		move.l	#4-2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo < -width, upper bound
_bltsiz_12b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000010011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltbmod,a6)
		move.l	#BASEMEM-$20-2+2,(bltbpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts

	;ascending, modulo > -width, lower bound
_bltsiz_1c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltcmod,a6)
		move.l	#-1,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo > -width, upper bound
_bltsiz_2c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltcmod,a6)
		move.l	#BASEMEM-$30+10+2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo == -width, lower bound
_bltsiz_3c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-6,(bltcmod,a6)
		move.l	#-1,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo == -width, upper bound
_bltsiz_4c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-6,(bltcmod,a6)
		move.l	#BASEMEM-6+2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo < -width, lower bound
_bltsiz_5c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-16-6,(bltcmod,a6)
		move.l	#$20-2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo < -width, upper bound
_bltsiz_6c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-16-6,(bltcmod,a6)
		move.l	#BASEMEM-6+2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo > -width, lower bound
_bltsiz_7c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltcmod,a6)
		move.l	#$20+4-2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo > -width, upper bound
_bltsiz_8c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltcmod,a6)
		move.l	#BASEMEM-2+2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo == -width, lower bound
_bltsiz_9c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-6,(bltcmod,a6)
		move.l	#4-2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo == -width, upper bound
_bltsiz_10c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-6,(bltcmod,a6)
		move.l	#BASEMEM-2+2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo < -width, lower bound
_bltsiz_11c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltcmod,a6)
		move.l	#4-2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo < -width, upper bound
_bltsiz_12c	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000001011111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltcmod,a6)
		move.l	#BASEMEM-$20-2+2,(bltcpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts

	;ascending, modulo > -width, lower bound
_bltsiz_1d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#-1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo > -width, upper bound
_bltsiz_2d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#BASEMEM-$30+10+2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo == -width, lower bound
_bltsiz_3d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-6,(bltdmod,a6)
		move.l	#-1,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo == -width, upper bound
_bltsiz_4d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-6,(bltdmod,a6)
		move.l	#BASEMEM-6+2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo < -width, lower bound
_bltsiz_5d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$20-2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;ascending, modulo < -width, upper bound
_bltsiz_6d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#BASEMEM-6+2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo > -width, lower bound
_bltsiz_7d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#$20+4-2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo > -width, upper bound
_bltsiz_8d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#BASEMEM-2+2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo == -width, lower bound
_bltsiz_9d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-6,(bltdmod,a6)
		move.l	#4-2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo == -width, upper bound
_bltsiz_10d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-6,(bltdmod,a6)
		move.l	#BASEMEM-2+2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo < -width, lower bound
_bltsiz_11d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#4-2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts
	;descending, modulo < -width, upper bound
_bltsiz_12d	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#BASEMEM-$20-2+2,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		rts

	;ascending, modulo > -width, lower bound
_bltsizprot_0	lea	.1,a3
		bra	_bltsizprot_ok
.1		move.w	#2*64+3,(bltsize,a6)		;2 lines, 3 words
		rts
_bltsizprot_1	lea	.1,a3
		bra	_bltsizprot_ok
.1		move.l	#$11000000+2*64+3,(bltdpt+2,a6)	;2 lines, 3 words
		rts
_bltsizprot_2	lea	.1,a3
		bra	_bltsizprot_ok
.1		move.w	#$1100,d0
		move.w	#2*64+3,d1
		move.l	(a7)+,a0
		bsr	_savreg
		movem.w	d0-d1,(bltdpt+2,a6)		;2 lines, 3 words
		jmp	(a0)
_bltsizprot_3	lea	.1,a3
		bra	_bltsizprot_ok
.1		move.w	#3,(bltsizv,a6)
		move.w	#2,(bltsizh,a6)
		rts
_bltsizprot_4	lea	.1,a3
		bra	_bltsizprot_ok
.1		move.l	#$30002,(bltsizv,a6)
		rts
_bltsizprot_5	lea	.1,a3
		bra	_bltsizprot_ok
.1		move.w	#3,d0
		move.w	#2,d1
		move.l	(a7)+,a0
		bsr	_savreg
		movem.w	d0-d1,(bltsizv,a6)		;2 lines, 3 words
		jmp	(a0)

_bltsizprot_ok	lea	$1100-4,a2
		moveq	#4,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		move.l	#16+6,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#$1100,(bltdpt,a6)
		bsr	_savreg
		jsr	(a3)
		bsr	_chkreg
		rts

	;fail lower bound
_bltsizprot_20	bsr	_bltsizprot_fl
		move.w	#2*64+3,(bltsize,a6)		;2 lines, 3 words
		rts
_bltsizprot_21	bsr	_bltsizprot_fl
		move.l	#$10fe0000+2*64+3,(bltdpt+2,a6)	;2 lines, 3 words
		rts
_bltsizprot_22	bsr	_bltsizprot_fl
		move.w	#$1100-2,d0
		move.w	#2*64+3,d1
		movem.w	d0-d1,(bltdpt+2,a6)		;2 lines, 3 words
		rts
_bltsizprot_23	bsr	_bltsizprot_fl
		move.w	#3,(bltsizv,a6)
		move.w	#2,(bltsizh,a6)
		rts
_bltsizprot_24	bsr	_bltsizprot_fl
		move.l	#$30002,(bltsizv,a6)
		rts
_bltsizprot_25	bsr	_bltsizprot_fl
		move.w	#3,d0
		move.w	#2,d1
		movem.w	d0-d1,(bltsizv,a6)		;2 lines, 3 words
		rts

_bltsizprot_fl	lea	$1100-4,a2
		moveq	#4,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		move.l	#16+6,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#$1100-2,(bltdpt,a6)
		rts

	;fail upper bound
_bltsizprot_40	bsr	_bltsizprot_fu
		move.w	#2*64+3,(bltsize,a6)		;2 lines, 3 words
		rts
_bltsizprot_41	bsr	_bltsizprot_fu
		move.l	#$11020000+2*64+3,(bltdpt+2,a6)	;2 lines, 3 words
		rts
_bltsizprot_42	bsr	_bltsizprot_fu
		move.w	#$1100+2,d0
		move.w	#2*64+3,d1
		movem.w	d0-d1,(bltdpt+2,a6)		;2 lines, 3 words
		rts
_bltsizprot_43	bsr	_bltsizprot_fu
		move.w	#3,(bltsizv,a6)
		move.w	#2,(bltsizh,a6)
		rts
_bltsizprot_44	bsr	_bltsizprot_fu
		move.l	#$30002,(bltsizv,a6)
		rts
_bltsizprot_45	bsr	_bltsizprot_fu
		move.w	#3,d0
		move.w	#2,d1
		movem.w	d0-d1,(bltsizv,a6)		;2 lines, 3 words
		rts

_bltsizprot_fu	lea	$1100-4,a2
		moveq	#4,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		move.l	#16+6,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#$1100+2,(bltdpt,a6)
		rts

	;descending, modulo > -width, lower bound
_bltsizprot_d0	lea	$1100-4,a2
		moveq	#4,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		move.l	#16+6,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#$1100+16+4,(bltdpt,a6)
		bsr	_savreg
		move.w	#2*64+3,(bltsize,a6)		;2 lines, 3 words
		bsr	_chkreg
		rts
_bltsizprot_d1	lea	$1100-4,a2
		moveq	#4,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		move.l	#16+6,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#$1100+16+4-2,(bltdpt,a6)
		bsr	_savreg
		move.w	#2*64+3,(bltsize,a6)		;2 lines, 3 words
		bsr	_chkreg
		rts
_bltsizprot_d2	lea	$1100-4,a2
		moveq	#4,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		move.l	#16+6,d0
		move.l	a2,a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#10,(bltdmod,a6)
		move.l	#$1100+16+4+2,(bltdpt,a6)
		bsr	_savreg
		move.w	#2*64+3,(bltsize,a6)		;2 lines, 3 words
		bsr	_chkreg
		rts

;======================================================================
;		111111
;		5432109876543210
; bltcon0	SSSSABCDMMMMMMMM S = start point in the first word
;				 ABCD = enable for dma channel ABCD = 1011
;				 M = miniterm, usually $CA
; bltcon1	SSSS     G OOOSL S = mask shift, usually same as bltcon0
;				 G = sign, 1 if 2*smalldelta<bigdelta
;				 OOO = octant
;				 S = single point line mode
;				 L = line mode = 1
; bltsize	HHHHHHHHHHWWWWWW height = 1..1024 lines
;				 width = 1..64 words, always 2

_bltline_init	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000101111001010,(bltcon0,a6)
		move.w	#%0000000000000001,(bltcon1,a6)
		move.w	#10,(bltapt+2,a6)
		move.w	#10,(bltamod,a6)
		move.w	#10,(bltbmod,a6)
		move.w	#0,(bltcmod,a6)
		move.w	#0,(bltdmod,a6)
		move.w	#$8000,(bltadat,a6)
		move.w	#$ffff,(bltbdat,a6)
		move.w	#$ffff,(bltafwm,a6)
		move.l	#$1000,(bltdpt,a6)
		move.l	#$1000,(bltcpt,a6)
		rts

_bltline_0	bsr	_bltline_init
_bltline_do	bsr	_savreg
		move.w	#32*64+2,(bltsize,a6)
		bsr	_chkreg
		rts

_bltline_1	bsr	_bltline_init
		bsr	_savreg
		move.w	#32*64+4,(bltsize,a6)
		bsr	_chkreg
		rts

_bltline_2	bsr	_bltline_init
		move.l	#BASEMEM+2,(bltdpt,a6)
		bra	_bltline_do

_bltline_3	bsr	_bltline_init
		move.l	#$1100,(bltcpt,a6)
		bra	_bltline_do

_bltline_4	bsr	_bltline_init
		move.w	#$ffff,(bltadat,a6)
		bra	_bltline_do

_bltline_5	bsr	_bltline_init
		move.w	#$1100,(bltcon0,a6)
		bra	_bltline_do

_bltline_6	bsr	_bltline_init
		move.w	#%0000010000000001,(bltcon1,a6)
		bra	_bltline_do

;======================================================================

_bltwait_11t	clr.l	-(a7)
		pea	-1
		pea	WHDLTAG_CHKBLTWAIT
		move.l	a7,a0
		jsr	(resload_Control,a4)
		add.w	#12,a7
		bra	_bltwait_11

_bltsizprot_21t	clr.l	-(a7)
		pea	-1
		pea	WHDLTAG_CHKBLTSIZE
		move.l	a7,a0
		jsr	(resload_Control,a4)
		add.w	#12,a7
		bra	_bltsizprot_21

_bltwait_16t	clr.l	-(a7)
		pea	-1
		pea	WHDLTAG_CHKBLTWAIT
		pea	-1
		pea	WHDLTAG_CHKBLTSIZE
		move.l	a7,a0
		jsr	(resload_Control,a4)
		add.w	#20,a7
		bra	_bltwait_16

;======================================================================

_bltwait_0b	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		bsr	_bw				;performs a byte read
		sf	(bltcon0l,a6)
		rts
_bltwait_0w	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		tst.w	(dmaconr,a6)			;word read
		sf	(bltcon0l,a6)
		rts
_bltwait_1	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		sf	(bltcon0l,a6)
		rts

_bltwait_3	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.w	#3*64+3,(bltsize,a6)		;3 lines, 3 words
		move.w	#0,(bltafwm,a6)
		rts
_bltwait_4	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.w	#$0000,(bltdpt,a6)
		move.l	#$10000000+3*64+3,(bltdpt+2,a6)	;3 lines, 3 words
		move.w	#0,(bltafwm,a6)
		rts
_bltwait_5	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.w	#0,d0
		move.w	#$1000,d1
		move.w	#3*64+3,d2
		movem.w	d0-d2,(bltdpt,a6)
		move.w	#0,(bltafwm,a6)
		rts
_bltwait_6	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#0,d0
		move.l	#$10000000+3*64+3,d1
		movem.l	d0-d1,(bltapt+2,a6)
		move.w	#0,(bltafwm,a6)
		rts

_bltwait_7	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.w	#0,d0
		move.w	#$1000,d1
		move.w	#3*64+3,d2
		movem.w	d0-d3,(bltdpt,a6)
		move.w	#0,(bltafwm,a6)
		rts
_bltwait_8	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,d0
		move.l	#(3*64+3)<<16,d1
		movem.l	d0-d1,(bltdpt,a6)
		move.w	#0,(bltafwm,a6)
		rts

_bltwait_9	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.w	#3,(bltsizv,a6)
		move.w	#3,(bltsizh,a6)
		move.w	#0,(bltafwm,a6)
		rts
_bltwait_10	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.l	#$30003,(bltsizv,a6)
		move.w	#0,(bltafwm,a6)
		rts
_bltwait_11	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.w	#3,d0
		move.w	d0,d1
		movem.w	d0-d1,(bltsizv,a6)
		move.w	#0,(bltafwm,a6)
		rts

_bltwait_15	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		moveq	#0,d0
		move.w	#3,d1
		move.w	d1,d2
		movem.w	d0-d2,(bltsize+2,a6)
		move.w	#0,(bltafwm,a6)
		rts
_bltwait_16	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.l	#(3*64+3)<<16,d0
		move.l	#$30003,d1
		movem.l	d0-d1,(bltsize,a6)
		move.w	#0,(bltafwm,a6)
		rts

;======================================================================

_copcon_0	st	(copcon+1,a6)		;a bit senseless because byte
						;access is anyway prohibited
		rts
_copcon_1	move.w	#-1,(copcon,a6)
		rts
_copcon_2	move.l	#-1,(copcon-2,a6)
		rts
_copcon_3	move.l	#-1,(copcon,a6)
		rts
_copcon_4	move.w	#-1,(copcon,a6)
		move.l	#-1,(copcon-2,a6)
		move.l	#-1,(copcon,a6)
		rts

;======================================================================

_cia_1		bsr	_savreg
		bchg	#CIAB_LED,_ciaa+ciapra
		bsr	_chkreg
		rts
_cia_2		bclr	#CIAB_OVERLAY,_ciaa+ciapra
		rts
_cia_3		bset	#CIAB_OVERLAY,_ciaa+ciapra
		rts
_cia_4		bclr	#CIAB_DSKRDY,_ciaa+ciaddra
		rts
_cia_5		bset	#CIAB_DSKRDY,_ciaa+ciaddra
		rts
_cia_6		bset	#CIACRBB_ALARM,_ciaa+ciacrb
		st	_ciaa+ciatodlow
		rts
_cia_7		bclr	#CIACRBB_ALARM,_ciaa+ciacrb
		st	_ciaa+ciatodlow
		rts
_cia_8		bset	#CIACRBB_ALARM,_ciaa+ciacrb
		addq.b	#1,_ciaa+ciatodlow
		rts
_cia_9		bsr	_savreg
		st	_ciaa+ciaicr
		bsr	_chkreg
		rts
_cia_10		bsr	_savreg
		sf	_ciaa+ciaicr
		bsr	_chkreg
		rts
; if no drive is attached, it seems CIAB_DSKSEL0 is always 0 and cannot be set to 1
; (done by WHDLoad on init), this will cause this check to fail
; tested with A4000/040 at 2017-01-02)
_cia_11		bsr	_savreg
		bset	#CIAB_DSKSEL3,_ciab+ciaprb
		bsr	_chkreg
		rts
_cia_12		bsr	_savreg
		bclr	#CIAB_DSKSEL3,_ciab+ciaprb
		bsr	_chkreg
		rts
_cia_13		bset	#CIAB_COMDTR,_ciab+ciaddra
		rts
_cia_14		bclr	#CIAB_COMDTR,_ciab+ciaddra
		rts
_cia_15		bset	#CIAB_DSKSEL3,_ciab+ciaddrb
		rts
_cia_16		bclr	#CIAB_DSKSEL3,_ciab+ciaddrb
		rts
_cia_17		bsr	_savreg
		st	_ciab+ciaicr
		bsr	_chkreg
		rts
_cia_18		bsr	_savreg
		sf	_ciab+ciaicr
		bsr	_chkreg
		rts

;======================================================================

_cust_1		tst.b	(adkconr,a6)
		rts
_cust_2		tst.w	(intreqr,a6)
		rts
_cust_3		tst.l	(vposr,a6)
		rts
_cust_4		tst.l	(intreqr,a6)
		rts
_cust_5		tst.w	(bltcon0,a6)
		rts
_cust_8		clr.b	(dmaconr,a6)
		rts
_cust_9		clr.w	(dmaconr,a6)
		rts
_cust_10	clr.l	(dmaconr,a6)
		rts
_cust_14	clr.w	(fmode,a6)
		rts
_cust_16	tst.w	(deniseid,a6)
		rts
_cust_18	clr.b	(aud0+ac_vol,a6)
		rts
_cust_19	clr.b	(aud0+ac_vol+1,a6)
		rts

_cust_20	move.l	(a7)+,a0
		move	#0,sr
		bsr	_savreg
		pea	0
		move.l	(a7)+,(bltapt,a6)
		bsr	_chkreg
		jmp	(a0)
_cust_21	bsr	_savreg
		pea	0
		move.l	(a7)+,(bltapt,a6)
		bsr	_chkreg
		rts

_cust_22	move.l	#0,(aud0+ac_ptr,a6)
		rts
_cust_23	move.l	#BASEMEM,(aud0+ac_ptr,a6)
		rts

_cust_25	move.w	#0,(bplcon0,a6)
		rts
_cust_26	move.w	#1,(bplcon0,a6)
		rts
_cust_27	move.l	#$10000,(bplcon0,a6)
		rts
_cust_28	move.w	#$8000,(bplcon2,a6)
		rts
_cust_29	move.l	#$8000,(bplcon1,a6)
		rts

_cust_34	move.w	#DMAF_SETCLR|DMAF_BLITHOG,(dmacon,a6)
		rts

_cust_36	move.w	#1,(copcon,a6)
		rts
_cust_37	move.l	#1,(copcon-2,a6)
		rts
_cust_38	move.l	#$10000,(copcon,a6)
		rts

_cust_42	move.w	#3,(bltsizv,a6)
		rts
_cust_46	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.w	#3,(bltsizh,a6)
		rts
_cust_47	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.l	#(3*64+3)<<16,(bltsize,a6)		;3 lines, 3 words
		rts
_cust_48	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000010,(bltcon1,a6)
		move.w	#-16-6,(bltdmod,a6)
		move.l	#$1000,(bltdpt,a6)
		move.w	#3,(bltsizv,a6)
		move.l	#3<<16,(bltsizh,a6)
		rts

_cust_60	move.l	#BASEMEM-2,d0
		move.l	d0,(bplpt,a6)
		move.w	d0,(bplpt+6,a6)
		swap	d0
		move.w	d0,(bplpt+4,a6)
		rts
_cust_612	move.l	#BASEMEM,(bplpt,a6)
		rts
_cust_634	move.l	#BASEMEM,(bplpt+7*4,a6)
		rts
_cust_65	move.l	#BASEMEM,d0
		move.w	d0,(bplpt+6,a6)
		swap	d0
		move.w	d0,(bplpt+4,a6)
		rts
	;for a low word write test BASEMEM had to be not aligned to $10000
_cust_67	clr.l	(bplpt-2,a6)
		rts
_cust_68	clr.l	(bplpt+2,a6)
		rts
_cust_69	clr.l	(bplpt+2+7*4,a6)
		rts

;======================================================================

COPLC = $5000

_cop_0		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	#$00a41111,(a0)+
		move.l	#$0100ffff,(a0)+	;bplcon0
		move.l	#$0104ffff,(a0)+	;bplcon2
		move.l	#BASEMEM-1,d0
		move.w	#bplpt+2,(a0)+
		move.w	d0,(a0)+
		move.w	#bplpt,(a0)+
		swap	d0
		move.w	d0,(a0)+
		move.l	#$0082<<16+COPLC+$1000,(a0)+
		move.l	#$0088ffff,(a0)+	;copjmp1
		move.l	#$02001111,(a0)		;illegal
		lea	COPLC+$1000,a0
		move.l	#$00a41111,(a0)+
		move.l	#$0086<<16+COPLC+$2000,(a0)+
		move.l	#$008affff,(a0)+	;copjmp2
		move.l	#$02001111,(a0)		;illegal
		lea	COPLC+$2000,a0
		move.l	#$0088ffff,(a0)+	;copjmp1
		move.l	#$02001111,(a0)		;illegal
		bsr	_savreg
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		bsr	_chkreg
		rts

_cop_1		lea	BASEMEM-4,a0
		move.l	a0,(cop1lc,a6)
		move.l	#$00401111,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		rts

_cop_2		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	#$02001111,(a0)+
		move.l	#-2,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		rts

_cop_3		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	#$01000000,(a0)+	;bplcon0
		move.l	#-2,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		rts

_cop_6		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	#$01000001,(a0)+	;bplcon0
		move.l	#-2,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		rts

_cop_8		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	#$01048000,(a0)+	;bplcon2
		move.l	#-2,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		rts

_cop_10		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	#BASEMEM,d0
		move.w	#bplpt+2,(a0)+
		move.w	d0,(a0)+
		move.w	#bplpt,(a0)+
		swap	d0
		move.w	d0,(a0)+
		move.l	#-2,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		rts

_cop_12		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	#-2,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		move.l	a0,a1
		move.l	#$02001111,(a0)+
		move.l	#-2,(a0)+
		move.l	a1,(cop1lc,a6)
		rts

_cop_13		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	#-2,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		move.l	a0,a1
		move.l	#$02001111,(a0)+
		move.l	#-2,(a0)+
		move.l	a1,(cop2lc,a6)
		rts

; check activation of copperlist scanner

_cop_acs	moveq	#-2,d0
		lea	COPLC,a0
		move.l	a0,(cop1lc,a6)
		move.l	a0,(cop2lc,a6)
		move.l	d0,(a0)+
		move.w	#DMAF_SETCLR|DMAF_COPPER,(dmacon,a6)
		move.l	a0,a1		;A0 = bad.l
		clr.l	(a1)+
		lea	$10000+COPLC,a1
		move.l	a1,d1
		swap	d1		;D1 = bad.msw
		clr.l	(a1)+
		move.l	d0,(a1)+
		rts

_cop_20		bsr	_cop_acs
		move.l	a0,(cop1lc,a6)
		rts

_cop_21		bsr	_cop_acs
		move.l	a0,(cop2lc,a6)
		rts

_cop_22		bsr	_cop_acs
		move.w	a0,(cop1lc+2,a6)
		rts

_cop_23		bsr	_cop_acs
		move.w	a0,(cop2lc+2,a6)
		rts

_cop_24		bsr	_cop_acs
		move.w	d1,(cop1lc,a6)
		rts

_cop_25		bsr	_cop_acs
		move.w	d1,(cop2lc,a6)
		rts

;======================================================================

_custtag_0	;addq.w	#1,_custom+copjmp1	;no rmw on the 68060 allowed
		tst.w	_custom+copjmp1
		tst.l	_custom+copjmp1
		;tst.l	_custom+copjmp1-2	;would read cop2lcl
		clr.w	_custom+copjmp1
		clr.l	_custom+copjmp1
		;clr.l	_custom+copjmp1-2	;forbidden
		rts

_custtag_1	bsr	_custtag_dis
		tst.l	_custom+copjmp1
		rts

_custtag_2	bsr	_custtag_dis
		clr.w	_custom+copjmp1
		rts

_custtag_dis	clr.l	-(a7)
		pea	copjmp1
		pea	WHDLTAG_CUST_DISABLE
		pea	$1fe
		pea	WHDLTAG_CUST_DISABLE
		move.l	a7,a0
		jsr	(resload_Control,a4)
		add.w	#20,a7
		rts

_custtag_3	bsr	_custtag_read
		tst.w	_custom+copjmp1
		rts

_custtag_4	bsr	_custtag_read
		clr.w	_custom+copjmp1
		rts

_custtag_read	clr.l	-(a7)
		pea	copjmp1
		pea	WHDLTAG_CUST_READ
		move.l	a7,a0
		jsr	(resload_Control,a4)
		add.w	#12,a7
		rts

_custtag_5	bsr	_custtag_write
		tst.w	_custom+copjmp1
		rts

_custtag_6	bsr	_custtag_write
		clr.w	_custom+copjmp1
		rts

_custtag_write	clr.l	-(a7)
		pea	copjmp1
		pea	WHDLTAG_CUST_WRITE
		move.l	a7,a0
		jsr	(resload_Control,a4)
		add.w	#12,a7
		rts

_custtag_7	bsr	_custtag_strobe
		tst.w	_custom+$1fe
		clr.w	_custom+$1fe
		rts

_custtag_8	tst.w	_custom+$1fe
		rts

_custtag_strobe	clr.l	-(a7)
		pea	$1fe
		pea	WHDLTAG_CUST_STROBE
		move.l	a7,a0
		jsr	(resload_Control,a4)
		add.w	#12,a7
		rts

;======================================================================

_af_inst_0	jmp	$a0000000		;raise instruction stream fault

; the following verifies that instructions are valid to execute also
; on protected areas

; protecting page 0 will cause additional faults because _Super will read/write
; the trace vector at $24, already during resload_Protect

_af_inst_1	sub.l	a2,a2
		bra	_af_inst

_af_inst_2	lea	$1000,a2
		bra	_af_inst

; the handler for the 68030 combines the access on a fault to a longword
; which would be outside BASEMEM if BASEMEM-2 is used

_af_inst_330	lea	BASEMEM-4,a2
		bra	_af_inst
_af_inst_360	lea	BASEMEM-2,a2
		bra	_af_inst

_af_inst_4	move.l	_expmem,a2
		bra	_af_inst

_af_inst_5	move.l	_expmem,a2
		add.l	#$100,a2
		bra	_af_inst

_af_inst_630	move.l	_expmem,a2
		add.l	#EXPMEM-4,a2
		bra	_af_inst
_af_inst_660	move.l	_expmem,a2
		add.l	#EXPMEM-2,a2

_af_inst	move.w	#$4e75,(a2)		;rts
		jsr	(resload_FlushCache,a4)
		moveq	#2,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		bsr	_savreg
		jsr	(a2)			;must succeed
		move.w	#1,SAVREG-2
		bsr	_chkreg
		clr.w	(a2)			;must succeed
		move.w	#2,SAVREG-2
		bsr	_chkreg
		tst.w	(a2)			;must fail
		nop				;avoid confusion on 68040
		rts

_af_inst_7	lea	$1000,a2
		moveq	#2,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
	;move.l	(_afa),a1
		bsr	_savreg
	;at least 4 word registers are required to overflow
	;the write buffers of the 68040 to cause a movem fault
	;st	(a1)
		movem.w	d0-d3,(-2,a2)		;must succeed
		bsr	_chkreg
		movem.w	(-2,a2),d0-d1		;must fail
		rts

_af_inst_8	lea	$1000,a2
		moveq	#2,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		bsr	_savreg
		movem.l	d0-d1,(-4,a2)		;must succeed
		bsr	_chkreg
		movem.l	(-4,a2),d0-d1		;must fail
		rts

; the follwing faults are not detected on 68040/60 because only the first
; access of the movem is verified, and the instruction as a whole is then emulated

_af_inst_9	lea	$1100,a2
		moveq	#2,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		bsr	_savreg
		movem.w	d0-d1,(-2,a2)		;must succeed
		bsr	_chkreg
		movem.w	(-2,a2),d0-d1		;must fail
		rts

_af_inst_10	lea	$1100,a2
		moveq	#2,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		bsr	_savreg
		movem.l	d0-d1,(-4,a2)		;must succeed
		bsr	_chkreg
		movem.l	(-4,a2),d0-d1		;must fail
		rts

; every instruction on a protected page can access protected areas
; because it will run with enabled translation

_af_inst_11	lea	$f00,a2
		lea	.code,a0
		move.l	(a0)+,(a2)
		move.l	(a0)+,(4,a2)
		jsr	(resload_FlushCache,a4)
		moveq	#2,d0
		lea	($100,a2),a0
		jsr	(resload_ProtectRead,a4)
		jmp	(a2)

.code		tst.w	($100,a2)		;must fail
		rts

; invisible to the 68040/60 because will cause instruction stream fault
; and emulation of this will make the protected fault undetectable

_af_inst_12	lea	$1000,a2
		lea	.code,a0
		move.l	(a0)+,(a2)
		move.l	(a0)+,(4,a2)
		jsr	(resload_FlushCache,a4)
		moveq	#2,d0
		lea	($100,a2),a0
		jsr	(resload_ProtectRead,a4)
		jmp	(a2)

.code		tst.w	($100,a2)		;must fail
		rts

; that must give address error

_af_inst_20	jmp	1

;======================================================================

_af_30		move.l	_expmem,a0
		lea	(-1,a0),a1
		move16	(a1)+,(a0)+
		rts

_af_31_60	movec	pcr,d0
		bclr	#1,d0			;enable fpu
		movec	d0,pcr

_af_31		lea	BASEMEM-4,a0
		fmove.x	(a0),fp0
		rts

;======================================================================

_fullchip	move.w	#DMAF_SETCLR|DMAF_MASTER|DMAF_BLITTER,(dmacon,a6)
		move.w	#%0000000111111111,(bltcon0,a6)
		move.w	#%0000000000000000,(bltcon1,a6)
		move.l	a0,(bltdpt,a6)
		move.w	#1*64+1,(bltsize,a6)		;1 lines, 1 words
		rts

_fullchip_1	lea	$40002,a0
		bra	_fullchip
_fullchip_2	lea	$1ff002,a0
		bra	_fullchip
_fullchip_3	lea	$100002,a0
		bsr	_fullchip
		lea	$110002,a0
		bra	_fullchip

;======================================================================

_af_smc_ok	lea	$1000,a2
		move.w	#$4e75,(a2)		;rts
		jsr	(resload_FlushCache,a4)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectSMC,a4)
		bsr	_savreg
		jsr	(a2)
		bsr	_chkreg
		clr.l	(a2)
		bsr	_chkreg
		tst.l	(a2)
		bsr	_chkreg
		rts

_af_smc_1	lea	$1000,a2
		move.w	#$4e75,d2		;rts
		move.w	d2,(a2)+
		move.w	d2,(a2)+
		move.w	d2,(a2)
		jsr	(resload_FlushCache,a4)
		moveq	#2,d0
		lea	(-2,a2),a0
		jsr	(resload_ProtectSMC,a4)
		or.w	d2,(a2)
		or.w	d2,-(a2)
		or.w	d2,-(a2)
		jsr	(a2)
		jsr	(4,a2)
		jmp	(2,a2)

_af_smc_ba1	moveq	#4,d0
		lea	$1000,a0
		jsr	(resload_ProtectRead,a4)
		moveq	#4,d0
		lea	$1000,a0
		jmp	(resload_ProtectSMC,a4)
_af_smc_ba2	moveq	#4,d0
		lea	$1000,a0
		jsr	(resload_ProtectSMC,a4)
		moveq	#4,d0
		lea	$1000,a0
		jmp	(resload_ProtectRead,a4)

;======================================================================

AF_CBAF_ADR = $1000
AF_CBAF_FAILREGSAVE = $100

_af_cbaf_0	lea	_af_cbaf_fail,a3
		bsr	_af_cbaf_init
.inst		tst.b	(a2)
		rts

_af_cbaf_1	lea	.cbaf,a3
		bsr	_af_cbaf_init
.inst		tst.b	(a2)
		rts
.cbaf		cmp.l	#0,d0
		bne	_af_cbaf_fail
		cmp.l	#1,d1
		bne	_af_cbaf_fail
		pea	.inst
		cmp.l	(a7)+,a0
		bne	_af_cbaf_fail
		cmp.l	#AF_CBAF_ADR,a1
		bne	_af_cbaf_fail
		moveq	#-1,d0
		rts

; 68030 supports also checking the written data
; WinUAE 2.6.0ß3 reports always .inst_pre

_af_cbaf_230	lea	.cbaf,a3
		bsr	_af_cbaf_init
.inst_pre	move.w	#$9876,(a2)
.inst_post	rts
.cbaf           cmp.l	#2,d0
		bne	_af_cbaf_fail
		cmp.l	#2,d1
		bne	_af_cbaf_fail
		pea	.inst_post
		cmp.l	(a7)+,a0
		bne	_af_cbaf_fail
		cmp.l	#AF_CBAF_ADR,a1
		bne	_af_cbaf_fail
		cmp.w	#$9876,(a2)
		bne	_af_cbaf_fail
		moveq	#-1,d0
		rts

; on the 68040 the pc points to the instruction after the fault

_af_cbaf_240	lea	.cbaf,a3
		bsr	_af_cbaf_init
		move.w	#$9876,(a2)
.inst   	rts
.cbaf		cmp.l	#2,d0
		bne	_af_cbaf_fail
		cmp.l	#2,d1
		bne	_af_cbaf_fail
		pea	.inst
		cmp.l	(a7)+,a0
		bne	_af_cbaf_fail
		cmp.l	#AF_CBAF_ADR,a1
		bne	_af_cbaf_fail
		move.w	(a2),AF_CBAF_FAILREGSAVE+16*4
		cmp.w	#$9876,(a2)
		bne	_af_cbaf_fail
		moveq	#-1,d0
		rts

; on the 68060 this may depend on the store buffer enabled/disabled?

_af_cbaf_260	lea	.cbaf,a3
		bsr	_af_cbaf_init
.inst		clr.w	(a2)
		rts
.cbaf		cmp.l	#2,d0
		bne	_af_cbaf_fail
		cmp.l	#2,d1
		bne	_af_cbaf_fail
		pea	.inst
		cmp.l	(a7)+,a0
		bne	_af_cbaf_fail
		cmp.l	#AF_CBAF_ADR,a1
		bne	_af_cbaf_fail
		moveq	#-1,d0
		rts

; 68030 will get a read and a write fault
; WinUAE 2.6.0ß3 reports always .inst_pre

_af_cbaf_330	lea	.cbaf,a3
		bsr	_af_cbaf_init
.inst_pre	addq.l	#1,(a2)
.inst_post	rts
.cbaf		cmp.l	#0,d0
		beq	.read
		cmp.l	#2,d0
		bne	_af_cbaf_fail
.write		cmp.l	#4,d1
		bne	_af_cbaf_fail
		pea	.inst_post
		cmp.l	(a7)+,a0
		bne	_af_cbaf_fail
		cmp.l	#AF_CBAF_ADR,a1
		bne	_af_cbaf_fail
		cmp.l	#$40414244,(a2)
		bne	_af_cbaf_fail
		moveq	#-1,d0
		rts
.read		cmp.l	#4,d1
		bne	_af_cbaf_fail
		pea	.inst_pre
		cmp.l	(a7)+,a0
		bne	_af_cbaf_fail
		cmp.l	#AF_CBAF_ADR,a1
		bne	_af_cbaf_fail
		moveq	#-1,d0
		rts

; 68040 will only see the read, then it gets emulated

_af_cbaf_340	lea	.cbaf,a3
		bsr	_af_cbaf_init
.inst		addq.l	#1,(a2)
		rts
.cbaf		cmp.l	#0,d0
		bne	_af_cbaf_fail
		cmp.l	#4,d1
		bne	_af_cbaf_fail
		pea	.inst
		cmp.l	(a7)+,a0
		bne	_af_cbaf_fail
		cmp.l	#AF_CBAF_ADR,a1
		bne	_af_cbaf_fail
		moveq	#-1,d0
		rts

; 68060 will see the rwm

_af_cbaf_360	lea	.cbaf,a3
		bsr	_af_cbaf_init
.inst		addq.l	#1,(a2)
		rts
.cbaf		cmp.l	#1,d0
		bne	_af_cbaf_fail
		cmp.l	#4,d1
		bne	_af_cbaf_fail
		pea	.inst
		cmp.l	(a7)+,a0
		bne	_af_cbaf_fail
		cmp.l	#AF_CBAF_ADR,a1
		bne	_af_cbaf_fail
		moveq	#-1,d0
		rts

; cause cbaf to fail and save registers

_af_cbaf_fail	movem.l	d0-a7,AF_CBAF_FAILREGSAVE
		moveq	#0,d0
		rts

_af_cbaf_init	lea	AF_CBAF_ADR,a2
		move.l	#$40414243,(a2)		;test value (68030)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		clr.l	-(a7)
		pea	(a3)
		pea	WHDLTAG_CBAF_SET
		move.l	a7,a0
		jsr	(resload_Control,a4)
		add.w	#12,a7
		rts

;======================================================================

_af_prot_rlok	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		moveq	#4,d0
		lea	(8,a2),a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		tst.l	(a2)
		clr.l	(a2)
		addq.l	#1,(a2)
		rts
_af_prot_wlok	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		moveq	#4,d0
		lea	(8,a2),a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		tst.l	(a2)
		clr.l	(a2)
		addq.l	#1,(a2)
		rts
_af_prot_rwok	lea	$1100,a2
		moveq	#2,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		moveq	#2,d0
		lea	(4,a2),a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		tst.w	(a2)
		clr.w	(a2)
		addq.w	#1,(a2)
		rts
_af_prot_wwok	lea	$1100,a2
		moveq	#2,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		moveq	#2,d0
		lea	(4,a2),a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		tst.w	(a2)
		clr.w	(a2)
		addq.w	#1,(a2)
		rts
_af_prot_rbok	lea	$1100,a2
		moveq	#1,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		moveq	#1,d0
		lea	(2,a2),a0
		add.l	d0,a2
		jsr	(resload_ProtectRead,a4)
		tst.b	(a2)
		clr.b	(a2)
		addq.b	#1,(a2)
		rts
_af_prot_wbok	lea	$1100,a2
		moveq	#1,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		moveq	#1,d0
		lea	(2,a2),a0
		add.l	d0,a2
		jsr	(resload_ProtectWrite,a4)
		bsr	_savreg
		tst.b	(a2)
		clr.b	(a2)
		addq.b	#1,(a2)
		bsr	_chkreg
		rts

_af_prot_rll	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		tst.l	(-3,a2)
		rts
_af_prot_rlu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		tst.l	(3,a2)
		rts
_af_prot_wll	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		clr.l	(-3,a2)
		rts
_af_prot_wlu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		clr.l	(3,a2)
		rts
_af_prot_mll	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		addq.l	#1,(-3,a2)
		rts
_af_prot_mlu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		addq.l	#1,(3,a2)
		rts

_af_prot_rwl	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		tst.w	(-1,a2)
		rts
_af_prot_rwu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		tst.w	(3,a2)
		rts
_af_prot_wwl	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		clr.w	(-1,a2)
		rts
_af_prot_wwu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		clr.w	(3,a2)
		rts
_af_prot_mwl	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		addq.w	#1,(-1,a2)
		rts
_af_prot_mwu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		addq.w	#1,(3,a2)
		rts

_af_prot_rbl	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		tst.b	(a2)
		rts
_af_prot_rbu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		tst.b	(3,a2)
		rts
_af_prot_wbl	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		clr.b	(a2)
		rts
_af_prot_wbu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		clr.b	(3,a2)
		rts
_af_prot_mbl	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		addq.b	#1,(a2)
		rts
_af_prot_mbu	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectReadWrite,a4)
		addq.b	#1,(3,a2)
		rts

; cas/tas instruction is always treated as RWM and WriteProtection
; will cause also the read to fail, so on 68030 fault will be
; always Read

_af_prot_tas	lea	$1100,a2
		moveq	#1,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		tas	(a2)
		rts
_af_prot_cas	lea	$1100,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		cas.l	d0,d1,(a2)
		rts

; some checks for bitfield instructions to help Toni with WinUAE

_af_prot_bf1	lea	$2000,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		bftst	(a2){1:1}			;read fault
		rts

_af_prot_bf2	lea	$2000,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		bftst	(a2){1:1}			;no fault
		rts

_af_prot_bf3	lea	$2000,a2
		clr.l	(a2)
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectWrite,a4)
		bfclr	(a2){1:1}			;rwm fault
		rts

_af_prot_bf4	lea	$2000,a2
		moveq	#4,d0
		move.l	a2,a0
		jsr	(resload_ProtectRead,a4)
		bfins	d0,(a2){0:32}			;rwm fault
		rts

;======================================================================

_emul_sr	move.l	(a7)+,a0
		moveq	#-1,d0
		moveq	#-1,d1
		moveq	#-1,d2
		move	sr,d2
		move	#0,sr
		move	sr,d0
		move	sr,-(a7)
		move.w	(a7)+,d1
		jmp	(a0)

;======================================================================

_patch_ok	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_R	2
		PL_P	$10,_patch_ok
		PL_PS	$20,_patch_ok
		PL_S	$30,16
		PL_I	$40
		PL_B	$50,$bb
		PL_W	$60,$1111
		PL_L	$70,$33333333
		PL_A	$80,$800
		PL_PA	$90,_expmem
		PL_NOP	$a0,$20
		PL_PSS	$100,_patch_ok,6
		PL_NEXT	_patch_ok_p2

_patch_ok_p2	PL_START
		PL_PSS	$120,_patch_ok,2
		PL_STR	$170,<Scheisse!>
		PL_DATA	$160,.e-.a
.a		dc.b	1,2,3,4,5
.e	EVEN
		PL_AB	$130,$11
		PL_AW	$140,$1111
		PL_AL	$150,$11111111
		PL_R	$8000
		PL_S	0,-$2000		;patch_1
		PL_A	0,-$2000		;patch_2
		PL_A	0,BASEMEM-$2000		;patch_3
		PL_B	BASEMEM-$2000-1,$11	;patch_4
		PL_END

_patch_1	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_S	0,-$2002
		PL_END

_patch_2	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_A	0,-$2001
		PL_END

_patch_3	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_A	0,BASEMEM-$2000+1
		PL_END

_patch_4	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_W	BASEMEM-$2000,$11
		PL_END

_patch_5	lea	.pl+1,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		dc.l	0

_patch_6	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_ORL	$101,1
		PL_END

_patch_71	bsr	_patch_7x
		cmp.l	#$cc02cccc,(a2)+
		bne	_patch_fail
		cmp.l	#$cccccccc,(a2)+
		bne	_patch_fail
		rts
_patch_72	bsr	_patch_7x
		cmp.l	#$0b0103cc,(a2)+
		bne	_patch_fail
		cmp.l	#$0607cccc,(a2)+
		bne	_patch_fail
		rts
_patch_fail	pea	_t_patch
		bra	_failmsg
_patch_7x	lea	.pl,a0
		move.l	#$2000,a1
		move.l	a1,a2
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_IFBW
		PL_B	0,$b
		PL_ENDIF
		PL_IFC5
		PL_B	1,1
		PL_ELSE
		PL_B	1,2
		PL_ENDIF
		PL_IFC2X 0
		PL_IFC2
		PL_B	2,3
		PL_IFC2X 1
		PL_B	3,5
		PL_ENDIF
		PL_ELSE
		PL_B	2,4
		PL_IFC2X 1
		PL_B	3,9
		PL_ENDIF
		PL_ENDIF
		PL_ENDIF
		PL_IFC3
		PL_B	4,6
		PL_ENDIF
		PL_IFC4
		PL_B	5,7
		PL_ENDIF
		PL_END

_patch_9	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
	;	PL_ELSE
		dc.w	PLCMDF_CTRL+PLCMD_ELSE
		PL_END

_patch_10	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
	;	PL_ENDIF
		dc.w	PLCMDF_CTRL+PLCMD_ENDIF
		PL_END

_patch_11	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
	;	PL_IFBW
		dc.w	PLCMDF_CTRL+PLCMD_IFBW
		PL_END

_patch_12	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
	;	PL_IFBW
		dc.w	PLCMDF_CTRL+PLCMD_IFBW
		PL_NEXT	_patch_11

_patch_13	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_IFC1X 31
		PL_ENDIF
	;	PL_IFC1X 32
	;	PL_ENDIF
		dc.w	PLCMDF_CTRL+PLCMD_IFC1X,32
		dc.w	PLCMDF_CTRL+PLCMD_ENDIF
		PL_END

_patch_14	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		PL_START
		PL_IFC1X -1
		PL_ENDIF
		PL_END

_patch_ff	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_Patch,a4)

.pl		dc.w	$80ff,$1234

_patchseg_ok	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_S	0,0			;begin first hunk
		PL_S	$800,-$800		;begin first hunk
		PL_S	0,$ffe			;end first hunk
		PL_S	$1400,-$400		;begin second hunk
		PL_S	$1800,$7fe		;end second hunk
		PL_A	$800,-$800		;begin first hunk
		PL_A	0,$1000			;end first hunk
		PL_B	$1fff,$11
		PL_END

_patchseg_1	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_S	0,-2			;begin first hunk
		PL_END

_patchseg_2	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_S	$800,-$802		;begin first hunk
		PL_END

_patchseg_3	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_S	0,$1000			;end first hunk
		PL_END

_patchseg_4	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_S	$1400,-$402		;begin second hunk
		PL_END

_patchseg_5	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_S	$1800,$800		;end second hunk
		PL_END

_patchseg_6	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_A	$800,-$801		;begin first hunk
		PL_END

_patchseg_7	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_A	0,$1001			;end first hunk
		PL_END

_patchseg_8	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		PL_START
		PL_B	$2000,$11
		PL_END

_patchseg_9	lea	.pl,a0
		move.l	#$2000,a1
		jmp	(resload_PatchSeg,a4)

.pl		PL_START
		PL_W	$10,$ffff
		PL_END

_patchseg_ff	lea	.pl,a0
		bra	_patchseg_patchseg

.pl		dc.w	$80ff,$1234


; create segment containing two hunks of $1000 bytes data starting at $2000-8
; the memory of the first hunk is from $2000-$3000
; the second from $3008-$4008

_patchseg_patchseg
		lea	$2000-8,a1
		move.l	#$1008,(a1)+		;length inclusive header
		move.l	#$3004/4,(a1)+		;next segment
		add.l	#$1000,a1
		move.l	#$1008,(a1)+		;length inclusive header
		clr.l	(a1)+			;next segment
		move.l	#$1ffc/4,a1
		jmp	(resload_PatchSeg,a4)

;======================================================================

_loadoffset_0	move.l	#$100,d0		;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	0,a1			;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_1	move.l	#$100,d0		;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	BASEMEMREAL-$100,a1	;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_2	move.l	#1,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	_base,a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_3	move.l	#1,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	_end-1,a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_4	move.l	#1,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		move.l	_expmem,a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_5	move.l	#1,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		move.l	_expmem,a1
		add.l	#EXPMEM-1,a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_6	move.l	#100,d0			;size
		move.l	#1,d1			;offset
		lea	_filename_100,a0	;filename
		sub.l	#100,a7
		move.l	a7,a1			;address
		jsr	(resload_LoadFileOffset,a4)
		add.l	#100,a7
		rts

_loadoffset_7	move.l	#100,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	(-100-64,a7),a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_8	move.l	(a7)+,a6
		move	#0,sr
		move.l	#100,d0			;size
		move.l	#1,d1			;offset
		lea	_filename_100,a0	;filename
		sub.l	#100,a7
		move.l	a7,a1			;address
		jsr	(resload_LoadFileOffset,a4)
		add.l	#100,a7
		jmp	(a6)

_loadoffset_9	move.l	(a7)+,a6
		move	#0,sr
		move.l	#100,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	(-100-64-4,a7),a1	;address
		jsr	(resload_LoadFileOffset,a4)
		jmp	(a6)

_loadoffset_10	move.l	(a7)+,a6
		sub.l	#100,a7
		move.l	a7,a1			;address
		move	#0,sr
		move.l	#100,d0			;size
		move.l	#1,d1			;offset
		lea	_filename_100,a0	;filename
		jsr	(resload_LoadFileOffset,a4)
		jmp	(a6)

_loadoffset_11	move.l	(a7)+,a6
		lea	(-100-64,a7),a1		;address
		move	#0,sr
		move.l	#100,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		jsr	(resload_LoadFileOffset,a4)
		jmp	(a6)

_loadoffset_12	move.l	#0,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	0,a1			;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_20	move.l	#$100,d0		;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	-1,a1			;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_21	move.l	#$100,d0		;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	BASEMEMREAL-$100+1,a1	;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_22	move.l	#2,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	_base-1,a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_23	move.l	#2,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	_end-1,a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_24	move.l	#2,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		move.l	_expmem,a1
		sub.l	#1,a1			;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_25	move.l	#2,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		move.l	_expmem,a1
		add.l	#EXPMEM-1,a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_26	move.l	#100,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		sub.l	#100,a7
		move.l	a7,a1
		sub.l	#1,a1			;address
		jsr	(resload_LoadFileOffset,a4)
		add.l	#100,a7
		rts

_loadoffset_27	move.l	#100,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	(-100-63,a7),a1		;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_28	move.l	(a7)+,a6
		move	#0,sr
		move.l	#100,d0			;size
		move.l	#1,d1			;offset
		lea	_filename_100,a0	;filename
		sub.l	#100,a7
		move.l	a7,a1
		sub.l	#1,a1			;address
		jsr	(resload_LoadFileOffset,a4)
		add.l	#100,a7
		jmp	(a6)

_loadoffset_29	move.l	(a7)+,a6
		move	#0,sr
		move.l	#100,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	(-100-63-4,a7),a1	;address
		jsr	(resload_LoadFileOffset,a4)
		jmp	(a6)

_loadoffset_30	move.l	(a7)+,a6
		sub.l	#100,a7
		move.l	a7,a1
		sub.l	#1,a1			;address
		move	#0,sr
		move.l	#100,d0			;size
		move.l	#1,d1			;offset
		lea	_filename_100,a0	;filename
		jsr	(resload_LoadFileOffset,a4)
		jmp	(a6)

_loadoffset_31	move.l	(a7)+,a6
		lea	(-100-63,a7),a1		;address
		move	#0,sr
		move.l	#100,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		jsr	(resload_LoadFileOffset,a4)
		jmp	(a6)

_loadoffset_32	move.l	#-1,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	0,a1			;address
		jmp	(resload_LoadFileOffset,a4)

_loadoffset_33	move.l	#$100,d0		;size
		move.l	#-1,d1		        ;offset
		lea	_filename_100,a0	;filename
		lea	0,a1			;address
		jmp	(resload_LoadFileOffset,a4)

;======================================================================

_loadfile_0	lea	_filename_100,a0	;filename
		lea	$1000,a1		;address
		jsr	(resload_LoadFile,a4)
		cmp.l	#256,d0
		bne	_badfilesize
		tst.l	d1
		bne	_badioerr
		move.l	#$100+8,d0
		lea	$1000-4,a0
		jsr	(resload_CRC16,a4)
		cmp.w	#$a9c6,d0
		bne	_badchksum
		rts

_loadfiledec_0	lea	_filename_100_crm1,a0	;filename
		bra	_loadfiledec

_loadfiledec_1	lea	_filename_100_crm1s,a0	;filename
		bra	_loadfiledec

_loadfiledec_2	lea	_filename_100_crm2,a0	;filename
		bra	_loadfiledec

_loadfiledec_3	lea	_filename_100_crm2s,a0	;filename
		bra	_loadfiledec

_loadfiledec_4	lea	_filename_100_im,a0	;filename
		bra	_loadfiledec

_loadfiledec_5	lea	_filename_100_rnc1,a0	;filename
		bra	_loadfiledec

_loadfiledec_6	lea	_filename_100_rnc2,a0	;filename

_loadfiledec	lea	$1000,a1		;address
		jsr	(resload_LoadFileDecrunch,a4)
		cmp.l	#256,d0
		bne	_badfilesize
		tst.l	d1
		bne	_badioerr
		move.l	#$100+8,d0
		lea	$1000-4,a0
		jsr	(resload_CRC16,a4)
		cmp.w	#$a9c6,d0
		bne	_badchksum
		rts

_loadfileoff_0	move.l	#256,d0			;size
		move.l	#0,d1			;offset
		lea	_filename_100,a0	;filename
		lea	$1000,a1		;address
		jsr	(resload_LoadFileOffset,a4)
		cmp.l	#-1,d0
		bne	_badfilesize
		tst.l	d1
		bne	_badioerr
		move.l	#$100+8,d0
		lea	$1000-4,a0
		jsr	(resload_CRC16,a4)
		cmp.w	#$a9c6,d0
		bne	_badchksum
		rts

_diskload_0	move.l	#0,d0			;offset
		move.l	#256,d1			;size
		move.l	#$12345603,d2		;diskno.b = 3
		lea	$1000,a0		;address
		jsr	(resload_DiskLoad,a4)
		cmp.l	#-1,d0
		bne	_badfilesize
		tst.l	d1
		bne	_badioerr
		move.l	#$100+8,d0
		lea	$1000-4,a0
		jsr	(resload_CRC16,a4)
		cmp.w	#$a9c6,d0
		bne	_badchksum
		rts

_getfilesize_0	lea	_filename_100,a0	 ;filename
		jsr	(resload_GetFileSize,a4)
		cmp.l	#256,d0
		bne	_badfilesize
		rts

_getfilesizedec_0 lea	_filename_100_crm1,a0	;filename
		bra	_getfilesizedec

_getfilesizedec_4 lea	_filename_100_im,a0	;filename

_getfilesizedec	jsr	(resload_GetFileSizeDec,a4)
		cmp.l	#256,d0
		bne	_badfilesize
		rts

_illegalname_0	lea	_filename_iname_0,a0
		lea	$10000,a1
		jmp	(resload_LoadFile,a4)
_illegalname_1	lea	_filename_iname_1,a0
		jmp	(resload_DeleteFile,a4)
_illegalname_2	lea	_filename_iname_2,a0
		jmp	(resload_GetFileSize,a4)
_illegalname_3	lea	_filename_iname_3,a0
		lea	$10000,a1
		jmp	(resload_Examine,a4)

_badchksum	pea	_t_badchksum
		bra	_failmsg

_badfilesize	pea	_t_badfilesize
		bra	_failmsg

_badioerr	pea	_t_badioerr
		bra	_failmsg

;======================================================================
; checks for resload_Decrunch
;======================================================================

; init routines which will set
; d6 = UWORD crc
; d7 = ULONG size
; a0 = CPTR  filename

_decrunch_i_good	move.l	#65536,d7	;size
			move.w	#$c6b4,d6	;crc
			rts
_decrunch_i_bad		move.l	#65200,d7	;size
			move.w	#$7dd7,d6	;crc
			rts
_decrunch_i_crm1_g	lea	_filename_crm1_g,a0
			bra	_decrunch_i_good
_decrunch_i_crm1_b	lea	_filename_crm1_b,a0
			bra	_decrunch_i_bad
_decrunch_i_crm1s_g	lea	_filename_crm1s_g,a0
			bra	_decrunch_i_good
_decrunch_i_crm1s_b	lea	_filename_crm1s_b,a0
			bra	_decrunch_i_bad
_decrunch_i_crm2_g	lea	_filename_crm2_g,a0
			bra	_decrunch_i_good
_decrunch_i_crm2_b	lea	_filename_crm2_b,a0
			bra	_decrunch_i_bad
_decrunch_i_crm2s_g	lea	_filename_crm2s_g,a0
			bra	_decrunch_i_good
_decrunch_i_crm2s_b	lea	_filename_crm2s_b,a0
			bra	_decrunch_i_bad
_decrunch_i_im_g	lea	_filename_im_g,a0
			bra	_decrunch_i_good
_decrunch_i_im_b	lea	_filename_im_b,a0
			bra	_decrunch_i_bad
_decrunch_i_rnc1_g	lea	_filename_rnc1_g,a0
			bra	_decrunch_i_good
_decrunch_i_rnc1_b	lea	_filename_rnc1_b,a0
			bra	_decrunch_i_bad
_decrunch_i_rnc2_g	lea	_filename_rnc2_g,a0
			bra	_decrunch_i_good
_decrunch_i_rnc2_b	lea	_filename_rnc2_b,a0
			bra	_decrunch_i_bad
_decrunch_i_rnc1o	move.l	#87792,d7	;size
			move.w	#$a4f0,d6	;crc
			lea	_filename_rnc1old,a0
			rts
_decrunch_i_tpwm	move.l	#3060,d7	;size
			move.w	#$b687,d6	;crc
			lea	_filename_tpwm,a0
			rts

; decrunching inplace (src=dest) align=long

_decrunch0_crm1_g	bsr	_decrunch_i_crm1_g
			bra	_decrunch0_gen
_decrunch0_crm1_b	bsr	_decrunch_i_crm1_b
			bra	_decrunch0_gen
_decrunch0_crm1s_g	bsr	_decrunch_i_crm1s_g
			bra	_decrunch0_gen
_decrunch0_crm1s_b	bsr	_decrunch_i_crm1s_b
			bra	_decrunch0_gen
_decrunch0_crm2_g	bsr	_decrunch_i_crm2_g
			bra	_decrunch0_gen
_decrunch0_crm2_b	bsr	_decrunch_i_crm2_b
			bra	_decrunch0_gen
_decrunch0_crm2s_g	bsr	_decrunch_i_crm2s_g
			bra	_decrunch0_gen
_decrunch0_crm2s_b	bsr	_decrunch_i_crm2s_b
			bra	_decrunch0_gen
_decrunch0_im_g		bsr	_decrunch_i_im_g
			bra	_decrunch0_gen
_decrunch0_im_b		bsr	_decrunch_i_im_b
			bra	_decrunch0_gen
_decrunch0_rnc1_g	bsr	_decrunch_i_rnc1_g
			bra	_decrunch0_gen
_decrunch0_rnc1_b	bsr	_decrunch_i_rnc1_b
			bra	_decrunch0_gen
_decrunch0_rnc2_g	bsr	_decrunch_i_rnc2_g
			bra	_decrunch0_gen
_decrunch0_rnc2_b	bsr	_decrunch_i_rnc2_b
			bra	_decrunch0_gen
_decrunch0_rnc1o	bsr	_decrunch_i_rnc1o
			bra	_decrunch0_gen
_decrunch0_tpwm		bsr	_decrunch_i_tpwm
_decrunch0_gen		lea	$1000,a2		;A2 = start
			bra	_decrunch0123_gen

; decrunching inplace (src=dest) align=long+1

_decrunch1_im_g		bsr	_decrunch_i_im_g
			bra	_decrunch1_gen
_decrunch1_im_b		bsr	_decrunch_i_im_b
			bra	_decrunch1_gen
_decrunch1_rnc1_g	bsr	_decrunch_i_rnc1_g
			bra	_decrunch1_gen
_decrunch1_rnc1_b	bsr	_decrunch_i_rnc1_b
			bra	_decrunch1_gen
_decrunch1_rnc2_g	bsr	_decrunch_i_rnc2_g
			bra	_decrunch1_gen
_decrunch1_rnc2_b	bsr	_decrunch_i_rnc2_b
			bra	_decrunch1_gen
_decrunch1_rnc1o	bsr	_decrunch_i_rnc1o
			bra	_decrunch1_gen
_decrunch1_tpwm		bsr	_decrunch_i_tpwm
_decrunch1_gen		lea	$1001,a2		;A2 = start
			bra	_decrunch0123_gen

; decrunching inplace (src=dest) align=long+2

_decrunch2_crm1_g	bsr	_decrunch_i_crm1_g
			bra	_decrunch2_gen
_decrunch2_crm1_b	bsr	_decrunch_i_crm1_b
			bra	_decrunch2_gen
_decrunch2_crm1s_g	bsr	_decrunch_i_crm1s_g
			bra	_decrunch2_gen
_decrunch2_crm1s_b	bsr	_decrunch_i_crm1s_b
			bra	_decrunch2_gen
_decrunch2_crm2_g	bsr	_decrunch_i_crm2_g
			bra	_decrunch2_gen
_decrunch2_crm2_b	bsr	_decrunch_i_crm2_b
			bra	_decrunch2_gen
_decrunch2_crm2s_g	bsr	_decrunch_i_crm2s_g
			bra	_decrunch2_gen
_decrunch2_crm2s_b	bsr	_decrunch_i_crm2s_b
			bra	_decrunch2_gen
_decrunch2_im_g		bsr	_decrunch_i_im_g
			bra	_decrunch2_gen
_decrunch2_im_b		bsr	_decrunch_i_im_b
			bra	_decrunch2_gen
_decrunch2_rnc1_g	bsr	_decrunch_i_rnc1_g
			bra	_decrunch2_gen
_decrunch2_rnc1_b	bsr	_decrunch_i_rnc1_b
			bra	_decrunch2_gen
_decrunch2_rnc2_g	bsr	_decrunch_i_rnc2_g
			bra	_decrunch2_gen
_decrunch2_rnc2_b	bsr	_decrunch_i_rnc2_b
			bra	_decrunch2_gen
_decrunch2_rnc1o	bsr	_decrunch_i_rnc1o
			bra	_decrunch2_gen
_decrunch2_tpwm		bsr	_decrunch_i_tpwm
_decrunch2_gen		lea	$1002,a2		;A2 = start
			bra	_decrunch0123_gen

; decrunching inplace (src=dest) align=long+3

_decrunch3_im_g		bsr	_decrunch_i_im_g
			bra	_decrunch3_gen
_decrunch3_im_b		bsr	_decrunch_i_im_b
			bra	_decrunch3_gen
_decrunch3_rnc1_g	bsr	_decrunch_i_rnc1_g
			bra	_decrunch3_gen
_decrunch3_rnc1_b	bsr	_decrunch_i_rnc1_b
			bra	_decrunch3_gen
_decrunch3_rnc2_g	bsr	_decrunch_i_rnc2_g
			bra	_decrunch3_gen
_decrunch3_rnc2_b	bsr	_decrunch_i_rnc2_b
			bra	_decrunch3_gen
_decrunch3_rnc1o	bsr	_decrunch_i_rnc1o
			bra	_decrunch3_gen
_decrunch3_tpwm		bsr	_decrunch_i_tpwm
_decrunch3_gen		lea	$1003,a2		;A2 = start

_decrunch0123_gen
		move.l	#$DEADBEEF,(-4,a2)
		move.l	#$DEADBEEF,(a2,d7.l)
		move.l	a2,a1
		jsr	(resload_LoadFile,a4)
		move.l	a2,a0
		move.l	a2,a1
		jsr	(resload_Decrunch,a4)
		cmp.l	d0,d7
		bne	_decrunch_badsize
		lea	(-$400,a2),a0
		move.l	d7,d0
		add.l	#$800,d0
		jsr	(resload_CRC16,a4)
		cmp.w	d0,d6
		bne	_decrunch_baddata
		rts

; decrunching without overlap

_decrunch4_crm1_g	bsr	_decrunch_i_crm1_g
			bra	_decrunch4_gen
_decrunch4_crm1_b	bsr	_decrunch_i_crm1_b
			bra	_decrunch4_gen
_decrunch4_crm1s_g	bsr	_decrunch_i_crm1s_g
			bra	_decrunch4_gen
_decrunch4_crm1s_b	bsr	_decrunch_i_crm1s_b
			bra	_decrunch4_gen
_decrunch4_crm2_g	bsr	_decrunch_i_crm2_g
			bra	_decrunch4_gen
_decrunch4_crm2_b	bsr	_decrunch_i_crm2_b
			bra	_decrunch4_gen
_decrunch4_crm2s_g	bsr	_decrunch_i_crm2s_g
			bra	_decrunch4_gen
_decrunch4_crm2s_b	bsr	_decrunch_i_crm2s_b
			bra	_decrunch4_gen
_decrunch4_im_g		bsr	_decrunch_i_im_g
			bra	_decrunch4_gen
_decrunch4_im_b		bsr	_decrunch_i_im_b
			bra	_decrunch4_gen
_decrunch4_rnc1_g	bsr	_decrunch_i_rnc1_g
			bra	_decrunch4_gen
_decrunch4_rnc1_b	bsr	_decrunch_i_rnc1_b
			bra	_decrunch4_gen
_decrunch4_rnc2_g	bsr	_decrunch_i_rnc2_g
			bra	_decrunch4_gen
_decrunch4_rnc2_b	bsr	_decrunch_i_rnc2_b
			bra	_decrunch4_gen
_decrunch4_rnc1o	bsr	_decrunch_i_rnc1o
			bra	_decrunch4_gen
_decrunch4_tpwm		bsr	_decrunch_i_tpwm

_decrunch4_gen	lea	$1000,a2			;A2 = source
		lea	$20000,a3			;A3 = destination
		move.l	#$DEADBEEF,d2			;D2 = DEADBEEF
		move.l	d2,(-4,a3)
		move.l	d2,(a3,d7.l)
		move.l	a2,a1
		jsr	(resload_LoadFile,a4)
		move.l	d2,(-4,a2)
		move.l	d2,(a2,d0.l)
		lea	(-$400,a2),a0
		add.l	#$800,d0
		move.l	d0,d3				;D3 = length crc source
		jsr	(resload_CRC16,a4)
		move.w	d0,d4				;D4 = crc source
		move.l	a2,a0
		move.l	a3,a1
		jsr	(resload_Decrunch,a4)
		cmp.l	d0,d7
		bne	_decrunch_badsize
		lea	(-$400,a2),a0
		move.l	d3,d0
		jsr	(resload_CRC16,a4)
		cmp.w	d0,d4
		bne	_decrunch_badsrc
		lea	(-$400,a3),a0
		move.l	d7,d0
		add.l	#$800,d0
		jsr	(resload_CRC16,a4)
		cmp.w	d0,d6
		bne	_decrunch_baddata
		rts

; decrunching with overlap, destination after source

_decrunch5_crm1_g	bsr	_decrunch_i_crm1_g
			bra	_decrunch5_gen
_decrunch5_crm1_b	bsr	_decrunch_i_crm1_b
			bra	_decrunch5_gen
_decrunch5_crm1s_g	bsr	_decrunch_i_crm1s_g
			bra	_decrunch5_gen
_decrunch5_crm1s_b	bsr	_decrunch_i_crm1s_b
			bra	_decrunch5_gen
_decrunch5_crm2_g	bsr	_decrunch_i_crm2_g
			bra	_decrunch5_gen
_decrunch5_crm2_b	bsr	_decrunch_i_crm2_b
			bra	_decrunch5_gen
_decrunch5_crm2s_g	bsr	_decrunch_i_crm2s_g
			bra	_decrunch5_gen
_decrunch5_crm2s_b	bsr	_decrunch_i_crm2s_b
			bra	_decrunch5_gen
_decrunch5_im_g		bsr	_decrunch_i_im_g
			bra	_decrunch5_gen
_decrunch5_im_b		bsr	_decrunch_i_im_b
			bra	_decrunch5_gen
_decrunch5_rnc1_g	bsr	_decrunch_i_rnc1_g
			bra	_decrunch5_gen
_decrunch5_rnc1_b	bsr	_decrunch_i_rnc1_b
			bra	_decrunch5_gen
_decrunch5_rnc2_g	bsr	_decrunch_i_rnc2_g
			bra	_decrunch5_gen
_decrunch5_rnc2_b	bsr	_decrunch_i_rnc2_b
			bra	_decrunch5_gen
_decrunch5_rnc1o	bsr	_decrunch_i_rnc1o
			bra	_decrunch5_gen
_decrunch5_tpwm		lea	_filename_tpwm,a0

_decrunch5_gen	lea	$1000,a2			;A2 = source
		lea	$1200,a3			;A3 = destination
		move.l	a2,a1
		move.l	a0,-(a7)
		jsr	(resload_LoadFileDecrunch,a4)
		move.l	d0,d7				;D7 = length
		move.l	a2,a0
		jsr	(resload_CRC16,a4)
		move.w	d0,d6				;D6 = crc
		move.l	(a7)+,a0
		move.l	a2,a1
		jsr	(resload_LoadFile,a4)
		move.l	a2,a0
		move.l	a3,a1
		jsr	(resload_Decrunch,a4)
		cmp.l	d0,d7
		bne	_decrunch_badsize
		move.l	a3,a0
		jsr	(resload_CRC16,a4)
		cmp.w	d0,d6
		bne	_decrunch_baddata
		rts

; decrunching with overlap, source after destination

_decrunch6_crm1_g	bsr	_decrunch_i_crm1_g
			bra	_decrunch6_gen
_decrunch6_crm1_b	bsr	_decrunch_i_crm1_b
			bra	_decrunch6_gen
_decrunch6_crm1s_g	bsr	_decrunch_i_crm1s_g
			bra	_decrunch6_gen
_decrunch6_crm1s_b	bsr	_decrunch_i_crm1s_b
			bra	_decrunch6_gen
_decrunch6_crm2_g	bsr	_decrunch_i_crm2_g
			bra	_decrunch6_gen
_decrunch6_crm2_b	bsr	_decrunch_i_crm2_b
			bra	_decrunch6_gen
_decrunch6_crm2s_g	bsr	_decrunch_i_crm2s_g
			bra	_decrunch6_gen
_decrunch6_crm2s_b	bsr	_decrunch_i_crm2s_b
			bra	_decrunch6_gen
_decrunch6_rnc1_g	bsr	_decrunch_i_rnc1_g
			bra	_decrunch6_gen
_decrunch6_rnc1_b	bsr	_decrunch_i_rnc1_b
			bra	_decrunch6_gen
_decrunch6_rnc2_g	bsr	_decrunch_i_rnc2_g
			bra	_decrunch6_gen
_decrunch6_rnc2_b	bsr	_decrunch_i_rnc2_b
			bra	_decrunch6_gen
_decrunch6_rnc1o	bsr	_decrunch_i_rnc1o
			bra	_decrunch6_gen
_decrunch6_tpwm		lea	_filename_tpwm,a0

_decrunch6_gen	lea	$1200,a2			;A2 = source
		lea	$1000,a3			;A3 = destination
		move.l	a2,a1
		move.l	a0,-(a7)
		jsr	(resload_LoadFileDecrunch,a4)
		move.l	d0,d7				;D7 = length
		move.l	a2,a0
		jsr	(resload_CRC16,a4)
		move.w	d0,d6				;D6 = crc
		move.l	(a7)+,a0
		move.l	a2,a1
		jsr	(resload_LoadFile,a4)
		move.l	a2,a0
		move.l	a3,a1
		jsr	(resload_Decrunch,a4)
		cmp.l	d0,d7
		bne	_decrunch_badsize
		move.l	a3,a0
		jsr	(resload_CRC16,a4)
		cmp.w	d0,d6
		bne	_decrunch_baddata
		rts

_decrunch_badsize	pea	_t_baddecsize
			bra	_failmsg
_decrunch_baddata	pea	_t_baddecdata
			bra	_failmsg
_decrunch_badsrc	pea	_t_baddecsrc
			bra	_failmsg

;======================================================================
; checks for resload_SaveFile, resload_SaveFileOffset
;======================================================================

_saveinit	lea	$2000,a0
		lea	_filename_save,a3	;A3 = name
		move.l	a0,a2			;A2 = buffer
		move.l	#$1000,d2		;D2 = length
		moveq	#0,d0
		move.w	#$1000/4-1,d1
.init		move.l	d0,(a0)+
		addq.l	#1,d0
		dbf	d1,.init
		move.l	d2,d0
		move.l	a2,a0
		jsr	(resload_CRC16,a4)
		move.l	d0,d7			;D7 = crc
		rts

_savefile0	bsr	_saveinit
		move.l	d2,d0
		move.l	a3,a0
		move.l	a2,a1
		jsr	(resload_SaveFile,a4)
		move.l	a3,a0
		move.l	a2,a1
		jsr	(resload_LoadFile,a4)
		cmp.l	d0,d2
		bne	_save_loadlen
		move.l	d2,d0
		move.l	a2,a0
		jsr	(resload_CRC16,a4)
		cmp.w	d0,d7
		bne	_save_crc
		rts

_save_loadlen	pea	_t_badloadlen
		bra	_failmsg
_save_crc	pea	_t_badcrc
		bra	_failmsg

_savefileoffset0
		bsr	_saveinit
		move.l	#0,d0			;empty file
		move.l	a3,a0
		move.l	a2,a1
		jsr	(resload_SaveFile,a4)
		move.l	d2,d0
		move.l	#$1000,d1		;offset
		add.l	d1,d2
		move.l	a3,a0
		move.l	a2,a1
		jsr	(resload_SaveFileOffset,a4)
		move.l	a3,a0
		move.l	a2,a1
		jsr	(resload_LoadFile,a4)
		cmp.l	d0,d2
		bne	_save_loadlen
		move.l	d2,d0
		move.l	a2,a0
		jsr	(resload_CRC16,a4)
		cmp.w	#$c22,d0
		bne	_save_crc
		rts

; check the file cache operations

_filecache0	moveq	#10,d0			;length
		moveq	#8,d1			;offset
		lea	_filename_protwrt,a0
		lea	$10000,a1
		jmp	(resload_SaveFileOffset,a4)
		
_filecache1	lea	_filename_protdel,a0
		move.l	a0,a3
		lea	$10000,a1
		move.l	a1,a2
		jsr	(resload_LoadFile,a4)	;read to file cache
		move.l	a3,a0
		move.l	a2,a1
		jmp	(resload_SaveFile,a4)
		
_filecache2	lea	_filename_protdel,a0
		move.l	a0,a3
		jmp	(resload_DeleteFile,a4)

_filecache3	lea	_filename_protdel,a0
		jsr	(resload_GetFileSize,a4)
		cmp.l	#120,d0
		bne	.fail
		bsr	_getioerr
		tst.l	d0
		bne	.fail
		rts
.fail		pea	_t_getfilesize
		bra	_failmsg

; with filecache it will return with #ERROR_OBJECT_NOT_FOUND
; with dircache or none cache it will fail with #ERROR_OBJECT_WRONG_TYPE
_filecache4	lea	_filename_dir,a0
		jsr	(resload_GetFileSize,a4)
		tst.l	d0
		bne	.fail
		bsr	_getioerr
		cmp.l	#ERROR_OBJECT_NOT_FOUND,d0
		bne	.fail
		rts
.fail		pea	_t_getfilesize
		bra	_failmsg

_filecache5	lea	_filename_notexist,a0
		jsr	(resload_GetFileSize,a4)
		tst.l	d0
		bne	.fail
		bsr	_getioerr
		cmp.l	#ERROR_OBJECT_NOT_FOUND,d0
		bne	.fail
		rts
.fail		pea	_t_getfilesize
		bra	_failmsg

_getioerr	clr.l	-(a7)
		clr.l	-(a7)
		pea	WHDLTAG_IOERR_GET
		move.l	a7,a0
		jsr	(resload_Control,a4)
		addq.l	#4,a7
		move.l	(a7)+,d0
		addq.l	#4,a7
		rts

_filecache6	lea	_filename_dir,a0
		move.l	a0,a3
		jmp	(resload_DeleteFile,a4)

;======================================================================
; support functions
;
; terminate with FAILMSG

_failmsg	pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a4)

; wait for blitter finish

_bw		BLITWAIT
		rts

; check if registers has been modified

_savreg		movem.l	d0-a7,SAVREG
		rts

_chkreg		movem.l	d0-a7,SAVREG+16*4
		move.l	(a7),SAVREG+16*8
		lea	SAVREG,a0
		lea	(16*4,a0),a1
		moveq	#15,d0
.cmp		cmp.l   (a0)+,(a1)+
		dbne	d0,.cmp
		bne	.fail
		movem.l	(a0),d0-a1
		rts
.fail		pea	.failmsg
		pea	TDREASON_FAILMSG
		jmp	(resload_Abort,a4)
.failmsg	dc.b	"registers are modified, check registers",10
		sprintx	"at $%lx before and $%lx after, pc at $%lx",SAVREG,SAVREG+16*4,SAVREG+16*8
		dc.b	0

;======================================================================

	INCLUDE	Sources:whdload/keyboard.s

;======================================================================

		dc.w	0	;dummy
	CNOP 0,4
_end

;======================================================================

	END
