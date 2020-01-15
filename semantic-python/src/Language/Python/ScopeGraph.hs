{-# LANGUAGE AllowAmbiguousTypes #-}
{-# LANGUAGE DataKinds #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
{-# LANGUAGE KindSignatures #-}
{-# LANGUAGE NamedFieldPuns #-}
{-# LANGUAGE PatternSynonyms #-}
{-# LANGUAGE RankNTypes #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# LANGUAGE TypeApplications #-}
{-# LANGUAGE TypeOperators #-}

module Language.Python.ScopeGraph
  ( scopeGraphModule
  ) where

import           Control.Effect.Sketch
import           Convert.ToScopeGraph (Result (..), complete, todo)
import           Data.Foldable
import qualified Data.List.NonEmpty as NonEmpty
import           Data.Name
import           Data.Typeable
import           GHC.Generics
import           GHC.Records
import           GHC.TypeLits
import           Language.Python.Core (pattern SingleIdentifier)
import           Source.Loc
import qualified TreeSitter.Python.AST as Py

-- This typeclass is internal-only, though it shares the same interface
-- as the one defined in semantic-scope-graph.
class Typeable t => ToScopeGraph t where
  scopeGraph ::
    ( Has (Sketch Name) sig m
    )
    => t Loc
    -> m Result

instance (ToScopeGraph l, ToScopeGraph r) => ToScopeGraph (l :+: r) where
  scopeGraph (L1 l) = scopeGraph l
  scopeGraph (R1 r) = scopeGraph r

onField ::
  forall (field :: Symbol) syn sig m r .
  ( Has (Sketch Name) sig m
  , HasField field (r Loc) (syn Loc)
  , ToScopeGraph syn
  )
  => r Loc
  -> m Result
onField
  = scopeGraph @syn
  . getField @field

onChildren ::
  ( Traversable t
  , ToScopeGraph syn
  , Has (Sketch Name) sig m
  , HasField "extraChildren" (r Loc) (t (syn Loc))
  )
  => r Loc
  -> m Result
onChildren
  = fmap fold
  . traverse scopeGraph
  . getField @"extraChildren"

scopeGraphModule :: Has (Sketch Name) sig m => Py.Module Loc -> m Result
scopeGraphModule = scopeGraph

instance ToScopeGraph Py.AssertStatement where scopeGraph = onChildren

instance ToScopeGraph Py.Assignment where
  scopeGraph (Py.Assignment _ (SingleIdentifier t) _val _typ) = complete <* declare @Name t DeclProperties
  scopeGraph x                                                = todo x

instance ToScopeGraph Py.Await where
  scopeGraph (Py.Await _ a) = scopeGraph a

instance ToScopeGraph Py.BooleanOperator where
  scopeGraph (Py.BooleanOperator _ _ left right) = mappend <$> scopeGraph left <*> scopeGraph right

instance ToScopeGraph Py.BinaryOperator where
  scopeGraph (Py.BinaryOperator _ _ left right) = mappend <$> scopeGraph left <*> scopeGraph right

instance ToScopeGraph Py.AugmentedAssignment where scopeGraph = onField @"right"

instance ToScopeGraph Py.Attribute where scopeGraph = todo

instance ToScopeGraph Py.Block where scopeGraph = onChildren

instance ToScopeGraph Py.BreakStatement where scopeGraph = const (pure mempty)

instance ToScopeGraph Py.Call where scopeGraph = todo

instance ToScopeGraph Py.ClassDefinition where scopeGraph = todo

instance ToScopeGraph Py.ConcatenatedString where scopeGraph = const (pure mempty)

deriving instance ToScopeGraph Py.CompoundStatement

instance ToScopeGraph Py.ConditionalExpression where scopeGraph = onChildren

instance ToScopeGraph Py.ContinueStatement where scopeGraph = const (pure mempty)

instance ToScopeGraph Py.DecoratedDefinition where scopeGraph = todo

instance ToScopeGraph Py.ComparisonOperator where scopeGraph = onChildren

instance ToScopeGraph Py.DeleteStatement where scopeGraph = const (pure mempty)

instance ToScopeGraph Py.Dictionary where scopeGraph = onChildren

instance ToScopeGraph Py.DictionaryComprehension where scopeGraph = todo

instance ToScopeGraph Py.DictionarySplat where scopeGraph = todo

deriving instance ToScopeGraph Py.Expression

instance ToScopeGraph Py.ElseClause where scopeGraph = onField @"body"

instance ToScopeGraph Py.ElifClause where
  scopeGraph (Py.ElifClause _ body condition) = mappend <$> scopeGraph condition <*> scopeGraph body

instance ToScopeGraph Py.Ellipsis where scopeGraph = const (pure mempty)

instance ToScopeGraph Py.ExceptClause where scopeGraph = onChildren

instance ToScopeGraph Py.ExecStatement where scopeGraph = const (pure mempty)

instance ToScopeGraph Py.ExpressionStatement where scopeGraph = onChildren

instance ToScopeGraph Py.ExpressionList where scopeGraph = onChildren

instance ToScopeGraph Py.False where scopeGraph _ = pure mempty

instance ToScopeGraph Py.FinallyClause where scopeGraph = onField @"extraChildren"

instance ToScopeGraph Py.Float where scopeGraph = const (pure mempty)

instance ToScopeGraph Py.ForStatement where scopeGraph = todo

instance ToScopeGraph Py.FunctionDefinition where scopeGraph = todo

instance ToScopeGraph Py.FutureImportStatement where scopeGraph = todo

instance ToScopeGraph Py.GeneratorExpression where scopeGraph = todo

instance ToScopeGraph Py.Identifier where
  scopeGraph (Py.Identifier _ name) = do
    reference @Name name name RefProperties
    complete


instance ToScopeGraph Py.IfStatement where
  scopeGraph (Py.IfStatement _ alternative body condition) = do
    con <- scopeGraph condition
    bod <- scopeGraph body
    alt <- traverse scopeGraph alternative
    pure (fold (con : bod : alt))

instance ToScopeGraph Py.GlobalStatement where scopeGraph = todo

instance ToScopeGraph Py.Integer where scopeGraph = const (pure mempty)

instance ToScopeGraph Py.ImportStatement where scopeGraph = todo

instance ToScopeGraph Py.ImportFromStatement where scopeGraph = todo

instance ToScopeGraph Py.Lambda where scopeGraph = todo

instance ToScopeGraph Py.List where scopeGraph = onChildren

instance ToScopeGraph Py.ListComprehension where scopeGraph = todo

instance ToScopeGraph Py.ListSplat where scopeGraph = onChildren

instance ToScopeGraph Py.NamedExpression where scopeGraph = todo

instance ToScopeGraph Py.None where scopeGraph = const (pure mempty)

instance ToScopeGraph Py.NonlocalStatement where scopeGraph = todo

instance ToScopeGraph Py.Module where scopeGraph = onChildren

instance ToScopeGraph Py.ReturnStatement where
  scopeGraph (Py.ReturnStatement _ mVal) = maybe (pure mempty) scopeGraph mVal

instance ToScopeGraph Py.True where
  scopeGraph _ = pure mempty

instance ToScopeGraph Py.NotOperator where scopeGraph = onField @"argument"

instance ToScopeGraph Py.Pair where
  scopeGraph (Py.Pair _ value key) = mappend <$> scopeGraph key <*> scopeGraph value

instance ToScopeGraph Py.ParenthesizedExpression where scopeGraph = onField @"extraChildren"

instance ToScopeGraph Py.PassStatement where scopeGraph _ = pure mempty

instance ToScopeGraph Py.PrintStatement where
  scopeGraph (Py.PrintStatement _ args _chevron) = fold <$> traverse scopeGraph args

deriving instance ToScopeGraph Py.PrimaryExpression

deriving instance ToScopeGraph Py.SimpleStatement

instance ToScopeGraph Py.RaiseStatement where scopeGraph = todo

instance ToScopeGraph Py.Set where scopeGraph = onChildren

instance ToScopeGraph Py.SetComprehension where scopeGraph = todo

instance ToScopeGraph Py.String where scopeGraph _ = pure mempty

instance ToScopeGraph Py.Subscript where scopeGraph = todo

instance ToScopeGraph Py.Tuple where scopeGraph = onChildren

instance ToScopeGraph Py.TryStatement where
  scopeGraph (Py.TryStatement _ body elseClauses) = do
    bod <- scopeGraph body
    els <- traverse scopeGraph elseClauses
    pure (fold (NonEmpty.cons bod els))

instance ToScopeGraph Py.UnaryOperator where scopeGraph = onField @"argument"

instance ToScopeGraph Py.WhileStatement where
  scopeGraph Py.WhileStatement{ alternative, body, condition } = do
    con <- scopeGraph condition
    bod <- scopeGraph body
    alt <- maybe (pure mempty) scopeGraph alternative
    pure (con <> bod <> alt)

instance ToScopeGraph Py.WithStatement where
  scopeGraph = todo

instance ToScopeGraph Py.Yield where scopeGraph = onChildren