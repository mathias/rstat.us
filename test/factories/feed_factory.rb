FactoryGirl.define do
  factory :feed do
    author { FactoryGirl.create(:author) }
  end
end
