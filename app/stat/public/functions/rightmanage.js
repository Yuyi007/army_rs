Ext.application({
  name: 'rightmanage',
  launch: onLaunch
});

var items = new Array();
var form;
var roleid;

function getAllFunctions()
{ 
  ajaxCall({
      'url'   : '/users/func_list',
      'method': 'POST',
      'onSuccess': function(res){
                  res = res.res
                  for (var i = res.length - 1; i >= 0; i--) {
                    var rc = res[i];
                    var id = rc.id;
                    var name = rc.name;
                    var desc = rc.desc;
                    var item ={boxLabel: loc('str_'+name)+":"+desc,
                               name: name,
                               inputValue: id,
                              };
                    items[i] = item;
                  };
                  
                  getRoleFunctions();
                },
    }); 

}

function getRoleFunctions()
{
  var arr = document.URL.split("?");
  var params = Ext.urlDecode(arr[arr.length - 1]);
  var id = params.id
  roleid = id;

  ajaxCall({
    'url'   : '/users/role_funcs',
    'method': 'POST',
    'params': {roleid: id},
    'onSuccess': function(res){
                res = res.res
                for (var i = items.length - 1; i >= 0; i--) 
                {
                  var item = items[i];
                  var find = false;
                  for (var j = res.length - 1; j >= 0; j--) 
                  {
                    if (item.inputValue == res[j].funid) 
                    {
                      find = true;
                      break;
                    };
                  };
                  
                  item['checked'] = find;
                };

                createView(items);
              },
  }); 
}

function createView(items)
{
  form = Ext.create('Ext.form.Panel', {
        title: loc('str_role_manage'),
        frame: true,
        defaults: {bodyStyle: "background-color: #FFFFFF;", frame: false},
        bodyPadding: 10,
        renderTo: Ext.getBody(),
        width: 550,
        items: [{
                  xtype: 'fieldset',
                  flex: 1,
                  width: 520,
                  title: loc('str_check_rights'),
                  defaultType: 'checkbox', 
                  layout: 'anchor',
                  defaults: {anchor: '100%',hideEmptyLabel: false},
                  items: items
                },
                {
                  xtype: 'button',
                  name: 'save',
                  text: loc('str_save'),
                  width: 80,
                  x: 150,
                  formBind: true,
                  handler: onBtnSave
                },
                {
                  xtype: 'button',
                  name: 'cancel',
                  text: loc('str_cancel'),
                  x: 220,
                  width: 80,
                  formBind: true,
                  handler: onBtnCancel
                }]
        });
}

function onLaunch()
{
  getAllFunctions();
}

function onBtnSave()
{
  var fids = new Array();
  var values = form.getValues();
  for (var i = items.length - 1; i >= 0; i--) {
    var item = items[i];
    var fid = values[item.name];
    if (typeof(fid) != 'undefined') {
      fids.push(fid);
    };
  };

  var params = {roleid: roleid, funids: Ext.encode(fids)};
  // alert(params.funids.length);
  ajaxCall({
    'url'   : '/users/save_role_rights',
    'method': 'POST',
    'params': params,
    'onSuccess': function(res){
                  Ext.Msg.alert(loc('alert'), loc('str_save_success'));
                  window.location.href = BASE_URL + "/users/role_manage";
                },
  }); 

}

function onBtnCancel()
{
  window.location.href = BASE_URL+"/users/role_manage";
}
