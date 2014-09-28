#!/bin/env ruby
# encoding: utf-8

# https://www.facebook.com/dialog/oauth?client_id=464891386855067&redirect_uri=https://www.facebook.com/connect/login_success.html&scope=basic_info,email,public_profile,user_about_me,user_activities,user_birthday,user_education_history,user_friends,user_interests,user_likes,user_location,user_photos,user_relationship_details&response_type=token



class Tinder
  require 'pyro'
  attr_reader :pyro

  def init
    facebook_id = "1244041238"
    facebook_token = "CAAGm0PX4ZCpsBAG7YO6XGQEI0AvWQVEUWxyE6aESkkqrEx12aH7svbh1r7R1lKsU1mycpRqQp4xhxIclK1SZAsOovpGutkxlxFHZAyxrPZBSOCVEbCKDWfckLRtnJzJfzmZCgktnhCgXcJkJhsVqgdih1VnboR1hSeLLXt9oClZAcFGav0PVWIsUdyUT7ExqlJUZCZAQU45npj59ZAgO36kbo"
    @pyro = TinderPyro::Client.new
    @pyro.sign_in(facebook_id, facebook_token)
  end

  def update_location
    latitude, longitude = [37.758107, -122.419232]
    @pyro.update_location(latitude, longitude)
  end

  def like_all(options = {})
    total_liked = 0
    matched = 0
    while true
      puts 'requesting' if options[:debug]
      users = JSON.parse(@pyro.get_nearby_users.body)["results"]
      puts 'got response:' if options[:debug]
      puts users if options[:debug]
      puts "length: #{users.length}" if options[:debug]
      break if users.length == 0 or total_liked > 500
      for user in users
        sleep(0.5)
        puts "Liking #{user["name"]}"
        response = @pyro.like user["_id"]
        match = JSON.parse(response.body)["match"]
        if match
          puts "Matched!"
          matched += 1
        end
        if options[:message] and match and !Match.where(tinder_id: match["_id"]).exists?
          Match.create!(tinder_id: match["_id"])
          @pyro.send_message(match["_id"], "🍻?")
          puts "Messaging #{user["name"]}"
        end
        total_liked += 1
      end
    end
    puts "Liked #{total_liked} users"
    puts "Matched #{matched} users"
  end

  def message_updates
    updates = JSON.parse(@pyro.fetch_updates.body)
    for match in updates["matches"]
      unless Match.where(tinder_id: match["_id"]).exists?
        puts "Messaging #{match["_id"]}"
        pyro.send_message(match["_id"], "🍻?")
        Match.create!(tinder_id: match["_id"])
      end
    end
  end

  def self.run
    t = Tinder.new
    t.init
    t.like_all
    t.message_updates
  end
end
