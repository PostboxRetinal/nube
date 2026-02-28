class Config:
    MYSQL_HOST = 'users_db'
    MYSQL_USER = 'app_users'    
    MYSQL_PASSWORD = 'app_password'
    MYSQL_DB = 'users_db'
    SQLALCHEMY_DATABASE_URI = f'mysql+pymysql://{MYSQL_USER}:{MYSQL_PASSWORD}@{MYSQL_HOST}/{MYSQL_DB}'
