FROM python:3.10

WORKDIR /app
COPY . .

RUN pip install -r requirements.txt
RUN apt update && apt install -y curl && rm -rf /var/lib/apt/lists/*

EXPOSE 3003 3013

CMD ["python", "run.py"]
