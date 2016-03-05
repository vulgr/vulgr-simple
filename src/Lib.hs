{-# LANGUAGE DataKinds       #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeOperators   #-}
module Lib where

import Control.Monad.IO.Class (liftIO)
import Control.Monad.Trans.Either
import Data.Aeson
import Data.Monoid ((<>))
import qualified Data.Aeson.TH
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified Data.HashMap.Strict as M
import qualified Database.Neo4j as Neo
import qualified Database.Neo4j.Transactional.Cypher as TC
import Network.Wai
import Network.Wai.Handler.Warp
import Servant

import Vulgr.Gradle

import Debug.Trace

type API =
    "graph" :> ReqBody '[JSON] GradleDependencySpec
            :> Post '[JSON] T.Text
{-    :<|> "graph"
            :> Capture "appName" T.Text
            :> Capture "version" T.Text
            :> Get '[JSON] T.Text
-}

startApp :: IO ()
startApp = run 8080 app

app :: Application
app = serve api server

api :: Proxy API
api = Proxy

server :: Server API
server = graphDeps

getDepsFor :: T.Text -> T.Text -> GradleDependencySpec -> EitherT ServantErr IO T.Text
getDepsFor appName version gdeps = do
    eitherResult <- liftIO $ graphGradleDeps gdeps
    case eitherResult of
        Right _ -> pure ("Created dependency graph for " <> appName <> " " <> version)
        Left _  -> pure "Error...!"

graphDeps :: GradleDependencySpec -> EitherT ServantErr IO T.Text
graphDeps gdeps = do
    eitherResult <- liftIO $ graphGradleDeps gdeps
    case eitherResult of
        Right _ -> pure ("Created dependency graph for ")
        Left err  -> pure $ (fst err) <> " : " <> (snd err)

