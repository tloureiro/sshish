require 'rubygems'
require 'xmpp4r'
require 'session'

class Sshish

	USERNAME = 'user@gmail.com'
	PASSWORD = 'userpassword'

	PASSPHRASE = 'blimblom'
	UNCRASHPHRASE = 'dingdong'

	#~ if MASTER is empty, any user can connect
	MASTER = 'master@gmail.com'

	CHECK_INTERVAL = 60

	@AUTHORIZED = false

	def send_message(client, msg)

		msg = Jabber::Message.new(client, msg)
		msg.type = :chat
		@client.send(msg)

	end

	def print_all_threads

		puts Thread.list.size.to_s + " threads"

		Thread.list.each do |th|
			
			puts th.inspect
			
		end
		
	end

	def init_client
		@jid = Jabber::JID::new(USERNAME)
		@client = Jabber::Client.new(@jid)
		@client.connect
		@client.auth(PASSWORD)
		@client.send(Jabber::Presence.new.set_type(:available))
	end
	
	def run

		init_client

		@client.add_message_callback do |message|

			#~ check for master
			if (message.body.to_s != "" && !MASTER.empty? &&
									message.from.to_s.split("/")[0]  != MASTER)
				send_message(message.from, "Not my master.")
			else
			
				th = Thread.new{
				
					if  message.body.to_s != ""
					
						if message.body.to_s == UNCRASHPHRASE
						
							send_message(message.from, ":| -> :) I'm ok with that! I'll be back soon")
							@client.disconnect
							raise "crashed!"
							
						elsif message.body.to_s == PASSPHRASE
							
							if !@AUTHORIZED
								@AUTHORIZED = true
								if @sh == nil
									@sh = Session::Bash.new
								end
								send_message(message.from, ":)")
							else
								@AUTHORIZED = false
								send_message(message.from, ":(")
							end
							
						elsif @AUTHORIZED
							
							stdout, stderr = @sh.execute(message.body)
							
							send_message(message.from, "\n" + stdout.chomp) unless stdout.empty?
							send_message(message.from, "\n" + stderr.chomp) unless stderr.empty?
							send_message(message.from, @sh.execute('pwd')[0].chomp + "$")
							
						else
							send_message(message.from, "hum.... na")
						end
					end 
				
				}
				
			end
		end

		loop do
			sleep CHECK_INTERVAL
			
			print_all_threads
			
			if !@client.is_connected?
				raise "lost connection!"
			end
		end
		
	end
	
	def close
		@client.close
	end
	
	def self.cleanThreads
	
		Thread.list.each do |th|
			
			if th != Thread.main
				th.exit
			end
		end
	end
	
	
end

Thread.abort_on_exception=true
begin
	s = Sshish.new
	s.run
rescue
	puts "exception"
	s.close
	sleep 10
	Sshish::cleanThreads
	sleep 10
	retry
end
