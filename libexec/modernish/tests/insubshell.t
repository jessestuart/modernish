#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Test the insubshell() function that checks if we're in a subshell or not.
# This includes background job subshells.
#
# The correct functioning of insubshell() is essential for die(), harden(),
# the trap stack, and mktemp().

doTest1() {
	title='main shell'
	not insubshell
}

doTest2() {
	title='regular subshell'
	( : 1>&1; insubshell )
}

doTest3() {
	title='command substitution subshell'
	return $( : 1>&1; insubshell; put $? )
	#	  ^^^^^^ on ksh93, this causes a forking subshell and resets ${.sh.subshell}; test if insubshell() handles this
}

doTest4() {
	title='background job subshell'
	test4file=$testdir/insubshell-test4
	# launch test background job
	( : 1>&1; umask 077; { insubshell && putln ok || putln NO; } >|$test4file ) &
	wait "$!"
	read result <$test4file
	identic $result ok
}

doTest5() {
	title='last element of pipe is subshell?'
	# This tests if insubshell() results are consistent with LEPIPEMAIN
	# feature detection results.
	: | insubshell
	e=$?
	if thisshellhas LEPIPEMAIN; then
		okmsg="it's not: LEPIPEMAIN"
		failmsg="it is, in spite of LEPIPEMAIN"
		eq e 1
	else
		okmsg="it is"
		failmsg="it's not, though no LEPIPEMAIN"
		eq e 0
	fi
}

doTest6() {
	title='get shell PID (main shell)'
	if insubshell -p || not identic $REPLY $$; then
		failmsg="$REPLY != $$"
		return 1
	fi
	isint $REPLY && okmsg=$REPLY
}

doTest7() {
	title='get shell PID (subshell)'
	okmsg=$(insubshell -p && put $REPLY)
	if identic $okmsg $$; then
		okmsg=$okmsg' (no fork!)'
	else
		isint $okmsg
	fi
}

doTest8() {
	title='get shell PID (background subshell)'
	okmsg=$( : 1>&1; if insubshell -p; then put $REPLY; fi & wait)
	if not isint $okmsg || identic $okmsg $$; then
		failmsg=$okmsg
		return 1
	fi
}

doTest9() {
	title='get shell PID (subshell of bg subshell)'
	okmsg=$( : 1>&1;
		(if	insubshell -p && put $REPLY
			put /
			mypid=$(insubshell -p && put $REPLY)
		then	put $mypid
		fi) & wait
		)
	if not isint ${okmsg#*/} || not isint ${okmsg%/*}; then
		failmsg=$okmsg
		return 1
	fi
	if identic ${okmsg#*/} ${okmsg%/*}; then
		okmsg=$okmsg' (no fork!)'
	fi
}

doTest10() {
	title='insubshell -u (regular subshell)'
	insubshell -u && return 1
	v=$REPLY
	(
		insubshell -u || exit 1
		not identic $REPLY $v
	)
}

doTest11() {
	title='insubshell -u (background subshell)'
	insubshell -u && return 1
	v=$REPLY
	(
		insubshell -u || exit 1
		not identic $REPLY $v
	) & wait "$!"
}

doTest12() {
	title='insubshell -u (subshell of bg subshell)'
	(
		insubshell -u || exit 1
		v=$REPLY
		(
			insubshell -u || exit 1
			not identic $REPLY $v
		)
		eq $? 0	# extra command needed to defeat an optimisation on some shells;
			# without it, the previous subshell parentheses may be ignored
	) & wait "$!"
}

lastTest=12
