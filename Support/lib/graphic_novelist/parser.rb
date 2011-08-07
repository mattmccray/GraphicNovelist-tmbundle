require 'ostruct'

module GraphicNovelist
  class Parser
    attr_reader :source, :metadata, :filename, :script_nodes, :dlg_cnt, :sfx_cnt
    
    def initialize( source, filename=nil )
      @script_nodes = []
      @metadata = {}
      @filename = filename
      @metadata['title'] = filename
      @metadata['author'] = ''
      @metadata['revision'] = ''
      @metadata['generated_on'] = Time.now
      @metadata['generated_by'] = "Graphic Novelist #{GraphicNovelist::VERSION}"
      @dlg_cnt = 1
      @sfx_cnt = 'A'
      @source = if source.is_a? String
        source.split("\n")
      elsif source.is_a? Array
        source
      else
        puts "! Unknown source type"
        source
      end
      parse!
    end

    attr_accessor :last_node, :last_line, :errors
    
    def parse!
      @last_node = OpenStruct.new
      @last_line = nil
      @errors = []
      page_number= 1
      panel_number= 1

      @source.each_with_index do |line, idx|
        skip_it = false
        node = OpenStruct.new
        node.src = line
        node.prev_node = @last_node
        
        case line[0..0]

          when '[' # New page
            node.kind = 'page-header'
            node.body = if /^\[(.*)\].*$/ =~ line.strip.chomp
              $1.strip
            else
              line.strip
            end
            node.number = if /(\d{1,3})/ =~ line.strip.chomp
              $1
            elsif /(\#{1})/ =~ line.strip.chomp
              node.body.gsub! /(\#{1})/, page_number.to_s
              page_number
            else
              nil
            end
            @dlg_cnt = 1
            @sfx_cnt = 'A'
            if page_number != node.number.to_i
              page_number = node.number.to_i
            end
            page_number += 1
            panel_number= 1
            
          when '@' # Meta data
            info = line[1..-1]
            data = info.split(":")
            data.each {|l| l.strip! }
            @metadata[ data.shift.downcase ] = data.join(':')
            node = last_node
            skip_it = true

          when ' ', "\t" # Dialog / SFX
            node.kind = 'dialog'
            dialog_src = line.split(":")
            # Only kill whitspace on the character name...
            dialog_src[0].strip!
            dialog_src[1].strip! if dialog_src.length > 1
            
            if dialog_src.length > 1
              node.char = dialog_src.shift.split(',')
              node.body = dialog_src.join(":")
              if node.char[0].upcase == 'SFX'
                node.kind = 'sfx'
              end

            elsif last_node.kind == 'dialog' # A continued line...
              @last_node.body += " #{dialog_src.join(":")}"
              node = last_node
              skip_it = true

            else
              @errors << [idx, line]
              skip_it = true
              node = @last_node
            end
            
            node.count = if node.kind == 'sfx'
              cnt = @sfx_cnt
              @sfx_cnt = @sfx_cnt.next
              cnt
            else
              cnt = @dlg_cnt
              @dlg_cnt = @dlg_cnt.next
              cnt
            end unless skip_it or !node.count.nil?
            
            if node.body =~ /^\((.*)\)(.*)$/
              node.parenthetical = "(#{$1.strip})"
              node.body = $2.strip
            end
          
          when "\n", ""
            skip_it = true
            node = @last_node

          else # Action
          
        # Panel action
            if line.strip.chomp =~ /^panel ([\d|\#]*)(.*)$/i
              node.kind = 'panel'
              node.panel = $1.strip
              node.body = $2.strip
              if /(\#{1})/ =~ node.panel
                node.panel = panel_number.to_s
              end
              panel_number += 1
        
        # Action (default)
            else
              if ['action','panel'].include?( @last_node.kind ) and @last_line != ""
                skip_it = true
                node = @last_node
                @last_node.body += " #{line.strip}"
        
        # Not continued, or seperated by whitespace
              else 
                node.kind = 'action'
                node.body = line.strip
                if line.strip.empty?
                  node = last_node
                  skip_it = true
                end
              end
            end
        end
        @last_node = node 
        @last_line = line
        @script_nodes << node unless skip_it
      end
      @script_nodes.unshift( OpenStruct.new(:kind=>'page-header', :body=>'')) if @script_nodes[0].kind != 'page-header'
    end
    
    class << self

      def from_file( filename )
        Parser.new( IO.readlines(filename), File.basename(filename) )
      end

    end
  end
end