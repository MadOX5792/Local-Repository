#===============================================================================
# Following Pokemon - Modified move_fancy to reduce rubberbanding
#-------------------------------------------------------------------------------
# This overrides move_fancy ONLY for Game_FollowingPkmn (the Followers EX
# Pokémon follower), leaving all other followers alone.
# Code was generated with ChatGPT to address the passability problems that
# may occur. This results in "rubber-banding" or bouncing forward repeatedly.
#
# Behavior:
# - Normal behavior:
#     * If the next tile is the player's tile, move through.
#     * If the next tile is passable, move through.
# - Special case:
#     * If the follower's current tile is not passable AND
#       the follower is on a map connected to the player AND
#       the follower is a few tiles behind the player,
#       then snap the follower to the tile directly behind the player
#       instead of walking it through several bad tiles.
#===============================================================================

if defined?(Game_FollowingPkmn)
  class Game_FollowingPkmn
    #---------------------------------------------------------------------------
    # Override move_fancy only for Following Pokemon
    #---------------------------------------------------------------------------
    def move_fancy(direction)
      # Convert direction (2,4,6,8) to x/y step
      delta_x = (direction == 6) ? 1 : (direction == 4) ? -1 : 0
      delta_y = (direction == 2) ? 1 : (direction == 8) ? -1 : 0
      new_x   = self.x + delta_x
      new_y   = self.y + delta_y

      # 1. Always allow moving into the player's tile
      if $game_player.x == new_x && $game_player.y == new_y
        move_through(direction)
        return
      end

      # 2. If the new tile is normally passable, just move into it
      if location_passable?(new_x, new_y, 10 - direction)
        move_through(direction)
        return
      end

      # 3. If our current tile is not passable, handle carefully
      if !location_passable?(self.x, self.y, direction)
        begin
          if defined?($map_factory) && $map_factory &&
             self.map && $game_player.map &&
             $map_factory.areConnected?($game_player.map.map_id, self.map.map_id)

            # Distance between follower and player across connected maps
            dx, dy = $map_factory.getThisAndOtherEventRelativePos(self, $game_player)
            dist = dx.abs + dy.abs

            # If follower is "near" the player (2-6 tiles away), snap behind them
            if dist >= 2 && dist <= 6
              behind_dir = 10 - $game_player.direction
              tile = $map_factory.getFacingTileFromPos(
                $game_player.map.map_id, $game_player.x, $game_player.y, behind_dir
              )
              if tile
                target_map_id = tile[0]
                target_x      = tile[1]
                target_y      = tile[2]
                self.map = $map_factory.getMap(target_map_id) if self.map.map_id != target_map_id
                moveto(target_x, target_y)
              else
                # Fallback: same tile as player
                self.map = $game_player.map
                moveto($game_player.x, $game_player.y)
              end
              calculate_bush_depth if respond_to?(:calculate_bush_depth)
              return
            end
          end
        rescue
          # On any error, fall back to original-style behavior below
        end

        # If not on a connected map or far away from the player,
        # behave like vanilla: force a step through.
        move_through(direction)
        return
      end

      # 4. Otherwise, do nothing this frame (no movement)
    end
  end
end
