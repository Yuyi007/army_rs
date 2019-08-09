declare("CHARACTER",
{
  LIBRARY = 0,   --牌库
  ME      = 1,   --自己
  RIGHT   = 2,   --右边
  LEFT    = 3,   --左边
  DESK    = 4,   --桌面
})

declare("COLOR",
{
  None   = 0,  --小王，大王
  Club   = 1,  --梅花
  Heart  = 2,  --红桃
  Spade  = 3,  --黑桃
  Square = 4,  --方片
})

declare("WEIGHT",
{
  Three = 3,
  Four  = 4,
  Five  = 5,
  Six   = 6,
  Seven = 7,
  Eight = 8,
  Nine  = 9,
  Ten   = 10,
  Jack  = 11,
  Queen = 12,
  King  = 13,
  One   = 14,
  Two   = 15,
  SJoker = 16,
  LJoker = 17,
})


declare("CARDTYPE",
{
  None   = 0,
  Single = 1,          --单 1  
  Double = 2,          --对儿 2
  TwoDouble = 4,       --双对 4
  Straight = 5,        --顺子 5-12
  DoubleStraight = 6,  --双顺 >=6 8 10 12 14 16 18 20
  TripleStraight = 7,  --飞机 >=6 9 12 15 18
  Three = 8,           --三不带 3
  ThreeAndOne = 9,     --三带一 4
  ThreeAndTwo = 10,    --三带二 5
  Boom = 11,           --炸弹 4
  JokerBoom = 12,      --王炸 2
})

declare("IDENTITY",
{
  Farmer = 0,       --农民
  Landlord = 1,     --地主
  Desk = 2,         --发牌员
})

declare("SOUNDS",
{
  [4] = "dui",
  [5] = "shunzi",
  [6] = "liandui",
  [7] = "feiji",
  [8] = "sange",
  [9] = "sandaiyi",
  [10] = "sandaiyidui",
  [11] = "zandan",
  [12] = "wangzha"
})

declare("SHOWPOINT",
{
  CreatePoint = 0,
  PlayerPoint = 1,
  RightPoint = 2,
  LeftPoint = 3,
})