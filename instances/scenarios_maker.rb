#!/usr/bin/env ruby

# Authors: Alice Raffaele, Riccardo Orizio
# Date: 15 October 2015
# A program that generates a given number of scenarios, starting from a zonegrid.

require_relative "filenames.rb"
require_relative "NormalDistribution.rb"

# Constants
DEFAULT_SCENARIOS = 4
ZONE_WIDTH = 1000
ZONE_HEIGHT = 700

CLIENTS_AVERAGE = 100
CLIENTS_STD_DEV = 15

DEMAND_STD_DEV = 20
SERVICE_STD_DEV = 20

VEHICLE_CAPACITY = 80
DEMAND_MIN = 1
SERVICE_TIME_MIN = 10

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
# As second argument we pretend the path to the grid file, if the path is
# uncorrect there might be some problems :)
zonegrid = ARGV[ 1 ]
if zonegrid == nil then
	zonegrid = Dir[ "#{DIR_INSTANCES}/*#{FILE_EXT_INSTANCE}" ].sort.last
else
	# Fixing one problem with the path, if "./" is missing at the beginning
	# of the name file we put it.
	# Still not consistent at all, the better way could be to find the shortest
	# path to that file with some ruby functions knowing the name file.
	# But given the fact that I will use this script there should be no such problems.
	zonegrid = "./" + zonegrid unless zonegrid.include? "./"
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
							:service_time)

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
dir_name = "#{DIR_SCENARIOS}/" +
		zonegrid.gsub( DIR_INSTANCES + "/", "" ).gsub( FILE_EXT_INSTANCE, "" )
Dir.mkdir( dir_name ) unless File.exists?( dir_name )

# Getting the number of set of scenarios already created
sets = Dir.glob( dir_name + "/*" ).select{ |x| File.file? x }
sets = sets.map{ |x| x.scan( /(\d+)#{FILE_EXT_SET}/ ) }.flatten.map( &:to_i ).sort
set_number =	if sets.empty? then
						1
					else
						Integer( sets.last ) + 1
					end

# Creating the file for the new set of scenarios
file_write_name = dir_name + "/#{set_number}#{FILE_EXT_SET}"
file_write = File.open( file_write_name, "w" )

file_write.printf("# SCENARIOS = %d\nVEHICLE CAPACITY = %d\n", scenarios, VEHICLE_CAPACITY)
file_write.printf("DEPOT COORDINATES (X,Y) = (%d, %d)\n", rand( 0..cols*ZONE_WIDTH ), rand( 0..(zones.length/cols)*ZONE_HEIGHT ))
file_write.printf("# ZONES = %d\n", zones.length)


# Array that keeps scenarios and their probabilities to happen
scenarios_set = Array.new

(1..scenarios).each do |k|

	# Array that keeps the clients of the current scenario created.
	# It will be created new at every step
	scenario = Array.new
	# Creating the clients:
	scenario_clients = Distribution::Normal.rng( CLIENTS_AVERAGE, CLIENTS_STD_DEV ).to_i
	# First I have to find in which area every client belongs
	(1..scenario_clients).each do

		# Creating a client extracting a number between 1 and the total number
		# of clients, taken from the cumulative sum array
		client_zone = rand( 1..prog_clients.last )

		# Getting his zone
		zone_number = prog_clients.find_index{ |x| client_zone <= x }

		# We have the zone, yeah
		# Then we save him in the scenario with his other informations
		# randomly generated

		# Protecting ourselves from negative number.
		# These are possible given the probability distribution used and the
		# low mean associated to them.
		demand = Distribution::Normal.rng( zones[zone_number][:demand], DEMAND_STD_DEV ).to_i
		demand = DEMAND_MIN unless demand >= DEMAND_MIN
		service_time = Distribution::Normal.rng( zones[zone_number][:service_time], SERVICE_STD_DEV ).to_i
		service_time = SERVICE_TIME_MIN unless service_time >= SERVICE_TIME_MIN

		scenario.push(
			ClientRequest.new(
				zone_number+1,
				rand( 0..ZONE_WIDTH ) + (zone_number%cols) * ZONE_WIDTH,
				rand( 0..ZONE_HEIGHT ) + (zone_number/cols) * ZONE_HEIGHT,
				demand,
				service_time ) )
				
	end
	# Computing the pdf probability of each scenario
	scenario_prob = Distribution::Normal.pdf((scenario_clients-CLIENTS_AVERAGE).to_f/CLIENTS_STD_DEV)/CLIENTS_STD_DEV
	scenarios_set.push([scenario, scenario_prob])
end

# Normalizing each scenario probability computing the weighted average
sum_prob = scenarios_set.collect{|x| x[1]}.reduce(:+)

# Printing all information on file
(0..scenarios_set.length-1).each do |k|

	file_write.printf( "\nSCENARIO #%d\t# CLIENTS = %d\tPROBABILITY = %5.3f\n", k+1, scenarios_set[k][0].length, scenarios_set[k][1]/sum_prob )
	file_write.printf( "CLIENT\tZONE\tX\tY\tDEMAND\tS_TIME\n" )
	scenarios_set[k][0].each_with_index{ |client, h|
		file_write.printf( "%3d\t%3d\t%5d\t%5d\t%3d\t%3d\n",
				h+1,
				client[:zone_number],
				client[:x],
				client[:y],
				client[:demand],
				client[:service_time])
	}
	file_write.printf("\n")
end

file_write.close

printf( "Fuck yeah! Instance %s, %d scenarios created. (◕‿◕✿)\n",
	   zonegrid.gsub( DIR_INSTANCES + "/", "" ).gsub( FILE_EXT_INSTANCE, "" ),
	   scenarios )
