import os
from products.views import app

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get("PORT_PRODUCTS", 5003)))
