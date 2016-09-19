socket=$1
function is_telnet_socket_closed {
    #TODO(AKutsan) APPLINK-15273 Remove waiting for closing telnet port
    res=$(netstat -pna 2>/dev/null | grep $socket | wc -l);
    [ $res -gt 1 ] && return 1 || return 0;
}
while ! is_telnet_socket_closed ; do sleep 1; done
