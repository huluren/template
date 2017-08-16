file 'app.json', <<-CODE
{
  "formation": {
    "web": {
      "quantity": 1,
      "size": "free"
    }
  },
  "buildpacks": [
    {
      "url": "heroku/ruby"
    }
  ],
  "addons": [
    "heroku-postgresql:hobby-dev",
    "heroku-redis:hobby-dev",
    "newrelic:wayne"
  ],
  "scripts": {
    "postdeploy": "bundle exec rails db:migrate"
  },
  "env": {
    "SECRET_KEY_BASE": {
      "description": "SECRET_KEY_BASE",
      "generator": "secret"
    },
    "DEVISE_SECRET_KEY": {
      "description": "DEVISE_SECRET_KEY",
      "generator": "secret"
    },
    "DEVISE_PEPPER": {
      "description": "DEVISE_PEPPER",
      "generator": "secret"
    }
  },
  "environments": {
    "test": {
      "env": {
        "SECRET_KEY_BASE": "SECRET_KEY_BASE",
        "DEVISE_SECRET_KEY": "DEVISE_SECRET_KEY",
        "DEVISE_PEPPER": "DEVISE_PEPPER"
      },
      "scripts": {
        "spec": "bundle exec rails spec"
      }
    }
  }
}
CODE
