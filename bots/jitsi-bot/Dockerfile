FROM python:3.12-alpine

WORKDIR /app

COPY bot.py ./

ENV PORT=3001 \
    PYTHONUNBUFFERED=1

EXPOSE 3001

CMD ["python", "bot.py"]
