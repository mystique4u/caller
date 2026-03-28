#!/usr/bin/env python3
"""
One-time Telegram session setup for media-bot.

Run this once after the first deploy to authenticate yt-dlp's Telegram extractor
so that t.me/ post links can be downloaded.

Usage (run on the server after first deploy):
    docker exec -it media-bot python3 /app/setup_telegram_session.py

The session is saved to /data/ and is included in daily backups.
After a server restore the session is automatically restored — no re-auth needed.
"""

import asyncio
import os
import sys
from pathlib import Path

DATA_DIR      = Path("/data")
API_ID        = os.environ.get("TELEGRAM_API_ID", "")
API_HASH      = os.environ.get("TELEGRAM_API_HASH", "")

if not API_ID or not API_HASH:
    print("❌  TELEGRAM_API_ID and TELEGRAM_API_HASH environment variables are required.")
    print("    These should be set in the container — check your .env file.")
    sys.exit(1)

try:
    from telethon import TelegramClient
    from telethon.errors import SessionPasswordNeededError
except ImportError:
    print("❌  telethon is not installed. It should be present in the container.")
    sys.exit(1)


async def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    # yt-dlp names the Telethon session "+sessions+<api_id>" when run from CWD
    session_name = str(DATA_DIR / f"+sessions+{API_ID}")

    print("=" * 60)
    print("  Telegram Session Setup for media-bot")
    print("=" * 60)
    print(f"  API ID   : {API_ID}")
    print(f"  Session  : {session_name}.session")
    print()

    async with TelegramClient(session_name, int(API_ID), API_HASH) as client:
        if await client.is_user_authorized():
            me = await client.get_me()
            print(f"✅  Already authenticated as {me.first_name} (@{me.username})")
            print("    No action needed.")
            return

        print("📱  Enter your Telegram phone number (e.g. +1234567890):")
        phone = input("Phone: ").strip()

        await client.send_code_request(phone)
        print()
        print("🔑  Enter the verification code sent via Telegram:")
        code = input("Code: ").strip()

        try:
            await client.sign_in(phone, code)
        except SessionPasswordNeededError:
            print()
            print("🔐  Two-step verification is enabled. Enter your cloud password:")
            password = input("Password: ").strip()
            await client.sign_in(password=password)

        me = await client.get_me()
        print()
        print(f"✅  Authenticated as: {me.first_name} (@{me.username})")
        print(f"✅  Session saved to: {session_name}.session")
        print()
        print("  t.me/ links will now work in media-bot.")
        print("  The session is included in daily backups — no re-auth needed after restore.")


if __name__ == "__main__":
    asyncio.run(main())
