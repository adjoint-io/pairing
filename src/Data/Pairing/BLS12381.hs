{-# OPTIONS -fno-warn-orphans #-}

module Data.Pairing.BLS12381
  ( module Data.Pairing
  -- * BLS12381 curve
  , BLS12381
  , parameterBin
  , parameterHex
  -- ** Fields
  , Fq
  , Fq2
  , Fq6
  , Fq12
  , Fr
  -- ** Groups
  , G1'
  , G2'
  , GT'
  -- ** Roots of unity
  , getRootOfUnity
  ) where

import Protolude

import Data.Curve.Weierstrass.BLS12381 as G1
import Data.Curve.Weierstrass.BLS12381T as G2
import Data.Field.Galois as F

import Data.Pairing (Pairing(..))
import Data.Pairing.Ate (finalExponentiationBLS12, millerAlgorithm)

-------------------------------------------------------------------------------
-- Fields
-------------------------------------------------------------------------------

-- | Cubic nonresidue.
xi :: Fq2
xi =
  [ 0xd0088f51cbff34d258dd3db21a5d66bb23ba5c279c2895fb39869507b587b120f55ffff58a9ffffdcff7fffffffd556
  , 0xd0088f51cbff34d258dd3db21a5d66bb23ba5c279c2895fb39869507b587b120f55ffff58a9ffffdcff7fffffffd555
  ]
{-# INLINABLE xi #-}

-- | @Fq6@.
type Fq6 = Extension V Fq2
data V
instance IrreducibleMonic V Fq2 where
  poly _ = [-xi, 0, 0, 1]
  {-# INLINABLE poly #-}

-- | @Fq12@.
type Fq12 = Extension W Fq6
data W
instance IrreducibleMonic W Fq6 where
  poly _ = [[0, -1], 0, 1]
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
  gen = toU'
    [ [ [ 0x1250ebd871fc0a92a7b2d83168d0d727272d441befa15c503dd8e90ce98db3e7b6d194f60839c508a84305aaca1789b6
        , 0x89a1c5b46e5110b86750ec6a532348868a84045483c92b7af5af689452eafabf1a8943e50439f1d59882a98eaa0170f
        ]
      , [ 0x31ee0cf8176faed3d5e214d37e4837b518958ee5c39b2997f01e9ffb9e533bf5cb7335184e4b9b91c232bd7551f5ef
        , 0x333fc379662be784e4ed53bc809b8c242cd5c26049b5dbe98b3e9599912e2523dbb28ca5f0764eaa9980581f5dd5f5b
        ]
      , [ 0x1434ca7627208b631fab9fe851983efa300f78c547c61f10017a080635adb658fcc639b4ed513fdb10cb2a9862a855e3
        , 0x129cac1291d7cede0e5c448a7fa1879dd6e1d4579d8748542c3a143f14588050bf3874ac39dc273dff6d6e70dadc272b
        ]
      ]
    , [ [ 0xf84ad8722c9486446b9d04ee5c12b31ca548f26fc85317fa4ae45dcacca2709ef1851df07d1c7ac4d23a6ebf1a82869
        , 0x140766a9b0c7736808ab0e3042aa7be8dd368d5062528949fb7c4413b0f51b6d7989a629b646c3ea8eed395c68774a20
        ]
      , [ 0xe83a4cf2599c26539d4183cce2597a90179aa3ac63883345c450f5245902578fd4737c27d92fcef5d7122d2718820b5
        , 0x14edc37a74f7bc0cc00ab7d3a7f085e28ebb7d2b9ba3b19a9dd51cacb1a07799f497594dbed2f8a2d9b64613f63d53f9
        ]
      , [ 0x12f6c0f91a404c38fd5629091c63e94df3020950c1adc74636d2cca650f75efe9f15ba1a87a57f85ff69a0640ea93d83
        , 0x6ecf38c504bc3b9f13ba96c27fbaa763995b521b26e8bb21f46fb401dc62936b863f0edd45760f665c063e9ba54e90c
        ]
      ]
    ]
  {-# INLINABLE gen #-}

-------------------------------------------------------------------------------
-- Pairings
-------------------------------------------------------------------------------

-- | Parameter in signed binary.
parameterBin :: [Int8]
parameterBin = [-1,-1, 0,-1, 0, 0,-1, 0, 0, 0, 0, 0, 0, 0, 0,-1, 0
                  , 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
                  , 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,-1, 0
                  , 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
               ]
{-# INLINABLE parameterBin #-}

-- | Parameter in hexadecimal.
parameterHex :: Integer
parameterHex = -0xd201000000010000
{-# INLINABLE parameterHex #-}

-- BLS12381 curve is pairing-friendly.
instance Pairing BLS12381 where

  type instance G1 BLS12381 = G1'

  type instance G2 BLS12381 = G2'

  type instance GT BLS12381 = GT'

  finalStep = const $ const snd
  {-# INLINABLE finalStep #-}

  lineFunction (A x y) (A x1 y1) (A x2 y2) f
    | x1 /= x2         = (A x3 y3, (<>) f $ toU' [embed (-y), [x *^ l, y1 - l * x1]])
    | y1 + y2 == 0     = (O, (<>) f $ toU' [embed x, embed (-x1)])
    | otherwise        = (A x3' y3', (<>) f $ toU' [embed (-y), [x *^ l', y1 - l' * x1]])
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

  pairing p q = finalExponentiationBLS12 parameterHex $
                finalStep p q $ millerAlgorithm parameterBin p q
  {-# INLINABLE pairing #-}

-------------------------------------------------------------------------------
-- Roots of unity
-------------------------------------------------------------------------------

-- | Precompute primitive roots of unity for binary powers that divide _r - 1.
getRootOfUnity :: Int -> Fr
getRootOfUnity 0  = 1
getRootOfUnity 1  = 52435875175126190479447740508185965837690552500527637822603658699938581184512
getRootOfUnity 2  = 3465144826073652318776269530687742778270252468765361963008
getRootOfUnity 3  = 28761180743467419819834788392525162889723178799021384024940474588120723734663
getRootOfUnity 4  = 35811073542294463015946892559272836998938171743018714161809767624935956676211
getRootOfUnity 5  = 32311457133713125762627935188100354218453688428796477340173861531654182464166
getRootOfUnity 6  = 6460039226971164073848821215333189185736442942708452192605981749202491651199
getRootOfUnity 7  = 3535074550574477753284711575859241084625659976293648650204577841347885064712
getRootOfUnity 8  = 21071158244812412064791010377580296085971058123779034548857891862303448703672
getRootOfUnity 9  = 12531186154666751577774347439625638674013361494693625348921624593362229945844
getRootOfUnity 10 = 21328829733576761151404230261968752855781179864716879432436835449516750606329
getRootOfUnity 11 = 30450688096165933124094588052280452792793350252342406284806180166247113753719
getRootOfUnity 12 = 7712148129911606624315688729500842900222944762233088101895611600385646063109
getRootOfUnity 13 = 4862464726302065505506688039068558711848980475932963135959468859464391638674
getRootOfUnity 14 = 36362449573598723777784795308133589731870287401357111047147227126550012376068
getRootOfUnity 15 = 30195699792882346185164345110260439085017223719129789169349923251189180189908
getRootOfUnity 16 = 46605497109352149548364111935960392432509601054990529243781317021485154656122
getRootOfUnity 17 = 2655041105015028463885489289298747241391034429256407017976816639065944350782
getRootOfUnity 18 = 42951892408294048319804799042074961265671975460177021439280319919049700054024
getRootOfUnity 19 = 26418991338149459552592774439099778547711964145195139895155358980955972635668
getRootOfUnity 20 = 23615957371642610195417524132420957372617874794160903688435201581369949179370
getRootOfUnity 21 = 50175287592170768174834711592572954584642344504509533259061679462536255873767
getRootOfUnity 22 = 1664636601308506509114953536181560970565082534259883289958489163769791010513
getRootOfUnity 23 = 36760611456605667464829527713580332378026420759024973496498144810075444759800
getRootOfUnity 24 = 13205172441828670567663721566567600707419662718089030114959677511969243860524
getRootOfUnity 25 = 10335750295308996628517187959952958185340736185617535179904464397821611796715
getRootOfUnity 26 = 51191008403851428225654722580004101559877486754971092640244441973868858562750
getRootOfUnity 27 = 24000695595003793337811426892222725080715952703482855734008731462871475089715
getRootOfUnity 28 = 18727201054581607001749469507512963489976863652151448843860599973148080906836
getRootOfUnity 29 = 50819341139666003587274541409207395600071402220052213520254526953892511091577
getRootOfUnity 30 = 3811138593988695298394477416060533432572377403639180677141944665584601642504
getRootOfUnity 31 = 43599901455287962219281063402626541872197057165786841304067502694013639882090
getRootOfUnity 32 = 937917089079007706106976984802249742464848817460758522850752807661925904159
getRootOfUnity _  = panic "getRootOfUnity: exponent too big for Fr / negative"
{-# INLINABLE getRootOfUnity #-}
