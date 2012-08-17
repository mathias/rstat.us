FactoryGirl.define do
  sequence(:uid) { |i| i }

  factory :authorization do
    uid
    nickname "god"
    provider "twitter"
    oauth_token "abcd"
    oauth_secret "efgh"
    user
  end
end
