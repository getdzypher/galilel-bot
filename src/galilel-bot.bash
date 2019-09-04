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

# global associative configuration array.
declare -A COIN_CONFIGS

# global result variable.
declare -a GLOBAL__result

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
	local LOCAL__text="${2}"

	# shift variable.
	shift 2

	# check output level.
	case "${LOCAL__level}" in
		HELP)
			printf "${LOCAL__text}\n" "${@}"
		;;
		FILE)

			# check if we should write debug output to console.
			[ "${GLOBAL__parameter_debug}" == "enabled" ] && {
				printf "${FUNCNAME[1]##*__}() ${LOCAL__text}\n" "${@}"
			}

			# check if we should write to logfile.
			[ -n "${LOGFILE}" ] && {
				printf "$(@DATE@ '+%b %e %H:%M:%S') ${HOSTNAME} ${GALILEL_BOT_PROCESS}[$$]: ${FUNCNAME[1]##*__}() ${LOCAL__text}\n" "${@}" >> "${LOGFILE}"
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
	galilel_bot__printf HELP "      --notify-block    <ticker> <block-hash>"
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
	local LOCAL__text="${4}"

	# shift variable.
	shift 4

	# build query.
	local LOCAL__query="$(printf "{ "'"'"content"'"'" : "'"'"${LOCAL__text}"'"'" }" "${@}")"

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
# @_${4}: monitor watch only
#
# this function fetches the balance from rpc daemon.
function galilel_bot__rpc_get_balance() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# clear variable.
	unset GLOBAL__result

	# check if watch only addresses must be included.
	[ "${4}" == "no" ] && {

		# get wallet balance.
		galilel_bot__curl_wallet \
			"${1}" \
			"${2}" \
			"${3}" \
			'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getbalance", "params" : [ ] }' || return "${?}"
	}
	[ "${4}" == "yes" ] && {

		# get wallet balance.
		galilel_bot__curl_wallet \
			"${1}" \
			"${2}" \
			"${3}" \
			'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getbalance", "params" : [ "*", 0, true ] }' || return "${?}"
	}

	# loop through result.
	while read LOCAL__line ; do

		# get balance information.
		local LOCAL__balance="$(@JSHON@ -Q -e result -u <<< "${LOCAL__line}")"
		local LOCAL__balance="$(printf "%.5f" "${LOCAL__balance}")"
	done <<< "${GLOBAL__curl}"

	# export the result.
	GLOBAL__result=("${LOCAL__balance}")

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
# @_${4}: monitor watch only
# @_${5}: transaction id
#
# this function fetches the raw value of a transaction from rpc daemon.
function galilel_bot__rpc_get_transaction() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# clear variable.
	unset GLOBAL__result

	# check if watch only addresses must be included.
	[ "${4}" == "no" ] && {

		# get wallet transaction.
		galilel_bot__curl_wallet \
			"${1}" \
			"${2}" \
			"${3}" \
			'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "'"${5}"'" ] }' || return "${?}"
	}
	[ "${4}" == "yes" ] && {

		# get wallet transaction.
		galilel_bot__curl_wallet \
			"${1}" \
			"${2}" \
			"${3}" \
			'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "'"${5}"'", true ] }' || return "${?}"
	}

	# loop through result.
	while read LOCAL__line ; do

		# get transaction information.
		local LOCAL__confirmations="$(@JSHON@ -Q -e result -e confirmations -u <<< "${LOCAL__line}")"
		local LOCAL__generated="$(@JSHON@ -Q -e result -e generated -u <<< "${LOCAL__line}")"
		local LOCAL__amount="$(@JSHON@ -Q -e result -e amount -u <<< "${LOCAL__line}")"
		local LOCAL__fee="$(@JSHON@ -Q -e result -e fee -u <<< "${LOCAL__line}")"
	done <<< "${GLOBAL__curl}"

	# check if incoming transaction.
	[ "${LOCAL__confirmations}" != "0" ] &&
	[ "${LOCAL__amount:0:1}" == "-" ] && {

		# spend.
		local LOCAL__type="transfer-out"

		# calculate amount.
		GLOBAL__result=("${LOCAL__amount/#-/}")
	}

	# check if outgoing transaction.
	[ "${LOCAL__confirmations}" != "0" ] &&
	[ "${LOCAL__amount:0:1}" != "-" ] && {

		# receive.
		local LOCAL__type="transfer-in"

		# calculate amount.
		GLOBAL__result=("${LOCAL__amount}")
	}

	# check if mining reward.
	[ "${LOCAL__confirmations}" != "0" ] &&
	[ "${LOCAL__generated}" == "true" ] &&
	[ "${LOCAL__amount:0:1}" == "-" ] && {

		# mining reward.
		local LOCAL__type="reward-mining"

		# calculate amount.
		GLOBAL__result=("$(printf "%.8f+%.8f\n" "${LOCAL__fee}" "${LOCAL__amount}" | @BC@)")
	}

	# check if masternode reward.
	[ "${LOCAL__confirmations}" != "0" ] &&
	[ "${LOCAL__generated}" == "true" ] &&
	[ "${LOCAL__amount:0:1}" != "-" ] && {

		# mining reward.
		local LOCAL__type="reward-masternode"

		# calculate amount.
		GLOBAL__result=("${LOCAL__amount}")
	}

	# export the result.
	GLOBAL__result=("$(printf "%.5f" "${GLOBAL__result[0]}")")
	GLOBAL__result=("${GLOBAL__result[0]}" "${LOCAL__type:-unknown}")

	# debug output.
	galilel_bot__printf FILE "successful"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__rpc_get_block()
#
# @_${1}: rpc url
# @_${2}: rpc username
# @_${3}: rpc password
# @_${4}: block hash
#
# this function fetches the block information from rpc daemon.
function galilel_bot__rpc_get_block() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# clear variable.
	unset GLOBAL__result

	# get wallet transaction reward.
	galilel_bot__curl_wallet \
		"${1}" \
		"${2}" \
		"${3}" \
		'{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getblock", "params" : [ "'"${4}"'" ] }' || return "${?}"

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
	done <<< "${GLOBAL__curl}"

	# export the result.
	GLOBAL__result=("${LOCAL__height}" "${LOCAL__difficulty}" "${LOCAL__date}")

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
	local LOCAL__transaction_id="${2}"

	# loop through the configuration array.
	local LOCAL__index="0"
	while [ : ] ; do

		# parse variables.
		local LOCAL__ticker="${COIN_CONFIGS[${LOCAL__index}_TICKER]}"
		local LOCAL__rpc_url="${COIN_CONFIGS[${LOCAL__index}_RPC_URL]}"
		local LOCAL__rpc_username="${COIN_CONFIGS[${LOCAL__index}_RPC_USERNAME]}"
		local LOCAL__rpc_password="${COIN_CONFIGS[${LOCAL__index}_RPC_PASSWORD]}"
		local LOCAL__monitor_block="${COIN_CONFIGS[${LOCAL__index}_MONITOR_BLOCK]}"
		local LOCAL__monitor_wallet="${COIN_CONFIGS[${LOCAL__index}_MONITOR_WALLET]}"
		local LOCAL__monitor_watch_only="${COIN_CONFIGS[${LOCAL__index}_MONITOR_WATCH_ONLY]}"
		local LOCAL__webhook_id="${COIN_CONFIGS[${LOCAL__index}_WEBHOOK_ID]}"
		local LOCAL__webhook_token="${COIN_CONFIGS[${LOCAL__index}_WEBHOOK_TOKEN]}"
		local LOCAL__text_reward_staking="${COIN_CONFIGS[${LOCAL__index}_TEXT_REWARD_STAKING]}"
		local LOCAL__text_reward_masternode="${COIN_CONFIGS[${LOCAL__index}_TEXT_REWARD_MASTERNODE]}"
		local LOCAL__text_transfer_in="${COIN_CONFIGS[${LOCAL__index}_TEXT_TRANSFER_IN]}"
		local LOCAL__text_transfer_out="${COIN_CONFIGS[${LOCAL__index}_TEXT_TRANSFER_OUT]}"
		local LOCAL__text_block="${COIN_CONFIGS[${LOCAL__index}_TEXT_BLOCK]}"

		# increment counter.
		((LOCAL__index++))

		# check if end is reached.
		[ -z "${LOCAL__ticker}" ] && {

			# terminate loop.
			break
		}

		# check if correct ticker.
		[ "${LOCAL__ticker}" !=  "${LOCAL__coin}" ] && {

			# wrong ticker, so continue.
			continue
		}

		# check if correct realm.
		[ "${LOCAL__monitor_wallet}" != "yes" ] && {

			# wrong realm, so continue.
			continue
		}

		# get wallet balance.
		galilel_bot__rpc_get_balance \
			"${LOCAL__rpc_url}" \
			"${LOCAL__rpc_username}" \
			"${LOCAL__rpc_password}" \
			"${LOCAL__monitor_watch_only}" || return "${?}"

		# parse result.
		local LOCAL__balance="${GLOBAL__result[0]}"

		# get raw transaction.
		galilel_bot__rpc_get_transaction \
			"${LOCAL__rpc_url}" \
			"${LOCAL__rpc_username}" \
			"${LOCAL__rpc_password}" \
			"${LOCAL__monitor_watch_only}" \
			"${LOCAL__transaction_id}" || return "${?}"

		# parse result.
		local LOCAL__amount="${GLOBAL__result[0]}"
		local LOCAL__type="${GLOBAL__result[1]}"

		# check if we found a pos block (staking).
		[ "${LOCAL__type}" == "reward-mining" ] && {

			# show information.
			galilel_bot__printf FILE "${LOCAL__text_reward_staking}" "${LOCAL__amount}" "${LOCAL__coin}" "${LOCAL__balance}" "${LOCAL__coin}"

			# check if in production mode.
			[ "${GLOBAL__parameter_test}" == "disabled" ] && {

				# push wallet notification to discord.
				galilel_bot__curl_discord \
					"https://discordapp.com/api/webhooks" \
					"${LOCAL__webhook_id}" \
					"${LOCAL__webhook_token}" \
					"${LOCAL__text_reward_staking}" \
					"${LOCAL__amount}" \
					"${LOCAL__coin}" \
					"${LOCAL__balance}" \
					"${LOCAL__coin}"
			}
		}

		# check if we found a pos block (masternode).
		[ "${LOCAL__type}" == "reward-masternode" ] && {

			# show information.
			galilel_bot__printf FILE "${LOCAL__text_reward_masternode}" "${LOCAL__amount}" "${LOCAL__coin}" "${LOCAL__balance}" "${LOCAL__coin}"

			# check if in production mode.
			[ "${GLOBAL__parameter_test}" == "disabled" ] && {

				# push wallet notification to discord.
				galilel_bot__curl_discord \
					"https://discordapp.com/api/webhooks" \
					"${LOCAL__webhook_id}" \
					"${LOCAL__webhook_token}" \
					"${LOCAL__text_reward_masternode}" \
					"${LOCAL__amount}" \
					"${LOCAL__coin}" \
					"${LOCAL__balance}" \
					"${LOCAL__coin}"
			}
		}

		# check if we received a transaction (transfer).
		[ "${LOCAL__type}" == "transfer-in" ] && {

			# show information.
			galilel_bot__printf FILE "${LOCAL__text_transfer_in}" "${LOCAL__amount}" "${LOCAL__coin}" "${LOCAL__balance}" "${LOCAL__coin}"

			# check if in production mode.
			[ "${GLOBAL__parameter_test}" == "disabled" ] && {

				# push wallet notification to discord.
				galilel_bot__curl_discord \
					"https://discordapp.com/api/webhooks" \
					"${LOCAL__webhook_id}" \
					"${LOCAL__webhook_token}" \
					"${LOCAL__text_transfer_in}" \
					"${LOCAL__amount}" \
					"${LOCAL__coin}" \
					"${LOCAL__balance}" \
					"${LOCAL__coin}"
			}
		}

		# check if we spend a transaction (transfer).
		[ "${LOCAL__type}" == "transfer-out" ] && {

			# show information.
			galilel_bot__printf FILE "${LOCAL__text_transfer_out}" "${LOCAL__amount}" "${LOCAL__coin}" "${LOCAL__balance}" "${LOCAL__coin}"

			# check if in production mode.
			[ "${GLOBAL__parameter_test}" == "disabled" ] && {

				# push wallet notification to discord.
				galilel_bot__curl_discord \
					"https://discordapp.com/api/webhooks" \
					"${LOCAL__webhook_id}" \
					"${LOCAL__webhook_token}" \
					"${LOCAL__text_transfer_out}" \
					"${LOCAL__amount}" \
					"${LOCAL__coin}" \
					"${LOCAL__balance}" \
					"${LOCAL__coin}"
			}
		}
	done

	# debug output.
	galilel_bot__printf FILE "successful"

	# if no error was found, return zero.
	return 0
}

# @_galilel_bot__notification_block()
#
# @_${1}: coin ticker
# @_${2}: block hash
#
# this function sends message to discord on block changes in the network.
function galilel_bot__notification_block() {

	# debug output.
	galilel_bot__printf FILE "starting"

	# local variables.
	local LOCAL__coin="${1}"
	local LOCAL__block_hash="${2}"

	# loop through the configuration array.
	local LOCAL__index="0"
	while [ : ] ; do

		# parse variables.
		local LOCAL__ticker="${COIN_CONFIGS[${LOCAL__index}_TICKER]}"
		local LOCAL__rpc_url="${COIN_CONFIGS[${LOCAL__index}_RPC_URL]}"
		local LOCAL__rpc_username="${COIN_CONFIGS[${LOCAL__index}_RPC_USERNAME]}"
		local LOCAL__rpc_password="${COIN_CONFIGS[${LOCAL__index}_RPC_PASSWORD]}"
		local LOCAL__monitor_block="${COIN_CONFIGS[${LOCAL__index}_MONITOR_BLOCK]}"
		local LOCAL__monitor_wallet="${COIN_CONFIGS[${LOCAL__index}_MONITOR_WALLET]}"
		local LOCAL__monitor_watch_only="${COIN_CONFIGS[${LOCAL__index}_MONITOR_WATCH_ONLY]}"
		local LOCAL__webhook_id="${COIN_CONFIGS[${LOCAL__index}_WEBHOOK_ID]}"
		local LOCAL__webhook_token="${COIN_CONFIGS[${LOCAL__index}_WEBHOOK_TOKEN]}"
		local LOCAL__text_reward_staking="${COIN_CONFIGS[${LOCAL__index}_TEXT_REWARD_STAKING]}"
		local LOCAL__text_reward_masternode="${COIN_CONFIGS[${LOCAL__index}_TEXT_REWARD_MASTERNODE]}"
		local LOCAL__text_transfer_in="${COIN_CONFIGS[${LOCAL__index}_TEXT_TRANSFER_IN]}"
		local LOCAL__text_transfer_out="${COIN_CONFIGS[${LOCAL__index}_TEXT_TRANSFER_OUT]}"
		local LOCAL__text_block="${COIN_CONFIGS[${LOCAL__index}_TEXT_BLOCK]}"

		# increment counter.
		((LOCAL__index++))

		# check if end is reached.
		[ -z "${LOCAL__ticker}" ] && {

			# terminate loop.
			break
		}

		# check if correct ticker.
		[ "${LOCAL__ticker}" !=  "${LOCAL__coin}" ] && {

			# wrong ticker, so continue.
			continue
		}

		# check if correct realm.
		[ "${LOCAL__monitor_block}" != "yes" ] && {

			# wrong realm, so continue.
			continue
		}

		# get block information.
		galilel_bot__rpc_get_block \
			"${LOCAL__rpc_url}" \
			"${LOCAL__rpc_username}" \
			"${LOCAL__rpc_password}" \
			"${LOCAL__block_hash}" || return "${?}"

		# parse result.
		local LOCAL__height="${GLOBAL__result[0]}"
		local LOCAL__difficulty="${GLOBAL__result[1]}"
		local LOCAL__date="${GLOBAL__result[2]}"

		# show information.
		galilel_bot__printf FILE "${LOCAL__text_block}" "${LOCAL__height}" "${LOCAL__date}" "${LOCAL__difficulty}"

		# check if in production mode.
		[ "${GLOBAL__parameter_test}" == "disabled" ] && {

			# push block notification to discord.
			galilel_bot__curl_discord \
				"https://discordapp.com/api/webhooks" \
				"${LOCAL__webhook_id}" \
				"${LOCAL__webhook_token}" \
				"${LOCAL__text_block}" \
				"${LOCAL__height}" \
				"${LOCAL__date}" \
				"${LOCAL__difficulty}"
		}
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

	# check if logfile is enabled, directory and file is writable.
	[ -n "${LOGFILE}" ] && {

		# check if directory exists, otherwise create it.
		[ ! -d "${LOGFILE%/*}" ] && {
			@MKDIR@ -p "${LOGFILE%/*}" 2> /dev/null || {
				galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: logfile directory ${LOGFILE%/*} could not be created"

				# return with error.
				return 1
			}
		}

		# check if directory is writable.
		[ ! -w "${LOGFILE%/*}" ] && {
			@TOUCH@ "${LOGFILE}" 2> /dev/null || {
				galilel_bot__printf HELP "${GALILEL_BOT_PROCESS}: logfile ${LOGFILE} could not be created"

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
