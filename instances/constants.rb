#!/usr/bin/env ruby

# Authors: Alice Raffaele, Riccardo Orizio
# Date: 15 October 2015
# Parameters

# Constants for dealing with files created
FILE_EXT_INSTANCE = ".instance"
FILE_EXT_SET = ".set"
DIR_INSTANCES = "./instances"
DIR_SCENARIOS = "./scenarios"

# Constants used in zonegrid_maker
HIGH_POP = 0.25
LOW_POP = 0.10
CLIENT_RANGE_HIGH = [ 70, 100 ]
CLIENT_RANGE_NORMAL = [ 10, 70 ]
CLIENT_RANGE_LOW = [ 1, 10 ]
ZONE_DEMAND_MIN = 10
ZONE_DEMAND_MAX = 120
ZONE_SERVICE_TIME_MIN = 30
ZONE_SERVICE_TIME_MAX = 300

# Constants used in scenarios_maker
DEFAULT_SCENARIOS = 4
ZONE_WIDTH = 1000
ZONE_HEIGHT = 700

CLIENTS_AVERAGE = 100
CLIENTS_STD_DEV = 15

DEMAND_STD_DEV = 20
SERVICE_STD_DEV = 20

VEHICLE_CAPACITY = ZONE_DEMAND_MAX * 5
SCENARIO_DEMAND_MIN = 1
SCENARIO_SERVICE_TIME_MIN = 10
