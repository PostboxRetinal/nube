class Config:
    MYSQL_HOST = 'orders_db'
    MYSQL_USER = 'app_orders'
    MYSQL_PASSWORD = 'app_password'
    MYSQL_DB = 'orders_db'
    SQLALCHEMY_DATABASE_URI = f'mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}/{MYSQL_DB}'
