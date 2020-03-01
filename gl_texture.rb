class GLTexture
  attr_reader :width, :height

  def initialize(filename)
    gosu_image = filename.is_a?(Gosu::Image) ? filename : Gosu::Image.new(filename, retro: true)
    array_of_pixels = gosu_image.to_blob
    tex_name_buf = ' ' * 4
    glGenTextures(1, tex_name_buf)
    @tex_name = tex_name_buf.unpack('L')[0]
    glBindTexture( GL_TEXTURE_2D, @tex_name )
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, gosu_image.width, gosu_image.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, array_of_pixels)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
  
    @width  = gosu_image.width
    @height = gosu_image.height
    gosu_image = nil
  end

  def get_id
    return @tex_name
  end

  def self.load_tiles(filename, width, height)
    temp_tileset = Gosu::Image.load_tiles(filename, width, height, retro: true)
    textures = []
    temp_tileset.each do |tile|
      textures.push GLTexture.new(tile)
    end
    return textures
  end
end
