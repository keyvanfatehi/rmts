require 'bait/object'
require 'bait/tester'
require 'json'
require 'httparty'

module Bait
  class Build < Bait::Object
    adapter :memory,
      Moneta.new(:YAML, :file => Bait.db_file('builds'))

    attribute :ref, String
    attribute :owner_name, String
    attribute :owner_email, String
    attribute :name, String
    attribute :clone_url, String
    attribute :passed, Boolean
    attribute :output, String, default: ""
    attribute :tested, Boolean, default: false
    attribute :running, Boolean, default: false

    validates_presence_of :name
    validates_presence_of :clone_url

    after_destroy  { tester.cleanup! }

    def tester
      @tester ||= Bait::Tester.new(self)
    end

    def test_later
      self.tested = false
      self.save
      Bait::Tester.async_test! self.id
      self
    end

    def queued?
      !self.reload.tested?
    end

    def status
      if queued?
        "queued"
      elsif passed?
        "passed"
      else
        "failed"
      end
    end
  end
end
