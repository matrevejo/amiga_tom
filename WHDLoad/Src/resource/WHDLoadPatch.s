
* $Id: WHDLoadPatch.s 1.2 2014/03/15 13:31:09 wepl Exp wepl $

	INCDIR	Includes:
	INCLUDE UserSymbols.i
	INCLUDE	whdload.i

	dc.l		.name
	dc.b		OREDSYM
	ORedSymbol	<PLCMD_END>,$ff,PLCMD_END
	ORedSymbol	<PLCMD_R>,$ff,PLCMD_R
	ORedSymbol	<PLCMD_P>,$ff,PLCMD_P
	ORedSymbol	<PLCMD_PS>,$ff,PLCMD_PS
	ORedSymbol	<PLCMD_S>,$ff,PLCMD_S
	ORedSymbol	<PLCMD_I>,$ff,PLCMD_I
	ORedSymbol	<PLCMD_B>,$ff,PLCMD_B
	ORedSymbol	<PLCMD_W>,$ff,PLCMD_W
	ORedSymbol	<PLCMD_L>,$ff,PLCMD_L
	ORedSymbol	<PLCMD_A>,$ff,PLCMD_A
	ORedSymbol	<PLCMD_PA>,$ff,PLCMD_PA
	ORedSymbol	<PLCMD_NOP>,$ff,PLCMD_NOP
	ORedSymbol	<PLCMD_C>,$ff,PLCMD_C
	ORedSymbol	<PLCMD_CB>,$ff,PLCMD_CB
	ORedSymbol	<PLCMD_CW>,$ff,PLCMD_CW
	ORedSymbol	<PLCMD_CL>,$ff,PLCMD_CL
	ORedSymbol	<PLCMD_PSS>,$ff,PLCMD_PSS
	ORedSymbol	<PLCMD_NEXT>,$ff,PLCMD_NEXT
	ORedSymbol	<PLCMD_AB>,$ff,PLCMD_AB
	ORedSymbol	<PLCMD_AW>,$ff,PLCMD_AW
	ORedSymbol	<PLCMD_AL>,$ff,PLCMD_AL
	ORedSymbol	<PLCMD_DATA>,$ff,PLCMD_DATA
	ORedSymbol	<PLCMD_ORB>,$ff,PLCMD_ORB
	ORedSymbol	<PLCMD_ORW>,$ff,PLCMD_ORW
	ORedSymbol	<PLCMD_ORL>,$ff,PLCMD_ORL
	ORedSymbol	<PLCMD_GA>,$ff,PLCMD_GA
	ORedSymbol	<PLCMD_BKPT>,$ff,PLCMD_BKPT
	ORedSymbol	<PLCMD_BELL>,$ff,PLCMD_BELL
	ORedSymbol	<PLCMD_IFBW>,$ff,PLCMD_IFBW
	ORedSymbol	<PLCMD_IFC1>,$ff,PLCMD_IFC1
	ORedSymbol	<PLCMD_IFC2>,$ff,PLCMD_IFC2
	ORedSymbol	<PLCMD_IFC3>,$ff,PLCMD_IFC3
	ORedSymbol	<PLCMD_IFC4>,$ff,PLCMD_IFC4
	ORedSymbol	<PLCMD_IFC5>,$ff,PLCMD_IFC5
	ORedSymbol	<PLCMD_IFC1X>,$ff,PLCMD_IFC1X
	ORedSymbol	<PLCMD_IFC2X>,$ff,PLCMD_IFC2X
	ORedSymbol	<PLCMD_IFC3X>,$ff,PLCMD_IFC3X
	ORedSymbol	<PLCMD_IFC4X>,$ff,PLCMD_IFC4X
	ORedSymbol	<PLCMD_IFC5X>,$ff,PLCMD_IFC5X
	ORedSymbol	<PLCMD_ELSE>,$ff,PLCMD_ELSE
	ORedSymbol	<PLCMD_ENDIF>,$ff,PLCMD_ENDIF
	ORedSymbol	<PLCMDF_WORDADR>,PLCMDF_WORDADR,PLCMDF_WORDADR
	ORedSymbol	<PLCMDF_CTRL>,PLCMDF_CTRL,PLCMDF_CTRL
	dc.b		ENDBASE
.name	dc.b		'WHDL Commands Patch',0

