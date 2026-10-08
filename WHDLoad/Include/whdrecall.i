;*---------------------------------------------------------------------------
;  :Module.	whdrecall.i
;  :Contens.	definitions for recall data created by WHDLoad
;  :Author.	Bert Jahn
;  :EMail.	wepl@whdload.de
;  :Version.	$Id: whdrecall.i 17.0 2011/08/14 23:40:24 wepl Exp wepl $
;  :History.	03.01.10 created
;  :Copyright.	© 2010 Bert Jahn, All Rights Reserved
;  :Language.	68000 Assembler
;  :Translator.	Barfly V2.9
;---------------------------------------------------------------------------*

 IFND WHDRECALL_I
WHDRECALL_I SET 1

	IFND	EXEC_TYPES_I
	INCLUDE	exec/types.i
	ENDC
	IFND	WHDDUMP_I
	INCLUDE	whddump.i
	ENDC

;=============================================================================

 BITDEF RECALL,RESET,0				;Ctrl-LAmiga-RAmiga detected by WHDLoad
 BITDEF RECALL,STATEOK,1			;system state is valid
 BITDEF RECALL,SHADOW,2				;BaseMem has been transfered to ShadowMem

	STRUCTURE	Recall,0
		STRUCT	recall_magic,8		;"WHDRECAL"
		LONG	recall_size		;size of the structure
		LONG	recall_flags
		LONG	recall_GlobalSize
		LONG	recall_GlobalPhy
		LONG	recall_ShadowMemSize
		STRUCT	recall_dump_header,wdh_SIZEOF
		STRUCT	recall_dump_cpu,wdc_SIZEOF
		STRUCT	recall_dump_custom,wdcu_SIZEOF
		STRUCT	recall_dump_ciaa,wdci_SIZEOF
		STRUCT	recall_dump_ciab,wdci_SIZEOF
		LABEL	recall_SIZEOF

;=============================================================================

 ENDC
