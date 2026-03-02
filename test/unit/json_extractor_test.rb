# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/jojo/json_extractor"

class JsonExtractorTest < JojoTest
  # -- passthrough --

  def test_returns_hash_unchanged
    input = {"key" => "value"}
    assert_equal input, Jojo::JsonExtractor.call(input)
  end

  def test_returns_array_unchanged
    input = [1, 2, 3]
    assert_equal input, Jojo::JsonExtractor.call(input)
  end

  # -- clean json --

  def test_parses_clean_json_object
    result = Jojo::JsonExtractor.call('{"name": "Alice"}')
    assert_equal({"name" => "Alice"}, result)
  end

  def test_parses_clean_json_array
    result = Jojo::JsonExtractor.call("[1, 2, 3]")
    assert_equal([1, 2, 3], result)
  end

  # -- markdown fences --

  def test_strips_json_code_fence_and_parses
    input = "```json\n{\"key\": \"value\"}\n```"
    assert_equal({"key" => "value"}, Jojo::JsonExtractor.call(input))
  end

  def test_strips_generic_code_fence_and_parses
    input = "```\n{\"key\": \"value\"}\n```"
    assert_equal({"key" => "value"}, Jojo::JsonExtractor.call(input))
  end

  def test_strips_fence_around_array
    input = "```json\n[1, 2, 3]\n```"
    assert_equal([1, 2, 3], Jojo::JsonExtractor.call(input))
  end

  # -- embedded object extraction --

  def test_extracts_object_embedded_in_prose
    input = 'Here is the result: {"score": 42} as requested.'
    assert_equal({"score" => 42}, Jojo::JsonExtractor.call(input))
  end

  def test_extracts_nested_object_embedded_in_prose
    input = 'Result: {"a": {"b": 1}} done.'
    assert_equal({"a" => {"b" => 1}}, Jojo::JsonExtractor.call(input))
  end

  # -- embedded array extraction --

  def test_extracts_array_embedded_in_prose
    input = "The indices are [1, 3, 5] for your consideration."
    assert_equal([1, 3, 5], Jojo::JsonExtractor.call(input))
  end

  def test_extracts_array_of_objects_embedded_in_prose
    input = 'Results: [{"id": 1}, {"id": 2}] end.'
    assert_equal([{"id" => 1}, {"id" => 2}], Jojo::JsonExtractor.call(input))
  end

  # -- object found before array when both present --

  def test_returns_whichever_json_structure_appears_first
    input = 'Object {"x": 1} then array [2, 3].'
    assert_equal({"x" => 1}, Jojo::JsonExtractor.call(input))
  end

  def test_returns_array_when_it_appears_before_object
    input = "Array [2, 3] then {\"x\": 1}."
    assert_equal([2, 3], Jojo::JsonExtractor.call(input))
  end

  # -- symbolize_names --

  def test_symbolize_names_on_parsed_object
    result = Jojo::JsonExtractor.call('{"name": "Alice"}', symbolize_names: true)
    assert_equal({name: "Alice"}, result)
  end

  def test_symbolize_names_on_fenced_object
    input = "```json\n{\"key\": \"value\"}\n```"
    result = Jojo::JsonExtractor.call(input, symbolize_names: true)
    assert_equal({key: "value"}, result)
  end

  def test_symbolize_names_on_extracted_object
    input = 'Prose: {"nested": {"deep": true}} end.'
    result = Jojo::JsonExtractor.call(input, symbolize_names: true)
    assert_equal({nested: {deep: true}}, result)
  end

  def test_symbolize_names_false_by_default
    result = Jojo::JsonExtractor.call('{"name": "Alice"}')
    assert result.key?("name"), "expected string keys by default"
  end

  # -- errors --

  def test_raises_when_no_json_found
    assert_raises(JSON::ParserError) do
      Jojo::JsonExtractor.call("no json here at all")
    end
  end

  def test_raises_on_empty_string
    assert_raises(JSON::ParserError) do
      Jojo::JsonExtractor.call("")
    end
  end
end
