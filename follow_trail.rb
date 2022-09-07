#==============================================================================
# ** Follow Trail                                                  (2022-09-07)
#    by Wreon
#------------------------------------------------------------------------------
#  This script allows chasing events to follow the player's trail exactly,
#  including diagonal movement and jumping.
#  
#  Usage:
#    event.follow_player_movement - Follow the player's trail
#    event.watch_player_movement - Start recording the player's movement
#  
#  watch_player_movement is only necessary if follow_player_movement is called
#  after the player starts moving, for example an event that waits a bit before
#  chasing.
#==============================================================================

# The maximum length of the movement record array before it cuts off to avoid
# memory leaks, although unlikely.
MOVEMENT_RECORD_MAX_LENGTH = 500

#==============================================================================
# ** Game_Player
#------------------------------------------------------------------------------
#  This class handles the player. It includes event starting determinants and
# map scrolling functions. The instance of this class is referenced by
# $game_player.
#==============================================================================

class Game_Player
  #--------------------------------------------------------------------------
  # * Public Instance Variables
  #--------------------------------------------------------------------------
  attr_reader   :movement_record          # Array of Movement Inputs
  attr_reader   :start_position           # Start Position on Map
  #--------------------------------------------------------------------------
  # * Move to Designated Position
  #--------------------------------------------------------------------------
  alias movement_record_moveto moveto
  def moveto(x, y)
    movement_record_moveto(x, y)
    @start_position = [@x, @y]
  end
  #--------------------------------------------------------------------------
  # * Start Recording Movement
  #--------------------------------------------------------------------------
  def start_recording_movement
    @movement_record = []
  end
  #--------------------------------------------------------------------------
  # * Move Straight
  #--------------------------------------------------------------------------
  alias movement_record_move_straight move_straight
  def move_straight(d, turn_ok = true)
    movement_record_move_straight(d, turn_ok)
    @movement_record.push([0, d, turn_ok]) if @movement_record and @movement_record.length < MOVEMENT_RECORD_MAX_LENGTH
  end
  #--------------------------------------------------------------------------
  # * Move Diagonally
  #--------------------------------------------------------------------------
  alias movement_record_move_diagonal move_diagonal
  def move_diagonal(horz, vert)
    movement_record_move_diagonal(horz, vert)
    @movement_record.push([1, horz, vert]) if @movement_record and @movement_record.length < MOVEMENT_RECORD_MAX_LENGTH
  end
  #--------------------------------------------------------------------------
  # * Jump
  #     x_plus : x-coordinate plus value
  #     y_plus : y-coordinate plus value
  #--------------------------------------------------------------------------
  alias movement_record_jump jump
  def jump(x_plus, y_plus)
    movement_record_jump(x_plus, y_plus)
    @movement_record.push([2, x_plus, y_plus]) if @movement_record and @movement_record.length < MOVEMENT_RECORD_MAX_LENGTH
  end
  #--------------------------------------------------------------------------
  # * Execute Player Transfer
  #--------------------------------------------------------------------------
  alias movement_record_perform_transfer perform_transfer
  def perform_transfer
    @movement_record = nil if transfer?
    movement_record_perform_transfer
  end
end

#==============================================================================
# ** Game_Event
#------------------------------------------------------------------------------
#  This class handles events. Functions include event page switching via
# condition determinants and running parallel process events. Used within the
# Game_Map class.
#==============================================================================

class Game_Event
  #--------------------------------------------------------------------------
  # * Move Toward Character
  #--------------------------------------------------------------------------
  def move_toward_target(x, y)
    sx = distance_x_from(x)
    sy = distance_y_from(y)
    if sx.abs > sy.abs
      move_straight(sx > 0 ? 4 : 6)
      move_straight(sy > 0 ? 8 : 2) if !@move_succeed && sy != 0
    elsif sy != 0
      move_straight(sy > 0 ? 8 : 2)
      move_straight(sx > 0 ? 4 : 6) if !@move_succeed && sx != 0
    end
  end
  #--------------------------------------------------------------------------
  # * Follow Player's Trail
  #--------------------------------------------------------------------------
  def follow_player_movement
    # Start recording the player's movements
    if !$game_player.movement_record then
      $game_player.start_recording_movement
    end
    # Get the player's start position
    player_start_pos = $game_player.start_position
    # Check if the event has reached the player's start point
    if @x == player_start_pos[0] and @y == player_start_pos[1] then
      @reached_start_pos = true
    end
    # Pathfind to the player's start point first of all
    if !@reached_start_pos then
      # Removed due to issues: pathfind(@player_start_pos[0], @player_start_pos[1])
      move_toward_target(player_start_pos[0], player_start_pos[1])
    # Follow the player's movements
    else
      # Begin following the player from their first movement
      if !@player_movement_record_index then
        @player_movement_record_index = 0
      end
      # Follow the player's current movement
      current_movement = $game_player.movement_record[@player_movement_record_index]
      if current_movement then
        previous_through = @through
        @through = false
        # Move straight
        if current_movement[0] == 0 then
          move_straight(current_movement[1], current_movement[2])
        # Move diagonally
        elsif current_movement[0] == 1 then
          move_diagonal(current_movement[1], current_movement[2])
        # Jump
        elsif current_movement[0] == 2 then
          jump(current_movement[1], current_movement[2])
        end
        @through = previous_through
        @player_movement_record_index += 1
      end
    end
  end
  #--------------------------------------------------------------------------
  # * Watch Player's Movement
  #--------------------------------------------------------------------------
  def watch_player_movement
    if !$game_player.movement_record then
      $game_player.start_recording_movement
    end
  end
end
