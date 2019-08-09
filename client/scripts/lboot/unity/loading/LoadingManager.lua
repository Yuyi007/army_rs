class("LoadingManager", function(self, options)
  self.options = options
  if self.options.mute == nil then self.options.mute = true end
  self:construct()
end)

local m = LoadingManager
local unity = unity

function m:construct()
  unity.beginSample('LoadingManager.construct')

  self.lastPercent = 0
  self.broadcast = self.options.broadcast
  self.onProgress = self.options.onProgress
  self.onComplete = self.options.onComplete
  self.tree = self.options.tree
  self.bundles = self.tree.bundles
  self.tree.bundles = nil
  self.countAll = self.tree:getCount()
  self.progressCountAll = self.tree:getProgressCount()
  self.countFinish = 0
  self.progressCountFinish = 0
  self.progressInfo = {percent = 0, curTaskInfo = nil}
  self:initRoutines()

  unity.endSample()
end

function m:initRoutines()
  self.tree:iterateLeaves(function(taskNode)
      taskNode:registerOnFinish(function(taskNode)
          self.countFinish = self.countFinish + 1
          self.progressCountFinish = self.progressCountFinish + (taskNode.count or 1)

          self.progressInfo.percent = self:getPercent()
          self.progressInfo.curTaskInfo = taskNode:getTaskInfo()

          self.progressInfo.total = self.progressCountAll
          self.progressInfo.cur = self.progressCountFinish

          -- logd("load percent: %s", tostring(self.progressInfo.percent))
          self:sendLoadingAction()

          if self.onProgress then
            self.onProgress(self.progressInfo)
          end

          if self.countFinish == self.countAll then
            self:procAfterComplete()
            if self.onComplete then
              --scheduler.performWithDelay(5, function() 
                  self.onComplete() 
                  --self.onComplete = nil

                --end)
              -- self.onComplete()
            end

            self.onProgress = nil
            self.onComplete = nil
          end
        end)
    end)
end

function m:procBeforeStart()
  -- sm:mute(self.options.mute)
  -- if self.options.mute then
  --   sm:stopMusic()
  -- end
  if UnityEngine.ThreadPriority then
    Application.backgroundLoadingPriority = UnityEngine.ThreadPriority.Normal
  end
end

function m:procAfterComplete()
  if UnityEngine.ThreadPriority then
    Application.backgroundLoadingPriority = UnityEngine.ThreadPriority.Low
  end
end

function m:sendLoadingAction()
  if not self.broadcast then 
    return 
  end

  local percent = self.progressInfo.percent
  local enlarge = math.floor(percent * 100)
  if enlarge > 100 then return end 
  if self.lastPercent >= enlarge  then return end

  local inc = (enlarge - self.lastPercent)
  if inc >= 1 or enlarge <= 100 then
    local action = ActionFactory.make("refree", "load_progress")
    action.data.percent = percent
    action.data.pid = md:pid()
    cc:sendCtrlAction(action)
  
    self.lastPercent = enlarge
  end
end

function m:getPercent()
  return (self.progressCountFinish / self.progressCountAll)
end

function m:start()
  unity.recordTime('LoadingManager.start')
  unity.beginSample('LoadingManager.start')
  logd('LoadingManager: start')

  self:procBeforeStart()
  self.tree:startLoad()
  self:startMonitorLoadTree()

  unity.endSample()
end

-- check load status of load tree, force finish if taking too long
function m:startMonitorLoadTree()
  self:stopMonitorLoadTree()
  logd('LoadingManager: startMonitorLoadTree')
  self.loadMonitor = coroutineStart(function ()
    while true do
      local tree = self.tree
      if not tree then
        logd('LoadingManager: load tree is nil, stop monitoring')
        return
      end
      if tree.finished then
        logd('LoadingManager: tree has finished, stop monitoring')
        return
      end
      
      tree:iterateLeaves(function(taskNode)
        if tree.finished then
          -- logd('LoadingManager: tree has finished')
          return
        end

        self:checkTaskNode(taskNode)
        coroutine.yield()
      end)
    end
  end)
end

function m:checkTaskNode(task)
  if task.startLoadTime and not task.finished then
    local now = Time:get_time()
    local time = now - task.startLoadTime
    local name = tostring(task.name or task.classname)

    if time >= 30 then
      if game.debug > 0 and game.mode == 'development' then
        FloatingTextFactory.makeNormal{text=string.format('Task %s timeout!!!!', name)}
      end
      loge('LoadingManager: task %s timeout!!!!', name)

      -- if not self.autoLogSent then
      --   DebugUtil.sendLogsToServer({
      --     isAutoLog = true,
      --   })
      --   self.autoLogSent = true
      -- end
    end

    if time >= 60 then
      logd('LoadingManager: task %s timeout asset=%s', name, peek(task.asset))
      loge('LoadingManager: force finishing task %s, good luck...', name)
      task:finish()
    end
  end
end

function m:stopMonitorLoadTree()
  if self.loadMonitor then
    logd('LoadingManager: stopMonitorLoadTree')
    scheduler.unschedule(self.loadMonitor)
  end
end

function m:stop()
  logd('LoadingManager: stop')

  self.tree:stopLoad()

  self:stopMonitorLoadTree()
end


