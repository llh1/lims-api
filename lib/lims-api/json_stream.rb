require 'lims-api/stream'
require 'oj'

module Lims::Api
  class JsonStream < Stream

    class HashStream
      attr_accessor :delimiter

      def initialize
        @key_added = false
        @delimiter = ""
      end

      def open_hash
        "{"
      end

      def value_added!
        @key_added = false
      end

      def add_key(key)
        raise RuntimeError, "Expecting a value" if @key_added
        @key_added = true
        @key = "#{@delimiter}#{Oj.dump(key)}:"
      end

      def add_value(value)
        raise RuntimeError, "Expecting a key" unless @key_added
        @key_added = false
        @delimiter = ","
        Oj.dump(value)
      end

      def close_hash
        "}"
      end
    end


    class ArrayStream
      attr_accessor :delimiter

      def initialize
        @delimiter = ""
      end

      def open_array
        "["
      end

      def add_key(key)
        raise RuntimeError, "Array not expecting key"
      end

      def add_value(value)
        result = "#{delimiter}#{Oj.dump(value)}"
        @delimiter = ","
        result
      end

      def close_array
        "]"
      end
    end


    def initialize(stream = nil)
      super
      @stream = stream
    end

    def json
      if @stream.respond_to?(:string)
        @stream.string
      else
        @stream.to_s
      end
    end

    def push_stream(sub_stream)
      @stream << sub_stream
    end

    def start_hash
      hash = HashStream.new
      update_current!
      push_stream hash.open_hash
      push hash 
    end

    def end_hash
      push_stream pop.close_hash
    end

    def start_array
      array = ArrayStream.new
      update_current!
      push_stream array.open_array
      push array 
    end

    # If the hash to be created is embedded in another structure
    # We should add a comma if the parent structure is a non empty
    # array. If the parent structure is a hash, we should tell it 
    # that the hash we create is actually the value of the current key.
    # Then we increment the size of the parent structure.
    def update_current!
      if current
        push_stream current.delimiter if current.is_a?(ArrayStream)
        current.value_added! if current.is_a?(HashStream)
        current.delimiter = ","
      end
    end

    def end_array
      push_stream pop.close_array
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
