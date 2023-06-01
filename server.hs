{-# LANGUAGE OverloadedStrings #-}

import Control.Exception (bracket)
import Data.Aeson (ToJSON, object, (.=))
import Data.ByteString.Lazy (ByteString)
import qualified Data.ByteString.Lazy.Char8 as LBS
import Database.MySQL.Simple

import Network.HTTP.Types (status200, status404, status500)
import Network.Wai (Application, Response, responseLBS)
import Network.Wai.Handler.Warp (run)

-- MySQL connection settings
dbHost = "localhost"
dbUser = "username"
dbPassword = "password"
dbName = "dbname"

-- User type
data User = User
  { userId :: Int
  , username :: String
  , email :: String
  } deriving (Show)

-- Convert User to JSON
instance ToJSON User where
  toJSON (User uid uname uemail) =
    object ["id" .= uid, "username" .= uname, "email" .= uemail]

-- Execute the SELECT query and fetch users from the database
getUsers :: Connection -> IO [User]
getUsers conn = query_ conn "SELECT * FROM users"

-- Handle HTTP request
handleRequest :: Connection -> Application
handleRequest conn req respond =
  case (rawPathInfo req) of
    "/users" ->
      getUsers conn >>= \users ->
        respond $
          responseLBS
            status200
            [("Content-Type", "application/json")]
            (encodeJson users)
    _ ->
      respond $
        responseLBS
          status404
          [("Content-Type", "text/plain")]
          "404 Not Found"

-- Encode a value to JSON
encodeJson :: ToJSON a => a -> ByteString
encodeJson = LBS.pack . show

main :: IO ()
main = do
  let settings = defaultConnectInfo {connectHost = dbHost, connectUser = dbUser, connectPassword = dbPassword, connectDatabase = dbName}
  bracket (connect settings) close $ \conn ->
    run 8080 (handleRequest conn)
