' Et program i Amiga Basic som regner
' ut sinus og cosinustabellen som brukes
' av rotasjonsrutinene.
DEFDBL a-z
pi=3.141592653589793#

input "Navn på sincos-tabellen:",n$

OPEN n$ FOR OUTPUT AS #1 LEN=3000

PRINT "Lager kombinert sincos tabell, og lagrer den i ";n$
PRINT

FOR t=0 TO pi*2.4999 STEP pi/512
  s=SIN(t)
  g%=INT(s*16384+.5)
  PRINT# 1,MKI$(g%);
NEXT t

PRINT "Ferdig"
END

