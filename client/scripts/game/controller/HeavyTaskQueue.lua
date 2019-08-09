
-- HeavyTaskQueue is used to spread execution of multiple cpu-intensive tasks to
-- multiple frames to avoid hiccups in one frame

class('HeavyTaskQueue', function (self)
  self.queues = {}
  self:initQueues()
end)

local m = HeavyTaskQueue
local table, assert = table, assert
local unity = unity

m.QUEUE_OPTS = {
  loading = { },
  sys_msg = { executeOnFlush = true, },
}
m.debug = nil

function m.submit(queueName, taskName, taskFunc, a1, a2, a3)
  gcr.taskQueue:submitTask(queueName, taskName, taskFunc, a1, a2, a3)
end

function m.flushAll()
  gcr.taskQueue:flushTasks()
end

function m:initQueues()
  for name, _opts in pairs(m.QUEUE_OPTS) do
    if m.debug then
      logd('[HeavyTaskQueue:%s] init queue', name)
    end
    self.queues[name] = {}
  end
end

function m:submitTask(queueName, taskName, taskFunc, a1, a2, a3)
  if unity.isLoadingLevel or ui.loading then
    if m.debug then
      logd('[HeavyTaskQueue:%s] execute task %s (when loading)', queueName, taskName)
    end
    taskFunc(a1, a2, a3)
    return
  end

  local queue = self.queues[queueName]
  assert(queue, string.format('submitTask: queue %s is nil', queueName))

  if m.debug then
    logd('[HeavyTaskQueue:%s] enqueue task %s', queueName, taskName)
  end
  queue[#queue + 1] = {taskName, taskFunc, a1, a2, a3}

  if not self.handler then
    self:startUpdate()
  end
end

function m:startUpdate()
  self:stopUpdate()

  logd('[HeavyTaskQueue] startUpdate')
  self.handler = scheduler.schedule(function ()
    self:update()
  end, 0)
end

function m:stopUpdate()
  if self.handler then
    logd('[HeavyTaskQueue] stopUpdate')
    scheduler.unschedule(self.handler)
    self.handler = nil
  end
end

function m:update()
  for name, queue in pairs(self.queues) do
    self:dequeueOneTask(name, queue)
  end
end

function m:dequeueOneTask(name, queue)
  local item = table.remove(queue, 1)
  if item then
    local taskName, taskFunc, a1, a2, a3 = item[1], item[2], item[3], item[4], item[5]
    if m.debug then
      logd('[HeavyTaskQueue:%s] dequeue task %s', name, taskName)
    end
    taskFunc(a1, a2, a3)
    return true
  else
    return false
  end
end

function m:flushTasks()
  for name, queue in pairs(self.queues) do
    logd('[HeavyTaskQueue:%s] flush queue', name)
    if m.QUEUE_OPTS[name].executeOnFlush then
      while self:dequeueOneTask(name, queue) do
      end
    else
      table.clear(queue)
    end
  end

  self:stopUpdate()
end
