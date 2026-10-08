' Et program i Amiga Basic som regner
' ut sinus og cosinustabellen som brukes
' av rotasjonsrutinene.
' Denne versjonen lagrer den som SOURCEKODE, dvs
' "dc.w 0,101,201,...." osv....

OPTION BASE 0
DIM s%(1279)

DEFDBL a-z
pi=3.141592653589793#

INPUT "Navn på sincos-tabellen (sourcefil):",n$
OPEN n$ FOR OUTPUT AS #1 LEN=10000

PRINT "Lager kombinert sincos SOURCEKODE tabell,"
PRINT "og lagrer den i ";n$
PRINT
t%=0
FOR t=0 TO pi*2.4999 STEP pi/512
  s=SIN(t)
  s%(t%)=INT(s*16384+.5)
  LOCATE 4,5
  PRINT t%;"/";1279
  t%=t%+1
NEXT t

FOR a%=0 TO 159
  LOCATE 5,5
  PRINT a%;"/";159
  PRINT# 1,"  dc.w ";
  i%=a%*8
  WRITE# 1,s%(i%),s%(i%+1),s%(i%+2),s%(i%+3),s%(i%+4),s%(i%+5),s%(i%+6),s%(i%+7)
NEXT
CLOSE# 1

PRINT "Ferdig"
END

