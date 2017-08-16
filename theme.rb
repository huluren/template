inside('app/assets/stylesheets') do
  file "#{app_name}.scss", <<-SCSS
@import 'bootstrap';

.navbar.sticky-top {
  opacity: .91;
}
  SCSS

  file "material-icons.css", <<-MATERIAL_ICONS
/* Rules for sizing the icon. */
.material-icons.md-18 { font-size: 18px; }
.material-icons.md-24 { font-size: 24px; }
.material-icons.md-36 { font-size: 36px; }
.material-icons.md-48 { font-size: 48px; }

/* Rules for using icons as black on a light background. */
.material-icons.md-dark { color: rgba(0, 0, 0, 0.54); }
.material-icons.md-dark.md-inactive { color: rgba(0, 0, 0, 0.26); }

/* Rules for using icons as white on a dark background. */
.material-icons.md-light { color: rgba(255, 255, 255, 1); }
.material-icons.md-light.md-inactive { color: rgba(255, 255, 255, 0.3); }
  MATERIAL_ICONS
end

inside('app/assets/javascripts') do
  insert_into_file 'application.js', before: '//= require rails-ujs' do
    <<-CODE
//= require jquery.min
//= require popper
//= require bootstrap.min
    CODE
  end

  insert_into_file 'application.js', after: "//= require rails-ujs\n" do
    <<-CODE
//= require rails-timeago
//= require locales/jquery.timeago.zh-CN.js
    CODE
  end

  file 'navbar_hide.coffee', <<-CODE
$(document).ready ->
  $(window).scroll ->
    if $(this).scrollTop() > $('body > nav.navbar').outerHeight(true) * 2.718
      $('body > nav.navbar').fadeOut 500
    else
      $('body > nav.navbar').fadeIn 500
  CODE
end
