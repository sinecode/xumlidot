require 'sexp_processor'
require 'pry'

require_relative '../types'

module Xamin
  module Parsers
    # Parser for the KLASS DEFINITION ONLY
    #
    # The main parser will handle method,
    # constants, etc
    class Klass < MethodBasedSexpProcessor
      def initialize(exp, namespace = nil)
        super()

        @exp = exp

        @_klass = ::Xamin::Types::Klass.new
        @_klass.namespace = namespace
      end

      def to_s
        process(@exp)
        @_klass.to_s
      end

      def process_class(exp)
        exp.shift # remove :class
        definition = exp.shift

        # Processes the name of the class
        if Sexp === definition
          case definition.sexp_type
          when :colon2 then # Reached in the event that a name is a compound
            name = definition.flatten
            name.delete :const
            name.delete :colon2
            name.each { |v| @_klass.name << v.to_s }
          when :colon3 then # Reached in the event that a name begins with ::
            @_klass.name << "::#{definition.last}"
          else
            raise "unknown type #{exp.inspect}"
          end
        else Symbol === definition
          #if we have a symbol we have the actual class name
          # e.g. class Foo; end
          @_klass.name << definition.to_s
        end

        # Processess inheritance
        process_until_empty(exp)

        s()
      end

      def process_const(exp)
        @_klass.superklass << exp.value.to_s
        process_until_empty(exp)
        s()
      end

      def process_colon2(exp)
        exp.shift # remove :colon2
        @_klass.superklass << exp.value.to_s
        process_until_empty(exp)
        s()
      end

      def process_colon3(exp)
        exp.shift # remove :colon3
        @_klass.superklass << "::#{exp.value}"
        process_until_empty(exp)
        s()
      end
    end
  end
end