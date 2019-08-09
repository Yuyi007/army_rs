
var BASE_URL = ""
var scriptEls = document.getElementsByTagName('script');
var path = scriptEls[scriptEls.length - 1].src;
path = path.substring(0, path.lastIndexOf('/shared')+1);

document.write('<META HTTP-EQUIV="Pragma" CONTENT="no-cache">\
  <link rel="stylesheet" type="text/css" href="'+path+'extjs/resources/css/ext-all-gray.css">\
  <script type="text/javascript" charset="UTF-8" src="'+path+'extjs/ext-all-rtl.js"></script>\
  <script type="text/javascript" charset="UTF-8" src="'+path+'locale/ext-lang-zh_CN.js"></script>\
  <script type="text/javascript" charset="UTF-8" src="'+path+'locale/zh.js"></script>');

function getSid()
{
  var sessionid = Ext.util.Cookies.get('sessionid');
  if(typeof(sessionid) == "undefined")
    window.location.href = BASE_URL + "/users/login";

  return sessionid;
}

function getUid()
{
  return Ext.util.Cookies.get('userid');
}

function getUrlParam()
{
  var arr = document.URL.split("?");
  var params = Ext.urlDecode(arr[arr.length - 1]);
  return params;
}

function ajaxCall(options)
{
  var sid = getSid();
  var params = options['params']
  if(!params)
    params = {}

  params.sid = sid

  var method = options['method']
  if(!method)
    method = 'POST'

  Ext.Ajax.request({
  headers: {
    'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
  },
  url: BASE_URL+ options['url'],
  method: method,
  params: params,
  success: function(response){
      var text = response.responseText;
      var res = Ext.decode(text);
      if(res.success == 'ok')
      {
        if(options['onSuccess'])
        {
          options['onSuccess'](res)
        }
      }else
      {
        if(res.reason == 'verify fail')
        {
          window.location.href = BASE_URL + "/users/login";
        }else{
          if(options['onFail'])
          {
            options['onFail'](res)
          }
          else
          {
            Ext.Msg.alert(loc('alert'), text);
          }
        }
      }
    },
  failure: function(response){
    var text = response.responseText;
      Ext.Msg.alert(loc('str_sys_inter_err'),text);
    }
  });
}

function getJsonOfStore(store)
{
    var datar = new Array();
    var jsonDataEncode = "";
    var records = store.getRange();
    for (var i = 0; i < records.length; i++) {
      datar.push(records[i].data);
    }
    jsonDataEncode = Ext.encode(datar);

    return jsonDataEncode;
}

function getJsonOfHeader(columns)
{
  return Ext.encode(columns);;
}

function doExportXls(file_name, store, cols, onComplete)
{
  var jsonData = getJsonOfStore(store);
  var jsonHead = getJsonOfHeader(cols);
  ajaxCall({
          'url'   : '/statsexport/save_export_data',
          'params': { str_header: jsonHead, str_data: jsonData},
          'onSuccess': function(res){
            var uid = getUid();
            var url = BASE_URL+ "/statsexport/export_to_xls.xls?uid="+uid+"&file_name="+file_name;
            var link = document.createElement('a');
            link.href = url;
            link.download= file_name + '.xls';
            link.click();

            if(onComplete)
            {
              onComplete();
            }
          }});
}

// 对Date的扩展，将 Date 转化为指定格式的String
// 月(M)、日(d)、小时(h)、分(m)、秒(s)、季度(q) 可以用 1-2 个占位符，
// 年(y)可以用 1-4 个占位符，毫秒(S)只能用 1 个占位符(是 1-3 位的数字)
// 例子：
// (new Date()).Format("yyyy-MM-dd hh:mm:ss.S") ==> 2006-07-02 08:09:04.423
// (new Date()).Format("yyyy-M-d h:m:s.S")      ==> 2006-7-2 8:9:4.18
Date.prototype.Format = function(fmt)
{ //author: meizz
  var o = {
    "M+" : this.getMonth()+1,                 //月份
    "d+" : this.getDate(),                    //日
    "h+" : this.getHours(),                   //小时
    "m+" : this.getMinutes(),                 //分
    "s+" : this.getSeconds(),                 //秒
    "q+" : Math.floor((this.getMonth()+3)/3), //季度
    "S"  : this.getMilliseconds()             //毫秒
  };
  if(/(y+)/.test(fmt))
    fmt=fmt.replace(RegExp.$1, (this.getFullYear()+"").substr(4 - RegExp.$1.length));
  for(var k in o)
    if(new RegExp("("+ k +")").test(fmt))
  fmt = fmt.replace(RegExp.$1, (RegExp.$1.length==1) ? (o[k]) : (("00"+ o[k]).substr((""+ o[k]).length)));
  return fmt;
}