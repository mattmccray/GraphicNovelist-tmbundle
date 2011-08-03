require 'erb'

module GraphicNovelist
  module Exporter
    class Html
      attr_reader :script_nodes, :ctx, :page_count, :page_numbers, :page_headers
      
      def initialize(document, ctx={})
        @document     = document
        @script_nodes = document.script_nodes
        @page_count   = 0
        @ctx          = ctx
        @page_numbers = []
        @page_headers = []
        @script_nodes.each do |n| 
          if n.kind == 'page-header'
            @page_headers << n
            @page_count += 1 
            @page_numbers << n.number || @page_count
          end
        end
      end
      
      def to_s
        tmpl = ERB.new( Exporter.fetch_template(:html) )
        tmpl.result binding
      end
      
      def is_empty?(key)
        if @document.metadata.has_key?( key )
          val = @document.metadata[ key ].to_s
          val.empty?
        else
          true
        end
      end
      
      def method_missing(name, *args)
        if @document.metadata.has_key?( name.to_s )
          @document.metadata[ name.to_s ]
          
        elsif name.to_s == 'title' or name.to_s == 'filename'
          @document.filename
          
        elsif @document.respond_to? name
          @document.send name, *args

        else
          super(name, *args)
        end
      end
    end
  end
end
