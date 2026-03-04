from flask import Blueprint, request, jsonify
from users.models.user_model import Users
from db.db import db
from exceptions import BadRequestError, InternalServerError

user_controller = Blueprint('user_controller', __name__)

@user_controller.route('/api/users', methods=['GET'])
def get_users():
    print("listado de usuarios")
    users = Users.query.all()
    result = [{'id': user.id, 'name': user.name, 'email': user.email, 'username': user.username} for user in users]
    return jsonify(result)

@user_controller.route('/api/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    print("obteniendo usuario")
    user = Users.query.get_or_404(user_id)
    return jsonify({'id': user.id, 'name': user.name, 'email': user.email, 'username': user.username})

@user_controller.route('/api/users', methods=['POST'])
def create_user():
    print("creando usuario")
    data = request.json
    if not data:
        raise BadRequestError("No data provided.")
    new_user = Users(name=data['name'], email=data['email'], username=data['username'], password=data['password'])
    db.session.add(new_user)
    db.session.commit()
    return jsonify({'message': 'User created successfully'}), 201

@user_controller.route('/api/users/<int:user_id>', methods=['PUT', 'OPTIONS'])
def update_user(user_id):
    if request.method == 'OPTIONS':
        return jsonify({'message': 'CORS preflight OK'}), 200

    print(f"updating user {user_id}")
    user = Users.query.get_or_404(user_id)

    data = request.json
    if not data:
        raise BadRequestError("No data provided.")

    user.name = data.get('name', user.name)
    user.email = data.get('email', user.email)
    user.username = data.get('username', user.username)

    if data.get('password'):
        user.password = data['password']

    try:
        db.session.commit()
        return jsonify({
            'message': 'User updated successfully',
            'user': {'id': user.id, 'name': user.name, 'email': user.email}
        }), 200
    except Exception:
        db.session.rollback()
        raise InternalServerError()

@user_controller.route('/api/users/<int:user_id>', methods=['DELETE'])
def delete_user(user_id):
    user = Users.query.get_or_404(user_id)
    db.session.delete(user)
    db.session.commit()
    return jsonify({'message': 'User deleted successfully'})