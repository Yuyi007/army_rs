# -*- coding: utf-8 -*-
# Configures your navigation
SimpleNavigation::Configuration.run do |navigation|
  # Specify a custom renderer if needed.
  # The default renderer is SimpleNavigation::Renderer::List which renders HTML lists.
  # The renderer can also be specified as option in the render_navigation call.
  # navigation.renderer = Your::Custom::Renderer
  navigation.renderer = SimpleNavigation::Renderer::List

  # Specify the class that will be applied to active navigation items. Defaults to 'selected'
  # navigation.selected_class = 'your_selected_class'

  # Specify the class that will be applied to the current leaf of
  # active navigation items. Defaults to 'simple-navigation-active-leaf'
  # navigation.active_leaf_class = 'your_active_leaf_class'

  # Item keys are normally added to list items as id.
  # This setting turns that off
  navigation.autogenerate_item_ids = false

  # You can override the default logic that is used to autogenerate the item ids.
  # To do this, define a Proc which takes the key of the current item as argument.
  # The example below would add a prefix to each key.
  # navigation.id_generator = Proc.new {|key| "my-prefix-#{key}"}

  # If you need to add custom html around item names, you can define a proc that will be called with the name you pass in to the navigation.
  # The example below shows how to wrap items spans.
  # navigation.name_generator = Proc.new {|name| "<span>#{name}</span>"}

  # The auto highlight feature is turned on by default.
  # This turns it off globally (for the whole plugin)
  # navigation.auto_highlight = false

  # Define the primary navigation
  navigation.items do |primary|
    # Add an item to the primary navigation. The following params apply:
    # key - a symbol which uniquely defines your navigation item in the scope of the primary_navigation
    # name - will be displayed in the rendered navigation. This can also be a call to your I18n-framework.
    # url - the address that the generated item links to. You can also use url_helpers (named routes, restful routes helper, url_for etc.)
    # options - can be used to specify attributes that will be included in the rendered navigation item (e.g. id, class etc.)
    #           some special options that can be set:
    #           :if - Specifies a proc to call to determine if the item should
    #                 be rendered (e.g. <tt>:if => Proc.new { current_user.admin? }</tt>). The
    #                 proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :unless - Specifies a proc to call to determine if the item should not
    #                     be rendered (e.g. <tt>:unless => Proc.new { current_user.admin? }</tt>). The
    #                     proc should evaluate to a true or false value and is evaluated in the context of the view.
    #           :method - Specifies the http-method for the generated link - default is :get.
    #           :highlights_on - if autohighlighting is turned off and/or you want to explicitly specify
    #                            when the item should be highlighted, you can set a regexp which is matched
    #                            against the current URI.  You may also use a proc, or the symbol <tt>:subpath</tt>.
    #

    # You can also specify a condition-proc that needs to be fullfilled to display an item.
    # Conditions are part of the options. They are evaluated in the context of the views,
    # thus you can use all the methods and vars you have available in the views.

    # you can also specify a css id or class to attach to this particular level
    # works for all levels of the menu
    primary.dom_id = 'dom-id'
    primary.dom_class = 'dom-class'

    # You can turn off auto highlighting for a specific level
    # primary.auto_highlight = false

    primary.item :dashboard, t(:dashboard), '/' do |dashboard|
    end

    primary.item :data, t(:data), '/data/view' do |data|
      data.item :view, t(:view), '/data/view'
      data.item :view, t(:history), '/data/history'
      data.item :view, t(:permission), '/permissions'
      data.item :view, t(:raw), '/data/raw'
      data.item :give, t(:batch_give), '/data_batch/edit'
      data.item :grantRecord, t(:view_grant_records), '/grant_records/', :highlights_on => %r(^/grant_records$)
      data.item :action, t(:action_logs), '/action_logs/index'
      data.item :query, t(:query_data), '/data_query/index'
    end

    primary.item :operation, t(:operation), '/channel/index' do |operation|
      operation.item :server_settings, t(:server_settings), '/server_settings/index'
      operation.item :maintainance, t(:maintainance), '/maintainance/index'
      operation.item :zone, t(:manage_zones), '/zone/index'
      operation.item :pkgVersion, t(:publish_force_update), '/app_version/index'
      operation.item :version, t(:publish_update), '/client_version/index'
      operation.item :buchang, t(:buchang), '/config/buchang'
      operation.item :notice, t(:send_message), '/channel/index'
      operation.item :applePush, t(:push_message), '/push/index'
      operation.item :bill, t(:bills), '/bills/index'
      operation.item :config, t(:manage_config), '/config_edit/index'
      operation.item :functions, t(:functions_open), '/functions/index'
      operation.item :events, t(:manage_events), '/events_zhenlong/index'
      operation.item :notice, t(:manage_notices), '/notice/index'
      operation.item :online, t(:online_data), '/online/index'
      operation.item :mail, t(:send_mail), '/mail/index'
      operation.item :player, t(:manage_players), '/player/index'
      operation.item :rewards, t(:rewards_edit), '/rewards/packagelist'
    end

    primary.item :manage, t(:manage), '/site_users/list' do |manage|
      manage.item :user, t(:user_list), '/site_users/list'
      manage.item :record, t(:view_records), '/site_user_records/index'
    end

  end

end
