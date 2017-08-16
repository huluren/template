
#========== Title ==========#
inside 'app/views/layouts/' do
  gsub_file 'application.html.erb', /(<title>).*(<\/title>)/, %q^\1<%= title %>\2^
end

inside 'config/locales/' do
  file 'title.yml', <<-CODE
en:
  titles:
    application: #{app_name.camelize}

zh-CN:
  titles:
    application: #{app_name.camelize}
  CODE
end
