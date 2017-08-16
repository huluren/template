#========== Comment ==========#
generate 'scaffold comment user:references content:text commentable:references{polymorphic}:index --no-resource-route --no-scaffold-stylesheet --parent=post'

route <<-CODE
concern :commentable do
    resources :comments, shallow: true
  end
CODE

gsub_file 'config/routes.rb', /resources :(users)/, '\0, concerns: :commentable'

file 'config/locales/comment.yml', <<-CODE
en:
  comment:
    comment: Comment
    content: Content
    write_comment: Write your comment...
    leave_comment_here: Leave comment here.
    save: Post
    comments:
      zero: "No comments"
      one: "%{count} comment"
      few: "%{count} comments"
      many: "%{count} comments"
      other: "%{count} comments"

    list_comments: Comments
    new_comment: New Comment
    edit_comment: Update Comment

zh-CN:
  comment:
    comment: 评论
    content: 内容
    write_comment: 发表评论
    leave_comment_here: 留下你的评论
    save: 发布
    comments:
      zero: "无评论"
      one: "%{count} 条评论"
      few: "%{count} 条评论"
      many: "%{count} 条评论"
      other: "%{count} 条评论"
    new_comment: 添加评论

    list_comments: 评论列表
    new_comment: 添加评论
    edit_comment: 编辑评论
CODE

inside 'app/models/' do
  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :user_comments, class_name: 'Comment'
  CODE

  inject_into_class 'user.rb', 'User', <<-CODE
  has_many :comments, as: :commentable, foreign_key: :belongs_to_id, foreign_type: :belongs_to_type, inverse_of: :commentable
  CODE

  inject_into_class 'post.rb', 'Post', <<-CODE
  has_many :comments, as: :commentable, foreign_key: :belongs_to_id, foreign_type: :belongs_to_type, inverse_of: :commentable
  CODE

  gsub_file 'comment.rb', /^\s+belongs_to :user\n/, ''
  insert_into_file 'comment.rb', ', foreign_key: :belongs_to_id, foreign_type: :belongs_to_type', after: /belongs_to :commentable, polymorphic: true$/
  inject_into_class 'comment.rb', 'Comment', <<-CODE
  alias_attribute :commentable_id, :belongs_to_id
  alias_attribute :commentable_type, :belongs_to_type
  validates :content, presence: true
  validates :commentable, presence: true
  CODE
end

inside 'app/controllers/' do
  inject_into_class 'comments_controller.rb', CommentsController, <<-CODE
  before_action :authenticate_user!, only: [:new, :edit, :create, :update, :destroy]
  CODE

  gsub_file 'comments_controller.rb', /(\n(\s*))(before_action :set_comment)(, only.*?)\n/, <<-CODE
\\1before_action :set_commentable, only: [:index, :create, :new]
\\2\\3_commentable\\4
  CODE

  gsub_file 'comments_controller.rb', /(\n(\s*))def set_comment\n.*?end\n/m, <<-CODE
\\1def set_comment_commentable
\\2  @comment = Comment.find(params[:id])
\\2  @commentable = @comment.commentable
\\2end

\\2# :index, :create, :new
\\2def set_commentable
\\2  @commentable = -> {
\\2    params.each do |name, value|
\\2      if name =~ /(.+)_id$/
\\2        return $1.classify.constantize.find(value)
\\2      end
\\2    end
\\2    return nil
\\2  }.call
\\2end
  CODE

  append_to_file 'comments_controller.rb', ', :belongs_to_id, :belongs_to_type', after: /params.require.+?.permit.+?:commentable_id, :commentable_type/

  gsub_file 'comments_controller.rb', /(def index\n.*?)Comment.all\n/m, <<-CODE
\\1@commentable.comments
  CODE

  gsub_file 'comments_controller.rb', /(def (new|create)\n.*?)Comment.new(.*?)\n/m, <<-CODE
\\1@commentable.comments.new\\3
  CODE

  gsub_file 'comments_controller.rb', /(\n(\s*?)def new\n[^\n]*?\n)(\s*?end)\n/m, <<-CODE
\\1\\2  @comment.user = current_user
\\3
  CODE

  insert_into_file 'comments_controller.rb', after: /^([ ]+?)if @comment.save\n/ do
    <<-CODE
\\1  format.js
    CODE
  end

  gsub_file 'comments_controller.rb', /(redirect_to )comments_url(, )/, '\1polymorphic_url([@commentable, Comment])\2'
end

inside 'app/views/comments/' do
  gsub_file 'index.html.haml', /^(\s*?%)(table|thead)$/, '\1\2.\2'
  gsub_file 'index.html.haml', /^(%h1) .*$/, %q^%h3= t('comment.list_comments')^
  gsub_file 'index.html.haml', /link_to 'New Comment'/, %q{link_to_if user_signed_in?, t('comment.new_comment')}
  gsub_file 'index.html.haml', /new_comment_path\n/, <<-CODE
new_polymorphic_url([@commentable, Comment]),
             data: {remote: true, method: :get, type: :script},
             class: 'btn btn-outline-primary',
             id: :new_comment  { link_to t('profile.login'), :new_user_session, class: 'btn btn-outline-primary' }
  CODE

  prepend_to_file 'index.html.haml', <<-CODE
= render @commentable
  CODE

  gsub_file 'index.html.haml', /(\n)%table.*?\n([^\s].*)\n/m, <<-CODE
\\1= render 'comments', commentable: @commentable, comments: @comments
\\2
  CODE

  file '_comments.html.haml', <<-CODE
/ commentable, comments
#comments.list-group{'data-url': polymorphic_url([commentable, :comments], only_path: true)}
  - comments.each do |comment|
    = render comment
  CODE

  file '_comment.html.haml', <<-CODE
.list-group-item.flex-column.align-items-start
  .d-flex.w-100.justify-content-between<>
  %p.comment-content.mt-1<>= comment.content.html_safe
  %small<>
  CODE

  gsub_file '_form.html.haml', /@comment/, 'comment'

  gsub_file '_form.html.haml', /(= f.text_field :)(user|commentable)$/, '= f.hidden_field :\2_id'
  gsub_file '_form.html.haml', /(= f.hidden_field :)(user_id)$/, '\1\2, value: current_user.id'
  gsub_file '_form.html.haml', /(\s+?).field\n\s+?= f\.label[^\n]+\n\s+?(= f\.hidden_field [^\n]+?\n)/m, '\1\2'

  gsub_file '_form.html.haml', /(= form_for ([@]*comment))( do .*)\n/, <<-CODE
- form_path = \\2.id ? comment_path(\\2) : polymorphic_url([\\2.commentable, :comments], only_path: true)
\\1, url: form_path, data: {remote: true, method: :post, type: :script, 'disable-with': 'Saving...'}\\3
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?)).field\n(\s+?[^\n]+content\n)+/m, <<-CODE
\\1.form-group.row
\\2  .input-group
\\2    %span.input-group-addon.btn.btn-secondary<>= t('comment.content')
\\2    = f.text_area :content,
\\2                  class: 'form-control ckeditor',
\\2                  placeholder: t('comment.write_comment'),
\\2                  'aria-describedby': 'comment-content-help',
\\2                  rows: 3
\\2  %small#comment-content-help.form-text.text-muted<>= t('comment.write_comment')
  CODE

  gsub_file '_form.html.haml', /(\n+?(\s+?))\.actions\n\s+?= f.submit [^\n]+?\n/m, <<-CODE
\\1.form-group.row.actions
\\2  = f.submit t('comment.save'), class: [:btn, "btn-primary", "btn-lg", "btn-block"]
  CODE

  gsub_file 'new.html.haml', /comments_path/, '[@commentable, Comment]'
  gsub_file 'new.html.haml', /= render 'form'$/, '\0, comment: @comment'
  gsub_file 'new.html.haml', /^(%h1) .*$/, %q^\1= t('comment.new_comment')^

  file 'new.js.coffee', <<-CODE
$("#new_comment").replaceWith "<%= escape_javascript(render 'form', comment: @comment) %>"
  CODE

  gsub_file 'show.html.haml', /comments_path/, '[@commentable, Comment]'

  gsub_file 'edit.html.haml', /comments_path/, '[@commentable, Comment]'
  gsub_file 'edit.html.haml', /= render 'form'$/, '\0, comment: @comment'
  gsub_file 'edit.html.haml', /^(%h1) .*$/, %q^\1= t('comment.edit_comment')^

  file 'create.js.coffee', <<-CODE
$("#new_comment").before "<%= escape_javascript(render @comment, commentable: @commentable) %>"
  CODE

  gsub_file 'show.html.haml', /^%p\n.+(\n\n)/m, '= render @comment\1'

  gsub_file 'new.html.haml', /= link_to 'Back', .*$/, %q^= link_to t('action.back'), :back^
  gsub_file 'edit.html.haml', /= link_to 'Back', .*$/, %q^= link_to t('action.back'), :back^
end

inside 'app/assets/javascripts/' do

  append_to_file 'comments.coffee', <<-CODE
$(document).on "turbolinks:load", ->

  $("main").on "ajax:success", "form#new_comment", (event) ->
    [response, status, xhr] = event.detail
    $(this).trigger("reset")
  $("main").on "ajax:error", "form#new_comment", (event) ->
    [response, status, xhr] = event.detail
    return ! confirm "Error, cannot save: " + status
  $("main").on "ajax:complete", "form#new_comment", (event) ->
    [xhr, status] = event.detail
    $(this).off( "submit" )

  true
  CODE

end

inside('spec/factories/') do
  gsub_file 'comments.rb', /^\s*user nil$/, '    user'
  gsub_file 'comments.rb', /^\s*content .*$/, '    sequence(:content) {|n| %/Comment Content #{n}/ }'
  gsub_file 'comments.rb', /^\s*commentable nil$/, '    association :commentable, factory: :user'

  insert_into_file 'comments.rb', after: %/association :commentable, factory: :user\n/ do
    <<-CODE

    factory :invalid_comment do
      user nil
      content nil
      commentable nil
    end

    factory :bare_comment do
      user nil
      content nil
      commentable nil
    end
    CODE
  end
end

inside 'spec/models/' do
  gsub_file 'comment_spec.rb', /^\s.pending .*\n/, <<-CODE
  it "should increment the count" do
    expect{ create(:comment) }.to change{Comment.count}.by(1)
  end

  it "should fail with bare comment" do
    expect( build(:bare_comment) ).to be_invalid
  end

  it "should fail with invalid" do
    expect( build(:invalid_comment) ).to be_invalid
  end

  it "should fail without :user" do
    expect( build(:comment, user: nil) ).to be_invalid
  end

  it "should fail without :content" do
    expect( build(:comment, content: nil) ).to be_invalid
  end

  it "should fail without :commentable" do
    expect( build(:comment, commentable: nil) ).to be_invalid
  end

  it "should have :commentable_id" do
    expect( create(:comment).commentable ).not_to be(nil)
  end

  describe "with commentable association" do
    it "create comment with #comments.new" do
      commentable = create(:user)
      expect( commentable.comments.new.commentable ).to be(commentable)
    end
  end
CODE
end

inside 'spec/controllers/' do
  insert_into_file 'comments_controller_spec.rb', after: /^(\n+?(\s+?))describe "(GET|POST|PUT|DELETE) #(new|edit|create|update|destroy)" do\n/ do
    <<-CODE
\\2  before do
\\2    sign_in create(:user)
\\2  end
    CODE
  end

  gsub_file 'comments_controller_spec.rb', /let\(:valid_attributes\) \{\n\s*skip.*?\n\s*\}\n/m, <<-CODE
let(:valid_attributes) {
    build(:comment, commentable: create(:user)).attributes.except("id", "created_at", "updated_at")
  }
  CODE

  gsub_file 'comments_controller_spec.rb', /(get :(index|new), params: \{)(})/, '\1 user_id: create(:user) \3'
  gsub_file 'comments_controller_spec.rb', /(post :create, params: {comment: (valid_attributes|invalid_attributes))(})/, %q!\1, :"#{valid_attributes['belongs_to_type'].downcase}_id" => \2['belongs_to_id']\3!

  gsub_file 'comments_controller_spec.rb', /let\(:invalid_attributes\) \{\n\s*skip.*?\n\s*\}\n/m, <<-CODE
let(:invalid_attributes) {
    build(:invalid_comment, commentable: create(:user)).attributes.except("id", "created_at", "updated_at")
  }
  CODE

  gsub_file 'comments_controller_spec.rb', /let\(:new_attributes\) \{\n\s*skip.*?\n\s*\}\n/m, <<-CODE
let(:new_attributes) {
        build(:comment).attributes.except("id", "created_at", "updated_at")
      }
  CODE

  gsub_file 'comments_controller_spec.rb', /(updates the requested comment.*?)skip\(.*?\)\n/m, <<-CODE
\\1expect(comment.attributes.fetch_values(*new_attributes.keys)).to be == new_attributes.values
  CODE

  gsub_file 'comments_controller_spec.rb', /(DELETE #destroy.*?redirects to the comments list.*?)\n(\s*)(delete :destroy.*?)comments_url(.*)\n/m, <<-CODE
\\1
\\2commentable = comment.commentable
\\2\\3[commentable, Comment]\\4
  CODE

end

inside 'spec/views/comments/' do
  gsub_file 'new.html.haml_spec.rb', /(before.*\n(\s*))assign\(:comment, Comment.new\(.*?\)\)\n/m, <<-CODE
\\1@commentable = create :user
\\2assign(:comment, build(:comment, commentable: @commentable))
  CODE
  insert_into_file 'new.html.haml_spec.rb', %^\\1  sign_in(create(:user))^, after: /(\s+?)before\(:each\) do/

  gsub_file 'new.html.haml_spec.rb', /(, )(comments_path)(, )/, '\1user_\2(@commentable)\3'

  gsub_file 'edit.html.haml_spec.rb', /(before.*?\n(\s*))(.*?)Comment.create!\(.*?\)\)\n/m, <<-CODE
\\1@commentable = build(:user)
\\2@comment = assign(:comment, create(:comment, commentable: @commentable))
  CODE
  insert_into_file 'edit.html.haml_spec.rb', %^\\1  sign_in(create(:user))^, after: /(\s+?)before\(:each\) do/

  gsub_file 'index.html.haml_spec.rb', /assign\(:comments,.*?\]\)(\n)/m, <<-CODE
@commentable = create :user
    @comments = assign(:comments, create_list(:comment, 2, commentable: @commentable))
  CODE

  gsub_file 'index.html.haml_spec.rb', /(renders a list of comments.*?)\n\s+render(\s*assert_select.*?\n)+/m, <<-CODE
\\1
    expect(@comments.size).to be(2)

    render

    @comments.each do |comment|
      assert_select "#comments .comment-content", text: comment.content.to_s, count: 1
    end
  CODE

  gsub_file 'show.html.haml_spec.rb', /(before.*?\n(\s*))(.*?)Comment.create!\(.*?\)\)\n/m, <<-CODE
\\1@commentable = create :user
\\2\\3create(:comment, commentable: @commentable))
  CODE

  gsub_file 'show.html.haml_spec.rb', /(renders attributes in .*?)expect.*?(\s+end)\n/m, <<-CODE
\\1expect(rendered).to match(/\#{@comment.content}/)\\2
  CODE

end

gsub_file 'spec/routing/comments_routing_spec.rb', /(\s*it .*?#(index|new|create).*?\n\s*?expect.*?)(\/comments.*?route_to\(.comments#\2.)(\))\n/m, <<-CODE
\\1/users/1\\3, user_id: '1'\\4
CODE

gsub_file 'spec/helpers/comments_helper_spec.rb', /^\s.pending .*\n/, ''

gsub_file 'spec/requests/comments_spec.rb', /comments_path$/, 'user_\0(create :user)'
