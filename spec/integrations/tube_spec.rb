#tube_spec.rb
require 'spec_helper'

require 'lims-api/context_service'
require 'lims-api/resource_shared'
require 'lims-core'
require 'lims-core/persistence/sequel'

require 'lims-api/resource_shared'
require 'integrations/lab_resource_shared'
require 'integrations/tube_resource_shared'
require 'integrations/spec_helper'

shared_context "expect tube JSON" do
  let(:expected_json) {
    path = "http://example.org/#{uuid}"
    { "tube" => {"actions" => {"read" => path,
          "update" => path,
          "delete" => path,
          "create" => path},
        "uuid" => uuid,
        "aliquots" => aliquot_array}
    }
  }
end

shared_context "expect tube JSON with labels" do
  let(:expected_json) {
    path = "http://example.org/#{uuid}"
    { "tube" => {"actions" => {"read" => path,
          "update" => path,
          "delete" => path,
          "create" => path},
        "uuid" => uuid,
        "aliquots" => aliquot_array,
        "labels" => actions_hash.merge(labellable_uuid_hash).merge(labels_hash)}
    }
  }
end

describe Lims::Core::Laboratory::Tube do
  include_context "use core context service", :tube_aliquots, :aliquots, :tubes, :samples, :labels, :labellables
  include_context "JSON"
  include_context "use generated uuid"
  let(:asset) { "tube" }
  let(:model) { "#{asset}s" }

  context "#create" do
    context do
      include_context "for empty tube-like asset"
      include_context "expect tube JSON"
      it_behaves_like('creating a resource') 
    end
    context do
      include_context "for tube-like asset with samples"
      include_context "expect tube JSON"
      include_context "with filled aliquots"
      it_behaves_like('creating a resource')
    end

    context do
      include_context "for tube-like asset with samples and labels"
      include_context "resource with labels for the expected JSON"
      include_context "with labels"
      include_context "expect tube JSON with labels"
      include_context "with filled aliquots"
      it_behaves_like('creating a resource with a label on it')
    end
  end

  context "#transfer tubes to tubes", :focus  => true do
    let(:url) { "/actions/transfer_tubes_to_tubes" }
    context "with empty tubes" do
      let(:parameters) { { :transfer_tubes_to_tubes => {} } }
      let(:expected_json) { {"errors" => {:transfers => "invalid" }
      }}
      it_behaves_like "an invalid core action", 422  # Unprocessable entity
    end

    context "from a tube with samples" do
      include_context "with filled aliquots"
      context "to an existing target tube" do
        let(:unit_type) { "mole" }
        let(:aliquot_type) { "NA" }
        let(:source_tube1_uuid) { '22222222-3333-4444-1111-000000000000'.tap do |uuid|
          quantity = 100
          volume = 100
          store.with_session do |session|
            tube = Lims::Core::Laboratory::Tube.new
            L=Lims::Core::Laboratory
            (1..1).each do |i|
              sample = L::Sample.new(:name => "Sample ##{i}")
              aliquot = L::Aliquot.new(:sample => sample, :quantity => quantity)
              tube << aliquot
            end
            tube << L::Aliquot.new(:type => L::Aliquot::Solvent, :quantity => volume)

            session << tube
            set_uuid(session, tube, uuid)
          end
        end

        }
        let(:target_tube2_uuid) { '22222222-3333-4444-1111-000000000001'.tap do |uuid|
            store.with_session do |session|
              tube = Lims::Core::Laboratory::Tube.new
              
              session << tube
              set_uuid(session, tube, uuid)
            end
          end
        }
        let(:transfers) { [ { "source_uuid" => source_tube1_uuid,
                              "target_uuid" => target_tube2_uuid,
                              "amount" => 100,
                              "aliquot_type" => "NA"}
          ]
        }
        let(:parameters) { { :transfer_tubes_to_tubes => { :transfers => transfers} }}
        let(:sample_uuid) { '11111111-2222-3333-4444-888888888888' }
        let(:sample_name) { "sample 1" }

        let(:expected_json) {
          source_tube1_url = "http://example.org/#{source_tube1_uuid}"
          target_tube2_url = "http://example.org/#{target_tube2_uuid}"
          { :transfer_tubes_to_tubes => 
            { :actions => {},
              :user => "user",
              :application => "application",
              "result"=> {
                "tubes" => [
                  {"tube" => {
                    "actions" => {
                      "create" => source_tube1_url,
                      "read" => source_tube1_url,
                      "update" => source_tube1_url,
                      "delete" => source_tube1_url
                    },
                    "uuid" => source_tube1_uuid,
                    "aliquots" => aliquot_array
                  }}
                ]},
                "targets" => {"tubes" => [
                  {"tube" => {
                    "actions" => {
                      "create" => target_tube2_url,
                      "read" => target_tube2_url,
                      "update" => target_tube2_url,
                      "delete" => target_tube2_url
                    },
                    "uuid" => target_tube2_uuid,
                    "aliquots" => aliquot_array
                  }}
                ]
              },
                 "sources" => {"tubes" => [
                  {"tube" => {
                    "actions" => {
                      "create" => target_tube2_url,
                      "read" => target_tube2_url,
                      "update" => target_tube2_url,
                      "delete" => target_tube2_url
                    },
                    "uuid" => target_tube2_uuid,
                    "aliquots" => aliquot_array
                  }}
                ]
              },
              "transfers" => transfers
            }
          }
        }
        
        it_behaves_like "a valid core action"
      end
    end
  end
end
