generate 'kaminari:views bootstrap4'

inside 'app/controllers/' do
  gsub_file 'comments_controller.rb', /(\n(\s*?)def index\n\s+@comments = [^\n]*?)$/, '\1.page(params[:page])'
end

inside 'app/views/' do
  insert_into_file 'comments/index.html.haml', "= paginate @comments\n", before: /^%(table|br)/
end

inside 'spec/views/' do
  gsub_file 'comments/index.html.haml_spec.rb', /(@(comments) = assign\(:\2, )(create_list.+?)(\))$/, '\1Kaminari.paginate_array(\3).page(1)\4'
end
