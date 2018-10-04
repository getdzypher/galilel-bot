# Introduction

galilel-bot is the bridge between the Galilel coin daemon and Discord. It uses
the Galilel internal notification system to forward blockchain related messages
to any Discord channel. It allows notification about received transactions like
donations and monitor movement of premine addresses. The block notification
system is able to announce current block height if new block is detected in the
network. The configuration of the bot is independent from the wallet, changes
doesn't require wallet daemon restart.

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
# coin configuration mappings. (one per row, format: ticker:rpcuser:rpcpassword:[address])
COIN_CONFIGS=(
	"GALI:galilel-user:galilel-password:UUr5nDmykhun1HWM7mJAqLVeLzoGtx19dX"
)

# discord webhook (wallet notification bot).
DISCORD_WALLET_WEBHOOK_ID="823434590193434954"
DISCORD_WALLET_WEBHOOK_TOKEN="5fbJ3d531IKTk9X706d35R1uovFZfVTcAkDQUp4vjkH5xiLf6FIb2lUe6J4fCqbCdA9v"

# discord webhook (block notification bot).
DISCORD_BLOCK_WEBHOOK_ID="907862382457824421"
DISCORD_BLOCK_WEBHOOK_TOKEN="94TsRdZNTa1neShJQ9pA7baGRx2yrY1P8EVZmQM0ubhkQKzIiuaX9QZ97KdquaUqZzdy"
```

The address column is an optional field if the wallet notification bot
(`walletnotify`) is used. With block notification bot (`blocknotify`) you can
leave this field empty.

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
