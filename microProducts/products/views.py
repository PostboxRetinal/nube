from flask import Flask
from products.controllers.product_controller import product_controller
from db.db import db
from flask_cors import CORS

app = Flask(__name__)

CORS(app, resources={
    r"/api/*": {
        "origins": "http://192.168.100.3:5001",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type"]
    }
})
app.config.from_object('config.Config')
db.init_app(app)

app.register_blueprint(product_controller)

if __name__ == '__main__':
    app.run()
