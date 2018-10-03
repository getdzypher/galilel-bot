# Introduction

galilel-bot is the bridge between the Galilel coin daemon and Discord. It uses
the Galilel internal notification system to forward blockchain related messages
to any Discord channel.

# Discord Configuration

The notification interface uses Discords Webhook system. It is required to
create Webhooks according to the bot features you want to use. If you are going
to use all features the following Webhooks have to be created:

* Donation Bot
* Block Bot

The names can be freely chosen. You need to copy the `webhook.id` and the
`webhook.token`. More information on executing a Webhook can be found at [https://discordapp.com/developers/docs/resources/webhook#execute-webhook](https://discordapp.com/developers/docs/resources/webhook#execute-webhook)

# Coin Configuration

It is necessary to enable the block and wallet notifications of the Galilel
coin daemon. Please add the following to `~/.galilel/galilel.conf` file:

```
walletnotify=/usr/bin/galilel-bot DONATION %s
blocknotify=/usr/bin/galilel-bot BLOCK %s
```

# Bot Configuration

The configuration takes place in a single file `/etc/galilel/galilel-bot.conf`
Please change the following options to match your requirements:

```
# coin ticker to use for announcements.
COIN_TICKER="GALI"

# donation address used for announcements.
COIN_ADDRESS="UUr5nDmykhun1HWM7mJAqLVeLzoGtx19dX"

# discord webhook (donation notification bot).
DISCORD_DONATION_WEBHOOK_ID="823434590193434954"
DISCORD_DONATION_WEBHOOK_TOKEN="5fbJ3d531IKTk9X706d35R1uovFZfVTcAkDQUp4vjkH5xiLf6FIb2lUe6J4fCqbCdA9v"

# discord webhook (block notification bot).
DISCORD_BLOCK_WEBHOOK_ID="907862382457824421"
DISCORD_BLOCK_WEBHOOK_TOKEN="94TsRdZNTa1neShJQ9pA7baGRx2yrY1P8EVZmQM0ubhkQKzIiuaX9QZ97KdquaUqZzdy"
```

# Help

If you need additional help regarding setup, please join our Discord channel [https://discord.galilel.cloud](https://discord.galilel.cloud)

# Donations

This project is a community based and decisions are made based on majority of
votes. If you like the work and fork it for your own coin, please donate
something to support its further development. You can use the following
addresses:

* Galilel (GALI): UUr5nDmykhun1HWM7mJAqLVeLzoGtx19dX
* Bitcoin (BTC): 13vZmvxWcpMxZPr2gtf4QBS8Q2En6kB3mo

Any contribution is greatly appreciated.
