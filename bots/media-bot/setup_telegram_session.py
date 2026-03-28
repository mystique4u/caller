#!/usr/bin/env python3
"""
One-time Telegram session setup for media-bot.

Creates the Telethon session that yt-dlp uses to download t.me/ post links.
This must be done interactively (phone number + verification code) but only
needs to happen once — the session file is then stored as a GitHub Secret and
deployed automatically on every future deploy / server restore.

─── RECOMMENDED WORKFLOW ─────────────────────────────────────────────────────

  1. Run locally (pip install telethon first):
       python3 bots/media-bot/setup_telegram_session.py --local

  2. The session file +sessions+<api_id>.session is created in the current dir.

  3. Base64-encode and add to GitHub Secrets:
       base64 -w0 "+sessions+<api_id>.session"
       → add that string as TELEGRAM_SESSION_B64 in GitHub Secrets

  4. On the next deploy, the workflow deploys the session automatically.
     No further manual steps needed, including after server restores.

─── FALLBACK: run in container (no GitHub Secret) ────────────────────────────

  After deploy, if TELEGRAM_SESSION_B64 is not set as a GitHub Secret:
       docker exec -it media-bot python3 /app/setup_telegram_session.py

  The session will be saved to /data/ and included in daily state-sync backups,
  so it survives restores — but you lose it if no backup has run yet.

──────────────────────────────────────────────────────────────────────────────
"""

import argparse
import asyncio
import os
import sys
from pathlib import Path

API_ID   = os.environ.get("TELEGRAM_API_ID", "")
API_HASH = os.environ.get("TELEGRAM_API_HASH", "")


def _check_deps():
    try:
        from telethon import TelegramClient  # noqa: F401
    except ImportError:
        print("❌  telethon is not installed.")
        print("    Install it with:  pip install telethon")
        sys.exit(1)


def _check_env():
    if not API_ID or not API_HASH:
        print("❌  TELEGRAM_API_ID and TELEGRAM_API_HASH must be set as environment variables.")
        print()
        print("    Export them before running:")
        print("      export TELEGRAM_API_ID=12345678")
        print("      export TELEGRAM_API_HASH=abcdef1234567890abcdef1234567890")
        sys.exit(1)


async def _run(session_dir: Path):
    from telethon import TelegramClient
    from telethon.errors import SessionPasswordNeededError

    session_dir.mkdir(parents=True, exist_ok=True)
    # yt-dlp names the session "+sessions+<api_id>" relative to CWD at download time
    session_name = str(session_dir / f"+sessions+{API_ID}")
    session_file = Path(f"{session_name}.session")

    print("=" * 60)
    print("  Telegram Session Setup for media-bot")
    print("=" * 60)
    print(f"  API ID      : {API_ID}")
    print(f"  Session file: {session_file}")
    print()

    async with TelegramClient(session_name, int(API_ID), API_HASH) as client:
        if await client.is_user_authorized():
            me = await client.get_me()
            print(f"✅  Already authenticated as {me.first_name} (@{me.username})")
            return session_file

        print("📱  Enter your Telegram phone number (with country code, e.g. +1234567890):")
        phone = input("Phone: ").strip()

        await client.send_code_request(phone)
        print()
        print("🔑  Enter the verification code Telegram sent to your app:")
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

    return session_file


def main():
    parser = argparse.ArgumentParser(description="One-time Telegram session setup for media-bot")
    parser.add_argument(
        "--local",
        action="store_true",
        help="Run locally (saves session to current directory instead of /data/)",
    )
    args = parser.parse_args()

    _check_deps()
    _check_env()

    if args.local:
        session_dir = Path(".")
    else:
        session_dir = Path("/data")

    session_file = asyncio.run(_run(session_dir))

    print(f"✅  Session saved to: {session_file}")
    print()

    if args.local:
        print("─── NEXT STEPS ──────────────────────────────────────────")
        print()
        print("  1. Base64-encode the session file:")
        print(f"       base64 -w0 '{session_file}'")
        print()
        print("  2. Add the output as a GitHub Secret named:")
        print("       TELEGRAM_SESSION_B64")
        print()
        print("  3. Push or re-run the deploy-media-bot workflow.")
        print("     The session will be deployed automatically from now on.")
        print()
        print("  4. (Optional) You can delete the local session file:")
        print(f"       rm '{session_file}'")
        print("─────────────────────────────────────────────────────────")
    else:
        print("  t.me/ links will now work in media-bot.")
        print("  The session is synced to StorageBox by the daily state-sync.")


if __name__ == "__main__":
    main()
