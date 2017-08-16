inject_into_class 'app/models/application_record.rb', 'ApplicationRecord', <<-CODE
  scope :recent, -> { unscope(:order).order(id: :desc) }
  scope :sample, ->(s=true) { s ? unscope(:order).order("RANDOM()") : nil }
CODE
