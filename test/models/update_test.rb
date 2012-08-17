require_relative '../test_helper'

describe Update do
  include TestHelper

  describe "text length" do
    it "is not valid without any text" do
      u = FactoryGirl.create.build(:update, :text => "")
      refute u.save, "I made an empty update, it's very zen."
    end

    it "is valid with one character" do
      u = FactoryGirl.create.build(:update, :text => "?")
      assert u.save
    end

    it "is not valid with > 140 characters" do
      u = FactoryGirl.create.build(:update, :text => "This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. This is a long update. jklol")
      refute u.save, "I made an update with over 140 characters"
    end
  end

  describe "@ replies" do
    describe "non existing user" do
      it "does not make links (before create)" do
        u = FactoryGirl.create.build(:update, :text => "This is a message mentioning @steveklabnik.")
        assert_match "This is a message mentioning @steveklabnik.", u.to_html
      end

      it "does not make links (after create)" do
        u = FactoryGirl.create(:update, :text => "This is a message mentioning @steveklabnik.")
        assert_match "This is a message mentioning @steveklabnik.", u.to_html
      end
    end

    describe "existing user" do
      before do
        FactoryGirl.create(:user, :username => "steveklabnik")
      end

      it "makes a link (before create)" do
        u = FactoryGirl.create.build(:update, :text => "This is a message mentioning @SteveKlabnik.")
        assert_match /\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.to_html
      end

      it "makes a link (after create)" do
        u = FactoryGirl.create(:update, :text => "This is a message mentioning @SteveKlabnik.")
        assert_match /\/users\/steveklabnik'>@SteveKlabnik<\/a>/, u.to_html
      end
    end

    describe "existing user with domain" do
      it "makes a link (before create)" do
        @author = FactoryGirl.create(:author, :username => "steveklabnik",
                                   :domain => "identi.ca",
                                   :remote_url => 'http://identi.ca/steveklabnik')
        u = FactoryGirl.create.build(:update, :text => "This is a message mentioning @SteveKlabnik@identi.ca.")
        assert_match /<a href='#{@author.url}'>@SteveKlabnik@identi.ca<\/a>/, u.to_html
      end

      it "makes a link (after create)" do
        @author = FactoryGirl.create(:author, :username => "steveklabnik",
                                   :domain => "identi.ca",
                                   :remote_url => 'http://identi.ca/steveklabnik')
        u = FactoryGirl.create(:update, :text => "This is a message mentioning @SteveKlabnik@identi.ca.")
        assert_match /<a href='#{@author.url}'>@SteveKlabnik@identi.ca<\/a>/, u.to_html
      end
    end

    describe "existing user mentioned in the middle of the word" do
      before do
        FactoryGirl.create(:user, :username => "steveklabnik")
        FactoryGirl.create(:user, :username => "bar")
      end

      it "does not make a link (before create)" do
        u = FactoryGirl.create.build(:update, :text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
        assert_match "\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='http:\/\/#{u.author.domain}\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.to_html
      end

      it "does not make a link (after create)" do
        u = FactoryGirl.create(:update, :text => "@SteveKlabnik @nobody foo@bar.wadus @SteveKlabnik")
        assert_match "\/users\/steveklabnik'>@SteveKlabnik<\/a> @nobody foo@bar.wadus <a href='http:\/\/#{u.author.domain}\/users\/steveklabnik'>@SteveKlabnik<\/a>", u.to_html
      end
    end
  end

  describe "links" do
    it "makes URLs into links (before create)" do
      u = FactoryGirl.create.build(:update, :text => "This is a message mentioning http://rstat.us/.")
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
      u = FactoryGirl.create.build(:update, :text => "https://github.com/hotsh/rstat.us/issues#issue/11")
      assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.to_html
    end

    it "makes URLs into links (after create)" do
      u = FactoryGirl.create(:update, :text => "This is a message mentioning http://rstat.us/.")
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
      u = FactoryGirl.create(:update, :text => "https://github.com/hotsh/rstat.us/issues#issue/11")
      assert_equal "<a href='https://github.com/hotsh/rstat.us/issues#issue/11'>https://github.com/hotsh/rstat.us/issues#issue/11</a>", u.to_html
    end

    it "makes URLs in this edgecase into links" do
      edgecase = <<-EDGECASE
        Not perfect, but until there's an API, you can quick add text to your status using
        links like this: http://rstat.us/?status={status}
      EDGECASE
      u = FactoryGirl.create.build(:update, :text => edgecase)
      assert_match "<a href='http://rstat.us/?status={status}'>http://rstat.us/?status={status}</a>", u.to_html
    end
  end

  describe "hashtags" do
    it "makes links if hash starts a word (before create)" do
      u = FactoryGirl.create.build(:update, :text => "This is a message with a #hashtag.")
      assert_match /<a href='\/search\?search=%23hashtag'>#hashtag<\/a>/, u.to_html
      u = FactoryGirl.create.build(:update, :text => "This is a message with a#hashtag.")
      assert_equal "This is a message with a#hashtag.", u.to_html
    end

    it "makes links if hash starts a word (after create)" do
      u = FactoryGirl.create(:update, :text => "This is a message with a #hashtag.")
      assert_match /<a href='\/search\?search=%23hashtag'>#hashtag<\/a>/, u.to_html
      u = FactoryGirl.create(:update, :text => "This is a message with a#hashtag.")
      assert_equal "This is a message with a#hashtag.", u.to_html
    end

    it "makes links for both a hashtag and a URL (after create)" do
      u = FactoryGirl.create(:update, :text => "This is a message with a #hashtag and mentions http://rstat.us/.")

      assert_match /<a href='\/search\?search=%23hashtag'>#hashtag<\/a>/, u.to_html
      assert_match /<a href='http:\/\/rstat.us\/'>http:\/\/rstat.us\/<\/a>/, u.to_html
    end

    it "extracts hashtags" do
      u = FactoryGirl.create(:update, :text => "#lots #of #hash #tags")
      assert_equal ["lots", "of", "hash", "tags"], u.tags
    end
  end

  describe "twitter" do
    describe "twitter => true" do
      it "sets the tweeted flag" do
        u = FactoryGirl.create.build(:update, :text => "This is a message", :twitter => true)
        assert_equal true, u.twitter?
      end

      it "sends the update to twitter" do
        f = FactoryGirl.create(:feed)
        at = FactoryGirl.create(:author, :feed => f)
        u = FactoryGirl.create(:user, :author => at)
        a = FactoryGirl.create(:authorization, :user => u)
        Twitter.expects(:update)
        u.feed.updates << FactoryGirl.create.build(:update, :text => "This is a message", :twitter => true, :author => at)
        assert_equal u.twitter?, true
      end

      it "does not send to twitter if there's no twitter auth" do
        f = FactoryGirl.create(:feed)
        at = FactoryGirl.create(:author, :feed => f)
        u = FactoryGirl.create(:user, :author => at)
        Twitter.expects(:update).never
        u.feed.updates << FactoryGirl.create.build(:update, :text => "This is a message", :twitter => true, :author => at)
      end
    end

    describe "twitter => false (default)" do
      it "does not set the tweeted flag" do
        u = FactoryGirl.create.build(:update, :text => "This is a message.")
        assert_equal false, u.twitter?
      end

      it "does not send the update to twitter" do
        f = FactoryGirl.create(:feed)
        at = FactoryGirl.create(:author, :feed => f)
        u = FactoryGirl.create(:user, :author => at)
        a = FactoryGirl.create(:authorization, :user => u)
        Twitter.expects(:update).never
        u.feed.updates << FactoryGirl.create.build(:update, :text => "This is a message", :twitter => false, :author => at)
      end
    end
  end

  describe "same update twice in a row" do
    it "will not save if both are from the same user" do
      feed = FactoryGirl.create(:feed)
      author = FactoryGirl.create(:author, :feed => feed)
      user = FactoryGirl.create(:user, :author => author)
      update = FactoryGirl.create.build(:update, :text => "This is a message", :feed => author.feed, :author => author, :twitter => false)
      user.feed.updates << update
      user.feed.save
      user.save
      assert_equal 1, user.feed.updates.size
      update = FactoryGirl.create.build(:update, :text => "This is a message", :feed => author.feed, :author => author, :twitter => false)
      user.feed.updates << update
      refute update.valid?
    end

    it "will save if each are from different users" do
      feed1 = FactoryGirl.create(:feed)
      author1 = FactoryGirl.create(:author, :feed => feed1)
      user1 = FactoryGirl.create(:user, :author => author1)
      feed2 = FactoryGirl.create(:feed)
      author2 = FactoryGirl.create(:author, :feed => feed2)
      user2 = FactoryGirl.create(:user, :author => author2)
      update = FactoryGirl.create.build(:update, :text => "This is a message", :feed => author1.feed, :author => author1, :twitter => false)
      user1.feed.updates << update
      user1.feed.save
      user1.save
      assert_equal 1, user1.feed.updates.size
      update = FactoryGirl.create.build(:update, :text => "This is a message", :feed => author2.feed, :author => author2, :twitter => false)
      user1.feed.updates << update
      assert update.valid?
    end
  end
end
