const PRODUCT_BASE_URL = `http://${window.location.hostname}:${PORT_PRODUCTS}/api/products`;
const ORDER_BASE_URL = `http://${window.location.hostname}:${PORT_ORDERS}/api/orders`;
const USER_BASE_URL = `http://${window.location.hostname}:${PORT_USERS}/api/users`;

function loadUsers() {
    fetch(USER_BASE_URL)
        .then(response => response.json())
        .then(users => {
            const select = document.getElementById('user-select');
            select.innerHTML = '<option value="">— Select a user —</option>';
            users.forEach(user => {
                const option = document.createElement('option');
                option.value = user.id;
                option.textContent = `${user.name} (${user.username})`;
                select.appendChild(option);
            });
        })
        .catch(error => console.error('Error loading users:', error));
}

function getProducts() {
    fetch(PRODUCT_BASE_URL)
        .then(response => response.json())
        .then(data => {
            var productListBody = document.querySelector('#product-list tbody');
            productListBody.innerHTML = '';

            data.forEach(product => {
                var row = document.createElement('tr');

                var nameCell = document.createElement('td');
                nameCell.textContent = product.name;
                row.appendChild(nameCell);

                var descriptionCell = document.createElement('td');
                descriptionCell.textContent = product.description || '';
                row.appendChild(descriptionCell);

                var priceCell = document.createElement('td');
                priceCell.textContent = product.price;
                row.appendChild(priceCell);

                var stockCell = document.createElement('td');
                stockCell.textContent = product.stock;
                row.appendChild(stockCell);

                var qtyCell = document.createElement('td');
                var qtyInput = document.createElement('input');
                qtyInput.type = 'number';
                qtyInput.min = '0';
                qtyInput.max = product.stock;
                qtyInput.value = '0';
                qtyInput.className = 'form-control order-qty-input';
                qtyInput.dataset.productId = product.id;

                if (product.stock === 0) {
                    qtyInput.disabled = true;
                }

                qtyCell.appendChild(qtyInput);
                row.appendChild(qtyCell);

                var actionsCell = document.createElement('td');

                var editLink = document.createElement('a');
                editLink.href = `/editProduct/${product.id}`;
                editLink.textContent = 'Edit';
                editLink.className = 'btn btn-primary mr-2';
                actionsCell.appendChild(editLink);

                var deleteLink = document.createElement('a');
                deleteLink.href = '#';
                deleteLink.textContent = 'Delete';
                deleteLink.className = 'btn btn-danger';
                deleteLink.addEventListener('click', function(e) {
                    e.preventDefault();
                    deleteProduct(product.id);
                });
                actionsCell.appendChild(deleteLink);

                row.appendChild(actionsCell);
                productListBody.appendChild(row);
            });
        })
        .catch(error => console.error('Error:', error));
}

function createProduct() {
    var data = {
        name: document.getElementById('name').value,
        description: document.getElementById('description').value,
        price: parseFloat(document.getElementById('price').value),
        stock: parseInt(document.getElementById('stock').value, 10)
    };

    fetch(PRODUCT_BASE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    })
    .then(response => response.json().then(resData => ({ ok: response.ok, data: resData })))
    .then(({ ok, data }) => {
        if (!ok) {
            alert('Error: ' + data.error);
            return;
        }
        alert('Producto creado correctamente');
        getProducts();
    })
    .catch(error => console.error('Error:', error));
}

function updateProduct() {
    var productId = document.getElementById('product-id').value;
    var data = {};

    var name = document.getElementById('name').value;
    if (name) data.name = name;

    var description = document.getElementById('description').value;
    if (description) data.description = description;

    var price = document.getElementById('price').value;
    if (price !== "") data.price = parseFloat(price);

    var stock = document.getElementById('stock').value;
    if (stock !== "") data.stock = parseInt(stock, 10);

    fetch(`${PRODUCT_BASE_URL}/${productId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    })
    .then(response => response.json().then(resData => ({ ok: response.ok, data: resData })))
    .then(({ ok, data }) => {
        if (!ok) {
            alert('Error: ' + data.error);
            return;
        }
        alert('Producto actualizado correctamente');
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Error inesperado al actualizar');
    });
}

function deleteProduct(productId) {
    if (confirm('Are you sure you want to delete this product?')) {
        fetch(`${PRODUCT_BASE_URL}/${productId}`, {
            method: 'DELETE',
        })
        .then(response => response.json().then(resData => ({ ok: response.ok, data: resData })))
        .then(({ ok, data }) => {
            if (!ok) {
                alert('Error: ' + data.error);
                return;
            }
            console.log('Product deleted successfully');
            getProducts();
        })
        .catch(error => console.error('Error:', error));
    }
}

function createOrderFromProducts() {
    const userId = parseInt(document.getElementById('user-select').value, 10);
    if (!userId) {
        alert('Por favor selecciona un usuario antes de crear la orden.');
        return;
    }

    const qtyInputs = document.querySelectorAll('.order-qty-input');
    const productsToOrder = [];

    qtyInputs.forEach(input => {
        const qty = parseInt(input.value, 10);
        if (qty > 0) {
            productsToOrder.push({
                id: parseInt(input.dataset.productId, 10),
                quantity: qty
            });
        }
    });

    if (productsToOrder.length === 0) {
        alert('Please select at least one product with a quantity greater than 0.');
        return;
    }

    fetch(ORDER_BASE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ user_id: userId, products: productsToOrder }),
    })
    .then(response => response.json().then(resData => ({ ok: response.ok, data: resData })))
    .then(({ ok, data }) => {
        if (!ok) {
            let msg = data.error;
            if (data.available_stock !== undefined) {
                msg += ` (Stock disponible: ${data.available_stock}, solicitado: ${data.requested_quantity})`;
            }
            if (data.product_id !== undefined) {
                msg += ` — Producto ID: ${data.product_id}`;
            }
            alert('Error: ' + msg);
            return;
        }
        alert(`Order created successfully! Order ID: ${data.order_id}`);
        getProducts();
        document.querySelectorAll('.order-qty-input').forEach(input => input.value = 0);
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Error inesperado al crear la orden');
    });
}