require 'lims-api/stream'
require 'oj'

module Lims::Api
  class JsonStream < Stream

    COMMA = ","
    OPEN_BRACKET = "{"
    CLOSE_BRACKET = "}"
    COLON = ":"
    OPEN_SQUARE_BRACKET = "["
    CLOSE_SQUARE_BRACKET = "]"

    class HashStream
      attr_accessor :delimiter

      def initialize(stream)
        @key_added = false
        @delimiter = nil 
        @stream = stream
      end

      def open_hash
       @stream << OPEN_BRACKET 
      end

      def value_added!
        @key_added = false
      end

      def add_key(key)
        raise RuntimeError, "Expecting a value" if @key_added
        @key_added = true
        @stream << @delimiter if @delimiter
        @stream << Oj.dump(key)
        @stream << COLON 
      end

      def add_value(value)
        raise RuntimeError, "Expecting a key" unless @key_added
        @key_added = false
        @delimiter = COMMA 
        @stream << Oj.dump(value)
      end

      def close_hash
        @stream << CLOSE_BRACKET 
      end
    end


    class ArrayStream
      attr_accessor :delimiter

      def initialize(stream)
        @delimiter = nil
        @stream = stream
      end

      def open_array
        @stream << OPEN_SQUARE_BRACKET 
      end

      def add_key(key)
        raise RuntimeError, "Array not expecting key"
      end

      def add_value(value)
        @stream << @delimiter if @delimiter
        @stream << Oj.dump(value)
        @delimiter = COMMA 
      end

      def close_array
        @stream << CLOSE_SQUARE_BRACKET 
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
        @stream
      end
    end

    def start_hash
      hash = HashStream.new(@stream)
      update_current!
      hash.open_hash
      push hash 
    end

    def end_hash
      pop.close_hash
    end

    def start_array
      array = ArrayStream.new(@stream)
      update_current!
      array.open_array
      push array 
    end

    # If the hash to be created is embedded in another structure
    # We should add a comma if the parent structure is a non empty
    # array. If the parent structure is a hash, we should tell it 
    # that the hash we create is actually the value of the current key.
    # Then we increment the size of the parent structure.
    def update_current!
      if current
        @stream << current.delimiter if current.is_a?(ArrayStream) && current.delimiter
        current.value_added! if current.is_a?(HashStream)
        current.delimiter = COMMA 
      end
    end

    def end_array
       pop.close_array
    end

    def add_key(key)
       current.add_key(key)
    end

    def add_value(value)
      current.add_value(value)
    end

    def end_struct
    end
  end
end
