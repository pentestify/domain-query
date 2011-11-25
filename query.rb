#!/usr/bin/ruby

require 'whois'

class StringMangle

	def initialize
		@character_string= "a,b,c,d,e,f,g,h,i,j,k,l,m,o,p,q,r,s,t,u,v,w,x,y,z"
		@character_list = @character_string.split(",")
	end

	def get_random_string(length=5)
		temp_string = ""
		length.times do |t|
			temp_string << @character_list[rand(@character_list.length)]	
		end
	temp_string
	end
end

class WordlistManager
	
	def initialize
		@current_directory = File.dirname(__FILE__)
		@wordlist_directory = "#{@current_directory}/wordlists"
	end
	
	def open_wordlist(file)
		File.open(file, :encoding => "ASCII").read.split("\n")
	end
	
	def get_wordlists_by_pattern(pattern)
		list = []
		Dir.glob("#{@wordlist_directory}/*#{pattern}*").each do |file|
			unless File.directory?(file)

				puts "DEBUG: Adding #{file} to the list"
				
				# Open each file in turn
				wordlist = File.open(file).read
				
				# Handle invalid utf-8
				#ic = ::Iconv.new('UTF-8//IGNORE', 'UTF-8')
				#valid_wordlist = ic.iconv(wordlist + ' ')[0..-2]

				# Add each word to an array 
				wordlist.split("\n").each do |word|
=begin
					begin 
						word = word.encode('utf-8', 'ascii')
					rescue
						# Probably going to result in garbage
						word = word.force_encoding('ascii')
					end
=end				
					list << word
				end
			end
		end
	list
	end
end

class Logger

	def initialize()
		@current_directory = File.dirname(__FILE__)
		@log_directory = "#{@current_directory}/log"
		@log = File.open("#{@log_directory}/finished_words.txt", "w+")
		@print_good_to_screen = true
		@print_bad_to_screen = true
	end

	def log_good(string)
		string = "[+] #{string}"
		puts string if @print_good_to_screen
		@log.write(string << "\n")
	end
		
	def log_bad(string)
		string = "[-] #{string}"
		puts string if @print_bad_to_screen
		@log.write(string << "\n")
	end

end

pattern = ARGV[0]

puts "DEBUG: Testing wordlists with pattern #{pattern}"

whois_client = Whois::Client.new
logger = Logger.new
manager = WordlistManager.new
wordlist = manager.get_wordlists_by_pattern(pattern)

puts "DEBUG: Testing #{wordlist.count} words."

wordlist.each do |word|
	["com"].each do |ending|
		
		# cleanup & construction
		word.gsub!("\r","")
		word.gsub!(" ","")
		domain_string = "#{word}.#{ending}"
		
		begin
			# do the actual query		
			answer = whois_client.query(domain_string)
			
			# do the right thing
			if answer.available?
				logger.log_good(domain_string)
			else
				logger.log_bad(domain_string)
			end
			
		rescue Timeout::Error => e
			puts "Error: Timed out while querying the domain (#{domain_string})."

			## Requeue
			wordlist << word

		rescue Errno::ECONNREFUSED => e
			puts "Error: Connection refused while querying the domain (#{domain_string})"

			## Requeue
			wordlist << word

		rescue Whois::ConnectionError => e
			puts "Error: Connection refused while querying the domain (#{domain_string})"

			## Requeue
			wordlist << word

		end
	end
end

