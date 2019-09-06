{-# OPTIONS -fno-warn-orphans #-}

module Data.Pairing.BN254A
  ( module Data.Pairing
  -- * BN254A curve
  , B.BN254A
  -- ** Domain parameters
  , B.Fq
  , B.Fq2
  , B.Fq6
  , B.Fq12
  , B.Fr
  -- ** Optimal ate pairing
  , module Data.Pairing.BN254A.Ate
  ) where

import Data.Pairing
import Data.Pairing.BN254A.Ate
import qualified Data.Pairing.BN254A.Base as B

-------------------------------------------------------------------------------
-- BN254A curve
-------------------------------------------------------------------------------

-- Pairing of BN254A curve.
instance Pairing B.BN254A where

  type instance G1 B.BN254A = B.G1

  type instance G2 B.BN254A = B.G2

  type instance GT B.BN254A = B.GT

  pairing = reducedPairing
  {-# INLINABLE pairing #-}
