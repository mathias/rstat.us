FactoryGirl.define do
  sequence(:text) { |i| "This is update #{i}" }
  factory :update do
    text 
    twitter false
    author { FactoryGirl.create author }
    feed { |update| FactoryGirl.create(:feed, update.author) }
  end
end
