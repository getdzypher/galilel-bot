#!@BASH@
#
# galilel-bot -- discord notification block for galilel coin daemon.
#
# Copyright (c) 2018 Maik Broemme <mbroemme@libmpq.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# exit immediately if command fails, use exit code of righmost pipeline.
set -eo pipefail

# global variables with process information.
export GALILEL_BOT_PROCESS="$(@BASENAME@ "${0}")"
export GALILEL_BOT_VERSION="@GALILEL_BOT_VERSION@"
export GALILEL_BOT_AUTHOR="@GALILEL_BOT_AUTHOR@"

# global variables with sane defaults.
declare -g GLOBAL__parameter_test="disabled"

# @_galilel_bot__printf()
#
# @_${1}: text string
#
# this function shows something on stdout ;)
function galilel_bot__printf() {

	# move out first argument.
	shift

	# echo to stdout.
	echo -e "${@}"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__show_help()
#
# this function shows the command line help.
function galilel_bot__show_help() {

	# show the help.
	galilel_bot__printf LOG_INFO "Usage: ${GALILEL_BOT_PROCESS} [OPTION]..."
	galilel_bot__printf LOG_INFO "${GALILEL_BOT_PROCESS} - send wallet and block notifications to discord."
	galilel_bot__printf LOG_INFO ""
	galilel_bot__printf LOG_INFO "Common arguments:"
	galilel_bot__printf LOG_INFO ""
	galilel_bot__printf LOG_INFO "  -h, --help            shows this help screen"
	galilel_bot__printf LOG_INFO "  -v, --version         shows the version information"
	galilel_bot__printf LOG_INFO "      --test            shows notification on console rather than in discord"
	galilel_bot__printf LOG_INFO ""
	galilel_bot__printf LOG_INFO "Notification arguments:"
	galilel_bot__printf LOG_INFO ""
	galilel_bot__printf LOG_INFO "      --notify-wallet   <ticker> <transaction id>"
	galilel_bot__printf LOG_INFO "                        discord notification about new transaction for address"
	galilel_bot__printf LOG_INFO "      --notify-block    <ticker> <blockhash>"
	galilel_bot__printf LOG_INFO "                        discord notification about new block on the network"
	galilel_bot__printf LOG_INFO ""
	galilel_bot__printf LOG_INFO "Please report bugs to the appropriate authors, which can be found in the"
	galilel_bot__printf LOG_INFO "version information."

	# if no error was found, return with successful status.
	return 2
}

# @_galilel_bot__get_switches()
#
# this function shows the command line version.
function galilel_bot__show_version() {

	# show the main script version.
	galilel_bot__printf LOG_INFO "${GALILEL_BOT_PROCESS} ${GALILEL_BOT_VERSION} ${GALILEL_BOT_RELEASE}"
	galilel_bot__printf LOG_INFO "Written by ${GALILEL_BOT_AUTHOR}"
	galilel_bot__printf LOG_INFO ""
	galilel_bot__printf LOG_INFO "This is free software; see the source for copying conditions. There is NO"
	galilel_bot__printf LOG_INFO "warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."

	# if no error was found, return with successful status.
	return 2
}

# @_galilel_bot__notification_wallet()
#
# @_${1}: coin ticker
# @_${2}: transaction id
#
# this function sends message to discord on monitored wallet address changes.
function galilel_bot__notification_wallet() {

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__notification_block()
#
# @_${1}: coin ticker
# @_${2}: blockhash
#
# this function sends message to discord on block changes in the network.
function galilel_bot__notification_block() {

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__get_switches()
#
# this function parse the switches of the command line.
function galilel_bot__get_switches() {

	# first check if no parameter was given.
	[ "${#}" == "0" ] && {
		galilel_bot__printf LOG_INFO "${GALILEL_BOT_PROCESS}: no option given"
		galilel_bot__printf LOG_INFO "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

		# return if we found nothing.
		return 1
	}

	# first parse command line for switches and flags.
	for LOOP__argument in "${@}" ; do
		case "${LOOP__argument}" in
			-h|--help)
				galilel_bot__show_help || return "${?}"
			;;      
			-v|--version)
				galilel_bot__show_version || return "${?}"
			;;
			--test)
				declare -g GLOBAL__parameter_test="enabled"
			;;
			*)
				continue
			;;
		esac
	done

	# second parse command line for notifications.
	while [ "${#}" -gt "0" ] ; do
		case "${1}" in
			-h|--help)
				shift
				continue
			;;      
			-v|--version)
				shift
				continue
			;;
			--test)
				shift
				continue
			;;
			--notify-wallet)

				# check if we miss some parameter.
				[ -z "${3}" ] && {

					# show the help for the missing parameter.
					galilel_bot__printf LOG_INFO "${GALILEL_BOT_PROCESS}: option \`${1}' requires 2 arguments"
					galilel_bot__printf LOG_INFO "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

					# return if we missed some parameter.
					return 1
				}

				# wallet notification.
				galilel_bot__notification_wallet "${2}" "${3}" || return "${?}"

				# clear variables.
				shift 3
			;;
			--notify-block)

				# check if we miss some parameter.
				[ -z "${3}" ] && {

					# show the help for the missing parameter.
					galilel_bot__printf LOG_INFO "${GALILEL_BOT_PROCESS}: option \`${1}' requires 2 arguments"
					galilel_bot__printf LOG_INFO "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

					# return if we missed some parameter.
					return 1
				}

				# wallet notification.
				galilel_bot__notification_block "${2}" "${3}" || return "${?}"

				# clear variables.
				shift 3
			;;
			*)

				# show the help for an unknown option.
				galilel_bot__printf LOG_INFO "${GALILEL_BOT_PROCESS}: unrecognized option \`${1}'"
				galilel_bot__printf LOG_INFO "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

				# return if we found some unknown option.
				return 1

				# clear variables.
				shift
			;;
		esac

		# skip to next parameter.
		shift
	done

	# if no error was found, return zero.
	return 0
}

# main() starts here.
{
	galilel_bot__get_switches "${@}"
}

# parse return code.
case "${?}" in
	1)

		# general error.
		exit 1
	;;
	2)

		# showed help or version.
		exit 0
	;;
	*)

		# unknown error.
		exit "${?}"
	;;
esac
