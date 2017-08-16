file 'config/locales/menu.yml', <<-CODE
en:
  menu:
    languages:
      lang: "Language"
      en: English
      zh-CN: 中文

    home: Home

zh-CN:
  menu:
    languages:
      lang: "Language"
      en: English
      zh-CN: 中文

    home: 首页
CODE

file 'config/locales/action.yml', <<-CODE
en:
  action:
    show: Show
    edit: Edit
    back: Back
    more: More
    save: Save
    submit: Submit

zh-CN:
  action:
    show: 查看
    edit: 修改
    back: 返回
    more: 更多
    save: 保存
    submit: 提交
CODE

#========== Layout Helpers ==========#
insert_into_file 'app/helpers/application_helper.rb', after: %/module ApplicationHelper\n/ do
  <<-CODE
  def flash_class(level, default=[])
    cls = case level.to_sym
      when :notice then [:alert, :'alert-info']
      when :success then [:alert, :'alert-success']
      when :error then [:alert, :'alert-danger']
      when :alert then [:alert, :'alert-warning']
      else []
    end
    return cls + default
  end
  CODE
end

#========== Layout Views ==========#
inside 'app/views/layouts/' do
  insert_into_file 'application.html.erb', before: /^([ ]+?)\<(title)>.+\<\/(\2)>$/ do
    <<-CODE
\\1<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    CODE
  end

  insert_into_file 'application.html.erb',
    "'//huluren.github.io/material-design-icons/iconfont/material-icons.css', ",
    after: /stylesheet_link_tag\s+'application', /

  gsub_file 'application.html.erb', '= yield', %!= render 'layouts/body'!

  file '_body.html.haml', <<-CODE
= render 'layouts/header'
= render 'layouts/main'
= render 'layouts/footer'
  CODE

  file '_header.html.haml', <<-CODE
%nav#navbar.navbar.navbar-expand-lg.navbar-dark.bg-primary.sticky-top

  .container

    %button.navbar-toggler.navbar-toggler-right{aria: {controls: 'navbarNavSiteMenus', expanded: 'false', label: 'Toggle navigation'}, 'aria-label': 'Toggle navigation', data: {toggle: 'collapse', target: '#navbarNavSiteMenus'}, type: 'button'}
      %span.navbar-toggler-icon

    = link_to :root, class: 'h1 navbar-brand mb-0' do
      %img.d-inline-block.align-top{alt: :🏝⛵️🍀🌿}

    #navbarNavSiteMenus.collapse.navbar-collapse
      .navbar-nav.mr-auto
        = link_to :root, class: ['nav-item', 'nav-link'] do
          %i.material-icons.md-18<> home
          = t('menu.home')
          %span.sr-only> (current)
        = content_for?(:controller_menu) ? yield(:controller_menu) : ''

      .navbar-nav
        = content_for?(:profile_menu) ? yield(:profile_menu) : ''
  CODE

  file '_main.html.haml', <<-CODE
%main{class: [:c, :a].zip([controller_name, action_name]).map {|n| n.join("-") }}
  .container<
    = render 'layouts/flash'
  .container<
    = content_for?(:content) ? yield(:content) : yield
  CODE

  file '_footer.html.haml', <<-CODE
%footer.footer.text-muted
  .container
    .list-inline
      %a.m-2{href: '/'}<>= t('menu.home')
      \|
      %a.m-2{href: '/'}<>= t('menu.support')

    %p<
      .small.m-2<
        = surround "由", "提供技术支持" do
          = link_to 'Lax', 'https://github.com/Lax', class: 'm-1'
  CODE

  file '_flash.html.haml', <<-CODE
- flash.each do |name, msg|
  %div{class: flash_class(name, [:flash, :'alert-dismissible']), role: :alert}
    %button.close{type: "button", "data-dismiss": "alert", "aria-label": "Close"}
      %span{"aria-hidden": true} &times;
    %strong= '[%s]' % name
    %span= msg
  CODE

end
