# frozen_string_literal: true

module Dbwatcher
  module FormattingHelper
    # Truncate cell values for display in compact view
    def truncate_cell_value(value, max_length = 50)
      return "" if value.nil?

      formatted_value = format_cell_value_simple(value)

      if formatted_value.length > max_length
        "#{formatted_value[0...max_length]}..."
      else
        formatted_value
      end
    end

    # Format cell values for display
    def format_cell_value(value)
      return "" if value.nil?

      case value
      when String
        format_string_value(value)
      when Hash, Array
        JSON.pretty_generate(value)
      when Time, DateTime
        format_datetime_value(value)
      when Date
        value.strftime("%Y-%m-%d")
      else
        value.to_s
      end
    end

    # Simple formatting for truncated display
    def format_cell_value_simple(value)
      return "" if value.nil?

      case value
      when String
        format_string_value_simple(value)
      when Hash
        format_hash_simple(value)
      when Array
        format_array_simple(value)
      when Time, DateTime
        format_datetime_value(value)
      when Date
        value.strftime("%Y-%m-%d")
      else
        value.to_s
      end
    end

    # Check if a value needs a tooltip (long content)
    def needs_tooltip?(value, max_length = 50)
      return false if value.nil?

      formatted_value = format_cell_value_simple(value)
      formatted_value.length > max_length
    end

    private

    # Format string values with JSON detection
    def format_string_value(value)
      return value unless json?(value)

      begin
        JSON.pretty_generate(JSON.parse(value))
      rescue JSON::ParserError
        value
      end
    end

    def format_string_value_simple(value)
      return value unless json?(value)

      begin
        parsed = JSON.parse(value)
        format_parsed_json_simple(parsed)
      rescue JSON::ParserError
        value
      end
    end

    def format_parsed_json_simple(parsed)
      if parsed.is_a?(Array)
        format_array_simple(parsed)
      elsif parsed.is_a?(Hash)
        format_hash_simple(parsed)
      else
        parsed.to_s
      end
    end

    def format_array_simple(array)
      "[#{array.length} items]"
    end

    def format_hash_simple(hash)
      "{#{hash.keys.length} keys}"
    end

    def format_datetime_value(value)
      value.strftime("%Y-%m-%d %H:%M:%S")
    end

    def json?(string)
      return false unless string.is_a?(String)

      string.strip.start_with?("{", "[")
    end
  end
end
