# frozen_string_literal: true

require_relative "check_foreign_key/version"
require "active_record"

module CheckForeignKey
  class Error < StandardError; end

  class << self
    def check_key
      fk_groups = foreign_key_groups(foreign_key_tables)

      check_for_associations(fk_groups)
    end

    private

    def foreign_key_tables
      # 存在するテーブルに対しforeign_keyの設定の有無を確認
      ActiveRecord::Base.connection.tables.flat_map do |table|
        ActiveRecord::Base.connection.foreign_keys(table.intern).pluck(:from_table, :to_table)
      end
    end

    def foreign_key_groups(fk_tables)
      # 主キー側のtableをkeyとしグループ分け
      fk_tables.inject(Hash.new{[]}) do |r, e|
        a, b = e
        r.update(b => r[b] << a)
      end
    end

    def check_for_associations(groups)
      # to_table -> 主キー側のtable
      # from_tables -> 外部キー制約をもったtableのグループ
      groups.each do |to_table, from_tables|
        # memo: アソシエーションで関連しないdependent optionを定義していた場合下記のconstantizeでクラスを呼び出し際に（ActiveRecord::Associations::Builder::Associationのprivate methodの）check_dependent_optionsでエラーになる
        to_table_associations = to_table.classify.constantize.reflect_on_all_associations
        to_table_associations.each do |to_association|
          unless from_tables.include?(to_association.name) && to_association.options.keys.include?(:dependent)
            put_recommended_dependent(to_association, to_table)
          end
        end
      end
    end

    def put_recommended_dependent(from_table, to_table)
      p "#{from_table.name}に外部キー制約がついていますが#{to_table}側の定義でdependetオプションがついていません。大丈夫ですか？"
    end
  end
end
