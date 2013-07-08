require 'rubygems'
require 'xmpp4r'
require 'session'

USERNAME = 'user@gmail.com'
PASSWORD = 'userpassword'

PASSPHRASE = 'blimblom'
UNCRASHPHRASE = 'dingdong'

#~ if MASTER is empty, any user can connect
MASTER = 'master@gmail.com'

CHECK_INTERVAL = 60

@AUTHORIZED = false

$garbage_threads = []
$inital_threads = []

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

def kill_garbage_threads

	$garbage_threads.each do |th|
	
		if ( !$initial_threads.include? th )
			th.exit
		end
	end


end

def collect_garbage_threads
	
	Thread.list.each do |th|
	
		if ( !$initial_threads.include? th )
			$garbage_threads << th
		end
	end	

end

@jid = Jabber::JID::new(USERNAME)
@client = Jabber::Client.new(@jid)
@client.connect
@client.auth(PASSWORD)
@client.send(Jabber::Presence.new.set_type(:available))

@client.add_message_callback do |message|

	#~ check for master
	if (message.body.to_s != "" && !MASTER.empty? &&
							message.from.to_s.split("/")[0]  != MASTER)
		send_message(message.from, "Not my master.")
	else
	
		th = Thread.new{
		
			if  message.body.to_s != ""
			
				if message.body.to_s == UNCRASHPHRASE
				
					collect_garbage_threads
					@sh = Session::Bash.new
					send_message(message.from, ":| -> :) I'm ok with that!")
					
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


$initial_threads = Thread.list


loop do
	sleep CHECK_INTERVAL
	
	#~ print_all_threads
	#~ puts 
	kill_garbage_threads
	
	if !@client.is_connected?
		@client.connect
		@client.auth(PASSWORD)
		@client.send(Jabber::Presence.new.set_type(:available))				
		puts "conected again!"
	end
end
