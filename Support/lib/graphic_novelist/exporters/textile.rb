module GraphicNovelist
  module Exporter
    class Textile
      attr_reader :script_nodes, :ctx
      
      def initialize(document, ctx={})
        @document = document
        @script_nodes = document.script_nodes
        @ctx   = ctx
      end
      
      def to_s
        tmpl = ERB.new( Exporter.fetch_template(:textile) )
        tmpl.result binding
      end
    end
  end
end
