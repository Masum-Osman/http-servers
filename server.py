from http.server import BaseHTTPRequestHandler, HTTPServer
import json
import pymysql

# MySQL connection settings
DB_HOST = 'localhost'
DB_USER = 'username'
DB_PASSWORD = 'password'
DB_NAME = 'dbname'

class UserHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/users':
            try:
                connection = pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASSWORD, db=DB_NAME)
                cursor = connection.cursor()

                query = "SELECT * FROM users"
                cursor.execute(query)

                users = []
                for row in cursor.fetchall():
                    user = {'id': row[0], 'username': row[1], 'email': row[2]}
                    users.append(user)

                response = json.dumps(users)

                self.send_response(200)
                self.send_header('Content-type', 'application/json')
                self.end_headers()
                self.wfile.write(response.encode('utf-8'))
                
                cursor.close()
                connection.close()
            except pymysql.Error as e:
                print("MySQL Error:", e)
                self.send_response(500)
                self.send_header('Content-type', 'text/plain')
                self.end_headers()
                self.wfile.write('500 Internal Server Error'.encode('utf-8'))
        else:
            self.send_response(404)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write('404 Not Found'.encode('utf-8'))

def run_server():
    host = 'localhost'
    port = 8080

    server = HTTPServer((host, port), UserHandler)
    print('Server started on http://{}:{}'.format(host, port))
    server.serve_forever()

if __name__ == '__main__':
    run_server()
