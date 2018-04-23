#! /shell/capability/test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# KSHARRAY: ksh88-style shell arrays (also on bash, and zsh under 'emulate sh')
# Note: this feature does not include mass assignment. See KSHARASGN.

# For shells without KSHARRAY, an array assignment looks like a command name.
# With KSHARRAY, a normal variable is identical to the fist element (0) of
# the array by the same name.
(	_Msh_test=
	PATH=/dev/null
	_Msh_test[0]=yes
	identic "${_Msh_test}" yes
) 2>/dev/null || return 1
