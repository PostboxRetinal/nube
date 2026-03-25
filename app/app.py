import os
import json
from typing import List, Dict
from flask import Flask
from flask_consulate import Consul
from data import Articles

app = Flask(__name__)
consul_host = os.environ.get('CONSUL_HOST', 'consul')

consul = Consul(app=app, host=consul_host, port=8500)

@app.route('/healthcheck')
def health_check():
    return "OK", 200

consul.register_service(
    name='flask-micro',
    interval='1s',
    tags=['web','python'],
    port=5000,
    httpcheck='http://flask-micro:5000/healthcheck'
)

def my_articles() -> List[Dict]:
    articles = Articles()
    return articles

@app.route('/')
def index() -> str:
    return json.dumps({'my_articles': my_articles()})

if __name__ == '__main__':
    app.run(host='0.0.0.0')
