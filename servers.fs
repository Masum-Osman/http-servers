open System
open System.Data
open MySql.Data.MySqlClient
open Newtonsoft.Json

// MySQL connection settings
let dbHost = "localhost"
let dbUser = "username"
let dbPassword = "password"
let dbName = "dbname"

// User type
type User =
    { Id : int
      Username : string
      Email : string }

// Convert User to JSON
let toJson user =
    JsonConvert.SerializeObject(user)

// Execute the SELECT query and fetch users from the database
let getUsers (conn: MySqlConnection) =
    let query = "SELECT * FROM users"
    use cmd = new MySqlCommand(query, conn)
    use reader = cmd.ExecuteReader()
    let rec readUsers acc =
        if reader.Read() then
            let user =
                { Id = reader.GetInt32(0)
                  Username = reader.GetString(1)
                  Email = reader.GetString(2) }
            readUsers (user::acc)
        else
            List.rev acc
    readUsers []

// Handle HTTP request
let handleRequest (conn: MySqlConnection) (context: HttpListenerContext) =
    match context.Request.Url.PathAndQuery with
    | "/users" ->
        let users = getUsers conn
        let responseString = toJson users
        let responseBytes = System.Text.Encoding.UTF8.GetBytes(responseString)
        context.Response.ContentType <- "application/json"
        context.Response.OutputStream.Write(responseBytes, 0, responseBytes.Length)
    | _ ->
        context.Response.StatusCode <- 404
        context.Response.StatusDescription <- "Not Found"

let main =
    let server = new HttpListener()
    server.Prefixes.Add("http://localhost:8080/")
    server.Start()
    printfn "Server started on http://localhost:8080"

    use conn = new MySqlConnection(sprintf "Server=%s;Uid=%s;Pwd=%s;Database=%s" dbHost dbUser dbPassword dbName)
    conn.Open()

    while true do
        let context = server.GetContext()
        handleRequest conn context
        context.Response.Close()
