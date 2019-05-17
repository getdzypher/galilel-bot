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

# global result variable.
declare -g GLOBAL__result

# global curl value.
declare -g GLOBAL__curl

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
		FILE)

			# check if we should write debug output to console.
			[ "${GLOBAL__parameter_debug}" == "enabled" ] && {
				echo -e "${FUNCNAME[1]##*__}() ${@}"
			}

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
	galilel_bot__printf HELP "  -v, --version   show version and exit"
	galilel_bot__printf HELP "      --conf      <filename>"
	galilel_bot__printf HELP "                  specify configuration file (default: ${GLOBAL__parameter_conffile})"
	galilel_bot__printf HELP "      --debug     enable debugging output"
	galilel_bot__printf HELP "      --test      enable notification on console rather than in discord"
	galilel_bot__printf HELP ""
	galilel_bot__printf HELP "Notification arguments:"
	galilel_bot__printf HELP ""
	galilel_bot__printf HELP "      --notify-wallet   <ticker> <transaction-id>"
	galilel_bot__printf HELP "                        discord notification about new transaction for wallet"
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

# @_galilel_bot__curl_discord()
#
# @_${1}: discord url
# @_${2}: webhook id
# @_${3}: webhook token
# @_${4}: query
#
# this function communicates via curl with discord webservice.
function galilel_bot__curl_discord() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# clear variable.
	unset GLOBAL__curl

	# local variables.
	local LOCAL__url="${1}"
	local LOCAL__id="${2}"
	local LOCAL__token="${3}"
	local LOCAL__query="${4}"

	# query output.
	galilel_bot__printf FILE "json query: '${LOCAL__query}'"

	GLOBAL__curl="$(@CURL@ \
		--request POST \
		--max-time 5 \
		--silent \
		--fail \
		--header 'content-type: application/json;' \
		--data-binary "${LOCAL__query}" \
		"${LOCAL__url}/${LOCAL__id}/${LOCAL__token}"
	)"

	# check return status of curl command.
	case "${?}" in
		7)

			# connection error.
			galilel_bot__printf FILE "failed to connect to discord webservice"

			# return error.
			return 7
		;;
		22)

			# http protocol error.
			galilel_bot__printf FILE "failed to retrieve url from discord webservice"

			# return error.
			return 22
		;;
	esac

	# debug output.
	galilel_bot__printf FILE "successful"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__curl_wallet()
#
# @_${1}: rpc url
# @_${2}: rpc username
# @_${3}: rpc password
# @_${4}: query
#
# this function communicates via curl with wallet rpc daemon.
function galilel_bot__curl_wallet() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# clear variable.
	unset GLOBAL__curl

	# local variables.
	local LOCAL__url="${1}"
	local LOCAL__username="${2}"
	local LOCAL__password="${3}"
	local LOCAL__query="${4}"

	# query output.
	galilel_bot__printf FILE "json query: '${LOCAL__query}'"

	GLOBAL__curl="$(@CURL@ \
		--request POST \
		--max-time 5 \
		--silent \
		--fail \
		--header 'content-type: text/plain;' \
		--data-binary "${LOCAL__query}" \
		--user "${LOCAL__username}:${LOCAL__password}" \
		"${LOCAL__url}"
	)"

	# check return status of curl command.
	case "${?}" in
		7)

			# connection error.
			galilel_bot__printf FILE "failed to connect to RPC wallet"

			# return error.
			return 7
		;;
		22)

			# http protocol error.
			galilel_bot__printf FILE "failed to retrieve url from RPC wallet"

			# return error.
			return 22
		;;
	esac

	# debug output.
	galilel_bot__printf FILE "successful"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__rpc_get_balance()
#
# @_${1}: rpc url
# @_${2}: rpc username
# @_${3}: rpc password
#
# this function fetches the balance from rpc daemon.
function galilel_bot__rpc_get_balance() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# clear variable.
	unset GLOBAL__result

	# get wallet balance.
	galilel_bot__curl_wallet \
		"${1}" \
		"${2}" \
		"${3}" \
		'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getbalance", "params" : [ ] }' || return "${?}"

	# loop through result.
	while read LOCAL__line ; do

		# get balance information.
		local LOCAL__balance="$(@JSHON@ -Q -e result -u <<< "${LOCAL__line}")"
		local LOCAL__balance="$(printf "%.5f" "${LOCAL__balance}")"
	done <<< "${GLOBAL__curl}"

	# export the result:
	GLOBAL__result="${LOCAL__balance}"

	# debug output.
	galilel_bot__printf FILE "successful"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__rpc_get_transaction()
#
# @_${1}: rpc url
# @_${2}: rpc username
# @_${3}: rpc password
# @_${4}: transaction id
#
# this function fetches the raw value of a transaction from rpc daemon.
function galilel_bot__rpc_get_transaction() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# clear variable.
	unset GLOBAL__result

	# get wallet balance.
	galilel_bot__curl_wallet \
		"${1}" \
		"${2}" \
		"${3}" \
		'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "'"${4}"'" ] }' || return "${?}"

	# loop through result.
	while read LOCAL__line ; do

		# get transaction information.
		local LOCAL__hex="$(@JSHON@ -Q -e result -e hex -u <<< "${LOCAL__line}")"
	done <<< "${GLOBAL__curl}"

	# export the result:
	GLOBAL__result="${LOCAL__hex}"

	# debug output.
	galilel_bot__printf FILE "successful"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__rpc_get_amount()
#
# @_${1}: rpc url
# @_${2}: rpc username
# @_${3}: rpc password
# @_${4}: wallet transaction
# @_${5}: wallet address
#
# this function fetches the amount of transaction for monitored wallet address from rpc daemon.
function galilel_bot__rpc_get_amount() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# clear variable.
	unset GLOBAL__result

	# get wallet balance.
	galilel_bot__curl_wallet \
		"${1}" \
		"${2}" \
		"${3}" \
		'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "decoderawtransaction", "params" : [ "'"${4}"'" ] }' || return "${?}"

	# loop through result.
	while read LOCAL__line ; do

		# get address information.
		declare -a LOCAL__addresses=($(@JSHON@ -Q -e result -e vout -a -e scriptPubKey -e addresses -e 0 -u <<< "${LOCAL__line}"))

		# get value information.
		declare -a LOCAL__values=($(@JSHON@ -Q -e result -e vout -a -e value -u <<< "${LOCAL__line}"))
	done <<< "${GLOBAL__curl}"

	# loop through array.
	local LOCAL__index
	for (( LOCAL__index = 0; LOCAL__index < "${#LOCAL__addresses[@]}" ; LOCAL__index++ )) ; do

		# check if address matches.
		[ "${5}" == "${LOCAL__addresses[${LOCAL__index}]}" ] && {

			# export the result:
			GLOBAL__result="${LOCAL__values[${LOCAL__index}]}"
			GLOBAL__result="$(printf "%.5f" "${GLOBAL__result}")"
		}
	done

	# debug output.
	galilel_bot__printf FILE "successful"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__notification_wallet()
#
# @_${1}: coin ticker
# @_${2}: transaction id
#
# this function sends message to discord on monitored wallet address changes.
function galilel_bot__notification_wallet() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# local variables.
	local LOCAL__coin="${1}"
	local LOCAL__transactionid="${2}"

	# loop through the configuration array.
	local LOCAL__index
	for (( LOCAL__index = 0; LOCAL__index < "${#GLOBAL__parameter_configs[@]}" ; LOCAL__index++ )) ; do

		# read data into variables.
		IFS=',' read LOCAL__ticker LOCAL__rpc LOCAL__username LOCAL__password LOCAL__address <<< "${GLOBAL__parameter_configs[${LOCAL__index}]}"

		# check if correct ticker.
		[ "${LOCAL__coin}" != "${LOCAL__ticker}" ] && {

			# wrong ticker, so continue.
			continue
		}

		# get wallet balance.
		galilel_bot__rpc_get_balance "${LOCAL__rpc}" "${LOCAL__username}" "${LOCAL__password}" || return "${?}"
		local LOCAL__balance="${GLOBAL__result}"

		# get raw transaction.
		galilel_bot__rpc_get_transaction "${LOCAL__rpc}" "${LOCAL__username}" "${LOCAL__password}" "${2}" || return "${?}"
		local LOCAL__transaction="${GLOBAL__result}"

		# get amount of transaction.
		galilel_bot__rpc_get_amount "${LOCAL__rpc}" "${LOCAL__username}" "${LOCAL__password}" "${LOCAL__transaction}" "${LOCAL__address}" || return "${?}"
		local LOCAL__amount="${GLOBAL__result}"

		# check if we found a pos block (staking).
		galilel_bot__curl_wallet \
			"${LOCAL__rpc}" \
			"${LOCAL__username}" \
			"${LOCAL__password}" \
			'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "'"${LOCAL__transactionid}"'" ] }' || return "${?}"

		# loop through result.
		while read LOCAL__line ; do

			# get transaction information (transfer).
			local LOCAL__confirmations="$(@JSHON@ -Q -e result -e confirmations -u <<< "${LOCAL__line}")"

			# check if coins have been transferred.
			[ "${LOCAL__confirmations}" -gt "0" ] && {

				# get wallet address.
				local LOCAL__wallet="$(@JSHON@ -Q -e result -e details -a -e address -u <<< "${LOCAL__line}")"

				# check if it is configured wallet address.
				[ "${LOCAL__address}" == "${LOCAL__wallet}" ] && {

					# get amount.
					local LOCAL__amount="$(@JSHON@ -Q -e result -e details -a -e amount -u <<< "${LOCAL__line}")"

					# show information.
					galilel_bot__printf FILE "Received donation of **'"${LOCAL__amount}"'** '"${LOCAL__coin}"' with new balance of **'"${LOCAL__balance}"'** '"${LOCAL__coin}"'"

					# check if in production mode.
					[ "${GLOBAL__parameter_test}" == "disabled" ] && {

						# push block notification to discord.
						galilel_bot__curl_discord \
							"https://discordapp.com/api/webhooks" \
							"${GLOBAL__parameter_wallet_webhook_id}" \
							"${GLOBAL__parameter_wallet_webhook_token}" \
							'{ "content" : "Received donation of **'"${LOCAL__amount}"'** '"${LOCAL__coin}"' with new balance of **'"${LOCAL__balance}"'** '"${LOCAL__coin}"'" }' || return "${?}"
					}
				}
			}

			# get transaction information (reward).
			local LOCAL__generated="$(@JSHON@ -Q -e result -e generated -u <<< "${LOCAL__line}")"
			local LOCAL__amount="$(@JSHON@ -Q -e result -e amount -u <<< "${LOCAL__line}")"
			local LOCAL__fee="$(@JSHON@ -Q -e result -e fee -u <<< "${LOCAL__line}")"

			# check if the block was generated.
			[ "${LOCAL__generated}" == "true" ] && {

				# calculate reward.
				local LOCAL__reward="$(echo "${LOCAL__fee}" + "${LOCAL__amount}" | @BC@)"
				local LOCAL__reward="$(printf "%.5f" "${LOCAL__reward}")"

				# show information.
				galilel_bot__printf FILE "Received staking reward **'"${LOCAL__reward}"'** '"${LOCAL__coin}"' with new balance of **'"${LOCAL__balance}"'** '"${LOCAL__coin}"'"

				# check if in production mode.
				[ "${GLOBAL__parameter_test}" == "disabled" ] && {

					# push block notification to discord.
					galilel_bot__curl_discord \
						"https://discordapp.com/api/webhooks" \
						"${GLOBAL__parameter_wallet_webhook_id}" \
						"${GLOBAL__parameter_wallet_webhook_token}" \
						'{ "content" : "Received staking reward **'"${LOCAL__reward}"'** '"${LOCAL__coin}"' with new balance of **'"${LOCAL__balance}"'** '"${LOCAL__coin}"'" }' || return "${?}"
				}
			}
		done <<< "${GLOBAL__result}"
	done

	# debug output.
	galilel_bot__printf FILE "successful"

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

	# debug output.
	galilel_bot__printf FILE "starting"

	# local variables.
	local LOCAL__coin="${1}"
	local LOCAL__blockhash="${2}"

	# loop through the configuration array.
	local LOCAL__index
	for (( LOCAL__index = 0; LOCAL__index < "${#GLOBAL__parameter_configs[@]}" ; LOCAL__index++ )) ; do

		# read data into variables.
		IFS=',' read LOCAL__ticker LOCAL__rpc LOCAL__username LOCAL__password LOCAL__address <<< "${GLOBAL__parameter_configs[${LOCAL__index}]}"

		# check if correct ticker.
		[ "${LOCAL__coin}" != "${LOCAL__ticker}" ] && {

			# wrong ticker, so continue.
			continue
		}

		# fetch block information.
		galilel_bot__curl_wallet \
			"${LOCAL__rpc}" \
			"${LOCAL__username}" \
			"${LOCAL__password}" \
			'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getblock", "params" : [ "'"${LOCAL__blockhash}"'" ] }' || return "${?}"

		# loop through result.
		while read LOCAL__line ; do

			# get block information.
			local LOCAL__height="$(@JSHON@ -Q -e result -e height -u <<< "${LOCAL__line}")"
			local LOCAL__difficulty="$(@JSHON@ -Q -e result -e difficulty -u <<< "${LOCAL__line}")"
			local LOCAL__time="$(@JSHON@ -Q -e result -e time -u <<< "${LOCAL__line}")"

			# get current date.
			local LOCAL__date="$(@DATE@ --date "@${LOCAL__time}")"

			# format variables.
			local LOCAL__difficulty="$(printf "%.2f" "${LOCAL__difficulty}")"

			# show information.
			galilel_bot__printf FILE "New block **'"${LOCAL__height}"'** at **'"${LOCAL__date}"'** with difficulty **'"${LOCAL__difficulty}"'**"

			# check if in production mode.
			[ "${GLOBAL__parameter_test}" == "disabled" ] && {

				# push block notification to discord.
				galilel_bot__curl_discord \
					"https://discordapp.com/api/webhooks" \
					"${GLOBAL__parameter_block_webhook_id}" \
					"${GLOBAL__parameter_block_webhook_token}" \
					'{ "content" : "New block **'"${LOCAL__height}"'** at **'"${LOCAL__date}"'** with difficulty **'"${LOCAL__difficulty}"'**" }' || return "${?}"
			}
		done <<< "${GLOBAL__result}"
	done

	# debug output.
	galilel_bot__printf FILE "successful"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__init()
#
# this function initializes the application and does various permission checks.
function galilel_bot__init() {

	# debug output.
	galilel_bot__printf FILE "starting"

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

		# check if directory exists, otherwise create it.
		[ ! -d "${GLOBAL__parameter_logfile%/*}" ] && {
			@MKDIR@ -p "${GLOBAL__parameter_logfile%/*}" 2> /dev/null || {
				galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: logfile directory ${GLOBAL__parameter_logfile%/*} could not be created"

				# return with error.
				return 1
			}
		}

		# check if directory is writable.
		[ ! -w "${GLOBAL__parameter_logfile%/*}" ] && {
			@TOUCH@ "${GLOBAL__parameter_logfile}" 2> /dev/null || {
				galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: logfile ${GLOBAL__parameter_logfile} could not be created"

				# return with error.
				return 1
			}
		}
	}

	# debug output.
	galilel_bot__printf FILE "successful"

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
			--debug)
				declare -g GLOBAL__parameter_debug="enabled"
				unset LOCAL__parameters[${LOOP__index}]
			;;
			--test)
				declare -g GLOBAL__parameter_test="enabled"
				unset LOCAL__parameters[${LOOP__index}]
			;;
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

	# load configuration and do basic checks.
	galilel_bot__init || return "${?}"

	# third parse command line for main switches.
	for LOOP__index in "${!LOCAL__parameters[@]}" ; do
		case "${LOCAL__parameters[${LOOP__index}]}" in
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
