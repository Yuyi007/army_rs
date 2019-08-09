Ext.application({
  name: 'vouchergainreport',
  launch: onLaunch
});

function onLaunch()
{
  var args = {
    reportname: '代金券各系统获取',
    categories: ['item_drop', 'dialy_activity', 'bq_drop_chapterevent', 'press_trigger_bonus2','delay_drop_comment', 'delay_drop_like', 'choose_npc_question', 'city_event',
                'sign', 'newbeereward', 'guild_envelop', 'guild_dialy', 'born_quest', 'npc_repo', 'cdkey'],
    catnames: ['礼包掉落', '每日活跃', '章节事件', '分享新闻', '朋友圈回复', '朋友圈点赞', '通讯录答题', '市井事件', '签到',
                '新手奖励', '公会红包', '公会翻牌', '开服狂欢', '纸币急购', 'cdkey礼包'],
    columns: ['voucher', 'accounts', 'players'],
    colnames: ['获取', '人数by账', '人数by角'],
    type_col: 'reason',
    src_table: 'gain_voucher_sys'
  };

  genView(args)
};