# This is a complete example of how to use command-line-flunky
# which also used for testing

module CommandLineFlunky
	
	STARTUP_MESSAGE = "\n------Test Utility------"

	MANUAL_HEADER = <<EOF
			
-------------Test Utility Manual---------------

  Written by Edmund Highcock (2014)

NAME

  test_utility


SYNOPSIS
	
  test_utility <command> [arguments] [options]


DESCRIPTION
	
  This test utility is written to test the command-line-flunky gem.
  
EXAMPLES

   $ test_utility hello_world
   
   $ test_utility test_bool -b
   
EOF
	
	COMMANDS = [
		['hello_world', 'hello', 0, [], 'Say hello to the world'],
		['test_bool', 'tbool', 0, [], 'Test whether the boolean flag works'],

	]
	
	COMMAND_LINE_FLAGS_WITH_HELP = [
		['--boolean', '-b', GetoptLong::REQUIRED_ARGUMENT, 'A boolean argument'],		

		]
		
	# specifying flag sets a bool to be true

	CLF_BOOLS = [:b]
	
	PROJECT_NAME = 'command_line_flunky_test_utility'
		
	def self.method_missing(method, *args)
# 		p method, args
		CommandLineFlunkyTestUtility.send(method, *args)
	end
	
	def self.setup(copts)
		CommandLineFlunkyTestUtility.setup(copts)
	end
	
	SCRIPT_FILE = __FILE__
end

class CommandLineFlunkyTestUtility
	class << self
		def hello_world(copts)
			puts "Hello World"
		end
		def test_bool(copts)
			puts "Bool is #{copts[:b]}"
		end
	end
end
