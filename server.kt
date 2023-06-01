import com.google.gson.Gson
import spark.Spark.*
import java.sql.DriverManager

data class User(val id: Int, val username: String, val email: String)

fun main() {
    // MySQL connection settings
    val dbHost = "localhost"
    val dbUser = "username"
    val dbPassword = "password"
    val dbName = "dbname"

    // Configure Spark server
    port(8080)

    // Configure MySQL connection
    val connectionString = "jdbc:mysql://$dbHost/$dbName"
    val connection = DriverManager.getConnection(connectionString, dbUser, dbPassword)

    // JSON serializer
    val gson = Gson()

    // GET /users endpoint
    get("/users") { _, _ ->
        val users = getUsers(connection)
        gson.toJson(users)
    }

    // Stop server and close connection on shutdown
    Runtime.getRuntime().addShutdownHook(Thread {
        stop()
        connection.close()
    })
}

fun getUsers(connection: Connection): List<User> {
    val query = "SELECT * FROM users"
    val statement = connection.createStatement()
    val resultSet = statement.executeQuery(query)
    val users = mutableListOf<User>()

    while (resultSet.next()) {
        val id = resultSet.getInt("id")
        val username = resultSet.getString("username")
        val email = resultSet.getString("email")
        users.add(User(id, username, email))
    }

    return users
}
