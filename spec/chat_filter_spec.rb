require_relative 'spec_helper'
require 'redstone_bot/chat_filter'

ChatMessage = RedstoneBot::Packet::ChatMessage

class ChatMessage
  def player_chat(username, chat)
    @data = "<#{username}> #{chat}"
    @username = username
    @chat = chat
  end
end

def player_chat(username, chat)
  p = ChatMessage.allocate
  p.player_chat(username, chat)
  p
end

class TestChatter
  def initialize
    @listeners = []
  end
  
  def listen(&proc)
    @listeners << proc
  end
  
  def <<(packet)
    @listeners.each do |l|
      l.call packet
    end
  end
  
  def username
    "testbot"
  end
end

describe RedstoneBot::ChatFilter do
  before do
    @chatter = TestChatter.new
    @filter = RedstoneBot::ChatFilter.new(@chatter)
    @receiver = double("receiver")
    @filter.listen { |p| @receiver.packet p }
  end

  it "should pass all Packet::ChatMessages by default" do
    @receiver.should_receive :packet
    @chatter << player_chat("Elavid", "wazzup")
  end
  
  it "should reject objects other than Packet::ChatMessage" do
    @receiver.should_not_receive :packet
    @chatter << RedstoneBot::Packet::KeepAlive.new
  end
  
  context "when rejecting messages from self" do
    before do
      @filter.reject_from_self
    end
  
    it "rejects messages from self" do
      @receiver.should_not_receive :packet
      @chatter << player_chat(@chatter.username, "hey")
    end

    it "passes messages from others" do
      @receiver.should_receive :packet
      @chatter << player_chat("Elavid", "hey")
    end
  end
  
  context "when only listening to one user" do  
    before do
      @filter.only_from_user "Elavid"
    end
    
    it "rejects messages from others" do
      @receiver.should_not_receive :packet
      @chatter << player_chat("RyanTM", "stuff")
    end
    
    it "passes messages from that user" do    
      @receiver.should_receive :packet
      @chatter << player_chat("Elavid", "do something")
    end
        
    it "rejects non-player chats" do
      @receiver.should_not_receive :packet
      @chatter << ChatMessage.new("DavidBot joined the game.")
    end
  end
  
  context "when only passing player chats" do
    before do
      @filter.only_player_chats
    end
    
    it "rejects non-player chats" do
      @receiver.should_not_receive :packet
      @chatter << ChatMessage.new("DavidBot joined the game.")
    end
    
    it "passes player chats" do
      @receiver.should_receive :packet
      @chatter << player_chat("iprefermuffins", "stuff")
    end
  end
  
  context "when using aliases" do
    before do
      @filter.aliases "good" => "great", "cool" => "awesome"
    end
    
    it "changes player chats that match the alias" do
      @receiver.should_receive(:packet).with player_chat("Elavid", "great")
      @chatter << player_chat("Elavid", "good")
    end
  end
  
end