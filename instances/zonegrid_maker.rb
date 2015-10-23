#!/usr/bin/env ruby

# Authors: Alice Raffaele, Riccardo Orizio
# Date: 15 October 2015
# A program that generates the zone grid filling every one of them with:
# - number of clients that made a request
# - average demand per client
# - average service time per client

require_relative "constants.rb"

# Get dimensions m x n from command line
rows = ( ARGV[ 0 ] || 2 ).to_i
cols = ( ARGV[ 1 ] || 2 ).to_i

# Total zones
zone_number = rows * cols

# Creating the struct builder needed to create every zone
Zone = Struct.new( :clients, :demand, :service_time )
zones = Array.new

# Creating the zones
for i in 1..zone_number

	# Client generation
	if i <= HIGH_POP * zone_number then
		cli = rand( CLIENT_RANGE_HIGH[0]..CLIENT_RANGE_HIGH[1] )
	elsif ( i - HIGH_POP * zone_number ) <= LOW_POP * zone_number then
		cli = rand( CLIENT_RANGE_LOW[0]..CLIENT_RANGE_LOW[1] )
	else
		cli = rand( CLIENT_RANGE_NORMAL[0]..CLIENT_RANGE_NORMAL[1] )
	end

	zones.push( Zone.new( cli,
						  rand( ZONE_DEMAND_MIN..ZONE_DEMAND_MAX ),
						  rand( ZONE_SERVICE_TIME_MIN..ZONE_SERVICE_TIME_MAX ) )
			  )
end

# Distributing the zones
zones = zones.shuffle

# File handling
# Creating the file name with the current time plus its extension
file_name = DIR_INSTANCES + "/" + Time.now.strftime( "%Y-%m-%d_%H:%M:%S" ) + FILE_EXT_INSTANCE

file_temp = File.open( file_name, "w" )
# Keeping this for tests:
# file_temp = File.open( "1pappappero.instance", "w" )

# We suppose that every value could reach maximum a 3 digits integer part.
# We print every zone on the file
for j in 0..zone_number-1
	file_temp.printf( "(%3d, %3d, %3d, %3d)\t",
						j+1,
						zones[j][:clients],
						zones[j][:demand],
						zones[j][:service_time] )
	if (j+1) % cols == 0 then
		file_temp.printf( "\n" )
	end
end

file_temp.close

puts file_name + " created o(≧∇≦o)"
