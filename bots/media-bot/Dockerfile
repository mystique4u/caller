FROM python:3.12-alpine

WORKDIR /app

# ffmpeg is required by yt-dlp to merge separate video and audio streams
# nodejs is required by yt-dlp 2026+ to decrypt YouTube format URLs (JS runtime)
RUN apk add --no-cache ffmpeg gcc musl-dev libffi-dev nodejs

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY bot.py setup_telegram_session.py ./

RUN mkdir -p /data

ENV PORT=3003 \
    PYTHONUNBUFFERED=1

EXPOSE 3003

CMD ["python", "bot.py"]
