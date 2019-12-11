module HtmlHeadless
  require 'fileutils'

  def initialize(template)
    @template = File.read(Rails.root.join('app/views').join(template+".html.erb"))
  end

  included do
    after_commit :share_image_generate
  end

  def to_image(obj, uploader_method, width=1200, height=630)
    html = ERB.new(@template.html_safe).result(binding)
    screenshot_file = Tempfile.new(['screen','.png'])
    File.open(html_file_path, 'w') {|f| f.write(html) }
    screenshot_file = Tempfile.new(['screen','.jpg'])
    begin
      cmd = "'#{chrome}'
        --headless
        --screenshot=#{screenshot_file.path}
        --window-size=#{width},#{height}
        --disable-gpu
        --disable-features=NetworkService #{html_file_path}".gsub("\n",' ')
      `#{cmd}`
      if $?.success?
        obj.class.skip_callback(:commit, :after, :share_image_generate)
        obj.send("#{uploader_method}=", screenshot_file)
        obj.save
        obj.class.set_callback(:commit, :after, :share_image_generate)
      else
        raise "result = #{$?}; command = #{cmd}"
      end
    ensure
       FileUtils.rm(html_file_path)
       screenshot_file.close
       screenshot_file.unlink
    end
  end

  def chrome
    if RbConfig::CONFIG['host_os'] =~ /darwin/
      "/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome"
    elsif RbConfig::CONFIG['host_os'] =~ /linux/
      "chromium-browser"
    else
      raise StandardError.new "host os don't detected"
    end
  end

  def html_file_path
    @path = Rails.public_path.join(SecureRandom.urlsafe_base64.downcase + ".html")
  end

  def sharing_image_generate

  end
end
