{-# OPTIONS -fno-warn-orphans #-}

module Data.Pairing.BN254D
  ( module Data.Pairing
  -- * BN254D curve
  , BN254D
  ) where

import Protolude

import Data.Curve.Weierstrass.BN254D as G1
import Data.Curve.Weierstrass.BN254DT as G2
import Data.Field.Galois as F
import Data.Poly.Semiring (monomial)

import Data.Pairing (Pairing(..))
import Data.Pairing.Ate (millerBN)
import Data.Pairing.Temp (conj)

-------------------------------------------------------------------------------
-- Fields
-------------------------------------------------------------------------------

-- | Cubic nonresidue.
xi :: Fq2
xi = 1 + U
{-# INLINABLE xi #-}

-- | @Fq6@.
type Fq6 = Extension V Fq2
data V
instance IrreducibleMonic V Fq2 where
  poly _ = X3 - monomial 0 xi
  {-# INLINABLE poly #-}

-- | @Fq12@.
type Fq12 = Extension W Fq6
data W
instance IrreducibleMonic W Fq6 where
  poly _ = X2 - Y X
  {-# INLINABLE poly #-}

-------------------------------------------------------------------------------
-- Curves
-------------------------------------------------------------------------------

-- | @G1@.
type G1' = G1.PA

-- | @G2@.
type G2' = G2.PA

-- | @GT@.
type GT' = RootsOfUnity R Fq12
instance CyclicSubgroup (RootsOfUnity R Fq12) where
  gen = toU' $
    toE' [ toE' [ toE' [ 0x162b1d8d5992ddbc4b1076b1608602b3a438540fdc62c78d28e15fd6b6d6488c
                       , 0x6a832abcf68a00ed481a0ae12884aae74b9e585eaae5f91f1273dff1b8c6fd5
                       ]
                , toE' [ 0x15a890f5d421f6d5789b7f6050ca410d198e7e1430e1d80d107e46656070a80
                       , 0x1f6aab0d6ba73556752142d26c7bb6ef91b265df48c606082014f7873a1bca05
                       ]
                , toE' [ 0x9a13a2b4214af1e30eda1e9a4fdb6940e0e0fc62ca99a5d443e05f8adcbd02
                       , 0xd9027e6080d657ef24a6de965df5b0b617677a4fb3aa875031bc85a42939fc
                       ]
                ]
         , toE' [ toE' [ 0x14c86295586eb7e9e845856758b7dd1f58cfa86b54d849bfccd5bfc266b356f1
                       , 0x15680ac39a5277f9c3d06881fe9326ec57556ec4a7d5bece1cc2fd9e5e3485ac
                       ]
                , toE' [ 0x173023031e9636fcb5a1cc9cdf755b5c5d6ac8d020b46f78e360204c1c5491d3
                       , 0x2b1de2e77e75107774ec7b3d2f6a0f50a5826e03ab0a0ed2b0c16bae064bbbf
                       ]
                , toE' [ 0x1883ed794f464284271515eed4d7079c3b002b3b58ecda27daaa8195a4d091ee
                       , 0x14f0f67248ac6b81b7aafe8a2623fe52774c5258761c5c6e96ea45df4c055681
                       ]
                ]
         ]
  {-# INLINABLE gen #-}

-------------------------------------------------------------------------------
-- Pairings
-------------------------------------------------------------------------------

-- BN254D curve is pairing-friendly.
instance Pairing BN254D where

  type instance G1 BN254D = G1'

  type instance G2 BN254D = G2'

  type instance GT BN254D = GT'

  finalExponentiation f = flip F.pow expVal . finalExponentiationFirstChunk <$> f
    where
      expVal = div (qq * (qq - 1) + 1) $ F.char (witness :: Fr)
      qq     = join (*) $ F.char (witness :: Fq)
  {-# INLINABLE finalExponentiation #-}

  frobFunction (A x y) = A (F.frob x * x') (F.frob y * y')
    where
      x' = pow xi $ quot (F.char (witness :: Fq) - 1) 3
      y' = pow xi $ shiftR (F.char (witness :: Fq)) 1
  frobFunction _       = O
  {-# INLINABLE frobFunction #-}

  lineFunction (A x y) (A x1 y1) (A x2 y2) f
    | x1 /= x2         = (A x3 y3, (<>) f . toU' $ toE' [embed (-y), toE' [x *^ l, y1 - l * x1]])
    | y1 + y2 == 0     = (O, (<>) f . toU' $ toE' [embed x, embed (-x1)])
    | otherwise        = (A x3' y3', (<>) f . toU' $ toE' [embed (-y), toE' [x *^ l', y1 - l' * x1]])
    where
      l   = (y2 - y1) / (x2 - x1)
      x3  = l * l - x1 - x2
      y3  = l * (x1 - x3) - y1
      x12 = x1 * x1
      l'  = (x12 + x12 + x12) / (y1 + y1)
      x3' = l' * l' - x1 - x2
      y3' = l' * (x1 - x3') - y1
  lineFunction _ _ _ _ = (O, mempty)
  {-# INLINABLE lineFunction #-}

  -- t = -4611688221751935493
  -- s = -27670129330511612956
  pairing = (.) finalExponentiation . millerBN
    [-1,-1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
       , 0, 0, 0, 0,-1,-1, 0, 0, 0, 0, 0, 0, 0,-1,-1, 0
       , 0, 0, 0, 0, 0, 0,-1, 0, 0,-1, 0, 0, 0, 0,-1,-1
       , 0, 0, 0, 0,-1,-1, 0, 0, 0, 0, 0,-1,-1,-1, 0, 0
    ]
  {-# INLINABLE pairing #-}

finalExponentiationFirstChunk :: Fq12 -> Fq12
finalExponentiationFirstChunk f
  | f == 0 = 0
  | otherwise = let f1 = conj f
                    f2 = recip f
                    newf0 = f1 * f2 -- == f^(_q ^6 - 1)
                in F.frob (F.frob newf0) * newf0 -- == f^((_q ^ 6 - 1) * (_q ^ 2 + 1))
{-# INLINABLE finalExponentiationFirstChunk #-}