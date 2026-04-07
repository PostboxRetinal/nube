FROM python:3.10

WORKDIR /app
COPY . .

RUN apt update && apt install -y curl && rm -rf /var/lib/apt/lists/*
RUN pip install -r requirements.txt

EXPOSE 3002 3012

CMD ["python", "run.py"]
