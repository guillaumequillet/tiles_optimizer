=begin
  TODO : 
  - handle walls better : playing with visibility, but also w, l, x, and z related to other walls
=end

require 'json'

class TiledMap
  def initialize(filename)
    infos = JSON.parse(File.read(filename))
    @width = infos['width']
    @height = infos['height']
    infos['layers'].each do |layer|
      case layer['name']
      when 'floors'
        @tiles = layer["data"].map {|e| e - 1}
      when 'walls'
        @walls = layer["data"].map {|e| e - 1}
      end
    end
    @tile_size = 16
    @tileset = GLTexture.load_tiles('gfx/tileset.png', @tile_size, @tile_size)
    @wallset = GLTexture.load_tiles('gfx/wallset.png', @tile_size, @tile_size * 3)
    remove_below_walls_tiles
    @tiles_rects = auto_rectangles(@tiles)
    @walls_rects = auto_rectangles(@walls)
  end

  def remove_below_walls_tiles
    @walls.each_with_index do |wall, id|
      if wall != -1
        @tiles[id] = -1
      end
    end
  end

  def auto_rectangles(data)
    @reserved = []
    rects = {}
    @height.times do |y|
      @width.times do |x|
        next if defined?(@reserved) && @reserved.include?([x, y])
        rect = get_rectangle(data, x, y)
        unless rect.nil?
          tile, x, z, w, l = rect
          rects[tile] = [] unless rects.has_key?(tile)
          rects[tile].push [x, z, w, l]
        end
      end
    end
    return rects
  end

  def get_tile(data, x, y)
    data[y * @width + x]
  end

  def get_rectangle(data, x, y)
    return nil if @reserved.include?([x, y])

    tile = get_tile(data, x, y)
    return nil if tile == -1

    min_x = x
    try_x = x
    while try_x >= 0
      if !@reserved.include?([try_x, y]) && get_tile(data, try_x, y) == tile
        min_x = try_x 
        try_x -= 1
      else
        break
      end
    end
    max_x = x
    for try_x in x...@width
      if !@reserved.include?([try_x, y]) && get_tile(data, try_x, y) == tile
        max_x = try_x 
      else
        break
      end
    end

    min_y = y
    try_y = y - 1
    while try_y >= 0
      tile_ok = true
      for try_x in min_x..max_x
        tile_ok = false if @reserved.include?([try_x, try_y]) || get_tile(data, try_x, try_y) != tile
      end
      if tile_ok
        min_y = try_y
        try_y -= 1
      else
        break
      end
    end

    max_y = y
    for try_y in (y + 1)...@height
      tile_ok = true
      for try_x in min_x..max_x
        tile_ok = false if @reserved.include?([try_x, try_y]) || get_tile(data, try_x, try_y) != tile
      end
      if tile_ok
        max_y = try_y 
      else
        break
      end
    end

    for y in min_y..max_y
      for x in min_x..max_x
        @reserved.push [x, y]
      end
    end

    return [tile, min_x, min_y, max_x - min_x + 1, max_y - min_y + 1]
  end

  def draw
    @tiles_rects.each do |tile_id, quads|
      glBindTexture(GL_TEXTURE_2D, @tileset[tile_id].get_id)
      glPushMatrix
      glScalef(@tile_size, @tile_size, @tile_size)
      glBegin(GL_QUADS)
        quads.each do |quad|
          x, z, w, l = quad
          glTexCoord2d(0, 0); glVertex3i(x, 0, z)
          glTexCoord2d(0, l); glVertex3i(x, 0, z+l)
          glTexCoord2d(w, l); glVertex3i(x+w, 0, z+l)
          glTexCoord2d(w, 0); glVertex3i(x+w, 0, z)
        end
      glEnd
      glPopMatrix
    end

    # walls tops
    @walls_rects.each_value do |quads|
      glBindTexture(GL_TEXTURE_2D, @tileset[0].get_id)
      glPushMatrix
      glScalef(@tile_size, @tile_size, @tile_size)
      glBegin(GL_QUADS)
        quads.each do |quad|
          x, z, w, l = quad
          glTexCoord2d(0, 0); glVertex3i(x, 3, z)
          glTexCoord2d(0, l); glVertex3i(x, 3, z+l)
          glTexCoord2d(w, l); glVertex3i(x+w, 3, z+l)
          glTexCoord2d(w, 0); glVertex3i(x+w, 3, z)
        end
      glEnd
      glPopMatrix
    end

    @walls_rects.each do |tile_id, quads|
      glBindTexture(GL_TEXTURE_2D, @wallset[tile_id].get_id)
      glPushMatrix
      glScalef(@tile_size, @tile_size * 3, @tile_size)
      glBegin(GL_QUADS)
        quads.each do |quad|
          x, z, w, l = quad

          # back wall
          glColor3ub(255, 255, 255)
          glTexCoord2d(0, 0); glVertex3i(x, 1, z)
          glTexCoord2d(0, 1); glVertex3i(x, 0, z)
          glTexCoord2d(w, 1); glVertex3i(x+w, 0, z)
          glTexCoord2d(w, 0); glVertex3i(x+w, 1, z)

          # front wall
          glColor3ub(255, 255, 255)
          glTexCoord2d(0, 0); glVertex3i(x, 1, z+l)
          glTexCoord2d(0, 1); glVertex3i(x, 0, z+l)
          glTexCoord2d(w, 1); glVertex3i(x+w, 0, z+l)
          glTexCoord2d(w, 0); glVertex3i(x+w, 1, z+l)

          # left wall
          glColor3ub(128, 128, 128)
          glTexCoord2d(0, 0); glVertex3i(x, 1, z)
          glTexCoord2d(0, 1); glVertex3i(x, 0, z)
          glTexCoord2d(l, 1); glVertex3i(x, 0, z+l)
          glTexCoord2d(l, 0); glVertex3i(x, 1, z+l)

          # right wall   
          glColor3ub(128, 128, 128)
          glTexCoord2d(0, 0); glVertex3i(x+w, 1, z)
          glTexCoord2d(0, 1); glVertex3i(x+w, 0, z)
          glTexCoord2d(l, 1); glVertex3i(x+w, 0, z+l)
          glTexCoord2d(l, 0); glVertex3i(x+w, 1, z+l)       
        end
      glEnd
      glPopMatrix
      glColor3ub(255, 255, 255)
    end
  end
end
