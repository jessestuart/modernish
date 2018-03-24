#! test/for/moderni/sh
# -*- mode: sh; -*-
# See the file LICENSE in the main modernish directory for the licence.

# Sanity checks to verify correct modernish initialisation.

doTest1() {
	title='availability of POSIX utils in $DEFPATH'
	# Modernish and its main modules depend on these POSIX utilities
	# to be installed in $(getconf PATH).
	# TODO: periodically update
	push IFS PATH cmd p
	IFS=:
	PATH=$DEFPATH
	for cmd in \
		[ \
		awk \
		bc \
		cat \
		dd \
		echo \
		expr \
		fold \
		grep \
		iconv \
		id \
		kill \
		ls \
		mkdir \
		nl \
		paste \
		printf \
		ps \
		rm \
		sed \
		sh \
		sort \
		stty \
		test \
		tput \
		tr \
		wc
	do
		for p in $DEFPATH; do
			can exec $p/$cmd && continue 2
		done
		xfailmsg=${xfailmsg:+${xfailmsg}, }\'$cmd\'
	done
	pop IFS PATH cmd p
	if isset xfailmsg; then
		if eq opt_q 2; then
			# We xfail rather than fail because it's not a bug in modernish or the shell. However,
			# if we're testing in extra-quiet mode, we might be running from install.sh. The xfails
			# are not displayed, but we still really want to warn the user about missing utilities.
			contains $xfailmsg ',' && v=utilities || v=utility
			putln "  ${tBold}WARNING:${tReset} Standard $v missing in $DEFPATH: ${tRed}${xfailmsg}${tReset}"
		fi
		xfailmsg="missing: $xfailmsg"
		return 2
	fi
}

doTest2() {
	title='control character constants'
	# These are now initialised quickly by including their control
	# character values directly in bin/modernish. Most editors handle
	# this gracefully, but check here that no corruption has occurred by
	# comparing it with 'printf' output.
	# The following implicitly tests the correctness of $CC01..$CC1F,$CC7F
	# as well, because these are all concatenated in $CONTROLCHARS.
	identic $CONTROLCHARS \
		$(PATH=$DEFPATH command printf \
			'\1\2\3\4\5\6\7\10\11\12\13\14\15\16\17\20\21\22\23\24\25\26\27\30\31\32\33\34\35\36\37\177')
}

doTest3() {
	title='check for fatal bug/quirk combinations'
	# Modernish currently does not cope well with these combinations of shell bugs and quirks.
	# No supported shell is known to have both, so we don't have the necessary workarounds. But
	# it's worth checking here, as these combinations could occur in the future. If they ever
	# do, the comments below should help search the code for problems in need of a workaround.

	if thisshellhas BUG_FNSUBSH QRK_EXECFNBI; then
		# If we cannot unset a shell function (e.g. hardened 'mkdir') within a subshell,
		# *and* we're trying to 'exec mkdir' from a subshell while bypassing that shell
		# function, with this combination that would be impossible. The only workarounds left
		# would be to pre-determine and store the absolute path and then 'exec' that, or to
		# abandon the use of 'exec' and put up with forking unnecessary extra processes.
		failmsg="${failmsg:+${failmsg}; }BUG_FNSUBSH+QRK_EXECFNBI"
	fi

	# TODO: think of other fatal shell bug/quirk combinations and add them above

	not isset failmsg
}

doTest4() {
	title="'unset' quietly accepts nonexistent item"
	# for zsh, we set a wrapper unset() for this in bin/modernish
	# so that 'unset -f foo' stops complaining if there is no foo().
	unset -v _Msh_nonexistent_variable &&
	unset -f _Msh_nonexistent_function ||
	return 1
}

lastTest=4
