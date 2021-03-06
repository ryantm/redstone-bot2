# Module with some functions to help your bot move its body.
# The blocking functions should only be called from inside a Fiber.
# Can be included into your bot as long as you have these things:
# A 'body' method that returns the RedstoneBot::Body.
# A 'chunk_tracker' method that returns a RedstoneBot::ChunkTracker.
#
# NOTE: David is not totally convinced that this should be a module instead
# of a class.  Any class that calls these body-moving functions should be
# built with the assumption that it could be either.
module RedstoneBot
  module BodyMovers
    
    def start_path_to(*args)
      body.start do
        if error = path_to(*args)
          chat "cant get to U #{error}"
        end
      end  
    end
    
    def start_follow(*args, &block)
      body.start { follow *args, &block }
    end
      
    def start_move_to(*args)
      body.start { move_to *args }
    end
    
    def start_jump(*args)
      body.start { jump *args }
    end
    
    def start_miracle_jump(*args)
      body.start { miracle_jump *args }
    end
    
    def miracle_jump(x, z)
      opts = { :update_period => 0.01, :speed => 600 }
      jump_to_height 276, opts
      move_to Coords[x, 257, z], opts
      fall opts
    end
    
    def follow(opts={}, &block)
      opts = opts.dup
      opts[:pathfinder] ||= Pathfinder.new(chunk_tracker, tolerance: 3, flying_aversion: 2)
      while true
        target = yield
        break if target.nil?
        if (body.position - target).abs <= 1
          #TODO maybe fall_update here instead
          body.wait_for_next_position_update 
        else
          case path_to target, opts
          when :solid, nil
            #TODO maybe fall_update here instead
            body.wait_for_next_position_update        
          when :no_path
            chat "cant get to U"
            body.delay 10
          end
        end
      end
      chat "lost U"
    end
    
    def path_to(target, opts={})
      target = target.to_int_coords
      pathfinder = opts[:pathfinder] || Pathfinder.new(chunk_tracker)
      
      return :solid if chunk_tracker.block_type(target).solid?
      
      pathfinder.start = body.position.to_int_coords
      pathfinder.goal = target
      path = pathfinder.find_path
      return :no_path unless path
      
      path.each do |waypoint|
        center = waypoint + Coords[0.5,0,0.5]
        move_to center, opts
      end
      
      return nil
    end
    
    def move_to(target, opts={})
      target = target.to_coords
    
      tolerance = opts[:tolerance] || 0.2
      speed = opts[:speed] || 10
      axes = [Coords::X, Coords::Y, Coords::Z].cycle
      
      while true
        body.wait_for_next_position_update(opts[:update_period])
        body.look_at target

        d = target - body.position
        if d.norm < tolerance
          return # reached it
        end
      
        max_distance = speed*body.last_update_period
        if d.norm > max_distance
          d = d.normalize*max_distance
        end
      
        if body.bumped?
          d = d.project_onto_unit_vector(axes.next)*3
        end
      
        body.position += d
      end
      
    end
    
    def jump(dy=3, opts={})
      jump_to_height body.position.y + dy, opts
    end
    
    def jump_to_height(y, opts={})
      speed = opts[:speed] || 10
    
      while body.position.y <= y
        body.wait_for_next_position_update(opts[:update_period])
        body.position.y += speed*body.last_update_period
        if body.bumped?
          return false   # the head got bumped
        end
      end
      return true
    end
	
    def fall(opts={})
      while true
        body.wait_for_next_position_update(opts[:update_period])
        break if fall_update(opts)
      end
    end
          
    def fall_update(opts={})
      speed = opts[:speed] || 10
      
      ground = find_nearby_ground || -1
      
      max_distance = speed * body.last_update_period
      
      dy = ground - body.position.y
      if dy.abs > max_distance
        dy = dy.to_f/dy.abs*max_distance
      end
      
      body.position.y += dy
      
      return (body.position.y - ground).abs < 0.2
    end
    
    def find_nearby_ground
      x,y,z = body.position.to_a
      # the body is a 0.6 x 0.6 square centered around the body.position
      # need to check all of the columns for a possible solid block we could be standing on
      columns = [[x+0.3,z+0.3],
                 [x-0.3,z+0.3],
                 [x+0.3,z-0.3],
                 [x-0.3,z-0.3]]
      y.ceil.downto(y.ceil-10).each do |test_y|
        columns.each do |column_x,column_z|
          block_type = chunk_tracker.block_type([column_x.floor, test_y, column_z.floor])
          block_type ||= ItemType::Air    # block_type is nil if it is in an unloaded chunk
          if block_type.solid?
            return test_y + 1
          end
        end
      end
      nil
    end
    
    def position
      body.position
    end
    
    def stop
      body.stop
    end
  end
end