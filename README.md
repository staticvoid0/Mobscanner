# MobScanner 3000

A lightweight **Final Fantasy XI Windower 4 addon** that scans nearby mobs for names on your watchlist. When a tracked mob is detected, MobScanner displays an in-game chat alert, plays a sound, and can optionally send a notification to a Discord channel so that you may receive notifications on your iPhonator.

## Features

- **Custom mob watchlist** — Add or remove mob names without editing Lua.
- **Automatic scanning** — Checks nearby valid, idle NPC targets on in-game time changes.
- **Local alerts** — Displays a chat message and plays `data/alert.wav`.
- **Optional Discord alerts** — Posts the detection message to a Discord channel through a webhook.
- **Persistent watchlist** — Saves mob names in a character-specific settings file.
- **30-second cooldown** — Limits repeat alerts for the same mob ID.

## Installation

1. Place the `Mobscanner` folder in your Windower `addons` directory.
2. Make sure `data/alert.wav` is included.
3. Load the addon in game:

   ```text
   //lua load Mobscanner
   ```

## Commands

| Command | Description |
| --- | --- |
| `//ms add <mob name>` | Add a mob to the watchlist. |
| `//ms remove <mob name>` | Remove a mob from the watchlist. |
| `//ms list` | Show watched mobs. |
| `//ms clear` | Clear the watchlist. |
| `//ms` | Show command help. |

`//mscanner` works as an alternative prefix.

### Examples

```text
//ms add Leaping Lizzy
//ms add Argus
//ms list
//ms remove Argus
```

Names are matched **case-insensitively**, but the full mob name must match. Quotes around a mob name are optional when adding or removing it.

## Optional Discord Webhook Setup

Discord notifications are **optional**. The in-game chat message and sound still work without a webhook configured.

### 1. Create a Discord webhook

1. Open Discord and choose the server and text channel where you want notifications.
2. Open **Edit Channel → Integrations → Webhooks**.
3. Create a new webhook, choose its name and destination channel, and copy its **Webhook URL**.
4. Make sure your Discord account has permission to manage webhooks in that channel. If you cannot see the option, ask a server administrator.

### 2. Paste the URL into `mobscanner.lua`

Open `mobscanner.lua` in a text editor. Near the top of the file, find:

```lua
local webhook_url = ''
```

Paste your copied Discord webhook URL between the quotes:

```lua
local webhook_url = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN'
```

The URL above is only an example. Use the **entire URL copied from Discord**, including its token. Save the file and reload the addon:

```text
//lua reload Mobscanner
```

**Important:** This version does **not** have an in-game command for configuring webhooks. The URL is entered directly in the Lua file and is **not** stored in `settings.xml`.

### 3. Enable phone notifications

Install or open Discord on your phone, sign in, and enable notifications for the server/channel receiving alerts. Also allow notifications for Discord in your phone's operating-system settings. Discord notification delivery depends on your personal channel, server, and device notification settings.

### How notifications work

When MobScanner finds a matching mob, it:

1. Displays a message such as `MobScanner 3000 detected "Argus".` in your in-game chatlog.
2. Plays the bundled alert sound.
3. Sends the same detection message to the configured Discord webhook..

The addon tracks the last alert time for each detected mob ID and normally waits **30 seconds** before alerting again for that ID. This cooldown resets when you change zones.

**Privacy and security:** Treat your webhook URL like a password. Anyone with it may be able to post messages to that Discord channel. Do not publish a configured URL in a public GitHub repository. If exposed, delete or regenerate the webhook in Discord.

**Current-code limitation:** The original v1.1 code attempts an HTTPS request even when the webhook URL is blank. Without a configured webhook, local alerts still run, but the request may fail; it does not check or display Discord delivery errors. Discord notifications also require an active internet connection and a valid webhook.

## Settings

The watchlist is saved in a character-specific XML file under the addon's `data` directory, using a filename like `settings_CharacterName.xml`. The webhook URL is **not** part of this file; it remains in `mobscanner.lua`.

## Requirements

- Final Fantasy XI with Windower 4
- The Lua HTTPS dependencies used by the addon (`ssl.https` and `ltn12`) for Discord delivery

---

**Author:** Staticvoid  
**Version:** 1.1
