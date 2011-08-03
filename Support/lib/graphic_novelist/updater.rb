# this probably requires ruby 1.8
require 'open-uri'
require 'erb'

module GraphicNovelist
  class Updater
    UPDATE_URL = "http://www.mattmccray.com/projects/graphic_novelist/version.txt"
    
    class << self
      attr_accessor :remote_ver, :local_ver
      
      def check_for_updates
        @remote_ver = get_remove_version
        unless remote_ver.nil?
          @local_ver = GraphicNovelist::VERSION.to_f
          if remote_ver > local_ver
            fetch_template('available')
          else
            fetch_template('latest')
          end
        else
          fetch_template("timeout")
        end
      end
      
      def get_remove_version
        open(UPDATE_URL).read.to_f
      rescue
        nil
      end
      
      def fetch_template(name)
        tmpl_path = File.join(File.dirname(__FILE__), 'templates', "update_#{name}.erb")
        src = IO.readlines(tmpl_path).join
        tmpl = ERB.new( src )
        tmpl.result( binding )
      end
      
    end
  end
end
