module Plutarch.Crypto (
  psha2_256,
  psha3_256,
  pblake2b_256,
  pverifySignature,
  PPubKey (..),
  PPubKeyHash (..),
  PSignature (..),
) where

import Plutarch (punsafeBuiltin)
import Plutarch.Bool (PBool)
import Plutarch.ByteString (PByteString)
import Plutarch.Prelude
import qualified PlutusCore as PLC
import Plutarch.API.V1 (PPubKey (..), PSignature (..), PPubKeyHash (..), PDatumHash)


-- | Hash a 'PByteString' using SHA-256.
psha2_256 :: Term s (PByteString :--> PByteString)
psha2_256 = punsafeBuiltin PLC.Sha2_256

-- | Hash a 'PByteString' using SHA3-256.
psha3_256 :: Term s (PByteString :--> PByteString)
psha3_256 = punsafeBuiltin PLC.Sha3_256

-- | Hash a 'PByteString' using Blake2B-256.
pblake2b_256 :: Term s (PByteString :--> PByteString)
pblake2b_256 = punsafeBuiltin PLC.Blake2b_256

-- | Verify the signature against the public key and message.
pverifySignature :: Term s (PPubKey :--> PDatumHash :--> PSignature :--> PBool)
pverifySignature = punsafeBuiltin PLC.VerifySignature
