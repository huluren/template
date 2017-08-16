#========== i18n ==========#
inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController', <<-CODE
  before_action :set_locale

  def self.default_url_options
    { locale: I18n.locale }
  end

  def set_locale
    if params[:locale] and I18n.available_locales.include?(params[:locale].to_s.strip.to_sym)
      l = params[:locale].to_s.strip.to_sym
    else
      l = I18n.default_locale
    end
    I18n.locale = l
  end
CODE
