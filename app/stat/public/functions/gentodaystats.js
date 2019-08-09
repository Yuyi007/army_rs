Ext.application({
  name: 'gentodaystats',
  launch: onLaunch
});

var label = Ext.create('Ext.form.Label', {
  text: "",
  margin: '0 0 0 10',
  width: 350,
  x: 25,
  y: 85,
});

var form;
function onLaunch()
{
  form = Ext.create('Ext.form.Panel', {
    // renderTo: Ext.getBody(),
    title: loc('str_gen_today'),
    layout: 'absolute',
    height: '100%',
    width: '100%',
    defaultType: 'textfield',
    items: [
        {
          xtype: 'button',
          name: 'btngen',
          text: loc('str_gen_today'),
          width: 150,
          x: 25,
          y: 25,
          handler: onBtnGen
        },
        label
    ]
});

  new Ext.Viewport({
    layout: 'fit',
    width: '100%',
    height: '100%',
    items: [ form ]
  });

// form.center();

};

var g_in_generating = false;

function onBtnGen()
{
  if(g_in_generating) return;

  Ext.Ajax.timeout = 30 * 60 * 100000; 
  ajaxCall({
      'url'   : '/statshelper/do_gen_today_stats',
      'onSuccess': function(res)
                  {
                    if(res.working)
                      label.setText('已经在生成中了，告诉你不要切换页面...'); 
                    else
                      label.setText('生成中，请不要切换页面...');
                    startCheck();
                  },
    });

  g_in_generating = true;
}

function startCheck()
{
  var runner = new Ext.util.TaskRunner();
  var task = runner.newTask({
       run: function () {
              ajaxCall({
                'url'   : '/statshelper/do_check_today_gen',
                'onSuccess': function(res)
                            {
                              if(res.complete)
                              {
                                label.setText('恭喜，生成好了!');
                                g_in_generating = false;
                                task.destroy();
                                alert(loc("str_gen_today_stats_success"))
                              }
                            },
              });
           },
       interval: 10000
   });
  task.start();
}