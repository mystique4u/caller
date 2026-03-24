FROM python:3.12-alpine
WORKDIR /app

# gcc + musl-dev: needed by the geoip2 C extension
# libmaxminddb-dev: MaxMind DB library
RUN apk add --no-cache gcc musl-dev libffi-dev libmaxminddb-dev

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY bot.py ./

# /data — stores GeoLite2-City.mmdb (mount as volume or copy in at deploy)
# /var/log — mount point for host log files (auth.log, syslog)
RUN mkdir -p /data /var/log

ENV PORT=3002
ENV PYTHONUNBUFFERED=1
EXPOSE 3002

CMD ["python", "bot.py"]
