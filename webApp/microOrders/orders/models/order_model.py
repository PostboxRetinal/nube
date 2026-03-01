from db.db import db

class Orders(db.Model):
    __tablename__ = 'orders'

    id = db.Column(db.String(36), primary_key=True)
    user_id = db.Column(db.Integer, nullable=False)
    total = db.Column(db.Numeric(10, 2), nullable=False)
    created_at = db.Column(db.DateTime, nullable=False)

    items = db.relationship('OrderItems', backref='order', lazy=True, cascade='all, delete-orphan')

    def __init__(self, id, user_id, total, created_at):
        self.id = id
        self.user_id = user_id
        self.total = total
        self.created_at = created_at

class OrderItems(db.Model):
    __tablename__ = 'order_items'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    order_id = db.Column(db.String(36), db.ForeignKey('orders.id'), nullable=False)
    product_id = db.Column(db.Integer, nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    subtotal = db.Column(db.Numeric(10, 2), nullable=False)

    def __init__(self, order_id, product_id, quantity, subtotal):
        self.order_id = order_id
        self.product_id = product_id
        self.quantity = quantity
        self.subtotal = subtotal