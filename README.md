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
standard and multisig address monitoring.

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
# coin configuration mappings (one per row, format: ticker,rpcurl,rpcuser,rpcpassword,[address]).
COIN_CONFIGS=(
	"GALI,http://127.0.0.1:36002,galilel-user,galilel-password,UUr5nDmykhun1HWM7mJAqLVeLzoGtx19dX"
)

# discord webhook (wallet notification bot).
DISCORD_WALLET_WEBHOOK_ID="823434590193434954"
DISCORD_WALLET_WEBHOOK_TOKEN="5fbJ3d531IKTk9X706d35R1uovFZfVTcAkDQUp4vjkH5xiLf6FIb2lUe6J4fCqbCdA9v"

# discord webhook (block notification bot).
DISCORD_BLOCK_WEBHOOK_ID="907862382457824421"
DISCORD_BLOCK_WEBHOOK_TOKEN="94TsRdZNTa1neShJQ9pA7baGRx2yrY1P8EVZmQM0ubhkQKzIiuaX9QZ97KdquaUqZzdy"

# notification texts.
TEXT_REWARD="Received staking reward **%s** %s with new balance of **%s** %s"
TEXT_TRANSFER="Received donation of **%s** %s with new balance of **%s** %s"
TEXT_BLOCK="New block **%s** at **%s** with difficulty **%s**"
```

The address column is an optional field if the wallet notification bot
`walletnotify` is used. While using the block notification bot `blocknotify`
only, you can leave this field empty.

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
of transactions from monitored wallet addresses. Therefore it is highly
recommended to configure logfile rotation. See [logrotate](https://github.com/logrotate/logrotate) for more information.

You can monitor multiple coin daemons from different currencies. Therefore you
need to change `COIN_CONFIGS` parameter as follows:

```
COIN_CONFIGS=(
	"GALI,http://127.0.0.1:36002,galilel-user,galilel-password,UUr5nDmykhun1HWM7mJAqLVeLzoGtx19dX"
	"BTC,http://127.0.0.1:8332,bitcoin-user,bitcoin-password,13vZmvxWcpMxZPr2gtf4QBS8Q2En6kB3mo"
	"GIO,http://127.0.0.1:23332,graviocoin-user:graviocoin-password,2MW87snpBrqnWUUeJ15uVkqoqEMZU8GSWLM"
)
```

With the example above it is possible to monitor Galilel (GALI), Bitcoin (BTC)
and Graviocoin (GIO). It allows monitoring of the wallet, blocks on the network
or both.

# Testing

It is possible to test wallet daemon configuration with announcements to local
console. You can execute the bot manually, for example wallet notification:

```
$> galilel-bot --debug --test --notify-wallet GALI b6b281e0fc50bf24955f0fbd1089f2d9e08f50aa9e559358b5e7a4663de58ce1
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
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "b6b281e0fc50bf24955f0fbd1089f2d9e08f50aa9e559358b5e7a4663de58ce1" ] }'
curl_wallet() successful
rpc_get_transaction() successful
rpc_get_amount() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "decoderawtransaction", "params" : [ "0100000002105d2a5eeafa68cf1c7693d04b22b01faaa9e1830e92f581c9358e3bbd9bea20010000006a47304402201e91fc52bcf6303d8e69d2df3aa99c6e4cf35ecb8ea7dcec574741f82b3b2fa502202931e2dc67a62e6fc3094f130b061b572babbeb5504aaf23dd4f8e1759923f720121026240a615c7d7da4ef3b9bb6edf1a362bcb38a808e4328931ae62fc7fc45ed9c8fffffffffe6a04173ff73dd76df9277cd57c017a27dac8356fef8886616394a51c74ae95010000006b483045022100edcc3050beab359b809410a4202c5cf09bdbff7e831fff41305798e7f76d3b7c02207bb0acce4155290bb1463117f99eb4a272b0f2b5d328ee8683439ae2a6045f1c012102ae01fd0e05789b942f78150d91299baa6507a21dc2251a4cd0e12f516e111dacffffffff0200e1f5050000000017a91411e3fa7baa678ebc20e40741b4c359f1ce18e1af87dfdd7801000000001976a914776a412dbeca0f5ab4347b09f59811937a94f02788ac00000000" ] }'
curl_wallet() successful
rpc_get_amount() successful
rpc_get_reward() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "b6b281e0fc50bf24955f0fbd1089f2d9e08f50aa9e559358b5e7a4663de58ce1" ] }'
curl_wallet() successful
rpc_get_reward() successful
notification_wallet() Received donation of **1.00000** GALI with new balance of **21830.46752** GALI
notification_wallet() successful
```

```
$> galilel-bot --debug --test --notify-wallet GALI 326259bf87cde3f419df4c2f667ef4468264cb40d56f7424ee4166a08a0d30fb
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
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "326259bf87cde3f419df4c2f667ef4468264cb40d56f7424ee4166a08a0d30fb" ] }'
curl_wallet() successful
rpc_get_transaction() successful
rpc_get_amount() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "decoderawtransaction", "params" : [ "010000000155e23823620b62e7d6e2a1546ffdd9f0be6448987b95ebeb4c8f0195c21938c0010000004847304402202f828bc838d6ff70329a14eeb44c7a0c31f8408576111b0c52104dca8af22759022036729e1f32b963790f25be43669e5a50b01fb45f302f83d378c654ab74f394f301ffffffff03000000000000000000003cfedc510000002321036f682253c0cf1e9b04969a3c67e3ffb32b627264c78989fbfbca1b50605528ceac8093dc14000000001976a91426e414a0386efa784e24d113068f6bc6cc51885188ac00000000" ] }'
curl_wallet() successful
rpc_get_amount() successful
rpc_get_reward() starting
curl_wallet() starting
curl_wallet() json query: '{ "jsonrpc" : "1.0", "id" : "galilel-bot", "method" : "gettransaction", "params" : [ "326259bf87cde3f419df4c2f667ef4468264cb40d56f7424ee4166a08a0d30fb" ] }'
curl_wallet() successful
rpc_get_reward() successful
notification_wallet() Received staking reward **1.50000** GALI with new balance of **21830.46752** GALI
notification_wallet() successful
```

and block notification:

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
notification_block() New block **522449** at **Fri 17 May 2019 07:45:16 PM CEST** with difficulty **32807.05**
notification_block() successful
```

The output is the raw text with the discord markdown characters. If `--debug`
is not used and the `--notify-wallet` output is empty, nothing was received
with the given transaction id for the monitored wallet address (neither a
transaction nor a reward).

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
