module Test.Main where

import Prelude

import Control.Monad.Aff (launchAff_, makeAff)
import Control.Monad.Aff.AVar (makeVar)
import Control.Monad.Aff.Console (log)
import Control.Monad.Eff (Eff)
import Control.Monad.Eff.Class (liftEff)
import Control.Monad.State as S
import Control.Transformers.Back.Trans (runBackT)
import Data.Function.Uncurried (runFn2)
import Data.Maybe (Maybe(..), fromMaybe)
import Data.StrMap (empty)
import Data.Tuple (Tuple(..))
import Presto.Core.Language.Runtime.API (APIRunner)
import Presto.Core.Language.Runtime.Interpreter (PermissionCheckRunner, PermissionRunner(..), PermissionTakeRunner, Runtime(..), UIRunner, run)
import Presto.Core.Types.App (AppEffects)
import Presto.Core.Types.Language.Flow (Flow, doAff, get, getS, goBack, set, setBackPoint, setS)
import Presto.Core.Types.Permission (Permission(..), PermissionStatus(..))
import Test.Spec.Reporter.Console (consoleReporter)

main :: forall e. Eff (AppEffects e) Unit
main = do
  let runtime = Runtime uiRunner permissionRunner apiRunner
  let freeFlow = (runBackT >>> S.evalStateT) (run runtime appFlow)
  launchAff_ (makeVar empty >>= freeFlow)
  where
    uiRunner :: UIRunner
    uiRunner a = pure ""

    permissionCheckRunner :: PermissionCheckRunner
    permissionCheckRunner x = pure PermissionGranted

    permissionTakeRunner :: PermissionTakeRunner
    permissionTakeRunner x = pure [Tuple PermissionSendSms PermissionGranted]

    permissionRunner :: PermissionRunner
    permissionRunner = PermissionRunner permissionCheckRunner permissionTakeRunner

    apiRunner :: APIRunner
    apiRunner request = pure ""

appFlow :: Flow Unit
appFlow = do
  doAff do log "Start"
  doAff do log "Setting back point"
  setBackPoint
  s <- get "key"
  doAff do log $ "Runs left: " <> (show $ fromMaybe 5 s)
  case s of
    Just 0 -> do
      doAff do log "Done"
      pure unit
    Just n -> do
      set "key" (n - 1)
      doAff do log "Going back"
      void goBack
      doAff do log "Went back. lol"
    Nothing -> do
      set "key" 5
      doAff do log "Going back"
      void goBack
      doAff do log "Went back.....LOL"
