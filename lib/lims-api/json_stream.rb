require 'lims-api/stream'

module Lims::Api
  class JsonStream < Stream

    class HashStream
      attr_accessor :size

      def initialize
        @key_added = false
        @size = 0
      end

      def start_hash
        "{"
      end

      def value_added!
        @key_added = false
      end

      def add_key(key)
        raise RuntimeError, "Expecting a value" if @key_added
        @key_added = true

        @key = "#{key.to_json}:"
        (@size > 0) ? ",#{@key}" : @key
      end

      def add_value(value)
        raise RuntimeError, "Expecting a key" unless @key_added
        @key_added = false
        @size += 1
        value.to_json
      end

      def end_hash
        "}"
      end
    end


    class ArrayStream
      attr_accessor :size

      def initialize
        @size = 0
      end

      def start_array
        "["
      end

      def add_key(key)
        raise RuntimeError, "Array not expecting key"
      end

      def add_value(value)
        result = (@size > 0) ? ",#{value.to_json}" : value.to_json
        @size += 1
        result
      end

      def end_array
        "]"
      end
    end


    def initialize
      super
      @stream = StringIO.new 
    end

    def struct
      @stream.string
    end

    def push_stream(sub_stream)
      @stream << sub_stream
    end

    def start_hash
      hash = HashStream.new

      if current
        push_stream "," if current.size > 0
        current.value_added! if current.is_a?(HashStream)
        current.size += 1
      end

      push_stream hash.start_hash
      push hash 
    end

    def end_hash
      push_stream pop.end_hash
    end

    def start_array
      array = ArrayStream.new

      if current
        push_stream "," if current.size > 0
        current.value_added! if current.is_a?(HashStream)
        current.size += 1
      end

      push_stream array.start_array
      push array 
    end

    def end_array
      push_stream pop.end_array
    end

    def add_key(key)
      push_stream current.add_key(key)
    end

    def add_value(value)
      push_stream current.add_value(value)
    end

    def end_struct
    end
  end
end
