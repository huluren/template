# Follow
generate 'acts_as_followable'
generate 'rspec:model follow follower:references{polymorphic}:index followable:references{polymorphic}:index blocked:boolean --no-migration'

inside 'app/models/' do

  inject_into_class 'user.rb', 'User', <<-CODE
  acts_as_followable
  acts_as_follower
  CODE

  inject_into_class 'post.rb', 'Post', <<-CODE
  acts_as_followable
  CODE

end

inside 'spec/' do
  gsub_file 'factories/follows.rb', /(^\s*?)(follower|followable) nil$/, '\1association :\2, factory: :user'

  gsub_file 'models/follow_spec.rb', /(^(\s*)?)pending .*\n/, <<-CODE
\\1it "should increment the count" do
\\2  expect{ create(:follow) }.to change{Follow.count}.by(1)
\\2end

\\2it "can follow" do
\\2  follower = create(:user)
\\2  followable = create(:user)

\\2  expect{ follower.follow(followable) }.to change{Follow.count}.by(1)
\\2  expect( follower.follow?(followable) ).to be true
\\2end

\\2it "should fail without :follower" do
\\2  expect( build(:follow, follower: nil) ).to be_invalid
\\2end

\\2it "should fail without :followable" do
\\2  expect( build(:follow, followable: nil) ).to be_invalid
\\2end
  CODE
end
