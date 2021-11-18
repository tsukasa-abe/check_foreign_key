# frozen_string_literal: true

require_relative "check_foreign_key/version"
require "active_record"

module CheckForeignKey
  class Error < StandardError; end

  def self.check_key
    ActiveRecord::Base
  end
end
