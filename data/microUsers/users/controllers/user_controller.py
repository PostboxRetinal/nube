from flask import Blueprint, request, jsonify
from users.models.user_model import Users
from db.db import db

user_controller = Blueprint('user_controller', __name__)

@user_controller.route('/api/users', methods=['GET'])
def get_users():
    print("listado de usuarios")
    users = Users.query.all()
    result = [{'id':user.id, 'name': user.name, 'email': user.email, 'username': user.username} for user in users]
    return jsonify(result)

# Get single user by id
@user_controller.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    print("obteniendo usuario")
    user = Users.query.get_or_404(user_id)
    return jsonify({'id': user.id, 'name': user.name, 'email': user.email, 'username': user.username})

@user_controller.route('/api/users', methods=['POST'])
def create_user():
    print("creando usuario")
    data = request.json
    #new_user = Users(name="oscar", email="oscar@gmail", username="omondragon", password="123")
    new_user = Users(name=data['name'], email=data['email'], username=data['username'], password=data['password'])
    db.session.add(new_user)
    db.session.commit()
    return jsonify({'message': 'User created successfully'}), 201

# Update an existing user
@user_controller.route('/api/users/<int:user_id>', methods=['PUT', 'OPTIONS'])
def update_user(user_id):
    # 1. Manejar la petición preflight de CORS
    if request.method == 'OPTIONS':
        return jsonify({'message': 'CORS preflight OK'}), 200

    print(f"actualizando usuario {user_id}")
    
    # 2. GET by ID: get_or_404 maneja el error 404 automáticamente si no existe
    user = Users.query.get_or_404(user_id)
    
    data = request.json
    if not data:
        return jsonify({'error': 'No se enviaron datos para actualizar'}), 400

    # 3. Merge: Actualizar solo los campos modificados (si no vienen, conserva el actual)
    user.name = data.get('name', user.name)
    user.email = data.get('email', user.email)
    user.username = data.get('username', user.username)
    
    # Lógica extra de seguridad: solo actualizar el password si realmente se envió uno nuevo
    if data.get('password'):
        user.password = data['password']

    # 4. Save: Persistir los cambios con manejo de errores
    try:
        db.session.commit()
        return jsonify({
            'message': 'User updated successfully',
            'user': {'id': user.id, 'name': user.name, 'email': user.email}
        }), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': 'Error interno del servidor al actualizar'}), 500

# Delete an existing user
@user_controller.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    user = Users.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    return jsonify({'message': 'User deleted successfully'})
