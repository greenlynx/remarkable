module Remarkable # :nodoc:
  module ActiveRecord # :nodoc:
    module Matchers # :nodoc:
      class ValidateNumericalityOfMatcher < Remarkable::Matcher::Base
        include Remarkable::ActiveRecord::Helpers

        NUMERIC_COMPARISIONS = [:equal_to, :less_than, :greater_than, :less_than_or_equal_to, :greater_than_or_equal_to]

        def initialize(*attributes)
          load_options(attributes.extract_options!)
          @attributes = attributes
        end

        def only_integer(value = true)
          @options[:only_integer] = value
          self
        end

        def odd(value = true)
          @options[:odd] = value
          self
        end

        def even(value = true)
          @options[:even] = value
          self
        end

        def equal_to(value)
          @options[:equal_to] = value
          self
        end

        def less_than(value)
          @options[:less_than] = value
          self
        end

        def greater_than(value)
          @options[:greater_than] = value
          self
        end

        def less_than_or_equal_to(value)
          @options[:less_than_or_equal_to] = value
          self
        end

        def greater_than_or_equal_to(value)
          @options[:greater_than_or_equal_to] = value
          self
        end

        def matches?(subject)
          @subject = subject

          assert_matcher_for(@attributes) do |attribute|
            @attribute = attribute

            only_allow_numeric_values? && allow_blank? && allow_nil? &&
            only_integer? && allow_odd? && allow_even? && equal_to?(:equal_to) &&
            equal_to?(:less_than, -1) && equal_to?(:greater_than, +1) &&
            equal_to?(:less_than_or_equal_to) && equal_to?(:greater_than_or_equal_to) &&
            more_than_maximum?(:equal_to, +1) && less_than_minimum?(:equal_to, -1) &&
            more_than_maximum?(:less_than) && less_than_minimum?(:greater_than) &&
            more_than_maximum?(:less_than_or_equal_to, +1) && less_than_minimum?(:greater_than_or_equal_to, -1)
          end
        end

        def description
          default_message + "values for #{@attributes.to_sentence}"
        end

        private

        def only_allow_numeric_values?
          return true if bad?("abcd")

          @missing = "allow non-numeric values for #{@attribute}"
          false
        end

        def only_integer?
          message = "allow non-integer values for #{@attribute}"
          assert_bad_or_good_if_key(:only_integer, valid_value_for_test.to_f, message)
        end

        def allow_even?
          message = "allow even values for #{@attribute}"
          assert_bad_or_good_if_key(:even, valid_value_for_test + 1, message, :even_message)
        end

        def allow_odd?
          message = "allow odd values for #{@attribute}"
          assert_bad_or_good_if_key(:odd, even_valid_value_for_test, message, :odd_message)
        end

        def equal_to?(key, add = 0)
          return true unless @options.key?(key)
          return true if good?(@options[key] + add, :"#{key}_message", @options[key])

          @missing = "not allow value equals to #{@options[key]} for #{@attribute}"
          false
        end

        def more_than_maximum?(key, add = 0)
          return true unless @options.key?(key)
          return true if bad?(@options[key] + add, :"#{key}_message", @options[key])

          @missing = "allow value #{@options[key] + add} which is more than #{@options[key]} for #{@attribute}"
          false
        end

        def less_than_minimum?(key, add = 0)
          return true unless @options.key?(key)
          return true if bad?(@options[key] + add, :"#{key}_message", @options[key])

          @missing = "allow value #{@options[key] + add} which is less than #{@options[key]} for #{@attribute}"
          false
        end

        # Returns a valid value for test.
        #
        def valid_value_for_test
          value = @options[:equal_to] || @options[:less_than_or_equal_to] || @options[:greater_than_or_equal_to]

          value ||= @options[:less_than].pred    if @options[:less_than]
          value ||= @options[:greater_than].next if @options[:greater_than]

          value ||= 10

          if @options[:even]
            value = (value / 2) * 2
          elsif @options[:odd]
            value = ((value / 2) * 2) + 1
          end

          value
        end

        # Returns a valid even value for test.
        # The method valid_value_for_test checks for :even option but does not
        # return necessarily an even value
        #
        def even_valid_value_for_test
          (valid_value_for_test / 2) * 2
        end

        def load_options(options = {})
          @options = {
            :message => :not_a_number,
            :odd_message => :odd,
            :even_message => :even
          }.merge(options)

          NUMERIC_COMPARISIONS.map do |key|
            @options[:"#{key}_message"] = key
          end
        end

        def expectation
          default_message + "values for #{@attribute}"
        end

        def default_message
          message = "only allow "
          message << "even " if @options[:even]
          message << "odd "  if @options[:odd]

          message << NUMERIC_COMPARISIONS.map do |key|
            @options[key] ? "#{key.to_s.gsub('_', ' ')} #{@options[key]} " : nil
          end.compact.join('or ')

          message << (@options[:only_integer] ? "integer " : "numeric ")
          message << "or nil "   if @options[:allow_nil]
          message << "or blank " if @options[:allow_blank]
          message
        end
      end

      # Ensures that the given attributes accepts only numbers.
      #
      # If an instance variable has been created in the setup named after the
      # model being tested, then this method will use that. Otherwise, it will
      # create a new instance to test against.
      #
      # Options:
      #
      # * <tt>:only_integer</tt> - when supplied, checks if it accepts only integers or not
      # * <tt>:odd</tt> - when supplied, checks if it accepts only odd values or not
      # * <tt>:even</tt> - when supplied, checks if it accepts only even values or not
      # * <tt>:equal_to</tt> - when supplied, checks if attributes are only valid when equal to given value
      # * <tt>:less_than</tt> - when supplied, checks if attributes are only valid when less than given value
      # * <tt>:greater_than</tt> - when supplied, checks if attributes are only valid when greater than given value
      # * <tt>:less_than_or_equal_to</tt> - when supplied, checks if attributes are only valid when less than or equal to given value
      # * <tt>:greater_than_or_equal_to</tt> - when supplied, checks if attributes are only valid when greater than or equal to given value
      # * <tt>:message</tt> - value the test expects to find in <tt>errors.on(:attribute)</tt>.
      #   Regexp, string or symbol. Default = <tt>I18n.translate('activerecord.errors.messages.not_a_number')</tt>
      #
      # Example:
      #
      #   it { should validates_numericality_of(:age, :price) }
      #   it { should validates_numericality_of(:age, :only_integer => true) }
      #   it { should validates_numericality_of(:price, :only_integer => false) }
      #   it { should validates_numericality_of(:age).only_integer }
      #
      #   it { should validates_numericality_of(:age).odd }
      #   it { should validates_numericality_of(:age).even }
      #   it { should validates_numericality_of(:age, :odd => true) }
      #   it { should validates_numericality_of(:age, :even => true) }
      #
      def validate_numericality_of(*attributes)
        ValidateNumericalityOfMatcher.new(*attributes)
      end
      alias :only_allow_numeric_values_for :validate_numericality_of

      # TODO Deprecate this method and say that it has to be changed to:
      #
      #   validate_numericality_of :attribute, :allow_blank => true
      #
      def only_allow_numeric_or_blank_values_for(*attributes)
        ValidateNumericalityOfMatcher.new(*attributes).allow_blank
      end
    end
  end
end
