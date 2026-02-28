class Config:
    MYSQL_HOST = 'products_db'
    MYSQL_USER = 'app_products'
    MYSQL_PASSWORD = 'app_password'
    MYSQL_DB = 'products_db'
    SQLALCHEMY_DATABASE_URI = f'mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}/{MYSQL_DB}'