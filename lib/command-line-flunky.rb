
if RUBY_VERSION.to_f < 1.9
	raise "Ruby version 1.9 or greater required (current version is #{RUBY_VERSION})"
end
module CommandLineFlunky
# 	$stderr.puts STARTUP_MESSAGE unless $has_put_startup_message

	COMMAND_FOLDER = Dir.pwd
        SCRIPT_FOLDER = File.dirname(File.expand_path(SCRIPT_FILE)) #i.e. where the script using command line flunky is
	SYS = (ENV['COMMAND_LINE_FLUNKY_SYSTEM'] or "genericlinux")
	@@sys = SYS
	def gets #No reading from the command line thank you very much!
		$stdin.gets
	end
	def self.gets
		$stdin.gets
	end
end
CommandLineFlunky::GLOBAL_BINDING = binding

# $stderr.print 'Loading libraries...' unless $has_put_startup_message
require 'getoptlong'
require 'rubyhacks'
# $stderr.puts unless $has_put_startup_message
$has_put_startup_message = true

# Log.log_file = nil


module CommandLineFlunky
# 	CLF = COMMAND_LINE_FLAGS = []
	CLF = COMMAND_LINE_FLAGS = COMMAND_LINE_FLAGS_WITH_HELP.map{|arr| arr.slice(0..2)}
	LONG_COMMAND_LINE_FLAGS = LONG_COMMAND_LINE_OPTIONS.map{|arr| [arr[0], arr[2]]}
	#
		# This lists all the commands available on the command line. The first two items in each array indicate the long and short form of the command, and the third indicates the number of arguments the command takes. They are all implemented as Code Runner class methods (the method is named after the long form). The short form of the command is available as a global method in Code Runner interactive mode.

	COMMANDS_WITH_HELP.push ['manual', 'man', 0, 'Print out command line manual', [], []]
	COMMANDS_WITH_HELP.push ["interactive_mode", "im", 0, 'Launch an interactive terminal. Any command line flags specified set the defaults for the session. Commands must be given in the short form, e.g. man. Options are given as a ruby hash.', [], []]	
 

  COMMANDS = COMMANDS_WITH_HELP.map{|arr| arr.slice(0..2)}

	
	# A lookup hash which gives the appropriate short command option (copt) key for a given long command flag
	
	CLF_TO_SHORT_COPTS = COMMAND_LINE_FLAGS.inject({}) do |hash, arr|
		unless arr.size == 2 
			long, short, req = arr 
			letter = short[1,1]
			hash[long] = letter.to_sym 
		end
		hash
	end 

	CLF_TO_LONG = LONG_COMMAND_LINE_OPTIONS.inject({}) do |hash, (long, short, req, help)|
		option = long[2, long.size].gsub(/\-/, '_').to_sym
		hash[long] = option
		hash
	end
	
	# specifying flag sets a bool to be true

# 	CLF_BOOLS = [:H, :U, :u, :A, :a, :T, :N, :q, :z, :d] 
# 		CLF_BOOLS = [:s, :r, :D, :H, :U, :u, :L, :l, :A, :a, :T, :N,:V, :q, :z, :d] # 

           
	# a look up hash that converts the long form of the command options to the short form (NB command options e.g. use_large_cache have a different form from command line flags e.g. --use-large-cache)
	
	LONG_TO_SHORT = COMMAND_LINE_FLAGS.inject({}) do |hash, arr|
		unless arr.size == 2 #No short version
			long, short, req = arr 
			letter = short[1,1]
			hash[long[2, long.size].gsub(/\-/, '_').to_sym] = letter.to_sym 
		end
		hash
	end
	
	#Converts a command line flag opt with value arg to a command option which is stored in copts

	def self.process_command_line_option(opt, arg, copts)
			if CLF_BOOLS.include? CLF_TO_SHORT_COPTS[opt]
				copts[CLF_TO_SHORT_COPTS[opt]] = true
			elsif CLF_INVERSE_BOOLS.include? CLF_TO_SHORT_COPTS[opt]
				copts[CLF_TO_SHORT_COPTS[opt]] = false
			elsif CLF_TO_SHORT_COPTS[opt] # Applies to most options
				copts[CLF_TO_SHORT_COPTS[opt]] = arg
			elsif CLF_BOOLS.include? CLF_TO_LONG[opt]
				copts[CLF_TO_LONG[opt]] = true
			elsif CLF_INVERSE_BOOLS.include? CLF_TO_LONG[opt]
				copts[CLF_TO_LONG[opt]] = false
			elsif CLF_TO_LONG[opt]
				copts[CLF_TO_LONG[opt]] = arg
			else 
				raise "Unknown command line argument: #{opt}"
			end	
		copts
	end

	# Default command options; they are usually determined by the command line flags, but can be set independently
	
	DEFAULT_COMMAND_OPTIONS = {} 

	def self.set_default_command_options_from_command_line
		opts = GetoptLong.new(*(COMMAND_LINE_FLAGS + LONG_COMMAND_LINE_FLAGS))
		opts.each do |opt, arg|
		      process_command_line_option(opt, arg, DEFAULT_COMMAND_OPTIONS)
		end
	end
end

module CommandLineFlunky
	def self.read_default_command_options(copts)
		DEFAULT_COMMAND_OPTIONS.each do |key, value|
			copts[key] ||= value
		end
	end


	INTERACTIVE_METHODS = <<EOF
CommandLineFlunky::COMMANDS.each do |command|
	eval("def #\{command[1]}(*args) 
		  CommandLineFlunky.send(#\{command[0].to_sym.inspect}, *args)
	      end")

EOF

	def self.interactive_mode(copts={})
# 		process_command_options(copts)
	  			unless false and FileTest.exist? (ENV['HOME'] + "/.#{PROJECT_NAME}_interactive_options.rb")
				File.open(ENV['HOME'] + "/.#{PROJECT_NAME}_interactive_options.rb", 'w') do |file|
					file.puts <<EOF
	$has_put_startup_message = true #please leave!
	$command_line_flunky_interactive_mode = true #please leave!
	require 'yaml'

	def reset
	  Dispatcher.reset_application!
	end
	  
	IRB.conf[:AUTO_INDENT] = true
	IRB.conf[:USE_READLINE] = true
	IRB.conf[:LOAD_MODULES] = []  unless IRB.conf.key?(:LOAD_MODULES)
	unless IRB.conf[:LOAD_MODULES].include?('irb/completion')
	  IRB.conf[:LOAD_MODULES] << 'irb/completion'
	end      

				
	require 'irb/completion'
	require 'irb/ext/save-history'
	IRB.conf[:PROMPT_MODE] = :SIMPLE
	IRB.conf[:SAVE_HISTORY] = 100
	IRB.conf[:HISTORY_FILE] = "\#\{ENV['HOME']}/.#{PROJECT_NAME}_irb_save_history"
	IRB.conf[:INSPECT_MODE] = false


EOF
				end
			end
			File.open(".int.tmp.rb", 'w')do |file|
				file.puts "#{copts.inspect}.each do |key, val|
					CommandLineFlunky::DEFAULT_COMMAND_OPTIONS[key] = val
				end"
				file.puts CommandLineFlunky::INTERACTIVE_METHODS
			end
			exec %[#{Config::CONFIG['bindir']}/irb#{Config::CONFIG['ruby_install_name'].sub(/ruby/, '')} -f -I '#{SCRIPT_FOLDER}' -I '#{File.dirname(__FILE__)}' -I '#{Dir.pwd}' -I '#{ENV['HOME']}' -r '.#{PROJECT_NAME}_interactive_options' -r '#{File.basename(SCRIPT_FILE)}'  -r .int.tmp ]
	end

	
	def self.run_script
		setup(DEFAULT_COMMAND_OPTIONS)
		return if $command_line_flunky_interactive_mode
		command = COMMANDS.find{|com| com.slice(0..1).include? ARGV[0]}
		raise "Command #{ARGV[0]} not found" unless command
		send(command[0].to_sym, *ARGV.slice(1...(1+command[2])), DEFAULT_COMMAND_OPTIONS)
	end
  def self.manual(copts={})
			help = <<EOF

			
#{MANUAL_HEADER}

COMMANDS

   Either the long or the short form of the command may be used, except in interactive mode, where only short form can be used.

    Long(Short)  <Arguments>  (Meaningful Options)  
    ---------------------------------------------

#{(COMMANDS_WITH_HELP.sort_by{|arr| arr[0]}.map do |arr| 
	   sprintf(" %s %s(%s) \n\t%s", "#{arr[0]}(#{arr[1]})",    arr[4].map{|arg| "<#{arg}>"}.join(' ').sub(/(.)$/, '\1 '), arr[5].map{|op| op.to_s}.join(','), arr[3], )
    end).join("\n\n")}

OPTIONS

#{((COMMAND_LINE_FLAGS_WITH_HELP + LONG_COMMAND_LINE_OPTIONS).map do |arr|
   sprintf("%-15s %-2s\n\t%s", arr[0], arr[1], arr[3])
  end).join("\n\n")
		}

EOF
		 #help.gsub(/(.{63,73} |.{73})/){"#$1\n\t"}.paginate
		 help.paginate
		end
end

CommandLineFlunky.set_default_command_options_from_command_line

####################
# CommandLineFlunky.run_script unles
###################


