require 'require_relative' if RUBY_VERSION[0,3] == '1.8'
require_relative 'acceptance_helper'

def search_for(query)
  visit "/search"
  fill_in "search", :with => query
  click_button "Search"
end

describe "search" do
  include AcceptanceHelper

  before do
    @update_text = "These aren't the droids you're looking for!"
    FactoryGirl.create(:update, :text => @update_text)
  end

  describe "logged in" do
    it "has a link to search when you're logged in" do
      log_in_as_some_user

      visit "/"

      assert has_link? "Search"
    end

    it "allows access to the search page" do
      visit "/search"

      assert_equal 200, page.status_code
      assert_match "/search", page.current_url
    end

    it "allows access to search" do
      search_for("droids")

      assert_match @update_text, page.body
    end
  end

  describe "anonymously" do
    it "allows access to the search page" do
      visit "/search"

      assert_equal 200, page.status_code
      assert_match "/search", page.current_url
    end

    it "allows access to search" do
      search_for("droids")

      assert_match @update_text, page.body
    end
  end

  describe "behavior regardless of authenticatedness" do
    it "gets a match for a word in the update" do
      search_for("droids")

      assert_match @update_text, page.body
    end

    it "doesn't get a match for a substring ending a word in the update" do
      search_for("roids")

      assert_match "No statuses match your search.", page.body
    end

    it "doesn't get a match for a substring starting a word in the update" do
      search_for("loo")

      assert_match "No statuses match your search.", page.body
    end

    it "gets a case-insensitive match for a word in the update" do
      search_for("DROIDS")

      assert_match @update_text, page.body
    end

    it "gets a match for hashtag search" do
      @hashtag_update_text = "This is a test #hashtag"
      FactoryGirl.create(:update, :text => @hashtag_update_text)

      search_for("#hashtag")

      assert has_link? "#hashtag"
    end
  end

  describe "pagination" do
    it "does not paginate when there are too few" do
      FactoryGirl.create_list(:update, 5, :text => "Testing pagination LIKE A BOSS")

      search_for("boss")

      refute_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward only if on the first page" do
      FactoryGirl.create_list(:update, 30, :text => "Testing pagination LIKE A BOSS")

      search_for("boss")

      refute_match "Previous", page.body
      assert_match "Next", page.body
    end

    it "paginates backward only if on the last page" do
      FactoryGirl.create_list(:update, 30, :text => "Testing pagination LIKE A BOSS")

      search_for("boss")
      click_link "next_button"

      assert_match "Previous", page.body
      refute_match "Next", page.body
    end

    it "paginates forward and backward if on a middle page" do
      FactoryGirl.create_list(:update, 54, :text => "Testing pagination LIKE A BOSS")

      search_for("boss")
      click_link "next_button"

      assert_match "Previous", page.body
      assert_match "Next", page.body
    end
  end
end
