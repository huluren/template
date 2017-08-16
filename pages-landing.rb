#========== Landing ==========#
generate :controller, :pages, :landing, '--no-helper --no-assets --no-controller-specs --no-view-specs --no-javascripts --no-stylesheets --no-helper-specs'
route %q{root to: 'pages#landing'}
