-- lboot_unity.lua

--[[

  The Foundation library
  To be required by app init

--]]

unity = rawget(_G, 'UnityEngine')
unity.Profiler = UnityEngine.Profiling.Profiler
require 'lboot/unity/lib/LuaValueType'
require 'lboot/unity/lib/functions/functions_unity'
require 'lboot/unity/lib/functions/functions_unity_log'
require 'lboot/unity/lib/functions/functions_unity_engine'
require 'lboot/unity/lib/functions/functions_unity_decorate'
require 'lboot/unity/lib/math/math'
require 'lboot/unity/lib/scheduler'

require 'lboot/unity/lib/decorators/GameObjectDecorator'
require 'lboot/unity/lib/decorators/TransformDecorator'
require 'lboot/unity/lib/decorators/LabelDecorator'
require 'lboot/unity/lib/decorators/SliderDecorator'
require 'lboot/unity/lib/decorators/ButtonDecorator'
require 'lboot/unity/lib/decorators/ToggleDecorator'
require 'lboot/unity/lib/decorators/ImageDecorator'
require 'lboot/unity/lib/decorators/ScrollRectDecorator'
require 'lboot/unity/lib/decorators/UI3DDecorator'
require 'lboot/unity/lib/decorators/GoTweenChainDecorator'
require 'lboot/unity/lib/decorators/ColorDecorator'
require 'lboot/unity/lib/decorators/Vector2Decorator'
require 'lboot/unity/lib/decorators/Vector3Decorator'
require 'lboot/unity/lib/decorators/Vector4Decorator'
require 'lboot/unity/lib/decorators/QuaternionDecorator'
require 'lboot/unity/lib/decorators/Matrix4x4Decorator'
require 'lboot/unity/lib/decorators/RectDecorator'
require 'lboot/unity/lib/decorators/RectTransformDecorator'
require 'lboot/unity/lib/decorators/CanvasDecorator'
require 'lboot/unity/lib/decorators/InputDecorator'
require 'lboot/unity/lib/decorators/TextExtendDecorator'
require 'lboot/unity/lib/decorators/TextWithIconDecorator'
require 'lboot/unity/lib/decorators/AudioSourceDecorator'
require 'lboot/unity/lib/decorators/FVRichTextDecorator'
require 'lboot/unity/lib/decorators/NicerOutlineDecorator'
require 'lboot/unity/lib/decorators/AnimatorDecorator'
require 'lboot/unity/lib/decorators/FVParticleRootDecorator'
-- init the unity
unity.init()

-- require 'lboot/unity/net/MsgEndpointUnitySocket'

require 'lboot/unity/views/ViewNode'
require 'lboot/unity/views/ViewBase'
require 'lboot/unity/views/ModalView'
require 'lboot/unity/views/View2D'
require 'lboot/unity/views/View3D'
require 'lboot/unity/views/ViewScene'
require 'lboot/unity/views/ViewUnique'
require 'lboot/unity/views/LightView'

require 'lboot/unity/utils/helpers_unity'

require 'lboot/unity/TransformCollection'
require 'lboot/unity/SpriteSheetCache'
require 'lboot/unity/GameObjectPool'
require 'lboot/unity/AssetBundleAssetLoader'
require 'lboot/unity/CachedAssetLoader'
require 'lboot/unity/UIManager'
require 'lboot/unity/UIMapper'
require 'lboot/unity/BundlePathCacher'
require 'lboot/unity/BindTree'
require 'lboot/unity/SoundManager'
require 'lboot/unity/CameraManager'
require 'lboot/unity/UnityObjectCache'
require 'lboot/unity/TouchEffectManager'
require 'lboot/unity/InputSource'
require 'lboot/unity/JoystickButtonTracker'


require 'lboot/unity/loading/LoadTaskNode'
require 'lboot/unity/loading/LoadAssetNode'
require 'lboot/unity/loading/LoadBranchNode'
require 'lboot/unity/loading/LoadIntervalUpdateNode'
require 'lboot/unity/loading/LoadRoutineNode'
require 'lboot/unity/loading/LoadingManager'
