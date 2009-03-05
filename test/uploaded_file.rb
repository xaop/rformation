class UploadedFile

  def initialize(data, original_filename, content_type)
    @data = data
    @original_filename = original_filename
    @content_type = content_type
  end
  
  def read
    @data
  end
  
  def original_filename
    @original_filename
  end
  
  def content_type
    @content_type
  end
  
end
