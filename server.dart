import 'dart:convert';
import 'package:mysql1/mysql1.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class User {
  final int id;
  final String username;
  final String email;

  User(this.id, this.username, this.email);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}

final dbHost = 'localhost';
final dbUser = 'username';
final dbPassword = 'password';
final dbName = 'dbname';

Future<List<User>> getUsers() async {
  final settings = ConnectionSettings(
    host: dbHost,
    port: 3306,
    user: dbUser,
    password: dbPassword,
    db: dbName,
  );

  final conn = await MySqlConnection.connect(settings);
  final results = await conn.query('SELECT * FROM users');
  await conn.close();

  return results
      .map((row) => User(row['id'], row['username'], row['email']))
      .toList();
}

Response handleRequest(Request request) {
  switch (request.url.path) {
    case '/users':
      final users = getUsers();
      final responseJson = jsonEncode(users.map((user) => user.toJson()).toList());
      return Response.ok(responseJson, headers: {'Content-Type': 'application/json'});
    default:
      return Response.notFound('Not Found');
  }
}

void main() async {
  final app = Router();
  app.get('/<ignored|.*>', handleRequest);

  final server = await shelf_io.serve(app, 'localhost', 8080);
  print('Server listening on ${server.address}:${server.port}');
}
