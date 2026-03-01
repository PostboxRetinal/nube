const ORDER_BASE_URL = `http://${window.location.hostname}:${PORT_ORDERS}/api/orders`;

function getOrders() {
    fetch(ORDER_BASE_URL)
        .then(response => response.json())
        .then(data => {
            var tbody = document.querySelector('#order-list tbody');
            tbody.innerHTML = '';

            data.forEach(order => {
                var row = document.createElement('tr');

                var idCell = document.createElement('td');
                idCell.className = 'order-id';
                idCell.textContent = order.id.split('-')[0] + '…';
                idCell.title = order.id;
                row.appendChild(idCell);

                var userCell = document.createElement('td');
                userCell.textContent = order.user;
                row.appendChild(userCell);

                var totalCell = document.createElement('td');
                totalCell.textContent = order.total.toFixed(2);
                row.appendChild(totalCell);

                var createdCell = document.createElement('td');
                createdCell.textContent = order.created_at;
                row.appendChild(createdCell);

                var itemsCell = document.createElement('td');
                var toggleBtn = document.createElement('button');
                toggleBtn.className = 'btn btn-outline-secondary btn-sm';
                toggleBtn.textContent = `${order.items.length} item(s)`;
                toggleBtn.onclick = function() {
                    var itemsRow = document.getElementById('items-' + order.id);
                    if (itemsRow) {
                        itemsRow.style.display = itemsRow.style.display === 'none' ? '' : 'none';
                    }
                };
                itemsCell.appendChild(toggleBtn);
                row.appendChild(itemsCell);

                var actionsCell = document.createElement('td');
                var deleteBtn = document.createElement('button');
                deleteBtn.textContent = 'Delete';
                deleteBtn.className = 'btn btn-danger btn-sm';
                deleteBtn.onclick = function() { deleteOrder(order.id); };
                actionsCell.appendChild(deleteBtn);
                row.appendChild(actionsCell);

                tbody.appendChild(row);

                var itemsRow = document.createElement('tr');
                itemsRow.id = 'items-' + order.id;
                itemsRow.className = 'items-row';
                itemsRow.style.display = 'none';

                var itemsTd = document.createElement('td');
                itemsTd.colSpan = 6;

                var itemsTable = document.createElement('table');
                itemsTable.className = 'table items-table mb-0';

                var thead = itemsTable.createTHead();
                var headerRow = thead.insertRow();
                ['Product', 'Quantity', 'Subtotal ($)'].forEach(text => {  // ← was: 'Product ID'
                    var th = document.createElement('th');
                    th.textContent = text;
                    headerRow.appendChild(th);
                });

                var itbody = itemsTable.createTBody();
                order.items.forEach(item => {
                    var iRow = itbody.insertRow();
                    // Product name with ID as fallback
                    iRow.insertCell().textContent = item.product_name || `ID: ${item.product_id}`;  // ← new
                    iRow.insertCell().textContent = item.quantity;
                    iRow.insertCell().textContent = item.subtotal.toFixed(2);
                });

                itemsTd.appendChild(itemsTable);
                itemsRow.appendChild(itemsTd);
                tbody.appendChild(itemsRow);
            });
        })
        .catch(error => console.error('Error fetching orders:', error));
}

function deleteOrder(orderId) {
    if (confirm('Are you sure you want to delete this order?')) {
        fetch(`${ORDER_BASE_URL}/${orderId}`, {
            method: 'DELETE',
        })
        .then(response => response.json().then(resData => ({ ok: response.ok, data: resData })))
        .then(({ ok, data }) => {
            if (!ok) {
                alert('Error: ' + data.error);
                return;
            }
            getOrders();
        })
        .catch(error => console.error('Error:', error));
    }
}