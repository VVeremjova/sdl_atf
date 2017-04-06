dirATF=$(pwd)
echo $dirATF
filename="sdl.pid"
# while read -r line
# do
#      pid="$line"
#      echo "wait for finish" $pid
# done < "$filename"

while s=`ps -p $pid -o s=` && [[ "$s" && "$s" != 'Z' ]]; do
	# echo "SDL is still executing"
    sleep 0
done

t1=$?
echo "tests " $t1
echo $t1 > pid.result
 exit  0