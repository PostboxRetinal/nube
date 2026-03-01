const ORDER_BASE_URL = `http://${window.location.hostname}:${PORT_ORDERS}/api/orders`;

function getOrders() {
    fetch(ORDER_BASE_URL)
        .then(response => response.json())
        .then(data => {
            var orderListBody = document.querySelector('#order-list tbody');
            orderListBody.innerHTML = '';

            data.forEach(order => {
                var row = document.createElement('tr');

                var idCell = document.createElement('td');
                idCell.textContent = order.id;
                row.appendChild(idCell);

                var userCell = document.createElement('td');
                userCell.textContent = order.user_id;
                row.appendChild(userCell);

                var productCell = document.createElement('td');
                productCell.textContent = order.product_id;
                row.appendChild(productCell);

                var qtyCell = document.createElement('td');
                qtyCell.textContent = order.quantity;
                row.appendChild(qtyCell);

                var totalCell = document.createElement('td');
                totalCell.textContent = order.total.toFixed(2);
                row.appendChild(totalCell);

                var actionsCell = document.createElement('td');
                var deleteBtn = document.createElement('button');
                deleteBtn.textContent = 'Delete';
                deleteBtn.className = 'btn btn-danger btn-sm';
                deleteBtn.onclick = function() { deleteOrder(order.id); };
                actionsCell.appendChild(deleteBtn);

                row.appendChild(actionsCell);
                orderListBody.appendChild(row);
            });
        })
        .catch(error => console.error('Error fetching orders:', error));
}

function createOrder() {
    var productId = parseInt(document.getElementById('product_id').value, 10);
    var quantity = parseInt(document.getElementById('quantity').value, 10);

    var payload = {
        products: [{ id: productId, quantity: quantity }]
    };

    fetch(ORDER_BASE_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
    })
    .then(response => response.json().then(resData => ({ ok: response.ok, data: resData })))
    .then(({ ok, data }) => {
        if (!ok) {
            // ← was: data.message — now reads data.error + optional inventory context
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
        alert('Order created successfully!');
        getOrders();
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Error inesperado al crear la orden');
    });
}

function deleteOrder(orderId) {
    if (confirm('Are you sure you want to delete this order?')) {
        fetch(`${ORDER_BASE_URL}/${orderId}`, {
            method: 'DELETE',
        })
        .then(response => response.json().then(resData => ({ ok: response.ok, data: resData })))
        .then(({ ok, data }) => {
            if (!ok) {
                alert('Error: ' + data.error);  // ← was: generic throw
                return;
            }
            console.log('Order deleted');
            getOrders();
        })
        .catch(error => console.error('Error:', error));
    }
}

function updateOrder() {
    var orderId = document.getElementById('order-id').value;
    var data = {
        product_id: parseInt(document.getElementById('product_id').value, 10),
        quantity: parseInt(document.getElementById('quantity').value, 10)
    };

    fetch(`${ORDER_BASE_URL}/${orderId}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    })
    .then(response => response.json().then(resData => ({ ok: response.ok, data: resData })))
    .then(({ ok, data }) => {
        if (!ok) {
            alert('Error: ' + data.error);  // ← was: resData.message
            return;
        }
        alert('Order updated successfully!');
        window.location.href = '/orders';
    })
    .catch(error => {
        console.error('Error:', error);
        alert('Error inesperado al actualizar la orden');
    });
}