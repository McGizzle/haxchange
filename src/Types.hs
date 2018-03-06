{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module Types where

import           Data.Aeson
import           Data.ByteString     (ByteString)
import           Data.Map            (Map)
import           Data.Monoid         ((<>))
import           Data.Text           (Text)
import qualified Data.Text           as Text
import           GHC.Generics
import           Network.HTTP.Client (HttpException (..))
import           Prelude             as P

-------------------------------------
type Params = [(Text,Text)]

data Opts =
        Opts {
               optPath       :: String
             , optParams     :: Params
             , optApiType    :: String
             , optApiVersion :: String
             , optApiPubKey  :: ByteString
             , optApiPrivKey :: ByteString
             , optPost       :: Params
             }

-------------------------------------

class TextConvert a where
        fromText :: Text -> a
        toText :: a -> Text

data Currency =
        FIAT Currency'
      | COIN Currency'
      | NA Text
 deriving(Eq,Show,Read,Generic,Ord)

instance TextConvert Currency where
        toText (FIAT a) = toText a
        toText (COIN a) = toText a
        toText (NA a)   = a

        fromText "EUR" = FIAT EUR
        fromText "BTC" = COIN BTC
        fromText "XBT" = COIN BTC
        fromText "XRP" = COIN XRP
        fromText "ETH" = COIN ETH
        fromText "LTC" = COIN LTC
        fromText a     = NA a

data Currency' =
        EUR
      | BTC
      | XRP
      | ETH
      | LTC
      | Text
        deriving(Show,Eq,Read,Generic,Ord)

instance FromJSON Currency'

instance TextConvert Currency' where
        toText EUR = "EUR"
        toText BTC = "BTC"
        toText XRP = "XRP"
        toText ETH = "ETH"
        toText LTC = "LTC"

        fromText "EUR" = EUR
        fromText "BTC" = BTC
        fromText "XBT" = BTC
        fromText "XRP" = XRP
        fromText "ETH" = ETH
        fromText "LTC" = LTC

newtype Markets = Markets { unMarkets :: [Market]}
        deriving(Show,Eq,Read)

data Market = Market Currency Currency
        deriving (Show,Eq,Read)

instance TextConvert Market where
        toText (Market a b) = toText a <> toText b

        fromText a = Market (fromText $ head s) (fromText $ P.last s)
                where s = Text.splitOn "-" a

newtype Balance = Balance (Map Currency Float)
        deriving(Show,Generic)

data Ticker =
        Ticker {
                 tickerBid       :: Float
               , tickerAsk       :: Float
               , tickerAskVolume :: Float
               , tickerBidVolume :: Float
               }
         deriving (Eq,Show,Generic)

data Order =
        Order {
                orderMarket :: Market
              , orderPrice  :: Text
              , orderVolume :: Text
              }
        deriving(Eq,Show,Generic)

newtype OrderId = OrderId Text
        deriving (Show,Generic)

newtype ServerTime = ServerTime Float
        deriving (Show,Generic)

--- ERRORS -------------------------------
data Error =
        Exception HttpException
      | ExchangeError [Err]
      | ParseError String
      | UnknownError String
      deriving Show

instance Eq Error where
        Exception _ == Exception _ = True
        ExchangeError a == ExchangeError b = a == b
        ParseError a == ParseError b = a == b
        _ == _ = False

data Err =
        UnknownAssetPair
      | InvalidArguments
      | Unavailable
      | Err Text
      deriving (Eq,Show)
