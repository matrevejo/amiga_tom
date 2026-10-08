cat stage.dat | sed 's/\./x/g' > stage.x

i=1
cat stage.x | while read x
do
y[i]=$x
echo ${y[i]}
let i=i+1
done


j=0
while [ $j -le 2000 ]
do

i=1
while [ $i -le 13 ]
do
c=`echo ${y[$i]:$j:1}`
#echo "<"$c">"

if [ "$c" != "x" ]
then
echo "	dc.w " "$"$j
echo "	dc.b " "$"$i",$"$c
fi

	
let i=i+1
done
let j=j+1
done
