#!/bin/bash

#Used variables: May be set outside
#SSH_AGENT_REUSE[=true]
#SSH_AGENT_REUSE_MUST_BE_SOURCED[=true] - By default, when script is runned as regular user, we have not any
#	chance export variables into parent scope. So, this variable should be true in most of cases.
#	BTW, if all this scrip set as alias(sic!), it may be set to false!

	if [[ ${SSH_AGENT_REUSE_MUST_BE_SOURCED=true} && $SECONDS -lt 2 ]]; then
	echo "This script must be sourced ('. $0') instead of simple run. Exiting."
	echo 'Just use next command to do it:'
	echo . $0
	exit
	fi

SSH_AUTH_SOCK=''

#SSH_AUTH_SOCK=$( ls /tmp/ssh-*/agent.* 2>/dev/null )
#SSH_AUTH_SOCK=$( find /tmp -wholename '/tmp/ssh-*/agent.*' -user `id -u` 2>/dev/null )
find /tmp -wholename '/tmp/ssh-*/agent.*' -user `id -u` 2>/dev/null | (	# About "(" Read http://bappoy.pp.ru/2008/12/18/bash-pitfalls-part02.html item #7 why we need it!!!
															# We need set SSH_AUTH_SOCK in while-cycle.
	while read socket ; do # Check all, cleanup dead
	agent_pid=$[ ${socket##*.} + 1 ] # I don't known why +1 needed!
	#D echo socket=$socket
	#D echo agent_pid=$agent_pid #Agent PID
		#Check PID ( http://linsovet.com/check-pid-with-kill )
		if ! kill -0 $agent_pid 2>/dev/null || [ $( ps -p $agent_pid -o comm= ) != "ssh-agent" ] ; then
		#D echo 'Process dead! Cleanup it.'
		rm "$socket"
		else
		#D echo 'Finded'
		SSH_AUTH_SOCK="$socket"
		break; # First occurancies
		fi
	done

	if [[ ! "$SSH_AUTH_SOCK" && ${SSH_AGENT_REUSE=true} != false ]]; then
	#D echo 'Start new ssh-agent'
	eval `/usr/bin/ssh-agent -s | grep SSH_AUTH_SOCK`
	fi

	if [ ! $SSH_AGENT_REUSE_MUST_BE_SOURCED ]; then #For aliasing
	echo "SSH_AUTH_SOCK="$SSH_AUTH_SOCK"; export SSH_AUTH_SOCK"
	else
	export SSH_AUTH_SOCK
	fi
)