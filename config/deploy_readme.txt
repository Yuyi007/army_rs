服务器更新
1.建立相关deploy目录下的配置文件【env.rb】
2.在相关服务器的config目录下建立相关config.env.combat【战斗服】和config.env.json【data服】的配置文件
3.cap env deploy

资源发布
1.rs/config 相关的服务器配置中 publish_url 修改成相应的cnd url [客户端链上来后服务器下发的更新地址就是这个,注意服务器同步代码不同步该配置，请到服务器修改或者后期用puppet修改]
2.cdn.yml配置相应的cnd服务器
3.服务器nginx 或者apache站点根目录设置成 cdn.yml中的dst路径
4.rake publish:env
5.rake publish:env_apply