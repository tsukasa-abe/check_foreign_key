# frozen_string_literal: true

require_relative "check_foreign_key/version"
require "active_record"

module CheckForeignKey
  class Error < StandardError; end

  def self.check_key
    foreign_key_tables = []
    # 存在するテーブルの確認
    tables = ActiveRecord::Base.connection.tables
    # 存在するテーブルに対しforeign_keyの設定の有無を確認
    foreign_key_tables = tables.flat_map do |table|
      ActiveRecord::Base.connection.foreign_keys(table.intern).map(&:to_table).map(&:classify)
    end

    # 上記でforeign_keyが設定されているテーブルのモデルのリレーションの内容を確認
    foreign_key_tables.map(&:constantize).map(&:reflect_on_all_associations).flatten
  end
end
