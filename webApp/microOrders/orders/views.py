from flask import Flask
from orders.controllers.order_controller import order_controller
from db.db import db
from flask_cors import CORS

app = Flask(__name__)

CORS(app, resources={
    r"/api/*": {
        "origins": "http://frontend:5001",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type"]
    }
})
app.config.from_object('config.Config')
db.init_app(app)

app.register_blueprint(order_controller)

if __name__ == '__main__':
    app.run()
