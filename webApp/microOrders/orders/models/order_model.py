from db.db import db

class Orders(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.String(255), nullable=False)
    product_id = db.Column(db.Integer, nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    total = db.Column(db.Numeric(10, 2), nullable=False)

    def __init__(self, user_id, product_id, quantity, total):
        self.user_id = user_id
        self.product_id = product_id
        self.quantity = quantity
        self.total = total
        