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
  end

  def button_down(id)
    close! if id == Gosu::KB_ESCAPE
  end

  def needs_cursor?; true; end

  def update

  end

  def draw
    gl do
      glEnable(GL_DEPTH_TEST)
      glEnable(GL_TEXTURE_2D)

      glMatrixMode(GL_PROJECTION)
      glLoadIdentity
      gluPerspective(45, self.width.to_f / self.height, 0.1, 1000)

      glMatrixMode(GL_MODELVIEW)
      glLoadIdentity
      gluLookAt(150, 50, 300,  150, 0, 0,  0, 1, 0)

      @tiled_map.draw
    end
  end
end

Window.new.show
