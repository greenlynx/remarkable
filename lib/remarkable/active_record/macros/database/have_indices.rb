module Remarkable
  module Syntax

    module RSpec
      class HaveIndices
        def initialize(*columns)
          @columns = columns
        end

        def matches?(klass)
          @table = klass.table_name
          indices = ::ActiveRecord::Base.connection.indexes(@table).map(&:columns)

          @columns.each do |column|
            columns = [column].flatten.map(&:to_s)
            return false unless indices.include?(columns)
          end
        end

        def description
          "have index on #{@table} for #{pretty_columns}"
        end

        def failure_message
          "expected to have index on #{@table} for #{pretty_columns}, but it didn't"
        end

        def negative_failure_message
          "expected not to have index on #{@table} for #{pretty_columns}, but it did"
        end

        private

        def pretty_columns
          @columns.collect { |col| col.is_a?(Array) ? "[#{col.join(', ')}]" : col }.to_sentence
        end    
      end

      # Ensures that there are DB indices on the given columns or tuples of columns.
      # Also aliased to should_have_index for readability
      #
      #   it { User.should have_indices(:email, :name, [:commentable_type, :commentable_id]) }
      #   it { User.should have_index(:age) }
      # 
      def have_indices(*columns)
        Remarkable::Syntax::RSpec::HaveIndices.new(*columns)
      end

      alias :have_index :have_indices
    end

    module Shoulda

    end

  end
end