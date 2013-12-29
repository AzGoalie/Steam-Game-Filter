#!/user/bin/env ruby

require 'json'
require 'open-uri'
require 'mechanize'

# Constants
key = '9476194843EE253F44A413B033CCB0B1'
store_page = 'http://store.steampowered.com'
game_page = '/app/'
filters = '(?<!Local )(Multi-player|Co-op)'	#regex(default)

# Steam user, can convert from vanity url if given
if ARGV.length < 1 or ARGV.length > 2
	puts "Need SteamID64 or vanity steam name"
	puts "(optional) a filter in quotes. Default is '(?<!Local )(Multi-player|Co-op)'" 
	puts "SteamID64 or Vanity URL can be found on your profile at"
	puts "http://steamcommunity.com/id/#################"
	puts "where the ##### would be it"
	exit
end

steamID = ARGV[0]
if steamID.match('[a-zA-Z]')
	# Try to resolve vanity url
	resolve_vanity = 'http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key=' + key + '&vanityurl=' + steamID
	response = JSON.parse(open(resolve_vanity).read)
	if response['response']['success'] == 42
		puts "Couldn't find a SteamID64 for user #{ARGV[0]}"
		exit
	end
	steamID = response['response']['steamid']
end

if ARGV[1] != nil
	filters = ARGV[1]
end

#URLs and searching
users_games = 'http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key='+key+'&steamid=' + steamID + '&include_appinfo=1&format=json'

# Cache, so we don't check games that are known to be in the filter (assuming they wont change)
multiplayer = []
File.open("games - #{ARGV[0]}.txt", 'a+').each_line { |line| multiplayer.push(line) }
multiplayer.map! { |x| x.strip }

# Create out agent (browser)
agent = Mechanize.new

# Get the game list
response = JSON.parse(open(users_games).read)
games = response['response']['games']

games.each do |game|
	id = game['appid']
	name = game['name']
	
	# Only do unknown games
	if !multiplayer.include? name
		puts "Parseing " + name
	
		page = agent.get(store_page + game_page + id.to_s)

		# If the game requires an age check
		if page.uri.to_s.include? "agecheck"
			age_form = page.forms[1]		# Need to find a better way than this...
	
			age_form.ageDay = '24'
			age_form.ageMonth = 'August'
			age_form.ageYear = '1993'
	
			agent.submit age_form
			page = agent.current_page
		end

		if page.body.match(filters)
			multiplayer.push(name)
		end
	end
end

multiplayer.sort!
File.open("games - #{ARGV[0]}.txt", 'w') { |file| multiplayer.each {|game|file.puts(game)} }