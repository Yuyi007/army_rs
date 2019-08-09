Ext.application({
  name: 'dashboard',
  launch: onLaunch
});

var g_tree;
var g_frame;
var map_modules = {
                    "role_manage"  : "users",
                    "user_manage" : "users",
                    "gen_today" : "statsbin",
                    "level_consume": "statshelper",
                    "consume_report": "statshelper",
                    "total_active": "statsorign",
                    "active_report": "statsorign",
                    "retention_report": "statsorign",
                    "chief_level_report": "statsorign",
                    "city_level_report": "statshelper",
                    "credits_consume_report": "statshelper",
                    "credits_gain_report": "statshelper",
                    "coins_consume_report": "statshelper",
                    "coins_gain_report": "statshelper",
                    "money_consume_report": "statshelper",
                    "money_gain_report": "statshelper",
                    "voucher_consume_report": "statshelper",
                    "voucher_gain_report": "statshelper",
                    "shop_consume_report": "statshelper",
                    "start_campaign_report": "statshelper",
                    "level_campaign_report": "statshelper",
                    "city_campaign_report": "statshelper",
                    "active_factions_report": "statshelper",
                    "all_factions_report": "statshelper",
                    "main_quest_cam_report": "statshelper",
                    "booth_trade_report": "statshelper",
                    "new_users_report": "realtimestats",
                    "active_users_report": "realtimestats",
                    "max_online_report": "realtimestats",
                    "ave_online_report": "realtimestats",
                    "chapter_quest_report": "statshelper",
                    "boss_practice_report": "statshelper",
                    "guild_level_record": "statshelper",
                    "guild_skill_record": "statshelper",
                    "guild_active_record": "statshelper",
                    "player_recharge_record": "recharge",
                    "player_recharge_report": "recharge",
                    "new_player_recharge_report": "recharge",
                    "loss_consume_report": "loss",
                    "loss_recharge_report": "loss",
                    "loss_report": "loss",
                    "all_player_level_report": "statshelper",
                    "all_player_city_event_level_report": "statshelper",
                    "add_equip_report": "statshelper",
                    "campaign_report": "statshelper",
                    "main_quest_report": "statshelper",
                    "main_quest_user_report": "statshelper",
                    "vip_level_report": "statshelper",
                    "vip_purchase_report": "statshelper",
                    "share_award_report": "statshelper",
                    "born_quest_report": "statshelper"
                  };

var modules = {users: null, stats: null};


function onSelectFunc(s,r)
{
  var id = r.data.id;

  var md = map_modules[id]
  if(typeof(md) != 'undefined' ){
    g_frame.load(BASE_URL+"/"+md+"/"+id);
  }
}


function onGetRights(res)
{
  res = res.sort();
  //functions tree
  var store = Ext.create('Ext.data.TreeStore', {
    root: {
        text: 'Root',
        expanded: true,
        children: []
        }
    });

  g_tree = Ext.create("Ext.tree.Panel", {
    title: loc("str_functions"),
    store: store,
    region: 'west',
    width:190,
    rootVisible: false,
    collapsible: true,
    split: true,
    listeners: {itemclick: onSelectFunc}
  });

  var root = store.getRootNode();

  for (var i = res.length - 1; i >= 0; i--) {
    var name = res[i];
    var module = map_modules[name];
    var node = modules[module];
    if(!node){
      node = root.appendChild({leaf: false, text: loc("str_module_"+module), id: module});
      modules[module] = node;
    }

    node.appendChild({leaf: true, text: loc("str_"+name), id: name});
  };

  //content iframe
  g_frame = Ext.create("Ext.ux.IFrame", {
                frameName: 'Content',
                src: BASE_URL+"/welcome.html",
                region: "center",
                split: true,
                border: true,
                title:'Content'
            });

  new Ext.Viewport({
                title: "Dashboard",
                layout: "border",
                defaults: {
                    bodyStyle: "background-color: #FFFFFFFF;",
                    frame: false
                },
                items:[
                  { region: "north",
                    xtype: "toolbar",
                    height: 50,
                    items:[{
                      xtype: 'button',
                      text: loc('str_logout'),
                      icon: '/images/application_go.png',
                      handler : onBtnLogout
                    }]},
                  g_tree,
                  g_frame,
                ]});
}

function onLaunch()
{
  ajaxCall({
      'url'   : '/main/get_rights',
      'method': 'POST',
      'onSuccess': function(res){
                    onGetRights(res.res);}
    })
}

function onBtnLogout()
{
  ajaxCall({
      'url'   : '/users/do_logout',
      'method': 'POST'
    })
  Ext.util.Cookies.set('sessionid', null);
  window.location.href = BASE_URL + "/users/login";
}
