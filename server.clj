(ns my-app.core
  (:gen-class)
  (:require [clojure.java.jdbc :as jdbc]
            [ring.adapter.jetty :as jetty]))

;; MySQL connection settings
(def db-host "localhost")
(def db-user "username")
(def db-password "password")
(def db-name "dbname")

;; Execute the SELECT query and fetch users from the database
(defn get-users []
  (jdbc/with-db-connection [conn {:host db-host :user db-user :password db-password :db db-name}]
    (jdbc/query conn ["SELECT * FROM users"])))

;; Handle HTTP request
(defn handle-request [request]
  (let [path (:uri request)]
    (cond (= path "/users")
          {:status 200
           :headers {"Content-Type" "application/json"}
           :body (get-users)}
          
          :else
          {:status 404
           :headers {"Content-Type" "text/plain"}
           :body "Not Found"})))

;; Start the server
(defn -main []
  (jetty/run-jetty (jetty/join-thread true) {:port 8080} (fn [request] (handle-request request))))
