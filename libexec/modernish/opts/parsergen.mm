#! /module/for/moderni/sh
\command unalias generateoptionparser 2>/dev/null
#
# opts/parsergen
#
# generateoptionparser: Option parser generator. Generates a modernish code
# loop for parsing a shell function's options. Supports short options, with
# the complete traditional UNIX syntax including combined (stacked) options
# and arguments.
#
# Unfortunately using 'getopts' for functions does not work consistently on
# all shells, so we have to provide our own parser.
#
# This also can't be a straightforward function call, as the code needs to
# be executed within the calling function in order to manipulate its
# positional parameters. That's why this function generates code, storing it
# in the REPLY variable for safe use with 'eval'.
#
# Usage:
# generateoptionparser [ -o ] [ -f FUNCNAME ] [ -v VARPREFIX ] \
#	[ -n OPTIONLETTERS ] [ -a OPTIONLETTERS ]
#
# Options are as follows:
#	-o: write code to standard output as well as storing it in REPLY.
#	    This allows for an easy usage: eval "$(generateoptionparser ...)"
#	    (at the cost of forking a command substitution subshell, of course).
#	-f FUNCNAME: name of the calling function, for error messages.
#	-v VARPREFIX: prefix for option variables. Defaults to: opt_
#	-n OPTIONLETTERS: string of options requiring no arguments.
#	-a OPTIONLETTERS: string of options requiring arguments.
# At least one of -n and -a is required.
# All option letters must be valid characters in portable shell variable names,
# that is: the ASCII ranges A-Z, a-z, 0-9 and _ are supported.
#
# An optional non-option argument, following the options, is the name of the
# variable in which to store the parser code; this defaults to REPLY.
#
# The parser generated by 'generateoptionparser' parses options, eliminating
# them from the positional parameters and setting or unsetting corresponding
# variables, until a non-option argument or the end of arguments is
# encountered.
#
# If a non-argument option is given, its corresponding variable is set to
# the empty string. For an option 'x' and variable prefix opt_, check like so:
#	if isset opt_x; then ...
# If an option requiring an argument is given, its corresponding variable is
# set to the value of the argument.
# If an option is not given, the corresponding variable remains unset.
#
# There are three possible ways of use:
# - On-the-fly generation and execution:
#     someFn() {
#       eval "$(generateoptionparser -o -n asQ -a P -f someFn -v myOpt_)"
#       if isset myOpt_Q; then ...etc...
#     }
# - Generation at initialisation time:
#     generateoptionparser -n asQ -a P -f someFn -v myOpt_
#     eval 'someFn() {
#       '"$REPLY"'
#       if isset myOpt_Q; then ...etc...
#     }'
# - Manual operation by issuing the 'generateoptionparser' command in an
#   interactive shell and inserting the output into your shell function.
#
# --- begin license ---
# Copyright (c) 2018 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

generateoptionparser() {
	# This function needs its own option parser; following option parser
	# was generated by (an earlier version of) this very function.
	# The command to regenerate the following parser is:
	#	generateoptionparser -o -n 'o' -a 'fvna' -f 'generateoptionparser' -v '_Msh_gOPo_'
	#
	# ___Start of generated option parser____
	unset -v _Msh_gOPo_o _Msh_gOPo_f _Msh_gOPo_v _Msh_gOPo_n _Msh_gOPo_a
	forever do
		case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_gOPo__o=${1#-}
			shift
			forever do
				case ${_Msh_gOPo__o} in
				( '' )	break ;;
				# if the option requires an argument, split it and break out of loop
				# (it is always the last in a combined set)
				( [fvna]* )
					_Msh_gOPo__a=-${_Msh_gOPo__o%"${_Msh_gOPo__o#?}"}
					push _Msh_gOPo__a
					_Msh_gOPo__o=${_Msh_gOPo__o#?}
					if not str empty "${_Msh_gOPo__o}"; then
						_Msh_gOPo__a=${_Msh_gOPo__o}
						push _Msh_gOPo__a
					fi
					break ;;
				esac
				# split options that do not require arguments (and invalid options) until we run out
				_Msh_gOPo__a=-${_Msh_gOPo__o%"${_Msh_gOPo__o#?}"}
				push _Msh_gOPo__a
				_Msh_gOPo__o=${_Msh_gOPo__o#?}
			done
			while pop _Msh_gOPo__a; do
				set -- "${_Msh_gOPo__a}" "$@"
			done
			unset -v _Msh_gOPo__o _Msh_gOPo__a
			continue ;;
		( -[o] )
			eval "_Msh_gOPo_${1#-}=''" ;;
		( -[fvna] )
			let "$# > 1" || die "generateoptionparser: $1: option requires argument" || return
			eval "_Msh_gOPo_${1#-}=\$2"
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "generateoptionparser: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	# ^^^End of generated option parser^^^

	if isset _Msh_gOPo_v; then
		str isvarname "${_Msh_gOPo_v}" || die "generateoptionparser: invalid variable prefix: $2" || return
	else
		_Msh_gOPo_v=opt_
	fi
	if ! isset _Msh_gOPo_n && ! isset _Msh_gOPo_a; then
		die "generateoptionparser: at least one of -n and -a is required" || return
	fi
	case ${_Msh_gOPo_n-}${_Msh_gOPo_a-} in
	( *[!"$ASCIIALNUM"_]* )
		die "generateoptionparser: invalid options string(s): ${_Msh_gOPo_n-} ${_Msh_gOPo_a-}" || return
	esac
	case $# in
	( 0 )	_Msh_gOP_var=REPLY ;;
	( 1 )	str isvarname "$1" || die "generateoptionparser: invalid variable name: $1" || return
		_Msh_gOP_var=$1 ;;
	( * )	die "generateoptionparser: only 1 non-option argument allowed" || return ;;
	esac

	# generate 'unset -v' command to unset all option variables, while validating against repeated options
	_Msh_gOP_code="${CCt}unset -v"
	_Msh_gOPo_oLs=${_Msh_gOPo_n-}${_Msh_gOPo_a-}	# all option letters
	while :; do
		case ${_Msh_gOPo_oLs} in
		( '' )	break ;;
		( * )	_Msh_gOPo_oL=${_Msh_gOPo_oLs%"${_Msh_gOPo_oLs#?}"} # "
			_Msh_gOP_code=${_Msh_gOP_code}\ ${_Msh_gOPo_v}${_Msh_gOPo_oL}
			_Msh_gOPo_oLs=${_Msh_gOPo_oLs#?}
			case ${_Msh_gOPo_oLs} in
			( *"${_Msh_gOPo_oL}"* )
				die "generateoptionparser: repeated option letter: ${_Msh_gOPo_oL}" || return ;;
			esac ;;
		esac
	done

	# Generate code to start loop and split any sets of combined options.
	if isset _Msh_gOPo_a; then
		# The last option in a combined set may have a tacked-on argument. This means we must work from left
		# to right, pushing arguments on the stack; this makes it possible to add them back to the left of
		# the positional parameters in reverse order, so everything ends up in the correct order in the end.
		_Msh_gOP_code="${_Msh_gOP_code}
	forever do
		case \${1-} in
		( -[!-]?* ) # split a set of combined options
			${_Msh_gOPo_v}_o=\${1#-}
			shift
			forever do
				case \${${_Msh_gOPo_v}_o} in
				( '' )	break ;;
				# if the option requires an argument, split it and break out of loop
				# (it is always the last in a combined set)
				( [${_Msh_gOPo_a}]* )
					${_Msh_gOPo_v}_a=-\${${_Msh_gOPo_v}_o%\"\${${_Msh_gOPo_v}_o#?}\"}
					push ${_Msh_gOPo_v}_a
					${_Msh_gOPo_v}_o=\${${_Msh_gOPo_v}_o#?}
					if not str empty \"\${${_Msh_gOPo_v}_o}\"; then
						${_Msh_gOPo_v}_a=\${${_Msh_gOPo_v}_o}
						push ${_Msh_gOPo_v}_a
					fi
					break ;;
				esac
				# split options that do not require arguments (and invalid options) until we run out
				${_Msh_gOPo_v}_a=-\${${_Msh_gOPo_v}_o%\"\${${_Msh_gOPo_v}_o#?}\"}
				push ${_Msh_gOPo_v}_a
				${_Msh_gOPo_v}_o=\${${_Msh_gOPo_v}_o#?}
			done
			while pop ${_Msh_gOPo_v}_a; do
				set -- \"\${${_Msh_gOPo_v}_a}\" \"\$@\"
			done
			unset -v ${_Msh_gOPo_v}_o ${_Msh_gOPo_v}_a
			continue ;;"
	else
		# Since there are no combined options with arguments, we can split them by working from right to
		# left, which is much easier.
		_Msh_gOP_code="${_Msh_gOP_code}
	forever do
		case \${1-} in
		( -[!-]?* ) # split a set of combined options
			${_Msh_gOPo_v}_o=\${1#-}
			shift
			while not str empty \"\${${_Msh_gOPo_v}_o}\"; do
				set -- \"-\${${_Msh_gOPo_v}_o#\"\${${_Msh_gOPo_v}_o%?}\"}\" \"\$@\"	#\"
				${_Msh_gOPo_v}_o=\${${_Msh_gOPo_v}_o%?}
			done
			unset -v ${_Msh_gOPo_v}_o
			continue ;;"
	fi

	if isset _Msh_gOPo_n; then
		_Msh_gOP_code="${_Msh_gOP_code}
		( -[${_Msh_gOPo_n}] )
			eval \"${_Msh_gOPo_v}\${1#-}=''\" ;;"
	fi

	if isset _Msh_gOPo_a; then
		_Msh_gOP_code="${_Msh_gOP_code}
		( -[${_Msh_gOPo_a}] )
			let \"\$# > 1\" || die \"${_Msh_gOPo_f+$_Msh_gOPo_f: }\$1: option requires argument\" || return
			eval \"${_Msh_gOPo_v}\${1#-}=\\\$2\"
			shift ;;"
	fi

	_Msh_gOP_code="${_Msh_gOP_code}
		( -- )	shift; break ;;
		( -* )	die \"${_Msh_gOPo_f+$_Msh_gOPo_f: }invalid option: \$1\" || return ;;
		( * )	break ;;
		esac
		shift
	done"

	eval "${_Msh_gOP_var}=\${_Msh_gOP_code}\${CCn}"
	if isset _Msh_gOPo_o; then
		putln "${_Msh_gOP_code}"
		unset -v _Msh_gOPo_o
	fi
	unset -v _Msh_gOPo_oLs _Msh_gOPo_oL _Msh_gOP_var \
		_Msh_gOP_code _Msh_gOPo_f _Msh_gOPo_n _Msh_gOPo_v _Msh_gOPo_a
}
