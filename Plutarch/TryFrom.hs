{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE UndecidableInstances #-}
{-# LANGUAGE UndecidableSuperClasses #-}

module Plutarch.TryFrom (
  PTryFrom (..),
  ptryFrom,
  PSubtypeRelation (..),
  PSubtype,
  PSubtype',
  pupcast,
  pupcastF,
  pdowncastF,
) where

import Data.Kind (Constraint)
import Data.Proxy (Proxy (Proxy))

import Plutarch.Internal (PType, Term, punsafeCoerce)
import Plutarch.Internal.PlutusType (PContravariant, PCovariant, PInner)
import Plutarch.Internal.Witness (witness)

import Plutarch.Reducible (Reduce)

import GHC.TypeLits (ErrorMessage (ShowType, Text, (:<>:)), TypeError)

data PSubtypeRelation
  = SuperType
  | Unrelated PType PType

type family Helper (a :: PType) (b :: PType) (bi :: PType) (oa :: PType) (ob :: PType) :: PSubtypeRelation where
  Helper _ b b oa ob = 'Unrelated oa ob
  Helper a _ bi oa ob = PSubtype'' a bi oa ob

type family PSubtype'' (a :: PType) (b :: PType) (oa :: PType) (ob :: PType) :: PSubtypeRelation where
  PSubtype'' a a _ _ = 'SuperType
  PSubtype'' a b oa ob = Helper a b (PInner b) oa ob

type family PSubtype' (a :: PType) (b :: PType) :: PSubtypeRelation where
  PSubtype' a b = PSubtype'' a b a b

{- | @PSubtype a b@ constitutes a subtyping relation between @a@ and @b@.
 This concretely means that `\(x :: Term s b) -> punsafeCoerce x :: Term s a`
 is legal and sound.

 You can not make an instance for this yourself.
 You must use the 'PInner' type family of 'PlutusType' to get this instance.

 Caveat: Only @PInner a POpaque@ is considered unfortunately, as otherwise
 getting GHC to figure out the relation with multiple supertypes is quite hard.

 Subtyping is transitive.
-}
type family PSubtypeHelper (r :: PSubtypeRelation) :: Constraint where
  PSubtypeHelper ( 'Unrelated a b) =
    TypeError
      ( 'Text "\"" ':<>: 'ShowType a ':<>: 'Text "\""
          ':<>: 'Text " is not a subtype of "
          ':<>: 'Text "\""
          ':<>: 'ShowType b
          ':<>: 'Text "\""
      )
  PSubtypeHelper 'SuperType = ()

type family PSubtype (a :: PType) (b :: PType) :: Constraint where
  PSubtype a b = (PSubtype' a b ~ 'SuperType, PSubtypeHelper (PSubtype' a b))

{- |
@PTryFrom a b@ represents a subtyping relationship between @a@ and @b@,
and a way to go from @a@ to @b@.
Laws:
- @(punsafeCoerce . fst) <$> tcont (ptryFrom x) ≡ pure x@
-}
class PSubtype a b => PTryFrom (a :: PType) (b :: PType) where
  type PTryFromExcess a b :: PType
  type PTryFromExcess a b = PTryFromExcess a (PInner b)
  ptryFrom' :: forall s r. Term s a -> ((Term s b, Reduce (PTryFromExcess a b s)) -> Term s r) -> Term s r
  default ptryFrom' :: forall s r. (PTryFrom a (PInner b), PTryFromExcess a b ~ PTryFromExcess a (PInner b)) => Term s a -> ((Term s b, Reduce (PTryFromExcess a b s)) -> Term s r) -> Term s r
  ptryFrom' opq f = ptryFrom @(PInner b) @a opq \(inn, exc) -> f (punsafeCoerce inn, exc)

ptryFrom :: forall b a s r. PTryFrom a b => Term s a -> ((Term s b, Reduce (PTryFromExcess a b s)) -> Term s r) -> Term s r
ptryFrom = ptryFrom'

pupcast :: forall a b s. PSubtype a b => Term s b -> Term s a
pupcast = let _ = witness (Proxy @(PSubtype a b)) in punsafeCoerce

pupcastF :: forall a b (p :: PType -> PType) s. (PSubtype a b, PCovariant p) => Proxy p -> Term s (p b) -> Term s (p a)
pupcastF _ =
  let _ = witness (Proxy @(PSubtype a b))
      _ = witness (Proxy @(PCovariant p))
   in punsafeCoerce

pdowncastF :: forall a b (p :: PType -> PType) s. (PSubtype a b, PContravariant p) => Proxy p -> Term s (p a) -> Term s (p b)
pdowncastF _ =
  let _ = witness (Proxy @(PSubtype a b))
      _ = witness (Proxy @(PContravariant p))
   in punsafeCoerce
