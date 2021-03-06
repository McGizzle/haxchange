{-# LANGUAGE DeriveAnyClass             #-}
{-# LANGUAGE DeriveFunctor              #-}
{-# LANGUAGE DeriveGeneric              #-}
{-# LANGUAGE GADTs                      #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE OverloadedStrings          #-}
{-# OPTIONS_GHC -fno-warn-incomplete-patterns #-}
module Haxchange.Types where

import           Data.Aeson
import           Data.ByteString     (ByteString)
import           Data.Map            (Map)
import           Data.Monoid         ((<>))
import           Data.Semigroup      (Semigroup)
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

data APIKeys = APIKeys ByteString ByteString
-------------------------------------

class FromText a where
        fromText :: Text -> a

class ToText a where
        toText :: a -> Text

data Currency =
        FIAT Currency'
      | COIN Currency'
      | NA Text
 deriving(Eq,Show,Read,Generic,Ord)

instance ToText Currency where
        toText (FIAT a) = toText a
        toText (COIN a) = toText a
        toText (NA a)   = a

instance FromText Currency where
        fromText "EUR"  = FIAT EUR
        fromText "CAD"  = FIAT CAD
        fromText "JPY"  = FIAT JPY
        fromText "USDT" = FIAT USDT
        fromText "BTC"  = COIN BTC
        fromText "XBT"  = COIN BTC
        fromText "ETH"  = COIN ETH
        fromText "BNB"  = COIN BNB
        fromText "XRP"  = COIN XRP
        fromText "LTC"  = COIN LTC
        fromText "ADA"  = COIN ADA
        fromText "NAV"  = COIN NAV
        fromText "XLM"  = COIN XLM
        fromText a      = NA a

data Currency' =
        EUR
      | USDT
      | CAD
      | JPY
      | BTC
      | XRP
      | ETH
      | LTC
      | BNB
      | ADA
      | NAV
      | XLM
      | Text
      deriving(Show,Eq,Read,Generic,Ord)

instance FromJSON Currency'

instance ToText Currency' where
        toText EUR  = "EUR"
        toText USDT = "USDT"
        toText CAD  = "CAD"
        toText JPY  = "JPY"
        toText BTC  = "BTC"
        toText XRP  = "XRP"
        toText ETH  = "ETH"
        toText LTC  = "LTC"
        toText BNB  = "BNB"
        toText ADA  = "ADA"
        toText NAV  = "NAV"
        toText XLM  = "XLM"


newtype Markets = Markets { unMarkets :: [Market]}
        deriving(Show,Eq,Read)

data Market = Market Currency Currency | MarketNA
        deriving (Show,Eq,Read,Semigroup)

instance Ord Market where
        (Market c1 c2) `compare` (Market c1' c2') = (c1 `compare` c1') `compare` (c2 `compare` c2')

instance Monoid Market where
        mempty = MarketNA

instance ToText Market where
        toText (Market a b) = toText a <> toText b

newtype Balance = Balance (Map Currency Float)
        deriving(Show,Generic)

newtype Tickers = Tickers { unTickers :: [Ticker] }
        deriving(Show,Eq)

data Ticker =
        Ticker {
                 tickerMarket    :: Market
               , tickerBid       :: Float
               , tickerAsk       :: Float
               , tickerAskVolume :: Float
               , tickerBidVolume :: Float
               }
         deriving (Eq,Show,Generic)

instance Ord Ticker where
        (Ticker m1 _ _ _ _) `compare` (Ticker m2 _ _ _ _) = m1 `compare` m2

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
