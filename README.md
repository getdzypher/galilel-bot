# Introduction

galilel-bot is the bridge between the Galilel coin daemon and Discord. It uses
the Galilel internal notification system to forward blockchain related messages
to any Discord channel. It allows notification about received transactions like
donations and monitor movement of premine addresses. The block notification
system is able to announce current block height if new block is detected in the
network. The configuration of the bot is independent from the wallet, changes
doesn't require wallet daemon restart. It supports testing of announcements
through local console as well as logging of notifications to a custom logfile.
It supports multiple coin daemons from different cryptocurrencies as it uses
generic RPC commands.

# Discord Configuration

The notification interface uses Discords Webhook system. It is required to
create Webhooks according to the bot features you want to use. If you are going
to use all features the following Webhooks have to be created:

* Wallet Bot
* Block Bot

The names can be freely chosen. You need to copy the `webhook.id` and the
`webhook.token`. More information on executing a Webhook can be found at [https://discordapp.com/developers/docs/resources/webhook#execute-webhook](https://discordapp.com/developers/docs/resources/webhook#execute-webhook)

# Coin Configuration

It is necessary to enable the block and wallet notifications of the Galilel
coin daemon. Please add the following to `~/.galilel/galilel.conf` file:

```
walletnotify=/usr/bin/galilel-bot --notify-wallet GALI %s
blocknotify=/usr/bin/galilel-bot --notify-block GALI %s
```

It is required to give galilel-bot RPC access to the Galilel coin daemon.
Minimum required configuration is the following:

```
rpcuser=galilel-user
rpcpassword=galilel-password
rpcallowip=127.0.0.1
```

# Bot Configuration

The configuration takes place in a single file `/etc/galilel/galilel-bot.conf`
Please change the following options to match your requirements:

```
# coin configuration mappings (one per row, format: ticker:rpcuser:rpcpassword:rpcip:rpcport:[address]).
COIN_CONFIGS=(
	"GALI:galilel-user:galilel-password:127.0.0.1:36002:UUr5nDmykhun1HWM7mJAqLVeLzoGtx19dX"
)

# discord webhook (wallet notification bot).
DISCORD_WALLET_WEBHOOK_ID="823434590193434954"
DISCORD_WALLET_WEBHOOK_TOKEN="5fbJ3d531IKTk9X706d35R1uovFZfVTcAkDQUp4vjkH5xiLf6FIb2lUe6J4fCqbCdA9v"

# discord webhook (block notification bot).
DISCORD_BLOCK_WEBHOOK_ID="907862382457824421"
DISCORD_BLOCK_WEBHOOK_TOKEN="94TsRdZNTa1neShJQ9pA7baGRx2yrY1P8EVZmQM0ubhkQKzIiuaX9QZ97KdquaUqZzdy"
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

# Testing

It is possible to test wallet daemon configuration with announcements to local
console. You can execute the bot manually, for example wallet notification:

```
$> galilel-bot --test --notify-wallet GALI c9d674b4a53cf31086bac309b11bd860945e8d53597eabaf9a4216c6868b97ea
Received donation of **'250.0'** 'GALI' with new balance of **'270343.04048631'** 'GALI'
```

```
$> galilel-bot --test --notify-wallet GALI e6698a51943e23877d3ad71d4f5c6231a5b4ba90f4f741e4aebce31b9585a9a1
Received staking reward **'19.99999'** 'GALI' with new balance of **'268413.04135991'** 'GALI'
```

and block notification:

```
$> galilel-bot --test --notify-block GALI 570d66289f41f835cbc5a6ba521ad007ab9958c4773c1fea82d8b338e633bd8c
New block **'189685'** at **'Thu Oct 4 15:45:48 CEST 2018'** with difficulty **'50829.65'**
```

The output is the raw text with the discord markdown characters. If the
`--notify-wallet` output is empty, nothing was received with the given
transaction id for the monitored wallet address (neither a transaction nor a
reward).

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
