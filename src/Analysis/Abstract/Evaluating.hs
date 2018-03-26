{-# LANGUAGE DataKinds, GeneralizedNewtypeDeriving, MultiParamTypeClasses, ScopedTypeVariables, StandaloneDeriving, TypeApplications, TypeFamilies, TypeOperators, UndecidableInstances #-}
module Analysis.Abstract.Evaluating
  ( type Evaluating
  , evaluate
  , evaluates
  , evaluateWith
  , evaluatesWith
  , findValue
  , findEnv
  , findHeap
  , require
  , load
  ) where

import Control.Abstract.Evaluator
import Control.Monad.Effect
import Control.Monad.Effect.Resumable
import Data.Abstract.Configuration
import qualified Data.Abstract.Environment as Env
import Data.Abstract.Environment (Environment)
import Data.Abstract.Heap (Heap(..))
import qualified Data.Abstract.Exports as Export
import Data.Abstract.Exports (Exports)
import Data.Abstract.Evaluatable
import Data.Abstract.ModuleTable
import Data.Abstract.Value
import Data.Blob
import qualified Data.IntMap as IntMap
import Data.Language
import Data.List.Split (splitWhen)
import Prelude hiding (fail)
import Prologue hiding (throwError)
import qualified Data.ByteString.Char8 as BC
import qualified Data.Map as Map
import qualified Data.Map.Monoidal as Monoidal
import System.FilePath.Posix

-- | Evaluate a term to a value.
evaluate :: forall value term effects
         .  ( effects ~ RequiredEffects term value (Evaluating term value effects)
            , Evaluatable (Base term)
            , FreeVariables term
            , MonadAddressable (LocationFor value) value (Evaluating term value effects)
            , MonadValue value (Evaluating term value effects)
            , Recursive term
            , Show (LocationFor value)
            )
         => term
         -> Final effects value
evaluate = runAnalysis @(Evaluating term value) . evaluateModule

evaluateWith :: forall value term effects
             .  ( effects ~ RequiredEffects term value (Evaluating term value effects)
                , Evaluatable (Base term)
                , FreeVariables term
                , MonadAddressable (LocationFor value) value (Evaluating term value effects)
                , MonadValue value (Evaluating term value effects)
                , Recursive term
                , Show (LocationFor value)
                )
         => term
         -> term
         -> Final effects value
evaluateWith prelude t = runAnalysis @(Evaluating term value) $ do
  -- evaluateTerm here rather than evaluateModule
  -- TODO: we could add evaluatePrelude to MonadAnalysis as an alias for evaluateModule,
  -- overridden in Evaluating to not reset the environment. In the future we'll want the
  -- result of evaluating the Prelude to be a build artifact, rather than something that's
  -- evaluated every single time, but that's contingent upon a whole lot of other future
  -- scaffolding.
  preludeEnv <- evaluateTerm prelude *> getEnv
  withDefaultEnvironment preludeEnv (evaluateModule t)

-- | Evaluate terms and an entry point to a value.
evaluates :: forall value term effects
          .  ( effects ~ RequiredEffects term value (Evaluating term value effects)
             , Evaluatable (Base term)
             , FreeVariables term
             , MonadAddressable (LocationFor value) value (Evaluating term value effects)
             , MonadValue value (Evaluating term value effects)
             , Recursive term
             , Show (LocationFor value)
             )
          => [(Blob, term)] -- List of (blob, term) pairs that make up the program to be evaluated
          -> (Blob, term)   -- Entrypoint
          -> Final effects value
evaluates pairs (b, t) = runAnalysis @(Evaluating term value) (withModules b pairs (evaluateModule t))

-- | Evaluate terms and an entry point to a value with a given prelude.
evaluatesWith :: forall value term effects
              .  ( effects ~ RequiredEffects term value (Evaluating term value effects)
                 , Evaluatable (Base term)
                 , FreeVariables term
                 , MonadAddressable (LocationFor value) value (Evaluating term value effects)
                 , MonadValue value (Evaluating term value effects)
                 , Recursive term
                 , Show (LocationFor value)
                 )
              => term           -- ^ Prelude to evaluate once
              -> [(Blob, term)] -- ^ List of (blob, term) pairs that make up the program to be evaluated
              -> (Blob, term)   -- ^ Entrypoint
              -> Final effects value
evaluatesWith prelude pairs (b, t)  = runAnalysis @(Evaluating term value) $ do
  preludeEnv <- evaluateTerm prelude *> getEnv
  withDefaultEnvironment preludeEnv (withModules b pairs (evaluateModule t))

-- | Run an action with the passed ('Blob', @term@) pairs available for imports.
withModules :: MonadAnalysis term value m => Blob -> [(Blob, term)] -> m a -> m a
withModules Blob{..} pairs = localModuleTable (const moduleTable)
  where
    moduleTable = ModuleTable (Map.fromListWith (<>) (map (bimap moduleName pure) pairs))
    rootDir = dropFileName blobPath
    moduleName Blob{..} = let path = dropExtensions (makeRelative rootDir blobPath)
     in case blobLanguage of
      -- TODO: Need a better way to handle module registration and resolution
      Just Go -> toName (takeDirectory path) -- Go allows defining modules across multiple files in the same directory.
      _ ->  toName path
    toName str = qualifiedName (fmap BC.pack (splitWhen (== pathSeparator) str))

-- | Require/import another module by name and return it's environment and value.
--
-- Looks up the term's name in the cache of evaluated modules first, returns if found, otherwise loads/evaluates the module.
require :: (MonadAnalysis term value m, MonadValue value m)
        => ModuleName
        -> m (EnvironmentFor value, value)
require name = getModuleTable >>= maybe (load name) pure . moduleTableLookup name

-- | Load another module by name and return it's environment and value.
--
-- Always loads/evaluates.
load :: (MonadAnalysis term value m, MonadValue value m)
     => ModuleName
     -> m (EnvironmentFor value, value)
load name = askModuleTable >>= maybe notFound evalAndCache . moduleTableLookup name
  where
    notFound = fail ("cannot load module: " <> show name)
    evalAndCache :: (MonadAnalysis term value m, MonadValue value m) => [term] -> m (EnvironmentFor value, value)
    evalAndCache []     = (,) <$> pure mempty <*> unit
    evalAndCache [x]    = evalAndCache' x
    evalAndCache (x:xs) = do
      (env, _) <- evalAndCache' x
      (env', v') <- evalAndCache xs
      pure (env <> env', v')

    evalAndCache' :: (MonadAnalysis term value m) => term -> m (EnvironmentFor value, value)
    evalAndCache' x = do
      v <- evaluateModule x
      env <- filterEnv <$> getExports <*> getEnv
      modifyModuleTable (moduleTableInsert name (env, v))
      pure (env, v)

    -- TODO: If the set of exports is empty because no exports have been
    -- defined, do we export all terms, or no terms? This behavior varies across
    -- languages. We need better semantics rather than doing it ad-hoc.
    filterEnv :: Exports l a -> Environment l a -> Environment l a
    filterEnv ports env
      | Export.null ports = env
      | otherwise = Export.toEnvironment ports <> Env.overwrite (Export.aliases ports) env

-- | An analysis evaluating @term@s to @value@s with a list of @effects@ using 'Evaluatable', and producing incremental results of type @a@.
newtype Evaluating term value effects a = Evaluating (Eff effects a)
  deriving (Applicative, Functor, Effectful, Monad)

deriving instance Member Fail      effects => MonadFail   (Evaluating term value effects)
deriving instance Member Fresh     effects => MonadFresh  (Evaluating term value effects)
deriving instance Member NonDet    effects => Alternative (Evaluating term value effects)
deriving instance Member NonDet    effects => MonadNonDet (Evaluating term value effects)

-- | Effects necessary for evaluating (whether concrete or abstract).
type EvaluatingEffects term value
  = '[ Resumable Prelude.String value
     , Fail                                        -- Failure with an error message
     , State  (EnvironmentFor value)                      -- Environments (both local and global)
     , State  (HeapFor value)                             -- The heap
     , Reader (ModuleTable [term])                        -- Cache of unevaluated modules
     , Reader (EnvironmentFor value)                      -- Default environment used as a fallback in lookupEnv
     , State  (ModuleTable (EnvironmentFor value, value)) -- Cache of evaluated modules
     , State  (ExportsFor value)                          -- Exports (used to filter environments when they are imported)
     , State  (IntMap.IntMap term)                        -- For jumps
     ]

-- | Find the value in the 'Final' result of running.
findValue :: forall value term effects . (effects ~ RequiredEffects term value (Evaluating term value effects))
          => Final effects value -> Either Prelude.String (Either Prelude.String value)
findValue (((((v, _), _), _), _), _) = v

-- | Find the 'Environment' in the 'Final' result of running.
findEnv :: forall value term effects . (effects ~ RequiredEffects term value (Evaluating term value effects))
        => Final effects value -> EnvironmentFor value
findEnv (((((_, env), _), _), _), _) = env

-- | Find the 'Heap' in the 'Final' result of running.
findHeap :: forall value term effects . (effects ~ RequiredEffects term value (Evaluating term value effects))
         => Final effects value -> Monoidal.Map (LocationFor value) (CellFor value)
findHeap (((((_, _), Heap heap), _), _), _) = heap


instance Members '[Resumable Prelude.String value] effects => MonadThrow Prelude.String value (Evaluating term value effects) where
   throwException = raise . throwError

instance Members '[Fail, State (IntMap.IntMap term)] effects => MonadControl term (Evaluating term value effects) where
  label term = do
    m <- raise get
    let i = IntMap.size m
    raise (put (IntMap.insert i term m))
    pure i

  goto label = IntMap.lookup label <$> raise get >>= maybe (fail ("unknown label: " <> show label)) pure

instance Members '[ State (ExportsFor value)
                  , State (EnvironmentFor value)
                  , Reader (EnvironmentFor value)
                  ] effects => MonadEnvironment value (Evaluating term value effects) where
  getEnv = raise get
  putEnv = raise . put
  withEnv s = raise . localState s . lower

  defaultEnvironment = raise ask
  withDefaultEnvironment e = raise . local (const e) . lower

  getExports = raise get
  putExports = raise . put
  withExports s = raise . localState s . lower

  localEnv f a = do
    modifyEnv (f . Env.push)
    result <- a
    result <$ modifyEnv Env.pop

instance Member (State (HeapFor value)) effects => MonadHeap value (Evaluating term value effects) where
  getHeap = raise get
  putHeap = raise . put

instance Members '[Reader (ModuleTable [term]), State (ModuleTable (EnvironmentFor value, value))] effects => MonadModuleTable term value (Evaluating term value effects) where
  getModuleTable = raise get
  putModuleTable = raise . put

  askModuleTable = raise ask
  localModuleTable f a = raise (local f (lower a))

instance Members (EvaluatingEffects term value) effects => MonadEvaluator term value (Evaluating term value effects) where
  getConfiguration term = Configuration term mempty <$> getEnv <*> getHeap

instance ( Evaluatable (Base term)
         , FreeVariables term
         , Members (EvaluatingEffects term value) effects
         , MonadAddressable (LocationFor value) value (Evaluating term value effects)
         , MonadValue value (Evaluating term value effects)
         , Recursive term
         , Show (LocationFor value)
         )
         => MonadAnalysis term value (Evaluating term value effects) where
  type RequiredEffects term value (Evaluating term value effects) = EvaluatingEffects term value

  analyzeTerm term = resumeException @value (eval term) (\yield exc -> string (BC.pack exc) >>= yield)