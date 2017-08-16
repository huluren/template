generate 'model post user:references:index title:string content:text type'
generate 'migration add_belongs_to_and_uuid_to_post belongs_to:references{polymorphic}:index uuid:string:uniq'

inside 'app/models/' do
  inject_into_class 'post.rb', 'Post', <<-CODE
  validates :user, presence: true

  acts_as_followable
  CODE

end

inside 'spec/factories/' do
  gsub_file 'posts.rb', /(^\s*?)(user) nil$/, '\1\2'
  gsub_file 'posts.rb', /(^\s*?)(title|content) .*?$/, %q^\1sequence(:\2) {|n| 'post_\2_%d' % n }^

  insert_into_file 'posts.rb', before: /^(\s\s)end$/ do
    <<-CODE
\\1  factory :invalid_post do
\\1    user nil
\\1    title nil
\\1    content nil
\\1  end
    CODE
  end
end

inside 'spec/models/' do
  gsub_file 'post_spec.rb', /(^(\s*)?)pending .*\n/, <<-CODE
\\1describe "#create" do
\\2  it "should increment the count" do
\\2    expect{ create(:post) }.to change{Post.count}.by(1)
\\2  end

\\2  it "should fail with invalid" do
\\2    expect( build(:invalid_post) ).to be_invalid
\\2  end

\\2  it "should fail without :user" do
\\2    expect( build(:post, user: nil) ).to be_invalid
\\2  end

\\2  it "should success without :title" do
\\2    expect( build(:post, title: nil) ).to be_valid
\\2  end

\\2  it "should success without :content" do
\\2    expect( build(:post, content: nil) ).to be_valid
\\2  end
\\2end

\\2describe "followable" do
\\2  it "can be followed by user" do
\\2    follower = create(:user)
\\2    followable = create(:post)
\\2    expect{ follower.follow(followable) }.to change{Follow.count}.by(1)
\\2    expect( follower.follow?(followable) ).to be true
\\2  end
\\2end
  CODE

end
