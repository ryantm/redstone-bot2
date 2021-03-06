require 'forwardable'
require 'fiber'

require "redstone_bot/bot"
require "redstone_bot/chat_evaluator"
require "redstone_bot/pathfinder"
require "redstone_bot/body_movers"
require "redstone_bot/chat_filter"
require "redstone_bot/chat_mover"
require "redstone_bot/profiler"
require "redstone_bot/packet_printer"

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
    extend Forwardable
    include BodyMovers
    include Profiler
    
    Aliases = {
      "meq" => "m -2570 -2069",
      "mpl" => "m 99.5 225.5",
      "mkn" => "m -211 785",
      }
    
    PrintPacketClasses = [
      Packet::ChatMessage,
    ]
    
    attr_reader :body, :chunk_tracker
    
    def setup
      standard_setup
      
      @inventory.debug = true
      
      @chat_filter = ChatFilter.new(@client)
      @chat_filter.only_player_chats
      @chat_filter.reject_from_self      
      @chat_filter.aliases Aliases
      @chat_filter.only_from_user(MASTER) if defined?(MASTER)
      
      @ce = ChatEvaluator.new(@chat_filter, self)
      @ce.safe_level = 2
      @ce.timeout = 2
      @cm = ChatMover.new(@chat_filter, self, @entity_tracker)
      
      @body.on_position_update do
        if !@body.current_fiber
          fall_update
          @body.look_at @entity_tracker.closest_entity
        end
      end
      
      @packet_printer = PacketPrinter.new(@client, PrintPacketClasses)
      
      @client.listen do |p|
        case p
        when Packet::Disconnect
          puts "Position = #{@body.position}"
          exit 2
        end
      end 
      
      @client.listen do |p|
        next unless p.is_a?(Packet::ChatMessage) && p.player_chat?
        
        case p.chat
        when /drop[ ]*(.*)/
          name = $1
          @inventory.drop 
        when /dump all[ ]*(.*)/
          name = $1
          type = ItemType.from(name)
          if type
            @inventory.dump_all(type)
          else
            chat "da understood #{name}"
          end  
        when /dump[ ]*(.*)/
          name = $1
          type = ItemType.from(name)
          if type
            @inventory.dump(type)
          else
            chat "da understood #{name}"
          end
        when /hold (.+)/  
          name = $1
          type = ItemType.from(name)
          if type
            @inventory.hold(type)
          else
            chat "da understood #{name}"
          end
        when /craft/
          #@client.send_packet Packet::PlayerBlockPlacement.new([-100,67,804],0,@inventory.slots[36])
          #@client.send_packet Packet::ClickWindow.new(1,
          #def initialize(window_id, slot_id, right_click, action_number, shift, clicked_item)
          
          
          
          
          
        when /i/
          puts "== INVENTORY =="
          @inventory.slots.each_with_index do |slot, slot_id|
            next unless slot
            puts "#{slot_id}: #{slot}"            
          end
          puts "===="
        when /ground report/
          coords = @body.position.dup
          coords.y = find_nearby_ground-1
          columns = [[coords.x+0.3,coords.y,coords.z+0.3],
                     [coords.x-0.3,coords.y,coords.z+0.3],
                     [coords.x+0.3,coords.y,coords.z-0.3],                     
                     [coords.x-0.3,coords.y,coords.z-0.3]]
          chat "The grnd is #{columns.collect { |col| @chunk_tracker.block_type(col)}}"
        when /how much (.+)/
          # TODO: perhaps cache these results using a SimpleCache
          name = $1
          item_type = ItemType.from name
          if item_type.nil? && name != "nil" && name != "unloaded"
            chat "dunno what #{name} is"
            next
          end          
          
          chat "counting #{item_type && item_type.inspect || 'unloaded blocks'}..."
          result = @chunk_tracker.loaded_chunks.inject(0) do |sum, chunk|
            sum + chunk.count_block_type(item_type)
          end
          chat "there are #{result}"
        end
      end
      
    end
    
    def miracle_jump(x,z)
      @start_fly = Time.now
      super
      chat "I be at #{@body.position} after #{Time.now - @start_fly} seconds."
    end
    
    def tmphax_find_path
      @pathfinder.start = @body.position.to_a.collect(&:to_i)
      @pathfinder.bounds = [94..122, 69..78, 233..261]
      @pathfinder.goal = [104, 73, 240]
      puts "Finding path from #{@pathfinder.start} to #{@pathfinder.goal}..."
      result = @pathfinder.find_path
      puts "t: " + result.inspect
    end
    
    def standing_on
      coord_array = (@body.position - Coords::Y*0.5).to_a.collect &:floor
      "#{block_type coord_array} #{@body.position.y}->#{coord_array[1]}"
    end
    
    def jump_to_height(*args)
      result = super
      chat "I bumped my head!" if !result
      result
    end

    protected
    def_delegators :@chunk_tracker, :block_type, :block_metadata
    def_delegators :@client, :chat
    def_delegators :@inventory, :hold
  end
end