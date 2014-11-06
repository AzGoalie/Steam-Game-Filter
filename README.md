Steam-Game-Filter
=================

Filter a users games on steam. I created this to see all the multi-player games that I own and compare them with my friends.

On a side note, this doesn't include free-to-play games like Team Fortress 2 or DOTA 2. If you want to include those, add '&nclude_played_free_games=1' to the end of users_games

## Requirements
* Ruby Gems
* json
* mechanize

## Arguments
* List of SteamID64 or Vanity URL: This can be found on your steam community profile page such as http://steamcommunity.com/id/AzGoalie/ or http://steamcommunity.com/id/76561197997952617 where 'AzGoalie' or '76561197997952617' would be vanity or SteamID64

* Filter (optional -f): This is a regular express to filter the games by. Default is '(?<!Local )(Multi-player|Co-op)'. Only list games if they are multiplayer or co-op. But not Local.

* Output file name (optional -o) The name of the output file.
	
## Output
* Creates a file called "games.txt" or the supplied output name with the games listed in alphabetical order. If more than one steam id was given, then it will output the games that all steam id’s have in common.