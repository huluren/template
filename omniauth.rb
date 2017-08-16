generate 'model authentication', 'user:references provider uid token secret email name nickname image'
generate 'devise:controllers authentication', '-c=omniauth_callbacks'

inside 'app/models/' do
  inject_into_class 'authentication.rb', 'Authentication', <<-CODE
  validates :provider, :uid, :token, presence: true
  CODE

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :authentications, autosave: true, dependent: :destroy

  def self.from_omniauth(auth, current_user)
    # 1. find link auth -> user_id
    # 2. if logged in, link auth -> user_id
    # 3. if verified email, create link auth email -> user email
    authentication = Authentication.where( provider: auth.provider, uid: auth.uid.to_s ).first_or_initialize do |authentication|
      authentication.token = auth.credentials.token
      authentication.secret = auth.credentials.secret

      authentication.email = auth.info.email
      authentication.name = auth.info.name
      authentication.nickname = auth.info.nickname
      authentication.image = auth.info.image

      authentication.user = current_user || authentication.user || (User.where( email: auth.info.email ).first_or_initialize if email_verified?(auth))
      authentication.user.authentications << authentication
    end

    authentication.user
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session['devise.user_attributes']
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  def self.email_verified?(auth)
    case auth.provider
    when 'github'
      auth.extra.all_emails.select {|e| e.email == auth.info.email and e.verified == true }.size > 0
    when 'twitter'
      true
    when 'facebook'
      true
    when 'google_oauth2'
      auth.extra.id_info.email_verified
    else
      false
    end
  end
  CODE

  insert_into_file 'user.rb', ', :omniauthable', after: ':validatable'
end

inside 'app/controllers/authentication/' do

  inject_into_class 'omniauth_callbacks_controller.rb', 'Authentication::OmniauthCallbacksController', <<-CODE
  def omniauth
    @user = User.from_omniauth(request.env["omniauth.auth"], current_user)
    if @user.persisted?
      flash[:notice] = t('devise.omniauth_callbacks.success', kind: request.env["omniauth.auth"].provider)
      sign_in_and_redirect @user
    elsif @user.save
      flash[:notice] = "Account created and signed in successfully."
      sign_in_and_redirect(@user)
    else
      flash[:notice] = "Please create a password for your account."
      session['devise.user_attributes'] = @user.attributes
      redirect_to new_user_registration_url
    end
  end

  alias_method :github, :omniauth
  alias_method :twitter, :omniauth
  alias_method :facebook, :omniauth
  alias_method :google_oauth2, :omniauth
  CODE

end

insert_into_file 'config/routes.rb', %q^, controllers: { omniauth_callbacks: 'authentication/omniauth_callbacks' }^, after: 'devise_for :users'

insert_into_file 'config/initializers/devise.rb', after: /# config.omniauth [^\n]+?\n/ do
  <<-CODE
  config.omniauth :github, ENV['GITHUB_APP_ID'], ENV['GITHUB_APP_SECRET'], scope: 'user:email'
  config.omniauth :twitter, ENV['TWITTER_API_KEY'], ENV['TWITTER_API_SECRET']
  config.omniauth :facebook, ENV['FACEBOOK_APP_ID'], ENV['FACEBOOK_APP_SECRET']
  config.omniauth :google_oauth2, ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'], verify_iss: false
  CODE
end

inside 'spec/factories/' do
  gsub_file 'authentications.rb', /(^\s*?)(user) nil$/, '\1\2'
  gsub_file 'authentications.rb', /(^\s*?)(provider|uid|token) .*?$/, %q^\1sequence(:\2) {|n| 'auth_\2_%d' % n }^

  insert_into_file 'authentications.rb', before: /^(\s\s)end$/ do
    <<-CODE

\\1  factory :invalid_authentication do
\\1    provider nil
\\1    uid nil
\\1    token nil
\\1  end
    CODE
  end
end

inside 'spec/models/' do
  gsub_file 'authentication_spec.rb', /(^(\s*)?)pending .*\n/, <<-CODE
\\1describe "#create" do

\\2  it "should increment the count" do
\\2    expect{ create(:authentication) }.to change{Authentication.count}.by(1)
\\2  end

\\2  it "should fail with invalid" do
\\2    expect( build(:invalid_authentication) ).to be_invalid
\\2  end

\\2  it "should fail without :provider" do
\\2    expect( build(:authentication, provider: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :uid" do
\\2    expect( build(:authentication, uid: nil) ).to be_invalid
\\2  end

\\2  it "should fail without :token" do
\\2    expect( build(:authentication, token: nil) ).to be_invalid
\\2  end

\\2end
  CODE
end
