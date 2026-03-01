from flask import Flask
from orders.controllers.order_controller import order_controller
from db.db import db
from flask_cors import CORS
from handlers import register_error_handlers
import os

app = Flask(__name__)

CORS(app, resources={
    r"/api/*": {
        "origins": f"http://192.168.80.3:{os.environ['PORT_FRONTEND']}",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type"]
    }
})
app.config.from_object('config.Config')
db.init_app(app)

app.register_blueprint(order_controller)

register_error_handlers(app)

if __name__ == '__main__':
    app.run()
