-- rss.lua

local tracemem = rawget(_G, 'TRACE_MEM')

if tracemem then traceMemory('rss 1') end

require 'game/gameGlobals'
require 'game/gameHelpers'
require 'game/delegate'
require 'game/reconnect'
require 'game/messages'


if tracemem then traceMemory('rss 2') end

-- common

require 'game/structures/structures'
require 'game/common/floating_text/FramedFloatingText'
require 'game/common/floating_text/FrameFloatingTextTwo'
require 'game/common/floating_text/FloatingText'
require 'game/common/floating_text/FloatingTextList'
require 'game/common/floating_text/FloatingIconText'
require 'game/common/floating_text/FloatingTextFactory'
require 'game/common/floating_text/FloatingTextManager'
require 'game/common/FloatingTextUtil'
require 'game/common/SystemStatusUtil'
require 'game/common/MathUtil'
require 'game/common/ServerTime'
require 'game/common/UIUtil'
require 'game/common/MatrixUtil'
require 'game/common/matrix'
require 'game/common/QualityUtil'
require 'game/common/TeamUtil'
require 'game/common/ObjectFactory'
require 'game/common/AudioRecordUtil'
require 'game/common/BundleUtil'
require 'game/common/ColorUtil'
require 'game/common/motioncalculator'
require 'game/common/SceneUtil'
require 'game/common/ScrollListUtil'
require 'game/common/TouchUtil'
require 'game/common/GmUtil'
require 'game/common/TouchTracker'
require 'game/common/LongPressTracker'
require 'game/common/TouchButton'
require 'game/common/ClipUtil'
require 'game/common/IntervalChecker'
require 'game/common/Util'
require 'game/common/SplashUtil'
require 'game/common/DebugUtil'
require 'game/common/fvtween/fvtween'
require 'game/common/ai/BTFactory'
require 'game/config/Config'
require 'game/config/loc'

require 'game/lib/bt/bt'
require 'game/lib/fsm/fsm'



if tracemem then traceMemory('rss 3') end

-- login
require 'game/debug/BarGraph'
require 'game/debug/ProFiHelper'
require 'game/debug/NetGraphDrawer'
require 'game/debug/LuaTimeGraphDrawer'
require 'game/debug/LuaAllocGraphDrawer'
require 'game/debug/MemGraphDrawer'
require 'game/debug/StatsDrawer'
require 'game/debug/LuaLogDrawer'
require 'game/debug/FrameDebugger'
require 'game/debug/LuaScriptDebugger'
require 'game/debug/DebuggerView'

require 'game/login/BusyView'
require 'game/login/DebugServerScene'
require 'game/login/UpdatingScene'
require 'game/login/LoginViewBase'
require 'game/login/LoginViewTest'
require 'game/login/ChooseServerView'
require 'game/login/ServerSlotView'
require 'game/login/LoginTestScene'
require 'game/login/UserView'


if tracemem then traceMemory('rss 10') end

require 'game/ui/ui'
require 'game/ui/ViewFactory'
require 'game/common/EfxLoadTask'
require 'game/common/ParticleView'
require 'game/common/ParticleFactory'
require 'game/common/TableViewController'
require 'game/common/SliderUtil'
require 'game/common/CommonPopupView'
require 'game/common/CommonPopBuyView'
require 'game/common/BonusesView'

require 'game/login/QueuingPopup'
require 'game/login/FakeQueuingPopup'

if tracemem then traceMemory('rss 11') end

-- global model
require 'game/model/AccountBase'
require 'game/model/Model'
require 'game/PaymentManager'
require 'game/model/ModelPrivate'
require 'game/model/ModelRpc'
require 'game/model/ModelRpcAccount'
require 'game/model/ModelSignal'
require 'game/model/decorators/model_decorators'

if tracemem then traceMemory('rss 12') end

require 'game/main/ViewReseter'
require 'game/controller/controllers'

require 'game/combat/CombatConsts'
require 'game/combat/model/CardModel'
require 'game/combat/model/RoundModel'
require 'game/combat/model/IntegrationModel'
require 'game/combat/model/CharacterModel'
require 'game/combat/model/DeskModel'
require 'game/combat/view/CardView'
require 'game/combat/view/InteractiveView'
require 'game/combat/view/CharacterView'
require 'game/combat/view/DeskView'
require 'game/combat/view/MyPlayerView'
require 'game/combat/view/LeftPlayerView'
require 'game/combat/view/RightPlayerView'
require 'game/combat/view/CombatOverView'
require 'game/combat/ctrl/CombatController'
require 'game/combat/ctrl/CharacterCtrl'
require 'game/combat/ctrl/DeskCtrl'
require 'game/combat/RulerUtil'
require 'game/combat/ComputerAl'


if tracemem then traceMemory('rss 15') end


if tracemem then traceMemory('rss end') end
