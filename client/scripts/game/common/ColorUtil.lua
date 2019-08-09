
class('ColorUtil')

ColorUtil.brown_str           = "#3e1026"
ColorUtil.rose_str            = "#751e47"
ColorUtil.shallow_black_str   = "#17020c"
ColorUtil.shallow_gray_str    = "#272727"

ColorUtil.light_gray2_str     = "#494949"

ColorUtil.light_green         = "#fff800"

ColorUtil.silvery_str         = "#729eb9"

ColorUtil.yellow_str          = "#ffc500"

ColorUtil.light_gray_str      = "#b7794c"
ColorUtil.gray_str            = "#5a5a5a"

ColorUtil.red_str             = "#bb3925"
ColorUtil.pure_red_str        = "#ff0000"
ColorUtil.super_red_str       = "#fe0000"
ColorUtil.red3_str            = "#d30b08"
ColorUtil.robber_red_str      = "#f52020"

ColorUtil.light_white_str     = "#d7e0f4"
ColorUtil.white_str           = "#ffffff"

ColorUtil.green_str           = "#24b93d"
ColorUtil.dark_green_str      = "#003f07"
ColorUtil.bright_green_str    = "#18D931"

ColorUtil.light_green_str     = "#3c8d4a"
ColorUtil.purple_str          = "#e81ed7"
ColorUtil.dark_purple_str     = "#591753"

ColorUtil.light_blue_str      = "#9ed6ed"
ColorUtil.blue_str            = "#389fd5"
ColorUtil.dark_blue_str       = "#143a7a"
ColorUtil.grayish_blue        = "#1F4769FF"


ColorUtil.orange_str           = "#ff7e20"
ColorUtil.dark_orange_str      = "#67290b"
ColorUtil.super_light_blue_str = "#28314BFF"
ColorUtil.orange2_str          = "#ff6a2a"
ColorUtil.orange3_str          = "#ff7e1f"

ColorUtil.black_str              = "#000000"
ColorUtil.reseda_str             = "#63fe0d"
ColorUtil.starYellow_str         = '#ffd928'
ColorUtil.notCurrent_str         = '#ff5a00'
ColorUtil.brightRed_str          = '#cc1b00'
ColorUtil.deepGreen_str          = '#072c0d'
ColorUtil.deepRed_str            = '#400e07'
ColorUtil.rageBlue_str           = '#00ccff'
ColorUtil.rageRed_str            = '#f7362f'
ColorUtil.rageGray_str           = "#616161"
ColorUtil.subTitleYellow_str     = "#fddb69"
ColorUtil.bloodLineYellow_str    = "#f3e721"
ColorUtil.bloodLineBlue_str      = "#29a5ec"
ColorUtil.bloodLinePurple_str    = "#e013f2"
ColorUtil.snsGreed_str           = "#183a1f"
ColorUtil.snsBlue_str            = "#2f0c4f"
ColorUtil.employ_gray_str        = "#7a7a7a"
ColorUtil.channel_blue_str       = "#01a8ff"
ColorUtil.high_blue_str          = "#2d6693"
ColorUtil.orange_yellow_str      = "#ffA400ff"
ColorUtil.npc_social_ui_blue_str = "#323f72"

ColorUtil.faction_qigong_str  = "#00aeef"
ColorUtil.faction_rune_str    = "#00aeef"
ColorUtil.faction_shadow_str  = "#ff0099"
ColorUtil.faction_fire_str    = "#ff0099"
ColorUtil.faction_fighter_str = "#ffc500"
ColorUtil.faction_sanda_str   = "#ffc500"


ColorUtil.wushu_res_bg_win_str   = "#101e4d"
ColorUtil.wushu_res_bg_win_str2   = "#f8e017"
ColorUtil.wushu_res_bg_lose_str   = "#404040"

ColorUtil.hospital_yellow_str           = "#ffc500"
ColorUtil.hospital_orange_str           = "#ff7e20"
ColorUtil.hospital_red_str              = "#fe0000"


function ColorUtil.init()
  ColorUtil.super_red     = unity.newHexToColor(string.sub(ColorUtil.super_red_str, 2, 7))
  ColorUtil.brown         = unity.newHexToColor(string.sub(ColorUtil.brown_str, 2, 7))
  ColorUtil.rose          = unity.newHexToColor(string.sub(ColorUtil.rose_str, 2, 7))
  ColorUtil.shallow_black = unity.newHexToColor(string.sub(ColorUtil.shallow_black_str, 2, 7))
  ColorUtil.shallow_gray  = unity.newHexToColor(string.sub(ColorUtil.shallow_gray_str, 2, 7))
  ColorUtil.light_gray2   = unity.newHexToColor(string.sub(ColorUtil.light_gray2_str, 2, 7))

  ColorUtil.silvery       =  unity.newHexToColor(string.sub(ColorUtil.silvery_str, 2, 7))

  ColorUtil.yellow     = unity.newHexToColor(string.sub(ColorUtil.yellow_str, 2, 7))
  ColorUtil.light_blue = unity.newHexToColor(string.sub(ColorUtil.light_blue_str, 2, 7))
  ColorUtil.light_gray = unity.newHexToColor(string.sub(ColorUtil.light_gray_str, 2, 7))

  ColorUtil.light_green = unity.newHexToColor(string.sub(ColorUtil.light_green_str, 2, 7))
  ColorUtil.green       = unity.newHexToColor(string.sub(ColorUtil.green_str, 2, 7))
  ColorUtil.bright_green= unity.newHexToColor(string.sub(ColorUtil.bright_green_str, 2, 7))

  ColorUtil.blue        = unity.newHexToColor(string.sub(ColorUtil.blue_str, 2, 7))
  ColorUtil.purple      = unity.newHexToColor(string.sub(ColorUtil.purple_str, 2, 7))
  ColorUtil.orange      = unity.newHexToColor(string.sub(ColorUtil.orange_str, 2, 7))

  ColorUtil.dark_green  = unity.newHexToColor(string.sub(ColorUtil.dark_green_str, 2, 7))
  ColorUtil.dark_blue   = unity.newHexToColor(string.sub(ColorUtil.dark_blue_str, 2, 7))
  ColorUtil.dark_purple = unity.newHexToColor(string.sub(ColorUtil.dark_purple_str, 2, 7))
  ColorUtil.dark_orange = unity.newHexToColor(string.sub(ColorUtil.dark_orange_str, 2, 7))

  ColorUtil.gray               = unity.newHexToColor(string.sub(ColorUtil.gray_str, 2, 7))
  ColorUtil.red                = unity.newHexToColor(string.sub(ColorUtil.red_str, 2, 7))
  ColorUtil.white              = unity.newHexToColor(string.sub(ColorUtil.white_str, 2, 7))
  ColorUtil.black              = unity.newHexToColor(string.sub(ColorUtil.black_str, 2, 7))
  ColorUtil.reseda             = unity.newHexToColor(string.sub(ColorUtil.reseda_str, 2, 7))
  ColorUtil.starYellow         = unity.newHexToColor(string.sub(ColorUtil.starYellow_str, 2, 7))
  ColorUtil.notCurrent         = unity.newHexToColor(string.sub(ColorUtil.notCurrent_str, 2, 7))
  ColorUtil.brightRed          = unity.newHexToColor(string.sub(ColorUtil.brightRed_str, 2, 7))
  ColorUtil.deepGreen          = unity.newHexToColor(string.sub(ColorUtil.deepGreen_str, 2, 7))
  ColorUtil.deepRed            = unity.newHexToColor(string.sub(ColorUtil.deepRed_str, 2, 7))
  ColorUtil.rageBlue           = unity.newHexToColor(string.sub(ColorUtil.rageBlue_str, 2, 7))
  ColorUtil.rageRed            = unity.newHexToColor(string.sub(ColorUtil.rageRed_str, 2, 7))
  ColorUtil.rageGray           = unity.newHexToColor(string.sub(ColorUtil.rageGray_str, 2, 7))
  ColorUtil.subTitleYellow     = unity.newHexToColor(string.sub(ColorUtil.subTitleYellow_str, 2, 7))
  ColorUtil.bloodLineYellow    = unity.newHexToColor(string.sub(ColorUtil.bloodLineYellow_str, 2, 7))
  ColorUtil.bloodLineBlue      = unity.newHexToColor(string.sub(ColorUtil.bloodLineBlue_str, 2, 7))
  ColorUtil.bloodLinePurple    = unity.newHexToColor(string.sub(ColorUtil.bloodLinePurple_str, 2, 7))
  ColorUtil.snsGreed           = unity.newHexToColor(string.sub(ColorUtil.snsGreed_str, 2, 7))
  ColorUtil.snsBlue            = unity.newHexToColor(string.sub(ColorUtil.snsBlue_str, 2, 7))
  ColorUtil.employ_gray        = unity.newHexToColor(string.sub(ColorUtil.employ_gray_str, 2, 7))
  ColorUtil.light_white        = unity.newHexToColor(string.sub(ColorUtil.light_white_str, 2, 7))
  ColorUtil.high_blue          = unity.newHexToColor(string.sub(ColorUtil.high_blue_str, 2, 7))
  ColorUtil.super_light_blue   = unity.newHexToColor(string.sub(ColorUtil.super_light_blue_str, 2, 7))
  ColorUtil.orange_yellow      = unity.newHexToColor(string.sub(ColorUtil.orange_yellow_str, 2, 7))
  ColorUtil.transparent        = unity.Color.new(unity.hexToColorWithAlpha("00000000"))
  ColorUtil.npc_social_ui_blue = unity.newHexToColor(string.sub(ColorUtil.npc_social_ui_blue_str, 2, 7))
  ColorUtil.orange2            = unity.newHexToColor(string.sub(ColorUtil.orange2_str, 2, 7))
  ColorUtil.orange3            = unity.newHexToColor(string.sub(ColorUtil.orange3_str, 2, 7))
  ColorUtil.red3               = unity.newHexToColor(string.sub(ColorUtil.red3_str, 2, 7))
  ColorUtil.robber_red         = unity.newHexToColor(string.sub(ColorUtil.robber_red_str, 2, 7))


  ColorUtil.wushu_res_bg_win   = unity.newHexToColor(string.sub(ColorUtil.wushu_res_bg_win_str, 2, 7))
  ColorUtil.wushu_res_bg_win2  = unity.newHexToColor(string.sub(ColorUtil.wushu_res_bg_win_str2, 2, 7))
  ColorUtil.wushu_res_bg_lose  = unity.newHexToColor(string.sub(ColorUtil.wushu_res_bg_lose_str, 2, 7))

  ColorUtil.hospital_yellow  = unity.newHexToColor(string.sub(ColorUtil.hospital_yellow_str, 2, 7))
  ColorUtil.hospital_orange  = unity.newHexToColor(string.sub(ColorUtil.hospital_orange_str, 2, 7))
  ColorUtil.hospital_red     = unity.newHexToColor(string.sub(ColorUtil.hospital_red_str, 2, 7))

  ColorUtil.vipColors = {
    {unity.newHexToColor("5a5a5a"), unity.newHexToColor("000000")},
    {unity.newHexToColor("ffffff"), unity.newHexToColor("000000")},
    {unity.newHexToColor("51ff00"), unity.newHexToColor("000000")},
    {unity.newHexToColor("00ffd9"), unity.newHexToColor("000000")},
    {unity.newHexToColor("db4aff"), unity.newHexToColor("000000")},
    {unity.newHexToColor("ff7919"), unity.newHexToColor("000000")},
    {unity.newHexToColor("ff1a40"), unity.newHexToColor("000000")},
    {unity.newHexToColor("a1fde6"), unity.newHexToColor("3271bf")},
    {unity.newHexToColor("fff01a"), unity.newHexToColor("b43117")},
  }

  ColorUtil.dummyRandomColors = {
    {unity.newHexToColor("70aa77"), unity.newHexToColor("c5f377")},
    {unity.newHexToColor("7a698f"), unity.newHexToColor("c9a2d5")},
    {unity.newHexToColor("829bbd"), unity.newHexToColor("8edfe7")},
    {unity.newHexToColor("9f7380"), unity.newHexToColor("efa8a0")},
    {unity.newHexToColor("9f8673"), unity.newHexToColor("d9c97c")},
  }

  ColorUtil.newsColor = {
    normal  = ColorUtil.green,
    quest   = ColorUtil.blue,
    special = ColorUtil.red,
    debate  = ColorUtil.orange,
  }

  ColorUtil.npcColor = {
    love = ColorUtil.green,
    hate = ColorUtil.red,
  }

  ColorUtil.npcColorStr = {
    love = ColorUtil.green_str,
    hate = ColorUtil.red_str,
  }

  ColorUtil.newsColorStr = {
    normal  = ColorUtil.green_str,
    quest   = ColorUtil.blue_str,
    special = ColorUtil.red_str,
    debate  = ColorUtil.orange_str,
  }


  ColorUtil.npcAbilityTabColor = {
    unity.newHexToColor("901e1e"),
    unity.newHexToColor("216dd4"),
    unity.newHexToColor("ffc500"),
  }

  ColorUtil.protectColor = {
    fukong = unity.newHexToColor("eae713"),
    stiff  = unity.newHexToColor("f117c1"),
    land   = unity.newHexToColor("13eae8"),
    combo  = unity.newHexToColor("f96811"),
  }

  ColorUtil.npcFriendshipColor = {
    deep={
        unity.newHexToColor("262323"),
        unity.newHexToColor("b1c0b8"),
        unity.newHexToColor("24b93d"),
        unity.newHexToColor("1364b6"),
        unity.newHexToColor("881173"),
        unity.newHexToColor("c24b16"),
        unity.newHexToColor("a61321"),
      },
    light={
        unity.newHexToColor("5a5a5a"),
        unity.newHexToColor("ddefe6"),
        unity.newHexToColor("63fe0d"),
        unity.newHexToColor("2bbceb"),
        unity.newHexToColor("f20dca"),
        unity.newHexToColor("f2630d"),
        unity.newHexToColor("f20d23"),
      },
  }

  ColorUtil.npcFriendshipColorStr = {
    deep={
        "#262323",
        "#b1c0b8",
        "#24b93d",
        "#1364b6",
        "#881173",
        "#c24b16",
        "#a61321",
      },
    light={
        "#5a5a5a",
        "#ddefe6",
        "#63fe0d",
        "#2bbceb",
        "#f20dca",
        "#f2630d",
        "#f20d23",
      },
  }

  ColorUtil.npcFriendshipColorSingleStr = {
    deep={
        "262323",
        "b1c0b8",
        "24b93d",
        "1364b6",
        "881173",
        "c24b16",
        "a61321",
      },
    light={
        "5a5a5a",
        "ddefe6",
        "63fe0d",
        "2bbceb",
        "f20dca",
        "f2630d",
        "f20d23",
      },
  }

  ColorUtil.elementAttrColor = {
    green = unity.newHexToColor("45D81B"),
    blue = unity.newHexToColor("3EAEFD"),
    red = unity.newHexToColor("F42525"),
    purple = unity.newHexToColor("BF3AEB"),
  }

  ColorUtil.npcAbilityColor = {
    deep={
        unity.newHexToColor("370606"),
        unity.newHexToColor("0f0d5e"),
        unity.newHexToColor("311b08"),
    },
    light={
        unity.newHexToColor("6f1515"),
        unity.newHexToColor("3c39b8"),
        unity.newHexToColor("764316"),
    }
  }

  ColorUtil.practiceEnergyColor = {
    deep={
        unity.newHexToColor("38120d"),
        unity.newHexToColor("272008"),
        unity.newHexToColor("0c210d"),
    },
    light={
        unity.newHexToColor("bb3925"),
        unity.newHexToColor("ffc500"),
        unity.newHexToColor("1eb425"),
    }
  }

  ColorUtil.bossLabelBgColors = {
    useable={
        red    = unity.newHexToColor("bb3925"),
        yellow = unity.newHexToColor("ffc500"),
    },
    disable={
        red    = unity.newHexToColor("7f7f7f"),
        yellow = unity.newHexToColor("7f7f7f"),
    }
  }

  ColorUtil.bossLabelTextColors = {
    useable={
        red    = unity.newHexToColor("ffffff"),
        yellow = unity.newHexToColor("000000"),
    },
    disable={
        red    = unity.newHexToColor("000000"),
        yellow = unity.newHexToColor("000000"),
    }
  }

  ColorUtil.practiceLabelBgColor = {
    purple = unity.newHexToColor('be3aea'),
    red = unity.newHexToColor('f32525'),
    blue = unity.newHexToColor('3daaff'),
    green = unity.newHexToColor('51ff1e'),
  }

  ColorUtil.assistBgColors = {
    disable = unity.newHexToColor("112330"),
    able = unity.newHexToColor("562234"),
    disable2 = unity.newHexToColor("0B1218"),
    able2 = unity.newHexToColor("170909")
  }

  ColorUtil.npcBtnColors =
  {
    selected   = {border = unity.newHexToColor("fcc101"), bg = unity.newHexToColor("fcc101")},
    unselected = {border = ColorUtil.rose, bg = ColorUtil.brown},
    stranger   = {border = ColorUtil.brown, bg = unity.newHexToColor("18020c")}
  }

  ColorUtil.ChaptersCateColors = {
    light = {
      strength   = unity.newHexToColor("bc11cb"),
      exp        = unity.newHexToColor("3daa2e"),
      reward     = unity.newHexToColor("cb901a"),
      anneal     = unity.newHexToColor("da161b"),
      friendship = unity.newHexToColor("6f9fe9"),
    },
    deep = {
      strength   = unity.newHexToColor("941d9c"),
      exp        = unity.newHexToColor("27761f"),
      reward     = unity.newHexToColor("855c09"),
      anneal     = unity.newHexToColor("781315"),
      friendship = unity.newHexToColor("1d3b74"),
    }
  }

  ColorUtil.pvpResultOutlineColors = {
    left = unity.newHexToColor("ffe203"),
    right = unity.newHexToColor("b63822")
  }

  ColorUtil.starColors = {
    red = unity.newHexToColor("bb3925"),
    white = unity.newHexToColor("ffffff")
  }

end


function ColorUtil.randDummyColor()
  local rndIndex = math.random(1, #ColorUtil.dummyRandomColors)
  return ColorUtil.dummyRandomColors[rndIndex]
end

function ColorUtil.gradeColor(grade)
  if grade == nil then
    grade = 0
  end
  local colors = {ColorUtil.white, ColorUtil.green, ColorUtil.blue, ColorUtil.purple, ColorUtil.orange, ColorUtil.red}
  return colors[grade+1]
end

function ColorUtil.gradeColorStr(grade)
  local colors = {ColorUtil.white_str, ColorUtil.green_str, ColorUtil.blue_str, ColorUtil.purple_str, ColorUtil.orange_str, ColorUtil.red_str}
  return colors[grade+1]
end

function ColorUtil.setGray(icon, isGray)
  if isGray == nil then
    isGray = true
  end

  if isGray then
    icon:setGray()
  else
    icon:setNormal()
  end
end

function ColorUtil.setNodeGray(node, isGray)
  local txt = node.gameObject:GetComponentsInChildren(UI.Text)
  local images = node.gameObject:GetComponentsInChildren(UI.Image)
  for v in Slua.iter(images) do
    if isGray then
      v:setGray()
    else
      v:setNormal()
    end
  end
  for v in Slua.iter(txt) do
    if isGray then
      v:setGray()
    else
      v:setNormal()
    end
  end
end

function ColorUtil.getColorString(str, color)
  local theColor = ColorUtil.white_str
  if color ~= nil then
    local colorStr = string.format('%s_str', color)
    if ColorUtil[colorStr] ~= nil then
      theColor = ColorUtil[colorStr]
    else
      theColor = color
    end
  end

  local colorHtmlString = string.format('<color=%s>%s</color>', theColor, str)
  return colorHtmlString
end

function ColorUtil.getColorGradeString(str, grade)
   local colors = {ColorUtil.white_str, ColorUtil.green_str, ColorUtil.blue_str, ColorUtil.purple_str, ColorUtil.orange_str, ColorUtil.red_str, ColorUtil.black_str}
   local color = colors[grade+1]

   local colorHtmlString = string.format('<color=%s>%s</color>', color, str)
   return colorHtmlString
end

function ColorUtil.setGrayText(txt, hideGray)
  if hideGray then
    txt:GetComponent(UI.Text).material = nil
  else
    local grayMaterial = ui:grayMat()
    txt:GetComponent(UI.Text).material = grayMaterial
  end
end

