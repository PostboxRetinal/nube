function getProducts() {
    const host = window.location.hostname || 'localhost';
    const proto = window.location.protocol;
    const port = window.API_PRODUCTS_PORT || '5003';
    fetch(`${proto}//${host}:${port}/api/products`)
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
                deleteLink.addEventListener('click', function() {
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

    const host = window.location.hostname || 'localhost';
    const proto = window.location.protocol;
    const port = window.API_PRODUCTS_PORT || '5003';
    fetch(`${proto}//${host}:${port}/api/products`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
        console.log(data);
    })
    .catch(error => {
        console.error('Error:', error);
    });
}

function updateProduct(e) {
    if (e && typeof e.preventDefault === 'function') e.preventDefault();
    var productId = document.getElementById('product-id').value;
    var data = {
        name: document.getElementById('name').value,
        description: document.getElementById('description').value,
        price: parseFloat(document.getElementById('price').value),
        stock: parseInt(document.getElementById('stock').value, 10)
    };

    const host = window.location.hostname || 'localhost';
    const proto = window.location.protocol;
    const port = window.API_PRODUCTS_PORT || '5003';
    fetch(`${proto}//${host}:${port}/api/products/${productId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    })
    .then(response => {
        if (!response.ok) {
            throw new Error('Network response was not ok');
        }
        return response.json();
    })
    .then(data => {
        console.log(data);
    })
    .catch(error => {
        console.error('Error:', error);
    });
}

function deleteProduct(productId) {
    if (confirm('Are you sure you want to delete this product?')) {
        const host = window.location.hostname || 'localhost';
        const proto = window.location.protocol;
        const port = window.API_PRODUCTS_PORT || '5003';
        fetch(`${proto}//${host}:${port}/api/products/${productId}`, {
            method: 'DELETE',
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            console.log('Product deleted successfully:', data);
            getProducts();
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }
}
