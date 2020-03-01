require 'json'

class TiledMap
  def initialize(filename)
    infos = JSON.parse(File.read(filename))
    @width = infos["width"]
    @height = infos["height"]
    infos["layers"].each do |layer|
      if layer["name"] == 'floor'
        @tiles = layer["data"].map {|e| e - 1}
      end

      # TODO : handle walls layer
    end
    @tile_size = 16
    @tileset = GLTexture.load_tiles('gfx/tileset.png', @tile_size, @tile_size)
    auto_rectangles
    total_rects = 0
    @rects.each_value {|v| total_rects += v.size}
    p total_rects
  end

  def auto_rectangles
    @rects = {}
    @height.times do |y|
      @width.times do |x|
        next if defined?(@reserved) && @reserved.include?([x, y])
        rect = get_rectangle(x, y)
        unless rect.nil?
          tile, x, z, w, l = rect
          @rects[tile] = [] unless @rects.has_key?(tile)
          @rects[tile].push [x, z, w, l]
        end
      end
    end
    return @rects
  end

  def get_tile(x, y)
    @tiles[y * @width + x]
  end

  def get_rectangle(x, y)
    @reserved ||= []

    return nil if @reserved.include?([x, y])

    tile = get_tile(x, y)

    min_x = x
    try_x = x
    while try_x >= 0
      if !@reserved.include?([try_x, y]) && get_tile(try_x, y) == tile
        min_x = try_x 
        try_x -= 1
      else
        break
      end
    end
    max_x = x
    for try_x in x...@width
      if !@reserved.include?([try_x, y]) && get_tile(try_x, y) == tile
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
        tile_ok = false if @reserved.include?([try_x, try_y]) || get_tile(try_x, try_y) != tile
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
        tile_ok = false if @reserved.include?([try_x, try_y]) || get_tile(try_x, try_y) != tile
      end
      if tile_ok
        max_y = try_y 
      else
        break
      end
    end

    # tile, x, y, w, h
    bounds = [tile, min_x, min_y, max_x - min_x + 1, max_y - min_y + 1]

    for y in min_y..max_y
      for x in min_x..max_x
        @reserved.push [x, y]
      end
    end

    return bounds
  end

  def draw
    @rects.each do |tile_id, quads|
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
  end
end
