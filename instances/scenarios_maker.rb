#!/usr/bin/env ruby

# Authors: Alice Raffaele, Riccardo Orizio
# Date: 15 October 2015
# A program that generates a given number of scenarios, starting from a zonegrid.

require_relative "filenames.rb"
require_relative "RandomGaussian.rb"

# Constants
ZONE_WIDTH = 7
ZONE_HEIGHT = 7
CLIENTS_MAX = 100
CLIENTS_MIN = 30
SD = 0.1

# We have two possibles arguments:
# ARGV[0] = number of scenarios to create
# ARGV[1] = zonegrid filename
# If no zonegrid filename is given, then we will use the most recent one.
scenarios = ( ARGV[ 0 ] || 4 ).to_i
zonegrid = ARGV[ 1 ]
if zonegrid == nil then
	inst_dir = Dir[ DIR_INSTANCES + "/*" + FILE_EXT_INSTANCE ].sort

	zonegrid = inst_dir.last
end

Zone = Struct.new( :zone_number, :clients, :demand, :service_time )
zones = Array.new
ClientRequest = Struct.new( :zone_number,
							:x,
							:y,
							:demand,
							:service_time,
							:date,
							:cost )

# Reading all the informations from the file with a REGEX ^_^
content = File.open( zonegrid ).read.scan( /(\d+(\.\d+)?)/ ).collect{ |elem| elem[0] }
for i in (0..content.length-1).step(4) do
	zones.push( Zone.new(	content[i].to_i,
							content[i+1].to_i,
							content[i+2].to_f,
							content[i+3].to_f ) )
end

# Calculating the number of clients and the columns of the grid
total_clients = zones.collect{ |elem| elem[:clients] }.inject{ |sum, x| sum + x }
cols = File.open( zonegrid, &:readline ).scan( /\)/ ).length

#	# Reading the zone file
#	file_read = File.open( zonegrid )
#	file_read.each do |line|
#		content = line.chomp.split( "\t" )
#		cols = content.length
#	
#		content.each{	|zone|
#			a = zone[1, zone.length-2].split( "," )
#			zones.push( Zone.new(	a[0].to_i,
#									a[1].to_i,
#									a[2].to_f, 
#									a[3].to_f ) )
#			total_clients += a[1].to_i
#		}
#	end
#	file_read.close
#	

#	prog_clients = zones.map{ |sum, x| sum += x[:clients] }
#	puts prog_clients

# Creating shits
dir_name = DIR_SCENARIOS + "/Scenario_" + 
		   zonegrid.gsub( DIR_INSTANCES + "/", "" ).gsub( FILE_EXT_INSTANCE, "" )
Dir.mkdir( dir_name ) unless File.exists?( dir_name )

scenario = Array.new
for k in (1..scenarios)
	scenario_clients = rand( CLIENTS_MIN..CLIENTS_MAX )
	scenario.clear
	prog_clients = Array.new( zones.length )
	prog_clients[0] = zones[0][:clients]
	for i in 1..prog_clients.length-1 do
		prog_clients[i] = prog_clients[i-1] + zones[i][:clients]
	end

	for i in 1..scenario_clients do
		client_zone = rand( 1..total_clients )
		for j in 0..prog_clients.length-1 do
			if client_zone < prog_clients[j] then
				break
			end
		end

		# We have the zone j, yeah
		scenario.push(
			ClientRequest.new(
				j+1,
				rand( 0..ZONE_WIDTH ) + (j%cols) * ZONE_WIDTH,
				rand( 0..ZONE_HEIGHT ) + (j/cols) * ZONE_HEIGHT,
				RandomGaussian.new( zones[j][:demand], SD ).rand,
				RandomGaussian.new( zones[j][:service_time], SD ).rand,
				Time.now, # TODO: JFC
				rand( 0..100 ) + 50 ) # TODO: JFC
		)
	end

	# TODO: Check name with JFC?
	file_write_name = dir_name + "/" + k.to_s + FILE_EXT_SCENARIO
	file_write = File.open( file_write_name, "w" )

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

puts "Fuck yeah! (◕‿◕✿)"
