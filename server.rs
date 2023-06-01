use mysql::prelude::*;
use mysql::*;

#[derive(Debug, PartialEq, Eq, Serialize, Deserialize)]
struct User {
    id: i32,
    username: String,
    email: String,
}

fn handle_get_users(pool: &mysql::Pool, stream: &mut mysql::Conn) -> Result<Vec<User>, mysql::Error> {
    let mut users = Vec::new();

    stream.query_iter("SELECT * FROM users")?
        .for_each(|row| {
            let (id, username, email) = mysql::from_row(row);
            users.push(User { id, username, email });
        });

    Ok(users)
}

fn handle_request(pool: &mysql::Pool, mut stream: mysql::Conn, request: &str) {
    let lines: Vec<&str> = request.lines().collect();
    let (method, path, _) = lines[0].split_whitespace().collect_tuple().unwrap();

    match (method, path) {
        ("GET", "/users") => {
            match handle_get_users(pool, &mut stream) {
                Ok(users) => {
                    let response = format!("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{}", serde_json::to_string(&users).unwrap());
                    stream.write(response.as_bytes()).unwrap();
                }
                Err(err) => {
                    eprintln!("MySQL query error: {}", err);
                    let response = "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\n500 Internal Server Error";
                    stream.write(response.as_bytes()).unwrap();
                }
            }
        }
        _ => {
            let response = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\n404 Not Found";
            stream.write(response.as_bytes()).unwrap();
        }
    }
}

fn start_server(pool: mysql::Pool) {
    let listener = std::net::TcpListener::bind("127.0.0.1:8080").unwrap();
    println!("Server started on http://localhost:8080");

    for stream in listener.incoming() {
        match stream {
            Ok(mut stream) => {
                let pool = pool.clone();
                let mut request = String::new();
                stream.read_to_string(&mut request).unwrap();
                handle_request(&pool, stream, &request);
            }
            Err(err) => {
                eprintln!("Error accepting connection: {}", err);
            }
        }
    }
}

fn main() {
    let url = "mysql://username:password@localhost:3306/dbname";
    let pool = mysql::Pool::new(url).unwrap();

    start_server(pool);
}
