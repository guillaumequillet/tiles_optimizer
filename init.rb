require 'gosu'
require 'opengl'
require 'glu'

OpenGL.load_lib
GLU.load_lib

include OpenGL, GLU

require_relative 'gl_texture.rb'
require_relative 'tiled_optimizer.rb'

class Window < Gosu::Window
  def initialize
    super(640, 480, false)
    @tiled_map = TiledMap.new('tiled_maps/test.json')
    @x, @y, @z = 0, 30, 100
    @t_x, @t_y, @t_z = 0, 10, 0
  end

  def button_down(id)
    close! if id == Gosu::KB_ESCAPE
  end

  def needs_cursor?; true; end

  def update
    v = 1
    if Gosu::button_down?(Gosu::KB_W)
      @z -= v
      @t_z -= v
    elsif Gosu::button_down?(Gosu::KB_S)
      @z += v
      @t_z += v
    elsif Gosu::button_down?(Gosu::KB_A)
      @x -= v
      @t_x -= v
    elsif Gosu::button_down?(Gosu::KB_D)
      @x += v
      @t_x += v
    end
  end

  def draw
    gl do
      glEnable(GL_DEPTH_TEST)
      glEnable(GL_TEXTURE_2D)

      glMatrixMode(GL_PROJECTION)
      glLoadIdentity
      gluPerspective(45, self.width.to_f / self.height, 1, 1000)

      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity
      gluLookAt(@x, @y, @z,  @t_x, @t_y, @t_z,  0, 1, 0)

      @angle ||= 0
      @angle += 0.2
      glRotatef(@angle, 0, 1, 0)

      @tiled_map.draw
    end
  end
end

Window.new.show
