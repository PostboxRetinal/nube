// Atrapamos la IP dinámicamente
const ORDER_API_PORT = 5004; // Cambia esto si tu puerto de órdenes es distinto (ej. 5001)
const ORDER_BASE_URL = `http://${window.location.hostname}:${ORDER_API_PORT}/api/orders`;

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
                var deleteLink = document.createElement('button');
                deleteLink.textContent = 'Delete';
                deleteLink.className = 'btn btn-danger btn-sm';
                deleteLink.onclick = function() { deleteOrder(order.id); };
                actionsCell.appendChild(deleteLink);

                row.appendChild(actionsCell);
                orderListBody.appendChild(row);
            });
        })
        .catch(error => console.error('Error fetching orders:', error));
}

function createOrder() {
    var productId = parseInt(document.getElementById('product_id').value, 10);
    var quantity = parseInt(document.getElementById('quantity').value, 10);

    // Tu controlador de Python espera un objeto con una lista llamada "products"
    var payload = {
        products: [
            { id: productId, quantity: quantity }
        ]
    };

    fetch(ORDER_BASE_URL, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
    })
    .then(response => {
        return response.json().then(data => {
            if (!response.ok) {
                throw new Error(data.message || 'Error creating order');
            }
            return data;
        });
    })
    .then(data => {
        alert('Order created successfully!');
        getOrders(); // Recargamos la tabla
    })
    .catch(error => {
        console.error('Error:', error);
        alert(error.message);
    });
}

function deleteOrder(orderId) {
    if (confirm('Are you sure you want to delete this order?')) {
        fetch(`${ORDER_BASE_URL}/${orderId}`, {
            method: 'DELETE',
        })
        .then(response => {
            if (!response.ok) { throw new Error('Network response was not ok'); }
            return response.json();
        })
        .then(data => {
            console.log('Order deleted:', data);
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
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    })
    .then(response => {
        return response.json().then(resData => {
            if (!response.ok) {
                throw new Error(resData.message || 'Error updating order');
            }
            return resData;
        });
    })
    .then(data => {
        console.log('Order updated:', data);
        alert('Order updated successfully!');
        window.location.href = '/orders'; // Redirigir a la lista de órdenes
    })
    .catch(error => {
        console.error('Error:', error.message);
        alert('Error updating order: ' + error.message);
    });
}