require 'spec_helper'
require 'lims-api/json_stream'

module Lims::Api
  describe JsonStream do
    context "build a stream" do
      let(:stream) { described_class.new }

      it "builds a hash" do
        stream.start_hash
        stream.add_key "A"
        stream.add_value 1
        stream.end_hash

        stream.struct.should == '{"A":1}'
      end

      it "builds a complex hash" do
        stream.start_hash
        stream.add_key "A"
        stream.start_hash
        stream.add_key "a"
        stream.add_value 1
        stream.end_hash

        stream.add_key "B"
        stream.start_hash
        stream.add_key "b"
        stream.add_value 2
        stream.end_hash
        stream.end_hash

        stream.struct.should == '{"A":{"a":1},"B":{"b":2}}'
      end

      it "builds an array" do
        stream.start_array
        stream.start_array
        stream.add_value "a"
        stream.add_value "b"
        stream.end_array
        stream.add_value 1
        stream.add_value 2

        stream.add_value 3
        stream.end_array

        stream.struct.should == '[["a","b"],1,2,3]'
      end

      it "builds a complex nested structure" do
        stream.start_hash
        stream.add_key "list"
        
        stream.start_array
        stream.add_value 1
        stream.add_value "hello"
        stream.add_value 2

        stream.struct.should == '{"list":[1,"hello",2'

        stream.start_hash
        stream.add_key "A"
        stream.add_value "hello 2"
        stream.end_hash

        stream.end_array

        stream.add_key "param"
        stream.add_value "hello 3"

        stream.end_hash

        stream.struct.should == '{"list":[1,"hello",2,{"A":"hello 2"}],"param":"hello 3"}'
      end

      it "builds a complex object using blocks", :focus => true do
        stream.with_hash do
          stream.add_key "list"

          stream.with_array do
            stream.add_value 1
            stream.add_value "hello"

            stream.with_hash do
              stream.add_key "A"
              stream.add_value 1
            end

            stream.add_value 2
          end

          stream.add_key "B"
          stream.with_array do
            stream.with_hash do
              stream.add_key "C"
              stream.add_value 3
            end
          end
        end

        stream.struct.should == '{"list":[1,"hello",{"A":1},2],"B":[{"C":3}]}'
      end
    end
  end
end
