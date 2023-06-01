#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <mysql/mysql.h>
#include <json-c/json.h>

#define MAX_BUFFER_SIZE 4096

typedef struct {
    int id;
    char username[50];
    char email[50];
} User;

void handleGetUsers(MYSQL* connection, int clientSocket) {
    MYSQL_RES* result;
    MYSQL_ROW row;
    char query[100];
    snprintf(query, sizeof(query), "SELECT * FROM users");

    if (mysql_query(connection, query)) {
        const char* error = mysql_error(connection);
        fprintf(stderr, "MySQL query error: %s\n", error);
        char response[] = "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\n500 Internal Server Error";
        send(clientSocket, response, sizeof(response) - 1, 0);
        return;
    }

    result = mysql_store_result(connection);
    if (result == NULL) {
        const char* error = mysql_error(connection);
        fprintf(stderr, "MySQL store result error: %s\n", error);
        char response[] = "HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\n500 Internal Server Error";
        send(clientSocket, response, sizeof(response) - 1, 0);
        return;
    }

    json_object* usersJson = json_object_new_array();

    while ((row = mysql_fetch_row(result))) {
        json_object* userJson = json_object_new_object();
        json_object_object_add(userJson, "id", json_object_new_int(atoi(row[0])));
        json_object_object_add(userJson, "username", json_object_new_string(row[1]));
        json_object_object_add(userJson, "email", json_object_new_string(row[2]));
        json_object_array_add(usersJson, userJson);
    }

    mysql_free_result(result);

    const char* usersJsonString = json_object_to_json_string(usersJson);

    char response[MAX_BUFFER_SIZE];
    snprintf(response, sizeof(response), "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n%s", usersJsonString);
    send(clientSocket, response, strlen(response), 0);

    json_object_put(usersJson);
}

void handleRequest(MYSQL* connection, int clientSocket, char* request) {
    char method[10];
    char path[100];
    char httpVersion[20];
    sscanf(request, "%s %s %s", method, path, httpVersion);

    if (strcmp(path, "/users") == 0 && strcmp(method, "GET") == 0) {
        handleGetUsers(connection, clientSocket);
    } else {
        char response[] = "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\n404 Not Found";
        send(clientSocket, response, sizeof(response) - 1, 0);
    }
}

void startServer(MYSQL* connection) {
    int serverSocket;
    int clientSocket;
    struct sockaddr_in serverAddress, clientAddress;

    serverSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (serverSocket == -1) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    serverAddress.sin_family = AF_INET;
    serverAddress.sin_addr.s_addr = INADDR_ANY;
    serverAddress.sin_port = htons(8080);

    if (bind(serverSocket, (struct sockaddr *)&serverAddress, sizeof(serverAddress)) < 0)
