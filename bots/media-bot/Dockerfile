FROM python:3.12-alpine

WORKDIR /app

# ffmpeg is required by yt-dlp to merge separate video and audio streams
# nodejs is required by yt-dlp 2026+ to decrypt YouTube format URLs (JS runtime)
RUN apk add --no-cache ffmpeg gcc musl-dev libffi-dev nodejs

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# Pre-install the EJS (External JavaScript Solver) used by yt-dlp to solve
# YouTube's n-challenge (throttling bypass). Baking it into the image avoids
# fetching it from GitHub at runtime and removes the "skipped solver" warning.
RUN yt-dlp --install-remote-components ejs || true

COPY bot.py setup_telegram_session.py ./

RUN mkdir -p /data

ENV PORT=3003 \
    PYTHONUNBUFFERED=1

EXPOSE 3003

CMD ["python", "bot.py"]
