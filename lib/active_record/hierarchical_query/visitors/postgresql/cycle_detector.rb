module ActiveRecord
  module HierarchicalQuery
    module Visitors
      module PostgreSQL
        class CycleDetector < Visitor
          COLUMN_NAME = '__path'.freeze

          def visit_non_recursive(arel)
            if enabled?
              arel.project Arel::Nodes::PostgresArray.new([primary_key]).as(column_name)
            end

            arel
          end

          def visit_recursive(arel)
            if enabled?
              arel.project Arel::Nodes::ArrayConcat.new(parent_column, primary_key)
              arel.constraints << Arel::Nodes::Not.new(primary_key.eq(any(parent_column)))
            end

            arel
          end

          private
          def enabled?
            builder.nocycle_value
          end

          def column_name
            COLUMN_NAME
          end

          def parent_column
            query.recursive_table[column_name]
          end

          def primary_key
            table[klass.primary_key]
          end

          def any(argument)
            Arel::Nodes::NamedFunction.new('ANY', [argument])
          end
        end
      end
    end
  end
end