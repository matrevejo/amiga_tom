
* $Id: WHDLoadResload.s 1.5 2014/03/15 13:30:48 wepl Exp wepl $

	INCDIR	Includes:
	INCLUDE UserSymbols.i
	INCLUDE	whdload.i

	dc.l		name
	dc.b		BYTESYM
	ByteSymbol	<resload_Install>,resload_Install
	ByteSymbol	<resload_Abort>,resload_Abort
	ByteSymbol	<resload_LoadFile>,resload_LoadFile
	ByteSymbol	<resload_SaveFile>,resload_SaveFile
	ByteSymbol	<resload_SetCACR>,resload_SetCACR
	ByteSymbol	<resload_ListFiles>,resload_ListFiles
	ByteSymbol	<resload_Decrunch>,resload_Decrunch
	ByteSymbol	<resload_LoadFileDecrunch>,resload_LoadFileDecrunch
	ByteSymbol	<resload_FlushCache>,resload_FlushCache
	ByteSymbol	<resload_GetFileSize>,resload_GetFileSize
	ByteSymbol	<resload_DiskLoad>,resload_DiskLoad
	ByteSymbol	<resload_DiskLoadDev>,resload_DiskLoadDev
	ByteSymbol	<resload_CRC16>,resload_CRC16
	ByteSymbol	<resload_Control>,resload_Control
	ByteSymbol	<resload_SaveFileOffset>,resload_SaveFileOffset
	ByteSymbol	<resload_ProtectRead>,resload_ProtectRead
	ByteSymbol	<resload_ProtectReadWrite>,resload_ProtectReadWrite
	ByteSymbol	<resload_ProtectWrite>,resload_ProtectWrite
	ByteSymbol	<resload_ProtectRemove>,resload_ProtectRemove
	ByteSymbol	<resload_LoadFileOffset>,resload_LoadFileOffset
	ByteSymbol	<resload_Relocate>,resload_Relocate
	ByteSymbol	<resload_Delay>,resload_Delay
	ByteSymbol	<resload_DeleteFile>,resload_DeleteFile
	ByteSymbol	<resload_ProtectSMC>,resload_ProtectSMC
	ByteSymbol	<resload_SetCPU>,resload_SetCPU
	ByteSymbol	<resload_Patch>,resload_Patch
	ByteSymbol	<resload_LoadKick>,resload_LoadKick
	ByteSymbol	<resload_Delta>,resload_Delta
	ByteSymbol	<resload_GetFileSize>,resload_GetFileSize
	ByteSymbol	<resload_PatchSeg>,resload_PatchSeg
	ByteSymbol	<resload_Examine>,resload_Examine
	ByteSymbol	<resload_ExNext>,resload_ExNext
	ByteSymbol	<resload_GetCustom>,resload_GetCustom
	ByteSymbol	<resload_VSNPrintF>,resload_VSNPrintF
	ByteSymbol	<resload_Log>,resload_Log
	dc.b		ENDBASE
name	dc.b		'WHDL Resload',0
	EVEN
