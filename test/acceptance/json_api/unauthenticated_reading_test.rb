require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative '../acceptance_helper'

describe "JSON Unauthenticated reading" do
  include AcceptanceHelper

  it "can request an individual user's timeline" do
    u = FactoryGirl.create(:user)
    update0 = FactoryGirl.create(:update,
                      :text       => "This is a message posted yesterday",
                      :author     => u.author,
                      :created_at => 1.day.ago)
    update1 = FactoryGirl.create(:update,
                      :text       => "This is a message posted last week",
                      :author     => u.author,
                      :created_at => 1.week.ago)
    u.feed.updates << update0
    u.feed.updates << update1

    visit "/users/#{u.username}.json"

    parsed_json = JSON.parse(source)

    parsed_json.length.must_equal 2

    parsed_json[0]["text"].must_equal(update0.text)
    parsed_json[0]["user"]["username"].must_equal(u.username)

    parsed_json[1]["text"].must_equal(update1.text)
    parsed_json[1]["user"]["username"].must_equal(u.username)
  end

  it "can request all updates" do
    u = FactoryGirl.create(:user)
    update = FactoryGirl.create(:update,
               :author => u.author
             )
    u.feed.updates << update

    visit "/updates.json"

    parsed_json = JSON.parse(source)
    parsed_json.length.must_equal 1

    parsed_json[0]["text"].must_equal(update.text)
    parsed_json[0]["user"]["username"].must_equal(u.username)
  end

  describe "pagination" do
    it "does not paginate when there are too few" do
      FactoryGirl.create_list(:update, 5)

      visit "/updates.json?page=2"

      parsed_json = JSON.parse(source)
      parsed_json.length.must_equal 0
    end

    it "returns the next page of results if we add the page param" do
      FactoryGirl.create_list(:update, 30)

      visit "/updates.json?page=2"
      parsed_json = JSON.parse(source)
      parsed_json.length.must_equal 10
    end
  end
end
