@Grab(group='mysql', module='mysql-connector-java', version='8.0.26')
@Grab(group='org.json', module='json', version='20210307')

import groovy.json.JsonOutput
import groovy.json.JsonSlurper
import java.sql.DriverManager

class User {
    int id
    String username
    String email
}

def handleGetUsers(connection, client) {
    def statement = connection.createStatement()
    def query = "SELECT * FROM users"
    def result = statement.executeQuery(query)

    def users = []
    while (result.next()) {
        def user = new User(id: result.getInt("id"), username: result.getString("username"), email: result.getString("email"))
        users << user
    }

    def responseJson = JsonOutput.toJson(users)
    def response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n${responseJson}"
    client.outputStream << response
}

def handleRequest(connection, client, request) {
    def lines = request.split("\r\n")
    def [method, path, httpVersion] = lines[0].split("\\s+")

    if (path == "/users" && method == "GET") {
        handleGetUsers(connection, client)
    } else {
        def response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\n404 Not Found"
        client.outputStream << response
    }
}

def startServer(connection) {
    def server = new ServerSocket(8080)

    println("Server started on http://localhost:8080")

    while (true) {
        def client = server.accept()

        def request = client.inputStream.newReader().readLine()
        handleRequest(connection, client, request)

        client.close()
    }
}

def url = "jdbc:mysql://localhost:3306/dbname"
def username = "username"
def password = "password"

def connection = DriverManager.getConnection(url, username, password)

startServer(connection)
