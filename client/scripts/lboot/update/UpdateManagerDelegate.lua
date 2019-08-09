-- UpdateManagerDelegate.lua

-----------------------------------------------------------
-- UpdateManager Sub Module: DelegateWithComponents
-- calls delegate methods on update manager components
-- forwards delegate methods to other delegates
-----------------------------------------------------------

class('DelegateWithComponents', function (self, delegate, verifier)
  self.delegate = delegate
  self.verifier = verifier

  delegateTo(self, self.delegate)
end)

function DelegateWithComponents:onUpdateComplete(msg)
  if self.verifier and type(self.verifier.onUpdateComplete) == 'function' then
    local status, err = pcall(function () self.verifier:onUpdateComplete() end)
    if not status then logd('verifier onUpdateComplete failed: ' .. tostring(err)) end
  end

  self.delegate:onUpdateComplete(msg)
end

function DelegateWithComponents:onUpdateInterrupted(msg)
  if self.verifier and type(self.verifier.onUpdateInterrupted) == 'function' then
    local status, err = pcall(function () self.verifier:onUpdateInterrupted() end)
    if not status then logd('verifier onUpdateInterrupted failed: ' .. tostring(err)) end
  end

  self.delegate:onUpdateInterrupted(msg)
end

function DelegateWithComponents:setCallbacks(onProgress, onError, onComplete)
  self.delegate.onProgress = onProgress
  self.delegate.onError = onError
  self.delegate.onComplete = onComplete
end

----------------------------------------------------
-- UpdateManager Sub Module: UpdateManagerDelegate
----------------------------------------------------

class('UpdateManagerDelegate', function (self, manager, onProgress, onError, onComplete)
  self.manager = manager
  self.info = manager.info
  self.onProgress = onProgress
  self.onError = onError
  self.onComplete = onComplete
end)

function UpdateManagerDelegate:onUpdateSkip(msg)
  self.onComplete(self.info, msg)
end

function UpdateManagerDelegate:onUpdateComplete(msg)
  engine.saveUserPrefs({
    ['app.lastUpdate'] = os.time(),
    ['app.version.' .. tostring(game.pkgVersion)] = self.manager.version
  })

  -- print statistics
  logd("--- Update statistics ---")
  logd("firstUpdate = " .. tostring(self.info.firstUpdate))
  logd("duration = " .. tostring(self.info.duration))
  logd("total = " .. tostring(self.info.total))
  logd("package = " .. tostring(self.info.package))
  logd("verified = " .. tostring(self.info.verified))
  logd("excluded = " .. tostring(self.info.excluded))
  logd("localUpdated = " .. tostring(self.info.localUpdated))
  logd("downloaded = " .. tostring(self.info.downloaded))
  logd("concurrentDownloads = " .. tostring(self.manager.options.concurrentDownloads))
  logd("updated to version " .. tostring(self.manager.version))

  self.onComplete(self.info, msg)
end

function UpdateManagerDelegate:onUpdateProgress(msg)
  self.onProgress(self.info, msg)
end

function UpdateManagerDelegate:onUpdateError(msg)
  self.onError(self.info, msg)
end

function UpdateManagerDelegate:onUpdateInterrupted(msg)
end

------------------------------------------------------------
-- UpdateManager Sub Module: BasicUpdateManagerDelegate
------------------------------------------------------------

class('BasicUpdateManagerDelegate', function (self, info, onProgress, onError, onComplete)
  self.info = info
  self.onProgress = onProgress
  self.onError = onError
  self.onComplete = onComplete
end)

function BasicUpdateManagerDelegate:onUpdateSkip(msg)
  if self.onComplete then
    self.onComplete(self.info, msg)
  end
end

function BasicUpdateManagerDelegate:onUpdateComplete(msg)
  if self.onComplete then
    self.onComplete(self.info, msg)
  end
end

function BasicUpdateManagerDelegate:onUpdateProgress(msg)
  if self.onProgress then
    self.onProgress(self.info, msg)
  end
end

function BasicUpdateManagerDelegate:onUpdateError(msg)
  if self.onError then
    self.onError(self.info, msg)
  end
end

function BasicUpdateManagerDelegate:onUpdateInterrupted(msg)
end
