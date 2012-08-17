FactoryGirl.define do

  factory :author do
    username
    email
    feed { |a| FactoryGirl.create(:feed, author: a ) }
    website "http://example.com"
    domain "foo.example.com"
    name "Something"
    bio "Hi, I do stuff."
  end
end
