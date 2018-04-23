#!/bin/bash

exec 4>&1

function get {
	url="$1"
	proto="${url%%:*}"
	uri="${url##$proto://}"
	host="${uri%%/*}"
	uri="/${uri#*/}"

	case "$proto" in
	http)
		echo >&4 "Get $url"
		get_http $host $uri
		;;
	https)
		echo >&4 "Get $url"
		get_https $host $uri
		;;
	*)
		echo >&2 "Unknown protocol $proto in URL $url"
		exit 10;;
	esac
}

function get_http {
	exec 5<> /dev/tcp/$1/80
	echo -ne "GET $2 HTTP/1.1\r\nHost: $1\r\nConnection: close\r\n\r\n" >&5
	# read until end of headers
	while read header; do
		if [ "$header" = $'\r' ]; then
			# output the result
			cat <&5
			break
		fi
	done <&5
}

function get_https {
	echo -ne "GET $uri HTTP/1.1\r\nHost: $1\r\nConnection: close\r\n\r\n" |
	 openssl s_client -quiet -connect $1:443 2>/dev/null |
	 # read until end of headers
	 while read header; do
		if [ "$header" = $'\r' ]; then
			# output the result
			cat
			break
		fi
	done
}

if ./cygapt -h >/dev/null 2>&1; then
	echo "cygapt is already functional"
	exit
fi

echo "Downloading missing cygapt dependencies"
mirror=$(grep -A1 last-mirror /etc/setup/setup.rc)
mirror="${mirror##last-mirror}"
mirror="${mirror#"${mirror%%[![:space:]]*}"}"

arch=$(uname -m)
arch="${arch/i6/x}"

spin="-"

get $mirror$arch/setup.bz2 | bzcat | while read line; do
	case "$line" in
	@*)
		pack="${line##@ }"
		release="cur"

		echo -en "\r$spin"
		case "$spin" in
		-) spin="\\" ;;
		\\) spin="|" ;;
		\|) spin="/" ;;
		*) spin="-" ;;
		esac

		continue
		;;
	\[*\])
		release="${line##\[}"
		release="${release%%\]}"
		continue
		;;
	install*)
		test "$release" = "cur" || continue
		case "$pack" in
		libcrypt0) ;;
		libssp0) ;;
		perl) ;;
		perl_base) ;;
		perl_autorebase) ;;
		perl-Compress-Bzip2) ;;
		perl-Digest-SHA) ;;
		perl-Scalar-List-Utils) ;;
		perl-TermReadKey) ;;
		perl-libwww-perl) ;;
		perl-Encode-Locale) ;;
		perl-File-Listing) ;;
		perl-HTTP-Date) ;;
		perl-HTML-Parser) ;;
		perl-HTML-Tagset) ;;
		perl-HTTP-Cookies) ;;
		perl-HTTP-Message) ;;
		perl-IO-HTML) ;;
		perl-LWP-MediaTypes) ;;
		perl-URI) ;;
		perl-HTTP-Daemon) ;;
		perl-HTTP-Negotiate) ;;
		perl-Net-HTTP) ;;
		perl-Try-Tiny) ;;
		perl-WWW-RobotRules) ;;
		*)
			continue;;
		esac
		path="${line##install: }"
		path="${path%% *}"
		;;
	*)
		continue
	esac

	if cygcheck -c $pack | grep -q OK; then
		# already installed
		continue
	fi

	echo -en "\r"
	get $mirror$path | tar -J -xf - -C /
done

./cygapt update
./cygapt fix
