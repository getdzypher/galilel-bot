# Introduction

galilel-bot is the bridge between the Galilel coin daemon or any other coin
daemon and Discord. It uses the internal notification system to forward
blockchain related messages to any Discord channel. It allows notification
about received transactions like donations and monitor movement of wallet
addresses. The block notification system is able to announce current block
height if new block is detected in the network. The configuration of the bot is
independent from the wallet and changes doesn't require wallet daemon restart.
It supports testing of announcements through local console as well as logging
of notifications to a custom logfile. It supports multiple coin daemons from
different cryptocurrencies as it uses generic RPC commands. Lastly it supports
standard and multisig address monitoring. Additionally it supports
multilanguage text notifications.

# Installation

galilel-bot uses GNU autotools build system to simplify cross-platform
deployment and configuration. In most cases the following instructions will
work on any Linux distribution:

```
git clone https://github.com/Galilel-Project/galilel-bot.git
cd galilel-bot
sh autogen.sh
./configure \
  --prefix=/usr \
  --sysconfdir=/etc \
  --localstatedir=/var
make install
```

For further information how to use GNU autotools, please look at [INSTALL](/INSTALL)
file.

# Discord Configuration

The notification interface uses Discords Webhook system. It is required to
create Webhooks according to the bot features you want to use. If you are going
to use all features the following Webhooks have to be created:

* Wallet Bot
* Block Bot

The names can be freely chosen. You need to copy the `webhook.id` and the
`webhook.token`. More information on executing a Webhook can be found at [https://discordapp.com/developers/docs/resources/webhook#execute-webhook](https://discordapp.com/developers/docs/resources/webhook#execute-webhook)

# Coin Configuration

It is necessary to enable the block and wallet notifications of the coin
daemon. Please add the following to `~/.galilel/galilel.conf` file:

```
walletnotify=/usr/bin/galilel-bot --notify-wallet GALI %s
blocknotify=/usr/bin/galilel-bot --notify-block GALI %s
```

It is required to give galilel-bot RPC access to the coin daemon.
Minimum required configuration is the following:

```
rpcuser=galilel-user
rpcpassword=galilel-password
rpcallowip=127.0.0.1
```

# Bot Configuration

The configuration takes place in a single file `/etc/galilel/galilel-bot.conf`
You can copy an example configuration from `/etc/galilel/galilel-bot.conf.example`.
Please change the following options to match your requirements:

```
# coin configuration mappings (multiple coins can be configured, start with 0_ up to N_).
COIN_CONFIGS=(

	# coin ticker.
	[0_TICKER]="GALI"

	# rpc url (can be local or remote).
	[0_RPC_URL]="http://127.0.0.1:36002"

	# rpc authentication data.
	[0_RPC_USERNAME]="galilel-user"
	[0_RPC_PASSWORD]="galilel-password"

	# monitor block height changes (default is yes).
	[0_MONITOR_BLOCK]="yes"

	# monitor wallet balance changes (default is yes).
	[0_MONITOR_WALLET]="yes"

	# include watch only addresses, can degrade performance (default is no).
	[0_MONITOR_WATCH_ONLY]="no"

	# discord webhook authentication data.
	[0_WEBHOOK_ID]="823434590193434954"
	[0_WEBHOOK_TOKEN]="5fbJ3d531IKTk9X706d35R1uovFZfVTcAkDQUp4vjkH5xiLf6FIb2lUe6J4fCqbCdA9v"

	# discord notification texts (if number of %s is changed, behavior is unknown).
	[0_TEXT_REWARD]="Received staking reward **%s** %s with new balance of **%s** %s"
	[0_TEXT_TRANSFER_IN]="Received donation of **%s** %s with new balance of **%s** %s"
	[0_TEXT_TRANSFER_OUT]="Spend **%s** %s with new balance of **%s** %s"
	[0_TEXT_BLOCK]="New block **%s** at **%s** with difficulty **%s**"
)
```

It is possible to configure multiple RPC wallet daemons and monitor them with a
single bot installation as well as pushing notifications to single or multiple
Discord servers and channels. This is achieved via N-to-M mappings while N is
the RPC wallet daemon and M is the Discord webhook valid for a particular
channel. It is possible to configure 1-to-M or N-to-1 mappings.

The galilel-bot has built-in and by default enabled capabilities for logging of
notifications. In standard configuration it writes to `/var/log/galilel/galilel-bot.log`.
If you need to specify another logfile, please do in `/etc/galilel/galilel-bot.conf`
and change the following:

```
# notification logfile (leave empty to disable).
LOGFILE="/var/log/galilel/galilel-bot.log"
```

To disable logging, it is enough to use `/dev/null`. Please be aware that the
logfile can grow significantly over the time, especially if you process a lot
of transactions from monitored wallet daemons. Therefore it is highly
recommended to configure logfile rotation. See [logrotate](https://github.com/logrotate/logrotate) for more information.

# Testing

It is possible to test wallet daemon configuration with announcements to local
console. You can execute the bot manually.

The output is the raw text with the discord markdown characters. If `--debug`
is not used and the `--notify-wallet` output is empty, nothing was received
with the given transaction id for the monitored wallet address (neither a
transaction nor a reward).

## Incoming Transaction

```
$> galilel-bot --debug --test --notify-wallet GALI 1bf1771006ee0406af027cfae07510f47334826bbfc66e0173b91c0a8bcfb4c2
init() starting
init() successful
notification_wallet() starting
rpc_get_balance() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getbalance", "params" : [ ] }'
curl_wallet() successful
rpc_get_balance() successful
rpc_get_transaction() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "1bf1771006ee0406af027cfae07510f47334826bbfc66e0173b91c0a8bcfb4c2" ] }'
curl_wallet() successful
rpc_get_transaction() successful
notification_wallet() Received donation of **1.00000** GALI with new balance of **126448.48773** GALI
notification_wallet() successful
```

## Outgoing Transaction

```
$> galilel-bot --debug --test --notify-wallet GALI 0fa33647c37886d1fbb91fdf0bdd7b192da6892befdc60d91ad521627a702d99
init() starting
init() successful
notification_wallet() starting
rpc_get_balance() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getbalance", "params" : [ ] }'
curl_wallet() successful
rpc_get_balance() successful
rpc_get_transaction() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "0fa33647c37886d1fbb91fdf0bdd7b192da6892befdc60d91ad521627a702d99" ] }'
curl_wallet() successful
rpc_get_transaction() successful
notification_wallet() Spend **1.00000** GALI with new balance of **126448.48773** GALI
notification_wallet() successful
```

## Staking Reward

```
$> galilel-bot --debug --test --notify-wallet GALI 087cd4ad30bf5f51b038cd4fbe6e4f76d0976689140d378fe025d572f85adaf3
init() starting
init() successful
notification_wallet() starting
rpc_get_balance() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getbalance", "params" : [ ] }'
curl_wallet() successful
rpc_get_balance() successful
rpc_get_transaction() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "087cd4ad30bf5f51b038cd4fbe6e4f76d0976689140d378fe025d572f85adaf3" ] }'
curl_wallet() successful
rpc_get_transaction() successful
notification_wallet() Received staking reward **1.50000** GALI with new balance of **126448.48773** GALI
notification_wallet() successful
```

## Masternode Reward

```
$> galilel-bot --debug --test --notify-wallet GALI 3a6a2bd4bb657cb4274e6daf351ce92c8942c2f0cc8012ce4dd1c973daf14fc9
init() starting
init() successful
notification_wallet() starting
rpc_get_balance() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getbalance", "params" : [ ] }'
curl_wallet() successful
rpc_get_balance() successful
rpc_get_transaction() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "3a6a2bd4bb657cb4274e6daf351ce92c8942c2f0cc8012ce4dd1c973daf14fc9" ] }'
curl_wallet() successful
rpc_get_transaction() successful
notification_wallet() Received masternode reward **3.50000** GALI with new balance of **325623.40319** GALI
notification_wallet() successful
```

## Block Notification

```
$> galilel-bot --debug --test --notify-block GALI c30d74043896bdeb25ac3aa7227da94e360fec668f22c424bd81d1ad7d0a0f53
init() starting
init() successful
notification_block() starting
rpc_get_block() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "getblock", "params" : [ "c30d74043896bdeb25ac3aa7227da94e360fec668f22c424bd81d1ad7d0a0f53" ] }'
curl_wallet() successful
rpc_get_block() successful
notification_block() New block **522449** at **Fri May 17 19:45:16 CEST 2019** with difficulty **32807.05**
notification_block() successful
```

# Help

If you need additional help regarding setup, please join our Discord channel [https://discord.galilel.cloud](https://discord.galilel.cloud)

# Donations

This project is community based and decisions are made based on majority of
votes. If you like the work and fork it for your own coin, please donate
something to support its further development. You can use the following
addresses:

* Galilel (GALI): UUr5nDmykhun1HWM7mJAqLVeLzoGtx19dX
* Bitcoin (BTC): 13vZmvxWcpMxZPr2gtf4QBS8Q2En6kB3mo

Any contribution is greatly appreciated.
