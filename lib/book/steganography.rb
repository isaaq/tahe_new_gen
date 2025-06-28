require 'chunky_png'

module Book
  class Steganography
    # 使用LSB隐写术在图片中隐藏信息
    # 参考: https://github.com/RobinDavid/LSB-Steganography
    def self.hide(image_path, message)
      image = ChunkyPNG::Image.from_file(image_path)
      message_bits = message.unpack('B*')[0].chars.map(&:to_i)
      
      # 首先存储消息长度（32位）
      length_bits = [message.length].pack('N').unpack('B*')[0].chars.map(&:to_i)
      
      # 存储长度信息
      length_bits.each_with_index do |bit, i|
        x, y = i % image.width, i / image.width
        pixel = image[x, y]
        
        r = ChunkyPNG::Color.r(pixel)
        g = ChunkyPNG::Color.g(pixel)
        b = ChunkyPNG::Color.b(pixel)
        a = ChunkyPNG::Color.a(pixel)
        
        # 修改蓝色通道的最低有效位
        b = (b & 0xFE) | bit
        
        image[x, y] = ChunkyPNG::Color.rgba(r, g, b, a)
      end
      
      # 存储消息内容
      message_bits.each_with_index do |bit, i|
        x, y = (i + 32) % image.width, (i + 32) / image.width
        
        # 确保不超出图片范围
        break if y >= image.height
        
        pixel = image[x, y]
        
        r = ChunkyPNG::Color.r(pixel)
        g = ChunkyPNG::Color.g(pixel)
        b = ChunkyPNG::Color.b(pixel)
        a = ChunkyPNG::Color.a(pixel)
        
        # 修改蓝色通道的最低有效位
        b = (b & 0xFE) | bit
        
        image[x, y] = ChunkyPNG::Color.rgba(r, g, b, a)
      end
      
      image
    end
    
    # 从图片中提取隐藏的信息
    def self.extract(image_path)
      image = ChunkyPNG::Image.from_file(image_path)
      
      # 提取长度信息（32位）
      length_bits = []
      32.times do |i|
        x, y = i % image.width, i / image.width
        pixel = image[x, y]
        b = ChunkyPNG::Color.b(pixel)
        length_bits << (b & 1)
      end
      
      # 计算消息长度
      length = length_bits.join.to_i(2)
      
      # 提取消息内容
      message_bits = []
      (length * 8).times do |i|
        x, y = (i + 32) % image.width, (i + 32) / image.width
        
        # 确保不超出图片范围
        break if y >= image.height
        
        pixel = image[x, y]
        b = ChunkyPNG::Color.b(pixel)
        message_bits << (b & 1)
      end
      
      # 将二进制转换回字符串
      message_bits.each_slice(8).map { |byte| byte.join.to_i(2).chr }.join
    end
  end
end
