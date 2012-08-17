FactoryGirl.define do
  sequence(:username) { |n| "user_#{n}" }
  sequence(:email) { |n| "user_#{n}@example.com" }

  factory :user do
    username
    email
    author { FactoryGirl.create(:author) }
  end
end
