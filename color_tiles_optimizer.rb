require 'gosu'

class Gosu::Image
  def get_pixel(x, y)
    if x < 0 or x >= self.width or y < 0 or y >= self.height
      return nil
    else
      @blob ||= self.to_blob
      result = @blob[(y * self.width + x) * 4, 4].unpack("C*")
      return Gosu::Color.new(result[3], result[0], result[1], result[2])
    end   
  end

  def pick_pixel(mouse_x, mouse_y, scale)
    color = get_pixel((mouse_x / scale).floor, (mouse_y / scale).floor)

    unless color.nil?
      "#{color.red},#{color.green},#{color.blue} on (#{(mouse_x / scale).floor}, #{(mouse_y / scale).floor})"
    end
  end

  def auto_rectangles
    rects = []
    self.height.times do |y|
      self.width.times do |x|
        next if defined?(@reserved) && @reserved.include?([x, y])
        rect = get_rectangle(x, y)
        rects.push rect unless rect.nil?
      end
    end
    return rects
  end

  def get_rectangle(x, y)
    @reserved ||= []

    return nil if @reserved.include?([x, y])

    color = get_pixel(x, y)

    min_x = x
    try_x = x
    while try_x >= 0
      if !@reserved.include?([try_x, y]) && get_pixel(try_x, y) == color
        min_x = try_x 
        try_x -= 1
      else
        break
      end
    end
    max_x = x
    for try_x in x...self.width
      if !@reserved.include?([try_x, y]) && get_pixel(try_x, y) == color
        max_x = try_x 
      else
        break
      end
    end

    min_y = y
    try_y = y - 1
    while try_y >= 0
      color_ok = true
      for try_x in min_x..max_x
        color_ok = false if @reserved.include?([try_x, try_y]) || get_pixel(try_x, try_y) != color
      end
      if color_ok
        min_y = try_y
        try_y -= 1
      else
        break
      end
    end

    max_y = y
    for try_y in (y + 1)...self.height
      color_ok = true
      for try_x in min_x..max_x
        color_ok = false if @reserved.include?([try_x, try_y]) || get_pixel(try_x, try_y) != color
      end
      if color_ok
        max_y = try_y 
      else
        break
      end
    end

    # x, y, w, h
    bounds = [min_x, min_y, max_x - min_x + 1, max_y - min_y + 1]

    for y in min_y..max_y
      for x in min_x..max_x
        @reserved.push [x, y]
      end
    end

    return bounds
  end
end

class Window < Gosu::Window
  def initialize
    super(640, 480, false)
    @image = Gosu::Image.new('test.png', retro: true)
    @clicked = []
  end

  def button_down(id)
    close! if id == Gosu::KB_ESCAPE

    if id == Gosu::MS_LEFT
      rectangle = @image.get_rectangle((self.mouse_x / @scale).floor, (self.mouse_y / @scale).floor)
      @clicked.push rectangle unless rectangle.nil?
    end

    if id == Gosu::KB_SPACE
      rects = @image.auto_rectangles
      p rects
      @clicked = rects
    end
  end

  def needs_cursor?; true; end

  def update
    @scale = 32
    self.caption = @image.pick_pixel(self.mouse_x, self.mouse_y, @scale) 
  end

  def draw
    scale(@scale, @scale) do 
      @image.draw(0, 0, 0)

      @clicked.each do |clicked|
        Gosu::draw_rect(*clicked, Gosu::Color.new(125, 255, 0, 255))
      end      
    end
  end
end

Window.new.show