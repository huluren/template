#========== Database Config ==========#
run 'mv config/database.yml config/database.yml.orig'
copy_file [__dir__, '/', 'database.yml'].join, 'config/database.yml'
