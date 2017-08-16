#========== Devise ==========#
generate 'devise:install'
generate 'devise:i18n:locale', :'zh-CN'
generate 'model user'
generate :devise, :user

route 'resources :users, only: []'

file 'config/locales/profile.yml', <<-CODE
en:
  profile:
    profile: Profile
    sign_up: Sign Up
    login: Login
    logout: Logout
    update: Update Profile

zh-CN:
  profile:
    profile: 个人帐户
    sign_up: 注册
    login: 登入
    logout: 登出
    update: 更新账户信息
CODE

inside 'app/views/users/' do
  file '_users.html.haml', <<-CODE
- users.each do |user|
  = render user
  CODE

  file '_user.html.haml', <<-CODE
.list-group-item.flex-column.align-items-start
  .d-flex.w-100.justify-content-between<>
    .lead.user-name
      = precede user.model_name.human do
        %b.ml-1<>= user.id
    %small.card.text-muted.p-1
  %p.user-description.mt-1<>
  .d-flex.w-100.justify-content-between<>
    - if user.respond_to? :comments
      %small
        = link_to t('comment.comments', count: user.comments.count),
                  polymorphic_url([user, :comments], only_path: true)
  CODE
end

inside 'app/views/layouts/' do
  prepend_to_file '_header.html.haml', <<-HEADER
- content_for :profile_menu do
  - if ! user_signed_in?
    = link_to t('profile.sign_up'), :new_user_registration, class: ['nav-item', 'nav-link']
    = link_to t('profile.login'), :new_user_session, class: ['nav-item', 'nav-link']
  - else
    .nav-item.dropdown
      %a#navbarNavProfileMenuLink.nav-link.dropdown-toggle{aria: {haspopup: "true", expanded: "false"}, data: {toggle: "dropdown"}}
        %i.material-icons.md-18<> person
        = t('profile.profile')
        %span.caret>
      .dropdown-menu.dropdown-menu-right{aria: {labelledby: "navbarNavProfileMenuLink"}}
        %h6.dropdown-header<
          = current_user.email
          %br<
          = precede "@" do
            %b>= current_user.id
        .dropdown-divider
        = link_to t('profile.logout'), :destroy_user_session, method: :delete, class: 'dropdown-item'
  HEADER
end


inside 'config/' do
  gsub_file 'initializers/devise.rb', /^(\s*# config.secret_key = ).*$/, '\1ENV["DEVISE_SECRET_KEY"]'
  gsub_file 'initializers/devise.rb', /^(\s*# config.pepper = ).*$/, '\1ENV["DEVISE_PEPPER"]'
end

inside 'spec' do

  file 'support/devise.rb', <<-DEVISE
RSpec.configure do |config|
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::ControllerHelpers, type: :view
  config.include Devise::Test::IntegrationHelpers, type: :feature
  config.include Devise::Test::IntegrationHelpers, type: :request
end
  DEVISE

  insert_into_file 'factories/users.rb', after: %/factory :user do\n/ do
    <<-USERS
    sequence(:email) { |n| "\#{n}@email.com" }
    password Devise.friendly_token[0, 6]

    factory :user_invalid_password do
      password Devise.friendly_token[0, 5]
    end

    factory :user_no_email do
      email nil
    end

    factory :user_no_password do
      password nil
    end
    USERS
  end

  gsub_file 'models/user_spec.rb', /^(\s*?)pending .*\n/, <<-USER
\\1describe "#create" do
\\1  it "should increment the count" do
\\1    expect{ create(:user) }.to change{User.count}.by(1)
\\1  end

\\1  it "should fail without ::email or :password" do
\\1    expect( build(:user_no_email) ).to be_invalid
\\1    expect( build(:user_no_password) ).to be_invalid
\\1  end
\\1end

\\1describe "#email duplicated" do
\\1  it "should fail with UniqueViolation" do
\\1    expect { 2.times {create(:user, email: 'duplicate@email.com')} }.to raise_error(ActiveRecord::RecordInvalid)
\\1  end
\\1end
  USER
end
