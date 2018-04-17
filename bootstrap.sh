#!/bin/bash

function get {
	url="$1"
	method="${url%%:*}"
	uri="${url##$method://}"
	host="${uri%%/*}"
	uri="/${uri#*/}"

	get_http $host $uri
}

function get_http {
	exec 5<> /dev/tcp/$host/80
	echo -ne "GET $uri HTTP/1.1\r\nHost: $host\r\nConnection: close\r\n\r\n" >&5 &
	cat <&5
# grep -vanm1 [:/] <file>
# tail +<n+1> <file>
}

function get_https {
	echo
}

get http://cygwin.mirror.constant.com/x86_64/setup.bz2
