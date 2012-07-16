require 'matrix'

module RedstoneBot
  class Pathfinder
    attr_reader :chunk_tracker
    
    # triplets of integers representing [x,y,z] coords
    attr_accessor :start, :goal
    
    # [xmin..xmax, ymin..ymax, zmin..zmax]
    attr_accessor :bounds
  
    def initialize(chunk_tracker)
      @chunk_tracker = chunk_tracker
    end
    
    def find_path
      "dunno"
    end
    
    def is_goal?(coords)
      coords == goal
    end
    
    def cost(from_coords, to_coords)
      # TODO: add a little something here to discourage flying and jumping
      distance from_coords, to_coords      
    end
    
    def heuristic_cost_estimate(from_coords, to_coords)
      distance from_coords, to_coords
    end
    
    def distance(a, b)
      (Vector[*a] - Vector[*b]).magnitude
    end
  end
end