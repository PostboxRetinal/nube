const USER_API_PORT = 5002;
const USER_BASE_URL = `http://${window.location.hostname}:${USER_API_PORT}/api/users`;

function getUsers() {
    fetch(USER_BASE_URL)
        .then(response => response.json())
        .then(data => {
            console.log(data);

            var userListBody = document.querySelector('#user-list tbody');
            userListBody.innerHTML = ''; 

            data.forEach(user => {
                var row = document.createElement('tr');

                var nameCell = document.createElement('td');
                nameCell.textContent = user.name;
                row.appendChild(nameCell);

                var emailCell = document.createElement('td');
                emailCell.textContent = user.email;
                row.appendChild(emailCell);

                var usernameCell = document.createElement('td');
                usernameCell.textContent = user.username;
                row.appendChild(usernameCell);

                var actionsCell = document.createElement('td');

                var editLink = document.createElement('a');
                editLink.href = `/editUser/${user.id}`;
                editLink.textContent = 'Edit';
                editLink.className = 'btn btn-primary mr-2';
                actionsCell.appendChild(editLink);

                var deleteLink = document.createElement('a');
                deleteLink.href = '#';
                deleteLink.textContent = 'Delete';
                deleteLink.className = 'btn btn-danger';
                deleteLink.addEventListener('click', function() {
                    deleteUser(user.id);
                });
                actionsCell.appendChild(deleteLink);

                row.appendChild(actionsCell);
                userListBody.appendChild(row);
            });
        })
        .catch(error => console.error('Error:', error));
}

function createUser() {
    var data = {
        name: document.getElementById('name').value,
        email: document.getElementById('email').value,
        username: document.getElementById('username').value,
        password: document.getElementById('password').value
    };

    fetch(USER_BASE_URL, {
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

function updateUser() {
    var userId = document.getElementById('user-id').value;
    var data = {};

    var name = document.getElementById('name').value;
    if (name) data.name = name;

    var email = document.getElementById('email').value;
    if (email) data.email = email;

    var username = document.getElementById('username').value;
    if (username) data.username = username;

    var password = document.getElementById('password').value;
    if (password) data.password = password;

    fetch(`${USER_BASE_URL}/${userId}`, {
        method: 'PUT',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
    })
    .then(response => {
        if (!response.ok) {
            return response.json().then(err => { throw new Error(err.error || 'Error en la actualización'); });
        }
        return response.json();
    })
    .then(data => {
        console.log('Usuario actualizado:', data);
        alert('Usuario actualizado correctamente');
    })
    .catch(error => {
        console.error('Error:', error.message);
        alert('Error al actualizar: ' + error.message);
    });
}

function deleteUser(userId) {
    console.log('Deleting user with ID:', userId);
    if (confirm('Are you sure you want to delete this user?')) {
        fetch(`${USER_BASE_URL}/${userId}`, {
            method: 'DELETE',
        })
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.json();
        })
        .then(data => {
            console.log('User deleted successfully:', data);
            getUsers();
        })
        .catch(error => {
            console.error('Error:', error);
        });
    }
}