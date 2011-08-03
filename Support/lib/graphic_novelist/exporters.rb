module GraphicNovelist
  module Exporter
    
    class << self
      
      def translate_to(kind, document, ctx={})
        case kind
        when :html
          GraphicNovelist::Exporter::Html.new(document, ctx).to_s
        when :textile
          GraphicNovelist::Exporter::Textile.new(document, ctx).to_s
        else
          puts "! Unknown export type: #{kind}. Should be one of [:html, :textile]"
          ""
        end
      end
      
      def fetch_template(name)
        tmpl_path = File.join(File.dirname(__FILE__), 'templates', "export_#{name}.erb")
        IO.readlines(tmpl_path).join
      end
      
    end
  end
end

require 'graphic_novelist/exporters/html'
require 'graphic_novelist/exporters/textile'
