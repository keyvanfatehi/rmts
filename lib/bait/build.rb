require 'bait'
require 'moneta'
require "toystore"
require 'bait/simple_query'
require 'bait/tester'

module Bait
  class Build
    include Toy::Store
    extend Bait::SimpleQuery

    @@db_file = Bait.db_file('builds')
    adapter :memory, Moneta.new(:YAML, :file => @@db_file)

    attribute :ref, String
    attribute :owner_name, String
    attribute :owner_email, String
    attribute :name, String
    attribute :clone_url, String
    attribute :passed, Boolean
    attribute :output, String, default: ""
    attribute :tested, Boolean, default: false

    validates_presence_of :name
    validates_presence_of :clone_url

    def tester
      @tester ||= Bait::Tester.new(self)
    end

    def test_later
      self.tested = false
      self.save
      unless Bait.env == "test"
        fork do
          self.tester.clone!
          self.tester.test!
        end
      end
      self
    end

    def queued?
      !self.reload.tested?
    end

    after_destroy  { tester.cleanup! }

  end
end
