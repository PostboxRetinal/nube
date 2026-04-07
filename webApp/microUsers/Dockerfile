FROM python:3.10

WORKDIR /app
COPY . .

RUN pip install -r requirements.txt
RUN apt update && apt install -y curl && rm -rf /var/lib/apt/lists/*

EXPOSE 3001 3011

CMD ["python", "run.py"]
