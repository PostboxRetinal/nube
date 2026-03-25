FROM python:3.11-slim

WORKDIR /app

# build dependencies for MySQL client
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        default-libmysqlclient-dev \
        python3-dev \
        pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app

EXPOSE 5002

CMD ["python", "run.py"]
