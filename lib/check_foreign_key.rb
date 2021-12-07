# frozen_string_literal: true

require_relative "check_foreign_key/version"
require "active_record"

module CheckForeignKey
  class Error < StandardError; end

  DEPENDENT_OPTION = "{:dependent=>:destroy}"

  class << self
    def check_key
      foreign_key_tables = []
      # 存在するテーブルに対しforeign_keyの設定の有無を確認
      foreign_key_tables = ActiveRecord::Base.connection.tables.flat_map do |table|
        ActiveRecord::Base.connection.foreign_keys(table.intern).pluck(:from_table, :to_table)
      end

      foreign_key_groups = {}
      # 主キー側のtableをkeyとしグループ分け
      foreign_key_groups = foreign_key_tables.inject(Hash.new{[]}) do |r, e|
        a, b = e
        r.update(b => r[b] << a)
      end

      # to_table -> 主キー側のtable
      # from_tables -> 外部キー制約をもったtableのグループ
      foreign_key_groups.each do |to_table, from_tables|
        to_table_associations = to_table.classify.constantize.reflect_on_all_associations
        to_table_associations.each do |to_association|
          unless from_tables.include?(to_association.name) && to_association.options.to_s.include?(DEPENDENT_OPTION)
            put_recommended_dependent(to_association, to_table)
          end
        end
      end
    end

    private

    def put_recommended_dependent(from_table, to_table)
      p "#{from_table.name}に外部キー制約があるのに#{to_table}側の定義でdependet: :destroyがついてないよ〜"
    end
  end
end
