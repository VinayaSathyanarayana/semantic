{-# LANGUAGE DeriveAnyClass #-}
module Data.Syntax.Expression where

import Algorithm
import Data.Align.Generic
import Data.Functor.Classes.Eq.Generic
import Data.Functor.Classes.Show.Generic
import Data.Mergeable
import GHC.Generics

-- | Typical prefix function application, like `f(x)` in many languages, or `f x` in Haskell.
data Call a = Call { callContext :: ![a], callFunction :: !a, callParams :: ![a], callBlock :: !a }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 Call where liftEq = genericLiftEq
instance Show1 Call where liftShowsPrec = genericLiftShowsPrec


data Comparison a
  = LessThan !a !a
  | LessThanEqual !a !a
  | GreaterThan !a !a
  | GreaterThanEqual !a !a
  | Equal !a !a
  | Comparison !a !a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 Comparison where liftEq = genericLiftEq
instance Show1 Comparison where liftShowsPrec = genericLiftShowsPrec


-- | Binary arithmetic operators.
data Arithmetic a
  = Plus !a !a
  | Minus !a !a
  | Times !a !a
  | DividedBy !a !a
  | Modulo !a !a
  | Power !a !a
  | Negate !a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 Arithmetic where liftEq = genericLiftEq
instance Show1 Arithmetic where liftShowsPrec = genericLiftShowsPrec

-- | Boolean operators.
data Boolean a
  = Or !a !a
  | And !a !a
  | Not !a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 Boolean where liftEq = genericLiftEq
instance Show1 Boolean where liftShowsPrec = genericLiftShowsPrec

-- | Javascript delete operator
newtype Delete a = Delete a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Delete where liftEq = genericLiftEq
instance Show1 Delete where liftShowsPrec = genericLiftShowsPrec

-- | A sequence expression such as Javascript or C's comma operator.
data SequenceExpression a = SequenceExpression { _firstExpression :: !a, _secondExpression :: !a }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 SequenceExpression where liftEq = genericLiftEq
instance Show1 SequenceExpression where liftShowsPrec = genericLiftShowsPrec

-- | Javascript void operator
newtype Void a = Void a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Void where liftEq = genericLiftEq
instance Show1 Void where liftShowsPrec = genericLiftShowsPrec

-- | Javascript typeof operator
newtype Typeof a = Typeof a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 Typeof where liftEq = genericLiftEq
instance Show1 Typeof where liftShowsPrec = genericLiftShowsPrec

-- | Bitwise operators.
data Bitwise a
  = BOr !a !a
  | BAnd !a !a
  | BXOr !a !a
  | LShift !a !a
  | RShift !a !a
  | Complement a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 Bitwise where liftEq = genericLiftEq
instance Show1 Bitwise where liftShowsPrec = genericLiftShowsPrec

-- | Member Access (e.g. a.b)
data MemberAccess a
  = MemberAccess !a !a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 MemberAccess where liftEq = genericLiftEq
instance Show1 MemberAccess where liftShowsPrec = genericLiftShowsPrec

-- | Subscript (e.g a[1])
data Subscript a
  = Subscript !a ![a]
  | Member !a !a
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 Subscript where liftEq = genericLiftEq
instance Show1 Subscript where liftShowsPrec = genericLiftShowsPrec

-- | Enumeration (e.g. a[1:10:1] in Python (start at index 1, stop at index 10, step 1 element from start to stop))
data Enumeration a = Enumeration { enumerationStart :: !a, enumerationEnd :: !a, enumerationStep :: !a }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 Enumeration where liftEq = genericLiftEq
instance Show1 Enumeration where liftShowsPrec = genericLiftShowsPrec

-- | InstanceOf (e.g. a instanceof b in JavaScript
data InstanceOf a = InstanceOf { instanceOfSubject :: !a, instanceOfObject :: !a }
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Show, Traversable)

instance Eq1 InstanceOf where liftEq = genericLiftEq
instance Show1 InstanceOf where liftShowsPrec = genericLiftShowsPrec

-- | ScopeResolution (e.g. import a.b in Python or a::b in C++)
data ScopeResolution a
  = ScopeResolution ![a]
  deriving (Diffable, Eq, Foldable, Functor, GAlign, Generic1, Mergeable, Show, Traversable)

instance Eq1 ScopeResolution where liftEq = genericLiftEq
instance Show1 ScopeResolution where liftShowsPrec = genericLiftShowsPrec
