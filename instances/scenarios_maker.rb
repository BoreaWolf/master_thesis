#!/usr/bin/env ruby

# Authors: Alice Raffaele, Riccardo Orizio
# Date: 15 October 2015
# A program that generates a given number of scenarios, starting from a zonegrid.

require_relative "filenames.rb"
require_relative "RandomGaussian.rb"

# Constants
DEFAULT_SCENARIOS = 4
ZONE_WIDTH = 10
ZONE_HEIGHT = 7
CLIENTS_MAX = 100
CLIENTS_MIN = 30
STD_DEV = 0.1

# Useful functions
# This function calculates the cumulative sum of an array
class Array
	def cumulative_sum
		sum = 0
		self.map{ |x| sum += x }
	end
end

# We have two possibles arguments:
# ARGV[0] = number of scenarios to create
# ARGV[1] = zonegrid filename
# If no zonegrid filename is given, then we will use the most recent one.
scenarios = ( ARGV[ 0 ] || DEFAULT_SCENARIOS ).to_i
# TODO: fix depending on the input that we give
zonegrid = ARGV[ 1 ]
if zonegrid == nil then
	zonegrid = Dir[ "#{DIR_INSTANCES}/*#{FILE_EXT_INSTANCE}" ].sort.last
end

# Creating the data structures needed: zone and client
Zone = Struct.new(	:zone_number,
					:clients,
					:demand,
					:service_time )

ClientRequest = Struct.new( :zone_number,
							:x,
							:y,
							:demand,
							:service_time,
							:date,
							:cost )

# Reading all the informations of the zones from the file with a REGEX ^_^
zones = Array.new
content = File.open( zonegrid ).read.scan( /(\d+(\.\d+)?)/ ).collect{ |elem| elem[0] }
(0..content.length-1).step(4).each do |i|
	zones.push( Zone.new(	content[i].to_i,
							content[i+1].to_i,
							content[i+2].to_f,
							content[i+3].to_f )
			  )
end

# Calculating the cumulative sum array, useful to find in which zone every
# random client will go
prog_clients = zones.collect{ |x| x[:clients] }.cumulative_sum 
# Counting the columns of the grid knowing that every zone is delimited with 
# brackets, so i just count them
cols = File.open( zonegrid, &:readline ).scan( /\)/ ).length

# Creating shits
# Creating the directory of the instance, if it doesn't exist already
# TODO: ask Alice if she wants something like Instance_# or # is enough
dir_name = "#{DIR_SCENARIOS}/" + 
		zonegrid.gsub( DIR_INSTANCES + "/", "" ).gsub( FILE_EXT_INSTANCE, "" )
Dir.mkdir( dir_name ) unless File.exists?( dir_name )

# Getting the number of scenarios already created
dirs = Dir.glob( dir_name + "/*" ).select{ |x| File.directory? x }
dirs = dirs.map{ |x| x.scan( /#{DIR_SINGLE_SCENARIO}(\d+)/ ) }.flatten.map( &:to_i ).sort
scenario_number =	if dirs.empty? then
						1
					else
						Integer( dirs.last ) + 1
					end

# Creating the folder for this session
dir_name += "/#{DIR_SINGLE_SCENARIO}#{scenario_number}"
Dir.mkdir( dir_name ) unless File.exists?( dir_name )

# Array that keeps the clients of the current scenario created.
# It will be cleared at every step
scenario = Array.new

(1..scenarios).each do |k|

	# Clearing the scenario
	scenario.clear

	# Creating the clients:
	scenario_clients = rand( CLIENTS_MIN..CLIENTS_MAX )
	# First I have to find in which area it belongs
	(1..scenario_clients).each do

		# Creating a client extracting a number between 1 and the total number
		# of clients, taken from the cumulative sum array
		client_zone = rand( 1..prog_clients.last )

		# Getting his zone
		zone_number = prog_clients.find_index{ |x| client_zone <= x }

		# We have the zone, yeah
		# Then we save him in the scenario with his other informations
		# randomly generated
		scenario.push(
			ClientRequest.new(
				zone_number+1,
				rand( 0..ZONE_WIDTH ) + (zone_number%cols) * ZONE_WIDTH,
				rand( 0..ZONE_HEIGHT ) + (zone_number/cols) * ZONE_HEIGHT,
				RandomGaussian.new( zones[zone_number][:demand], STD_DEV ).rand,
				RandomGaussian.new( zones[zone_number][:service_time], STD_DEV ).rand,
				Time.now, # TODO: JFC
				rand( 0..100 ) + 50 ) # TODO: JFC
		)
	end

	# TODO: Check name with JFC?
	file_write_name = "#{dir_name}/#{k}#{FILE_EXT_SCENARIO}"
	file_write = File.open( file_write_name, "w" )

	# TODO: Check if this is really needed
	# Preamble
	file_write.printf( "CLIENT\tZONE\tX\tY\tDEMAND\tS_TIME\tCOST\tDATE\n" )
	scenario.each_with_index{ |client, h|
		file_write.printf( "%3d\t%3d\t%3d\t%3d\t%7.3f\t%7.3f\t%3d\t%d\n",
				h+1,
				client[:zone_number],
				client[:x],
				client[:y],
				client[:demand],
				client[:service_time],
				client[:cost],
				client[:date].to_i )
	}

	file_write.close
end

printf( "Fuck yeah! Instance %s, Scenario %d, %d scenarios created. (◕‿◕✿)\n",
	   zonegrid.gsub( DIR_INSTANCES + "/", "" ).gsub( FILE_EXT_INSTANCE, "" ),
	   scenario_number,
	   scenarios )
