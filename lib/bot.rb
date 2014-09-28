#!/bin/env ruby
# encoding: utf-8

class Bot
  require 'pyro'
  attr_reader :pyro
  attr_accessor :facebook_id, :access_token, :count, :latitude

  def self.go
    tinder = self.new

    if File.exists?("facebook_id.txt")
      id = `cat facebook_id.txt`.chomp
      if id.present?
        puts "Last time, you used Facebook ID #{id}. Reuse this one? (type yes or no)"
        if ['yes', 'y'].include? gets.chomp
          tinder.facebook_id = id
        end
      end
    end

    unless tinder.facebook_id.present?
      puts "We need your Facebook ID. Go here to find it:"
      puts "http://findmyfacebookid.com/"
      puts "Then paste the ID in here:"
      tinder.facebook_id = gets.chomp
      while tinder.facebook_id.blank?
        tinder.facebook_id = gets.chomp
        puts "Sorry, didn't catch that. What's your Facebook id?" if tinder.facebook_id.blank?
      end
      `echo #{tinder.facebook_id} > facebook_id.txt`
    end

    unless tinder.facebook_id.present?
      puts "We need your Facebook ID. Go here to find it:"
      puts "http://findmyfacebookid.com/"
      puts "Then paste the ID in here:"
      tinder.facebook_id = gets.chomp
      while tinder.facebook_id.blank?
        tinder.facebook_id = gets.chomp
        puts "Sorry, didn't catch that. What's your Facebook id?" if tinder.facebook_id.blank?
      end
      `echo #{tinder.facebook_id} > facebook_id.txt`
    end

    puts "\n\n==============================\n\n\n"


    if File.exists?("facebook_token.txt")
      token = `cat facebook_token.txt`.chomp
      if token.present?
        puts "We've got your last access_token on file. But they only last a few hours, so it may have expired by now. Retry with this one? (type yes or no)"
        if ['yes', 'y'].include? gets.chomp
          tinder.access_token = token
        end
      end
    end

    if tinder.access_token.blank?
      puts 'Great. Now we need an access token. Open this URL in your browser, and when you hit the Facebook "Success" page, *immediately* copy the URL. You will be redirected away within about 2 seconds, so be fast. (You can try as many times as you need though). Here\'s the URL:'
      puts ""
      puts "https://www.facebook.com/dialog/oauth?client_id=464891386855067&redirect_uri=https://www.facebook.com/connect/login_success.html&scope=basic_info,email,public_profile,user_about_me,user_activities,user_birthday,user_education_history,user_friends,user_interests,user_likes,user_location,user_photos,user_relationship_details&response_type=token"
      puts ""
      puts 'Enter the URL of the "Success" page here (it should contain the word "access_token"):'
      while tinder.access_token.blank?
        access_url = gets.chomp
        tinder.access_token = access_url[/access_token=.*[&^]/]
        puts "Sorry, we couldn't find the access_token in that URL, please try again, and enter the new URL:" if tinder.access_token.blank?
      end
      tinder.access_token.gsub!(/access_token=/, '')
      tinder.access_token.gsub!(/&/, '')
      `echo #{tinder.access_token} > facebook_token.txt`
    end

    puts "\n\n==============================\n\n\n"

    puts "Great! How many people would you like to auto-like?"
    while tinder.count.blank?
      tinder.count = gets.chomp.to_i
      tinder.count = nil if tinder.count <= 0
      puts "Sorry, didn't catch that. How many people would you like to auto-like?" if tinder.count.blank?
    end
    puts "All right, let's see if this works. Logging in..."
    tinder.init
    puts "Logged in! Getting nearby users..."
    tinder.like
  end

  def init
    @pyro = TinderPyro::Client.new
    @pyro.sign_in(self.facebook_id, self.access_token)
  end

  def like
    total_liked = 0
    matched = 0
    while true
      #puts 'requesting' if options[:debug]
      response = JSON.parse(@pyro.get_nearby_users.body)
      users = response["results"]
      if users.nil?
        puts "Sorry, no users included in response from Tinder API. The response was:"
        puts response
        break
      end

      if users.length == 0
        puts "You ran out of users to match with!"
        break
      end

      for user in users
        sleep(0.5)
        puts "Liking #{user["name"]}"
        response = @pyro.like user["_id"]
        match = JSON.parse(response.body)["match"]
        if match
          puts "Matched with #{user["name"]}!"
          matched += 1
          # send_message(match) # You can use this to auto send a message with each *immediate* match
        end
        total_liked += 1
        break if total_liked >= self.count
      end
      break if total_liked >= self.count
    end
    puts "Liked #{total_liked} users"
    puts "Matched #{matched} users"
  end

  def send_message(match)
    @pyro.send_message(match["_id"], your_message_here)
    puts "Messaging #{user["name"]}"
  end

  def message_updates
    # This doesn't seem to work yet, so not using it
    updates = JSON.parse(@pyro.fetch_updates.body)
    for match in updates["matches"]
      unless Match.where(tinder_id: match["_id"]).exists?
        puts "Messaging #{match["_id"]}"
        pyro.send_message(match["_id"], "🍻?")
        Match.create!(tinder_id: match["_id"])
      end
    end
  end

  def update_location
    #latitude, longitude = [37.758107, -122.419232]
    #@pyro.update_location(latitude, longitude)
  end
end
