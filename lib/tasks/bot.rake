require 'rake'
task :auto_like do |t, args|
  require 'tinder'
  puts "whats your fb id2"
  puts gets.chomp
  t = Tinder.new
  t.init
  t.like_all(message: false, debug: false)
  # t.message_updates
end
