#!@BASH@
#
# galilel-bot -- discord notification bot for galilel coin daemon.
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

# global variables with process information.
export GALILEL_BOT_PROCESS="${0##*/}"
export GALILEL_BOT_VERSION="@GALILEL_BOT_VERSION@"
export GALILEL_BOT_AUTHOR="@GALILEL_BOT_AUTHOR@"

# global variables with sane defaults.
declare -g GLOBAL__parameter_debug="disabled"
declare -g GLOBAL__parameter_test="disabled"
declare -g GLOBAL__parameter_conffile="@SYSCONFDIR@/galilel/galilel-bot.conf"

# global variables filled from configuration file.
declare -g GLOBAL__parameter_logfile
declare -a GLOBAL__parameter_configs
declare -g GLOBAL__parameter_wallet_webhook_id
declare -g GLOBAL__parameter_wallet_webhook_token
declare -g GLOBAL__parameter_block_webhook_id
declare -g GLOBAL__parameter_block_webhook_token

# @_galilel_bot__printf()
#
# @_${1}: log level
# @_${@}: text string(s)
#
# this function shows something on stdout and logs into a file.
function galilel_bot__printf() {

	# local variables.
	local LOCAL__level="${1}"

	# shift variable.
	shift

	# check output level.
	case "${LOCAL__level}" in
		HELP)
			echo -e "${@}"
		;;
		INFO)

			# check override options.
			case "${GLOBAL__parameter_debug}" in
				enabled)
					echo -e "${FUNCNAME[1]##*__}() ${@}"
				;;
				disabled)
					echo -e "${@}"
				;;
			esac

			# check if we should write to logfile.
			[ -n "${GLOBAL__parameter_logfile}" ] && {
				echo -e "$(@DATE@ '+%b %e %H:%M:%S')" "${HOSTNAME}" "${GALILEL_BOT_PROCESS}[$$]:" "${FUNCNAME[1]##*__}() ${@}" >> "${GLOBAL__parameter_logfile}"
			}
		;;
		FILE)

			# check if we should write to logfile.
			[ -n "${GLOBAL__parameter_logfile}" ] && {
				echo -e "$(@DATE@ '+%b %e %H:%M:%S')" "${HOSTNAME}" "${GALILEL_BOT_PROCESS}[$$]:" "${FUNCNAME[1]##*__}() ${@}" >> "${GLOBAL__parameter_logfile}"
			}
		;;
	esac

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__show_help()
#
# this function shows the command line help.
function galilel_bot__show_help() {

	# show the help.
	galilel_bot__printf HELP "Usage: ${GALILEL_BOT_PROCESS} [OPTION]..."
	galilel_bot__printf HELP "${GALILEL_BOT_PROCESS} - send wallet and block notifications to discord."
	galilel_bot__printf HELP ""
	galilel_bot__printf HELP "Common arguments:"
	galilel_bot__printf HELP ""
	galilel_bot__printf HELP "  -h, --help      show this help screen"
	galilel_bot__printf HELP "  -v, --version   show version  and exit"
	galilel_bot__printf HELP "      --conf      <filename>"
	galilel_bot__printf HELP "                  set configuration file (default: ${GLOBAL__parameter_conffile})"
	galilel_bot__printf HELP "      --debug     set debug to enabled"
	galilel_bot__printf HELP "      --test      test notification on console rather than in discord"
	galilel_bot__printf HELP ""
	galilel_bot__printf HELP "Notification arguments:"
	galilel_bot__printf HELP ""
	galilel_bot__printf HELP "      --notify-wallet   <ticker> <transaction id>"
	galilel_bot__printf HELP "                        discord notification about new transaction for address"
	galilel_bot__printf HELP "      --notify-block    <ticker> <blockhash>"
	galilel_bot__printf HELP "                        discord notification about new block on the network"
	galilel_bot__printf HELP ""
	galilel_bot__printf HELP "Please report bugs to the appropriate authors, which can be found in the"
	galilel_bot__printf HELP "version information."

	# if no error was found, return with successful status.
	return 2
}

# @_galilel_bot__get_switches()
#
# this function shows the command line version.
function galilel_bot__show_version() {

	# show the main script version.
	galilel_bot__printf HELP "${GALILEL_BOT_PROCESS} ${GALILEL_BOT_VERSION} ${GALILEL_BOT_RELEASE}"
	galilel_bot__printf HELP "Written by ${GALILEL_BOT_AUTHOR}"
	galilel_bot__printf HELP ""
	galilel_bot__printf HELP "This is free software; see the source for copying conditions. There is NO"
	galilel_bot__printf HELP "warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE."

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

	# local variables.
	local LOCAL__coin="${1}"
	local LOCAL__transactionid="${2}"

	# loop through the configuration array.
	local LOCAL__index
	for (( LOCAL__index = 0; LOCAL__index < "${#GLOBAL__parameter_configs[@]}" ; LOCAL__index++ )) ; do

		# read data into variables.
		IFS=':' read LOCAL__ticker LOCAL__username LOCAL__password LOCAL__ip LOCAL__port LOCAL__address <<< "${GLOBAL__parameter_configs[${LOCAL__index}]}"

		# check if correct ticker.
		[ "${LOCAL__coin}" != "${LOCAL__ticker}" ] && {

			# wrong ticker, so continue.
			continue
		}

		# check if we found a pos block (staking).
		@CURL@ \
			--request POST \
			--max-time 5 \
			--silent \
			--fail \
			--header 'content-type: text/plain;' \
			--data-binary '{ "jsonrpc" : "1.0", "id" : "curltest", "method" : "gettransaction", "params" : [ "'"${LOCAL__transactionid}"'" ] }' \
			--user "${LOCAL__username}:${LOCAL__password}" \
			"http://${LOCAL__ip}:${LOCAL__port}/" |
		while read LOCAL__line ; do

			# get transaction information.
			local LOCAL__generated="$(@JSHON@ -Q -e result -e generated -u <<< "${LOCAL__line}")"
			local LOCAL__amount="$(@JSHON@ -Q -e result -e amount -u <<< "${LOCAL__line}")"
			local LOCAL__fee="$(@JSHON@ -Q -e result -e fee -u <<< "${LOCAL__line}")"

			# check if the block was generated.
			[ "${LOCAL__generated}" == "true" ] && {
				echo "LOCAL__amount: ${LOCAL__amount}"
				echo "LOCAL__fee: ${LOCAL__fee}"

				# calculate reward.
				local LOCAL__reward="$(echo "${LOCAL__fee}" + "${LOCAL__amount}" | @BC@)"
				local LOCAL__reward="$(printf "%.5f" "${LOCAL__reward}")"

				# get donation wallet balance.
				@CURL@ \
					--request POST \
					--max-time 5 \
					--silent \
					--fail \
					--header 'content-type: text/plain;' \
					--data-binary '{ "jsonrpc" : "1.0", "id" : "curltest", "method" : "getbalance", "params" : [ ] }' \
					--user "${LOCAL__username}:${LOCAL__password}" \
					"http://${LOCAL__ip}:${LOCAL__port}/" |
				while read LOCAL__line ; do

					# get balance information.
					local LOCAL__balance="$(@JSHON@ -Q -e result -u <<< "${LOCAL__line}")"
					local LOCAL__balance="$(printf "%.5f" "${LOCAL__balance}")"

					# check if in test mode.
					[ "${GLOBAL__parameter_test}" == "enabled" ] && {
						galilel_bot__printf INFO "Received staking reward **'"${LOCAL__reward}"'** '"${LOCAL__coin}"' with new balance of **'"${LOCAL__balance}"'** '"${LOCAL__coin}"'"
					}

					# check if in production mode.
					[ "${GLOBAL__parameter_test}" == "disabled" ] && {
						galilel_bot__printf FILE "Received staking reward **'"${LOCAL__reward}"'** '"${LOCAL__coin}"' with new balance of **'"${LOCAL__balance}"'** '"${LOCAL__coin}"'"

						# push block notification to discord.
						/usr/bin/curl \
							--request POST \
							--max-time 5 \
							--silent \
							--fail \
							--header 'content-Type: application/json' \
							--data-binary '{ "content" : "Received staking reward **'"${LOCAL__reward}"'** '"${LOCAL__coin}"' with new balance of **'"${LOCAL__balance}"'** '"${LOCAL__coin}"'" }' \
							"https://discordapp.com/api/webhooks/${GLOBAL__parameter_wallet_webhook_id}/${GLOBAL__parameter_wallet_webhook_token}"
					}
				done

				# check pipe status of curl command.
				case "${PIPESTATUS[0]}" in
					7)

						# connection error.
						galilel_bot__printf INFO "${GALILEL_BOT_PROCESS}: failed to connect to galilel RPC wallet"

						# return error.
						return 7
					;;
					22)

						# http protocol error.
						galilel_bot__printf INFO "${GALILEL_BOT_PROCESS}: failed to retrieve url from RPC wallet"

						# return error.
						return 22
					;;
				esac
			}
		done

		# check pipe status of curl command.
		case "${PIPESTATUS[0]}" in
			7)

				# connection error.
				galilel_bot__printf INFO "${GALILEL_BOT_PROCESS}: failed to connect to galilel RPC wallet"

				# return error.
				return 7
			;;
			22)

				# http protocol error.
				galilel_bot__printf INFO "${GALILEL_BOT_PROCESS}: failed to retrieve url from RPC wallet"

				# return error.
				return 22
			;;
		esac
	done

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

	# local variables.
	local LOCAL__coin="${1}"
	local LOCAL__blockhash="${2}"

	# loop through the configuration array.
	local LOCAL__index
	for (( LOCAL__index = 0; LOCAL__index < "${#GLOBAL__parameter_configs[@]}" ; LOCAL__index++ )) ; do

		# read data into variables.
		IFS=':' read LOCAL__ticker LOCAL__username LOCAL__password LOCAL__ip LOCAL__port LOCAL__address <<< "${GLOBAL__parameter_configs[${LOCAL__index}]}"

		# check if correct ticker.
		[ "${LOCAL__coin}" != "${LOCAL__ticker}" ] && {

			# wrong ticker, so continue.
			continue
		}

		# fetch block information.
		@CURL@ \
			--request POST \
			--max-time 5 \
			--silent \
			--fail \
			--header 'content-type: text/plain;' \
			--data-binary '{ "jsonrpc" : "1.0", "id" : "curltest", "method" : "getblock", "params" : [ "'"${LOCAL__blockhash}"'" ] }' \
			--user "${LOCAL__username}:${LOCAL__password}" \
			"http://${LOCAL__ip}:${LOCAL__port}/" |
		while read LOCAL__line ; do

			# get block information.
			local LOCAL__height="$(@JSHON@ -Q -e result -e height -u <<< "${LOCAL__line}")"
			local LOCAL__difficulty="$(@JSHON@ -Q -e result -e difficulty -u <<< "${LOCAL__line}")"
			local LOCAL__time="$(@JSHON@ -Q -e result -e time -u <<< "${LOCAL__line}")"

			# get current date.
			local LOCAL__date="$(@DATE@ --date "@${LOCAL__time}")"

			# format variables.
			local LOCAL__difficulty="$(printf "%.2f" "${LOCAL__difficulty}")"

			# check if in test mode.
			[ "${GLOBAL__parameter_test}" == "enabled" ] && {
				galilel_bot__printf INFO "New block **'"${LOCAL__height}"'** at **'"${LOCAL__date}"'** with difficulty **'"${LOCAL__difficulty}"'**"
			}

			# check if in production mode.
			[ "${GLOBAL__parameter_test}" == "disabled" ] && {
				galilel_bot__printf FILE "New block **'"${LOCAL__height}"'** at **'"${LOCAL__date}"'** with difficulty **'"${LOCAL__difficulty}"'**"

				# push block notification to discord.
				/usr/bin/curl \
					--request POST \
					--max-time 5 \
					--silent \
					--fail \
					--header 'content-Type: application/json' \
					--data-binary '{ "content" : "New block **'"${LOCAL__height}"'** at **'"${LOCAL__date}"'** with difficulty **'"${LOCAL__difficulty}"'**" }' \
					"https://discordapp.com/api/webhooks/${GLOBAL__parameter_block_webhook_id}/${GLOBAL__parameter_block_webhook_token}"
			}
		done

		# check pipe status of curl command.
		case "${PIPESTATUS[0]}" in
			7)

				# connection error.
				galilel_bot__printf INFO "${GALILEL_BOT_PROCESS}: failed to connect to galilel RPC wallet"

				# return error.
				return 7
			;;
			22)

				# http protocol error.
				galilel_bot__printf INFO "${GALILEL_BOT_PROCESS}: failed to retrieve url from RPC wallet"

				# return error.
				return 22
			;;
		esac
	done

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__init()
#
# this function initializes the application and does various permission checks.
function galilel_bot__init() {

	# check if configuration file is readable.
	[ ! -r "${GLOBAL__parameter_conffile}" ] && {
		galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: configuration file ${GLOBAL__parameter_conffile} is not readable"

		# exit with error.
		exit 1
	}

	# load configuration file.
	source "${GLOBAL__parameter_conffile}"

	# move config options to global variables.
	GLOBAL__parameter_logfile="${LOGFILE}"
	GLOBAL__parameter_configs=("${COIN_CONFIGS[@]}")
	GLOBAL__parameter_wallet_webhook_id="${DISCORD_WALLET_WEBHOOK_ID}"
	GLOBAL__parameter_wallet_webhook_token="${DISCORD_WALLET_WEBHOOK_TOKEN}"
	GLOBAL__parameter_block_webhook_id="${DISCORD_BLOCK_WEBHOOK_ID}"
	GLOBAL__parameter_block_webhook_token="${DISCORD_BLOCK_WEBHOOK_TOKEN}"

	# check if logfile is enabled, directory and file is writable.
	[ -n "${GLOBAL__parameter_logfile}" ] && {
		[ ! -w "${GLOBAL__parameter_logfile%/*}" ] && {
			galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: logfile directory ${GLOBAL__parameter_logfile%/*} is not writable"

			# return with error.
			return 1
		}
		[ -e "${GLOBAL__parameter_logfile}" ] && [ ! -w "${GLOBAL__parameter_logfile}" ] && {
			galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: logfile ${GLOBAL__parameter_logfile} is not writable"

			# return with error.
			return 1
		}
	}

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__main()
#
# @_${@}: command line parameters.
#
# this function parse the command line and initializes the bot.
function galilel_bot__main() {

	# local variables.
	local -a LOCAL__parameters=("${@}")

	# check if no parameter was given.
	[ "${#LOCAL__parameters[@]}" == "0" ] && {
		galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: no option given"
		galilel_bot__printf HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

		# return if we found nothing.
		return 1
	}

	# first parse command line for switches for help and version.
	for LOOP__index in "${!LOCAL__parameters[@]}" ; do
		case "${LOCAL__parameters[${LOOP__index}]}" in
			-h|--help)
				galilel_bot__show_help || return "${?}"
			;;
			-v|--version)
				galilel_bot__show_version || return "${?}"
			;;
			*)
				continue
			;;
		esac
	done

	# second parse command line for custom config file.
	for LOOP__index in "${!LOCAL__parameters[@]}" ; do
		case "${LOCAL__parameters[${LOOP__index}]}" in
			--conf)

				# variables.
				local LOCAL__parameter_0="${LOCAL__parameters[${LOOP__index}]}"
				local LOCAL__parameter_1="${LOCAL__parameters[$(( ${LOOP__index} + 1))]}"

				# check if we miss some parameter.
				[ -z "${LOCAL__parameter_1}" ] && {

					# show the help for the missing parameter.
					galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: option \`${LOCAL__parameter_0}' requires 1 argument"
					galilel_bot__printf HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

					# return if we missed some parameter.
					return 1
				}

				# unset array items.
				unset LOCAL__parameters[${LOOP__index}]
				unset LOCAL__parameters[$(( ${LOOP__index} + 1))]

				# put custom configuration file in global variable.
				declare -g GLOBAL__parameter_conffile="${LOCAL__parameter_1}"

				# unset switch variables.
				unset LOCAL__parameter_0
				unset LOCAL__parameter_1
			;;
			*)
				continue
			;;
		esac
	done

	galilel_bot__init || return "${?}"

	# third parse command line for main switches.
	for LOOP__index in "${!LOCAL__parameters[@]}" ; do
		case "${LOCAL__parameters[${LOOP__index}]}" in
			--debug)
				declare -g GLOBAL__parameter_debug="enabled"
				unset LOCAL__parameters[${LOOP__index}]
			;;
			--test)
				declare -g GLOBAL__parameter_test="enabled"
				unset LOCAL__parameters[${LOOP__index}]
			;;
			--notify-wallet)

				# variables.
				local LOCAL__parameter_0="${LOCAL__parameters[${LOOP__index}]}"
				local LOCAL__parameter_1="${LOCAL__parameters[$(( ${LOOP__index} + 1))]}"
				local LOCAL__parameter_2="${LOCAL__parameters[$(( ${LOOP__index} + 2))]}"

				# check if we miss some parameter.
				[ -z "${LOCAL__parameter_2}" ] && {

					# show the help for the missing parameter.
					galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: option \`${LOCAL__parameter_0}' requires 2 arguments"
					galilel_bot__printf HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

					# return if we missed some parameter.
					return 1
				}

				# unset array items.
				unset LOCAL__parameters[${LOOP__index}]
				unset LOCAL__parameters[$(( ${LOOP__index} + 1))]
				unset LOCAL__parameters[$(( ${LOOP__index} + 2))]

				# wallet notification.
				galilel_bot__notification_wallet "${LOCAL__parameter_1}" "${LOCAL__parameter_2}" || return "${?}"

				# unset switch variables.
				unset LOCAL__parameter_0
				unset LOCAL__parameter_1
				unset LOCAL__parameter_2
			;;
			--notify-block)

				# variables.
				local LOCAL__parameter_0="${LOCAL__parameters[${LOOP__index}]}"
				local LOCAL__parameter_1="${LOCAL__parameters[$(( ${LOOP__index} + 1))]}"
				local LOCAL__parameter_2="${LOCAL__parameters[$(( ${LOOP__index} + 2))]}"

				# check if we miss some parameter.
				[ -z "${LOCAL__parameter_2}" ] && {

					# show the help for the missing parameter.
					galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: option \`${LOCAL__parameter_0}' requires 2 arguments"
					galilel_bot__printf HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

					# return if we missed some parameter.
					return 1
				}

				# unset array items.
				unset LOCAL__parameters[${LOOP__index}]
				unset LOCAL__parameters[$(( ${LOOP__index} + 1))]
				unset LOCAL__parameters[$(( ${LOOP__index} + 2))]

				# wallet notification.
				galilel_bot__notification_block "${LOCAL__parameter_1}" "${LOCAL__parameter_2}" || return "${?}"

				# unset switch variables.
				unset LOCAL__parameter_0
				unset LOCAL__parameter_1
				unset LOCAL__parameter_2
			;;
			*)
				continue
			;;
		esac
	done

	# check if unprocessed parameters are left.
	[ "${#LOCAL__parameters[@]}" != "0" ] && {

		# show the help for an unknown option.
		galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: unrecognized option \`${LOCAL__parameters[${LOOP__index}]}'"
		galilel_bot__printf HELP "Try \`${GALILEL_BOT_PROCESS} --help' for more information."

		# return if we found some unknown option.
		return 1
	}

	# if no error was found, return zero.
	return 0
}

# main() starts here.
galilel_bot__main "${@}"

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
