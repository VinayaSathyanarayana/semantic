{-# LANGUAGE DataKinds, DeriveAnyClass, DeriveGeneric #-}
module Data.Syntax.Literal where

import Algorithm
import Data.Align.Generic
import Data.ByteString (ByteString)
import Data.Functor.Classes.Eq.Generic
import Data.Functor.Classes.Pretty.Generic
import Data.Functor.Classes.Show.Generic
import Data.Syntax (prettyBytes)
import GHC.Generics
import Prelude

-- Boolean

newtype Boolean a = Boolean Bool
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

true :: Boolean a
true = Boolean True

false :: Boolean a
false = Boolean False

instance Eq1 Boolean where liftEq = genericLiftEq
instance Show1 Boolean where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 Boolean where liftPretty = genericLiftPretty


-- Numeric

-- | A literal integer of unspecified width. No particular base is implied.
newtype Integer a = Integer { integerContent :: ByteString }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Data.Syntax.Literal.Integer where liftEq = genericLiftEq
instance Show1 Data.Syntax.Literal.Integer where liftShowsPrec = genericLiftShowsPrec

instance Pretty1 Data.Syntax.Literal.Integer where
  liftPretty _ _ (Integer s) = pretty ("Integer" :: Prelude.String) <+> prettyBytes s

-- TODO: Should IntegerLiteral hold an Integer instead of a ByteString?
-- TODO: Do we care about differentiating between hex/octal/decimal/binary integer literals?
-- TODO: Consider a Numeric datatype with FloatingPoint/Integral/etc constructors.

-- | A literal float of unspecified width.
newtype Float a = Float { floatContent :: ByteString }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Data.Syntax.Literal.Float where liftEq = genericLiftEq
instance Show1 Data.Syntax.Literal.Float where liftShowsPrec = genericLiftShowsPrec

instance Pretty1 Data.Syntax.Literal.Float where
  liftPretty _ _ (Float s) = pretty ("Float" :: Prelude.String) <+> prettyBytes s

-- Rational literals e.g. `2/3r`
newtype Rational a = Rational ByteString
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Data.Syntax.Literal.Rational where liftEq = genericLiftEq
instance Show1 Data.Syntax.Literal.Rational where liftShowsPrec = genericLiftShowsPrec

instance Pretty1 Data.Syntax.Literal.Rational where
  liftPretty _ _ (Rational s) = pretty ("Rational" :: Prelude.String) <+> prettyBytes s

-- Complex literals e.g. `3 + 2i`
newtype Complex a = Complex ByteString
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Data.Syntax.Literal.Complex where liftEq = genericLiftEq
instance Show1 Data.Syntax.Literal.Complex where liftShowsPrec = genericLiftShowsPrec

instance Pretty1 Complex where
  liftPretty _ _ (Complex s) = pretty ("Complex" :: Prelude.String) <+> prettyBytes s


-- Strings, symbols

newtype String a = String { stringElements :: [a] }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Data.Syntax.Literal.String where liftEq = genericLiftEq
instance Show1 Data.Syntax.Literal.String where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 Data.Syntax.Literal.String where liftPretty = genericLiftPretty

-- TODO: Should string literal bodies include escapes too?

-- | An interpolation element within a string literal.
newtype InterpolationElement a = InterpolationElement { interpolationBody :: a }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 InterpolationElement where liftEq = genericLiftEq
instance Show1 InterpolationElement where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 InterpolationElement where liftPretty = genericLiftPretty


-- | A sequence of textual contents within a string literal.
newtype TextElement a = TextElement { textElementContent :: ByteString }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 TextElement where liftEq = genericLiftEq
instance Show1 TextElement where liftShowsPrec = genericLiftShowsPrec

instance Pretty1 TextElement where
  liftPretty _ _ (TextElement s) = pretty ("TextElement" :: Prelude.String) <+> prettyBytes s

data Null a = Null
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Null where liftEq = genericLiftEq
instance Show1 Null where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 Null where liftPretty = genericLiftPretty

newtype Symbol a = Symbol { symbolContent :: ByteString }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Symbol where liftEq = genericLiftEq
instance Show1 Symbol where liftShowsPrec = genericLiftShowsPrec

instance Pretty1 Symbol where
  liftPretty _ _ (Symbol s) = pretty ("Symbol" :: Prelude.String) <+> prettyBytes s

-- TODO: Heredoc-style string literals?
-- TODO: Character literals.
-- TODO: Regular expressions.


-- Collections

newtype Array a = Array { arrayElements :: [a] }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Array where liftEq = genericLiftEq
instance Show1 Array where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 Array where liftPretty = genericLiftPretty


newtype Hash a = Hash { hashElements :: [a] }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Hash where liftEq = genericLiftEq
instance Show1 Hash where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 Hash where liftPretty = genericLiftPretty

data KeyValue a = KeyValue { key :: !a, value :: !a }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 KeyValue where liftEq = genericLiftEq
instance Show1 KeyValue where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 KeyValue where liftPretty = genericLiftPretty


newtype Tuple a = Tuple { tupleContents :: [a]}
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Tuple where liftEq = genericLiftEq
instance Show1 Tuple where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 Tuple where liftPretty = genericLiftPretty


newtype Set a = Set { setElements :: [a] }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Set where liftEq = genericLiftEq
instance Show1 Set where liftShowsPrec = genericLiftShowsPrec
instance Pretty1 Set where liftPretty = genericLiftPretty

-- TODO: Object literals as distinct from hash literals? Or coalesce object/hash literals into “key-value literals”?
-- TODO: Function literals (lambdas, procs, anonymous functions, what have you).
-- TODO: Regexp literals.
