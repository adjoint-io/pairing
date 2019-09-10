{-# OPTIONS -fno-warn-orphans #-}

module Data.Pairing.BarretoNaehrig.BN254A
  ( module Data.Pairing
  , module Data.Pairing.BarretoNaehrig
  -- * BN254A curve
  , BN254A
  ) where

import Protolude

import Data.Pairing
import Data.Pairing.BarretoNaehrig
import Data.Pairing.BarretoNaehrig.Ate
import Data.Pairing.BarretoNaehrig.BN254A.Base

-------------------------------------------------------------------------------
-- BN254A curve
-------------------------------------------------------------------------------

-- BN254A curve is a pairing-friendly curve.
instance Pairing (BN BN254A) where

  type instance G1 (BN BN254A) = G1BN BN254A

  type instance G2 (BN BN254A) = G2BN BN254A

  type instance GT (BN BN254A) = GTBN BN254A

  pairing = (.) finalExponentiation . millerAlgorithm
  {-# INLINABLE pairing #-}
