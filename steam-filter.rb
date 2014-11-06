#!/usr/bin/ruby
require 'json'
require 'open-uri'
require 'mechanize'
require 'optparse'

# Constants
key = '9476194843EE253F44A413B033CCB0B1'
vanityAPI1 = 'http://api.steampowered.com/ISteamUser/ResolveVanityURL/v0001/?key='
vanityAPI2 = '&vanityurl='
gameAPI1 = 'http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key='+key+'&steamid='
gameAPI2 = '&include_appinfo=1&format=json'
store_page = 'http://store.steampowered.com'
game_page = '/app/'
filters = '(?<!Local )(Multi-player|Co-op)'	#regex(default)
cachename = 'cache'

games = Hash.new

options = {:output => 'games.txt', :filter => filters}

# Parse the options
parser = OptionParser.new do|opts|
	opts.banner = "Usage: steam-filter.rb [steam ids] [options]\n" +
		"Need SteamID64 or vanity steam name\n" +
		"SteamID64 or Vanity URL can be found on your profile at\n" +
		"http://steamcommunity.com/id/#################\n" +
		"where the ##### would be it"

	opts.on('-o', '--output filename', 'Output filename') do |output|
		options[:output] = output;
	end

	opts.on('-f', '--filter Filter', 'Regular expression to filter games by') do |f|
		options[:filter] = f;
	end

	opts.on('-h', '--help', 'Displays Help') do
		puts opts
		exit
	end
end

parser.parse!

if ARGV.length < 1
	puts parser.banner

# Read in the steam id's
else
	ARGV.each do |id|
		# Try to resolve vanity url
		if id.match('[a-zA-Z]')
			resolve_vanity = vanityAPI1 + key + vanityAPI2 + id
			response = JSON.parse(open(resolve_vanity).read)
			if response['response']['success'] == 42
				puts "Couldn't find a SteamID64 for user #{id}"
				exit
			end
			id = response['response']['steamid']
		end
		games[id] = []
	end
end

# Load the cache (or create it)
cache = []
File.open(cachename, 'a+').each_line { |line| cache.push(line) }
cache.map! { |x| x.strip }

# Create out agent (browser)
agent = Mechanize.new

# Loop through each user, find games, check cache or goto steam
games.each do |key, value|
	#Find the user's game list
	users_games = gameAPI1 + key + gameAPI2
	response = JSON.parse(open(users_games).read)
	users_games = response['response']['games']

	users_games.each do |game|
		id = game['appid']
		name = game['name']
	
		# Only do unknown games
		if !cache.any? { |game| game.include? name }
			puts "Parsing " + name
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
				cache.push(name + '`yes')
				games[key].push(name)
			else
				cache.push(name + '`no')
			end
		else
			tmp = cache.select { |game| game.include? name }
			tmp = tmp[0].split('`')
			if (tmp[0] == name and tmp[1] == 'yes')
				games[key].push(name)
			end
		end
	end
end

# if there are more than 1 id's find common games
if ARGV.length > 1
	list = []
	games.each do |key, value|
		value.each do |game|
			list.push(game)
		end
	end

	list.sort!
	File.open(options[:output], 'w') { |file| file.puts(list.group_by { |e| e }.select { |k, v| v.size > 1 }.map(&:first)) }

# else just write out the users id
else
	File.open(options[:output], 'w') { |file| file.puts(games.first) }
end

# save the cache
cache.sort!
File.open(cachename, 'w') { |file| cache.each {|game|file.puts(game)} }