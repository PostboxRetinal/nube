# AKS REST API curl reqs

## 0) Base URL (Ingress)

```bash
INGRESS_IP=$(kubectl get svc -n ingress-nginx ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
BASE="http://${INGRESS_IP}"
echo "$BASE"
```

## 1) Unique Test Data

```bash
STAMP=$(date +%s)
USER_NAME="api_user_${STAMP}"
USER_EMAIL="api_user_${STAMP}@example.com"
USER_USERNAME="api_user_${STAMP}"
PRODUCT_NAME="api_product_${STAMP}"
```

## 2) Users - GET / POST / PUT / DELETE

### Get all users

```bash
curl -sS -i "${BASE}/api/users"
```

### Create a user

```bash
curl -sS -i -X POST "${BASE}/api/users" \
  -H "Content-Type: application/json" \
  -d '{"name":"'"${USER_NAME}"'","email":"'"${USER_EMAIL}"'","username":"'"${USER_USERNAME}"'","password":"Secret123!"}'
```

### Get created user ID

```bash
USER_ID=$(curl -sS "${BASE}/api/users" | jq -r ".[] | select(.username==\"${USER_USERNAME}\") | .id")
echo "USER_ID=${USER_ID}"
```

### Get user by ID

```bash
curl -sS -i "${BASE}/api/users/${USER_ID}"
```

### Update user (PUT only)

```bash
curl -sS -i -X PUT "${BASE}/api/users/${USER_ID}" \
  -H "Content-Type: application/json" \
  -d '{"name":"'"${USER_NAME}_updated"'","email":"'"${USER_EMAIL}"'","username":"'"${USER_USERNAME}"'}'
```

## 3) Products - GET / POST / PUT / DELETE

### Get all products

```bash
curl -sS -i "${BASE}/api/products"
```

### Create a product

```bash
curl -sS -i -X POST "${BASE}/api/products" \
  -H "Content-Type: application/json" \
  -d '{"name":"'"${PRODUCT_NAME}"'","description":"AKS API test","price":129.90,"stock":25}'
```

### Get created product ID

```bash
PRODUCT_ID=$(curl -sS "${BASE}/api/products" | jq -r ".[] | select(.name==\"${PRODUCT_NAME}\") | .id")
echo "PRODUCT_ID=${PRODUCT_ID}"
```

### Get product by ID

```bash
curl -sS -i "${BASE}/api/products/${PRODUCT_ID}"
```

### Update product (PUT only)

```bash
curl -sS -i -X PUT "${BASE}/api/products/${PRODUCT_ID}" \
  -H "Content-Type: application/json" \
  -d '{"price":149.99,"stock":30}'
```

## 4) Orders - GET / POST / DELETE

### Get all orders

```bash
curl -sS -i "${BASE}/api/orders"
```

### Create an order

```bash
ORDER_ID=$(curl -sS -X POST "${BASE}/api/orders" \
  -H "Content-Type: application/json" \
  -d '{"user_id":'"${USER_ID}"',"products":[{"id":'"${PRODUCT_ID}"',"quantity":2}]}' | jq -r '.order_id')
echo "ORDER_ID=${ORDER_ID}"
```

### Get all orders again

```bash
curl -sS -i "${BASE}/api/orders"
```

### Delete order by ID

```bash
curl -sS -i -X DELETE "${BASE}/api/orders/${ORDER_ID}"
```

## 5) Cleanup (Optional)

### Delete product

```bash
curl -sS -i -X DELETE "${BASE}/api/products/${PRODUCT_ID}"
```

### Delete user

```bash
curl -sS -i -X DELETE "${BASE}/api/users/${USER_ID}"
```

## Notes

- Use paths without a trailing slash: `/api/users`, not `/api/users/`.
- Users and products support `PUT`; `PATCH` is not implemented.
- Orders support `GET`, `POST`, and `DELETE` only.
