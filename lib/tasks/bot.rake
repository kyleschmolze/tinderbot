task :like => :environment do
  require 'tinder'
  t = Tinder.new
  t.init
  t.like_all(message: false, debug: false)
  # t.message_updates
end
