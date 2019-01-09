#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Test the insubshell() function that checks if we're in a subshell or not.
# This includes background job subshells.
#
# The correct functioning of insubshell() is essential for die(), harden(),
# the trap stack, and mktemp().

TEST title='main shell'
	not insubshell
ENDT

TEST title='regular subshell'
	( : 1>&1; insubshell )
ENDT

TEST title='command substitution subshell'
	return $( : 1>&1; insubshell; put $? )
	#	  ^^^^^^ on ksh93, this causes a forking subshell and resets ${.sh.subshell}; test if insubshell() handles this
ENDT

TEST title='background job subshell'
	test4file=$testdir/insubshell-test4
	# launch test background job
	( : 1>&1; umask 077; { insubshell && putln ok || putln NO; } >|$test4file ) &
	wait "$!"
	read result <$test4file
	str id $result ok
ENDT

TEST title='last element of pipe is subshell?'
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
ENDT

TEST title='get shell PID (main shell)'
	if insubshell -p || not str id $REPLY $$; then
		failmsg="$REPLY != $$"
		return 1
	fi
	str isint $REPLY && okmsg=$REPLY
ENDT

TEST title='get shell PID (subshell)'
	okmsg=$(insubshell -p && put $REPLY)
	if str id $okmsg $$; then
		okmsg=$okmsg' (no fork!)'
	else
		str isint $okmsg
	fi
ENDT

TEST title='get shell PID (background subshell)'
	okmsg=$( : 1>&1; if insubshell -p; then put $REPLY; fi & wait)
	if not str isint $okmsg || str id $okmsg $$; then
		failmsg=$okmsg
		return 1
	fi
ENDT

TEST title='get shell PID (subshell of bg subshell)'
	okmsg=$( : 1>&1;
		(if	insubshell -p && put $REPLY
			put /
			mypid=$(insubshell -p && put $REPLY)
		then	put $mypid
		fi) & wait
		)
	if not str isint ${okmsg#*/} || not str isint ${okmsg%/*}; then
		failmsg=$okmsg
		return 1
	fi
	if str id ${okmsg#*/} ${okmsg%/*}; then
		okmsg=$okmsg' (no fork!)'
	fi
ENDT

TEST title='insubshell -u (regular subshell)'
	insubshell -u && return 1
	v=$REPLY
	(
		insubshell -u || exit 1
		not str id $REPLY $v
	)
ENDT

TEST title='insubshell -u (background subshell)'
	insubshell -u && return 1
	v=$REPLY
	(
		insubshell -u || exit 1
		not str id $REPLY $v
	) & wait "$!"
ENDT

TEST title='insubshell -u (subshell of bg subshell)'
	(
		insubshell -u || exit 1
		v=$REPLY
		(
			insubshell -u || exit 1
			not str id $REPLY $v
		)
		eq $? 0	# extra command needed to defeat an optimisation on some shells;
			# without it, the previous subshell parentheses may be ignored
	) & wait "$!"
ENDT
