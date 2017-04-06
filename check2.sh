dirATF=$(pwd)
echo $dirATF
filename="sdl.pid"
while read -r line
do
     pid="$line"
     echo "wait for finish" $pid
done < "$filename"

# while kill -0 "$pid";
# 	do
#       echo "SDL is still executing"
#        sleep 0
# done

while s=`ps -p $pid -o s=` && [[ "$s" && "$s" != 'Z' ]]; do
	# echo "SDL is still executing"
    sleep 0
done

# if test -e /proc/$(cat sdl.pid); echo "exist"

# echo "here"
# wait $pid
t1=$?
# echo $t1
echo "tests " $t1
echo $t1 > pid.result
 exit  0




# # echo $?
# echo "the exit status was =" $SDL_exit_status
# if test -e /proc/$(cat sdl.pid); then echo "Got pid!" $(/proc/$pid
# fi


# return $SDL_exit_status