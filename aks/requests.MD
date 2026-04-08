# 0) Base URL (Ingress)
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
BASE="http://${INGRESS_IP}"
echo "$BASE"

# Unique test data
STAMP=$(date +%s)
USER_NAME="api_user_${STAMP}"
USER_EMAIL="api_user_${STAMP}@example.com"
USER_USERNAME="api_user_${STAMP}"
PRODUCT_NAME="api_product_${STAMP}"

# 1) USERS - GET/POST/PUT/DELETE
# GET all users
curl -sS -i "${BASE}/api/users"
# POST create user
curl -sS -i -X POST "${BASE}/api/users" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${USER_NAME}\",\"email\":\"${USER_EMAIL}\",\"username\":\"${USER_USERNAME}\",\"password\":\"Secret123!\"}"
# Get created user id
USER_ID=$(curl -sS "${BASE}/api/users" | jq -r ".[] | select(.username==\"${USER_USERNAME}\") | .id")
echo "USER_ID=${USER_ID}"
# GET user by id
curl -sS -i "${BASE}/api/users/${USER_ID}"
# PUT update user (PATCH is NOT implemented)
curl -sS -i -X PUT "${BASE}/api/users/${USER_ID}" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${USER_NAME}_updated\",\"email\":\"${USER_EMAIL}\",\"username\":\"${USER_USERNAME}\"}"

# 2) PRODUCTS - GET/POST/PUT/DELETE
# GET all products
curl -sS -i "${BASE}/api/products"
# POST create product
curl -sS -i -X POST "${BASE}/api/products" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"${PRODUCT_NAME}\",\"description\":\"AKS API test\",\"price\":129.90,\"stock\":25}"
# Get created product id
PRODUCT_ID=$(curl -sS "${BASE}/api/products" | jq -r ".[] | select(.name==\"${PRODUCT_NAME}\") | .id")
echo "PRODUCT_ID=${PRODUCT_ID}"
# GET product by id
curl -sS -i "${BASE}/api/products/${PRODUCT_ID}"
# PUT update product (PATCH is NOT implemented)
curl -sS -i -X PUT "${BASE}/api/products/${PRODUCT_ID}" \
  -H "Content-Type: application/json" \
  -d "{\"price\":149.99,\"stock\":30}"
  
# 3) ORDERS - GET/POST/DELETE (no PUT/PATCH endpoint)
# GET all orders
curl -sS -i "${BASE}/api/orders"
# POST create order
ORDER_ID=$(curl -sS -X POST "${BASE}/api/orders" \
  -H "Content-Type: application/json" \
  -d "{\"user_id\":${USER_ID},\"products\":[{\"id\":${PRODUCT_ID},\"quantity\":2}]}" | jq -r '.order_id')
echo "ORDER_ID=${ORDER_ID}"
# GET all orders again
curl -sS -i "${BASE}/api/orders"
# DELETE order by id
curl -sS -i -X DELETE "${BASE}/api/orders/${ORDER_ID}"

# 4) Cleanup (optional)
# DELETE product
curl -sS -i -X DELETE "${BASE}/api/products/${PRODUCT_ID}"
# DELETE user
curl -sS -i -X DELETE "${BASE}/api/users/${USER_ID}"
Notes:
- Use paths without trailing slash (e.g., /api/users, not /api/users/) for clean behavior.
- Users/Products support PUT, not PATCH.
- Orders supports GET, POST, DELETE only.