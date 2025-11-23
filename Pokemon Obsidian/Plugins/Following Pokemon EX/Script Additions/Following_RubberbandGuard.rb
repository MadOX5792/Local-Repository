#===============================================================================
# Following Pokemon - Rubberband Guard on Connected Maps
#-------------------------------------------------------------------------------
# This script wraps Game_FollowingPkmn#follow_leader and adds a simple guard:
# If the follower drifts too far from the player on connected maps (like
# Shellcove <-> Route 1), it will be snapped to the tile directly behind the
# player once, instead of doing several visible "catch up" jumps.
#
# It does not modify Scene_Map, and it does not require any other Script
# Additions files. It only depends on:
#   - Game_FollowingPkmn (from Pokemon Followers EX)
#   - $map_factory and its helper methods
#===============================================================================

if defined?(Game_FollowingPkmn) && defined?($map_factory)
  class Game_FollowingPkmn
    #---------------------------------------------------------------------------
    # Alias the existing follow_leader so we can wrap it.
    #---------------------------------------------------------------------------
    unless method_defined?(:__rubber_guard_follow_leader)
      alias __rubber_guard_follow_leader follow_leader
    end

    #---------------------------------------------------------------------------
    # New follow_leader wrapper
    #---------------------------------------------------------------------------
    def follow_leader(leader, instant = false, leaderIsTrueLeader = true)
      begin
        if leader && self.map && leader.map && defined?($map_factory) && $map_factory
          # Only care when the maps are connected (scrolling join)
          if $map_factory.areConnected?(leader.map.map_id, self.map.map_id)
            # Do not interfere with special stair handling
            if !(defined?(on_stair?) && on_stair?)
              # Distance between follower and leader across connected maps
              dx, dy = $map_factory.getThisAndOtherEventRelativePos(self, leader)
              dist = dx.abs + dy.abs

              # If follower is noticeably behind but not lost, snap it behind player
              if dist >= 2 && dist <= 6 && !@move_route_forcing
                snap_behind_player_safely(leader)
                return
              end
            end
          end
        end
      rescue
        # If anything goes wrong in the guard logic, fall through to normal behavior.
      end

      # Default behavior from Followers EX
      __rubber_guard_follow_leader(leader, instant, leaderIsTrueLeader)
    end

    #---------------------------------------------------------------------------
    # Helper to snap follower to the tile directly behind the player
    #---------------------------------------------------------------------------
    def snap_behind_player_safely(leader)
      return if !leader || !defined?($map_factory) || !$map_factory

      behind_dir = 10 - leader.direction
      tile = $map_factory.getFacingTileFromPos(
        leader.map.map_id, leader.x, leader.y, behind_dir
      )

      if tile
        target_map_id = tile[0]
        target_x      = tile[1]
        target_y      = tile[2]
        # Ensure follower is on correct map
        self.map = $map_factory.getMap(target_map_id) if self.map.map_id != target_map_id
        moveto(target_x, target_y)
      else
        # Fallback: same tile as player
        self.map = leader.map if self.map != leader.map
        moveto(leader.x, leader.y)
      end

      # Keep internal tracking in sync so the follower does not try to "catch up"
      begin
        @last_leader_x = leader.x
        @last_leader_y = leader.y
      rescue
      end

      calculate_bush_depth if respond_to?(:calculate_bush_depth)
    end
  end
end
