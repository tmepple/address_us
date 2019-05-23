defmodule AddressUS.Parser.Helpers do
  # TODO: Alphabetize functions

  require Logger

  def append_string(nil, str) do
    String.trim(str) |> String.replace_prefix("-", "")
  end

  def append_string(str1, str2) do
    String.trim(str1) <> String.trim(String.replace_prefix(str2, "-", ""))
  end

  def append_string_with_space(nil, str) do
    String.trim(str) |> String.replace_prefix("-", "")
  end

  def append_string_with_space(str1, str2) do
    (String.trim(str1) <> " " <> String.trim(String.replace_prefix(str2, "-", "")))
    |> String.trim()
  end

  def apply_casing(str, :title), do: title_case(str)

  def apply_casing(str, _), do: str

  # Cleans up hyphenated street values by removing the hyphen and returing the
  # values or the appropriate USPS abbreviations for said values in a list.

  # TODO: is this to deal with I-15 and SR-44?  If so maybe it can be modified to do
  # general string substitution for the street name field
  def clean_hyphenated_street(value) when not is_binary(value), do: [value]

  def clean_hyphenated_street(value) do
    case value |> String.match?(~r/-/) do
      true ->
        sub_data = AddressUSConfig.street_name_subs()
        subs = Map.keys(sub_data) ++ Map.values(sub_data)
        values = value |> String.split("-")
        truths = Enum.map(values, &Enum.member?(subs, &1))

        new_values =
          Enum.map(values, fn v ->
            case safe_has_key?(sub_data, v) do
              true -> Map.get(sub_data, v)
              false -> v
            end
          end)

        case Enum.any?(truths) do
          true -> new_values
          false -> [value]
        end

      false ->
        [value]
    end
  end

  # Determines if address list contains a PO Box.
  def contains_po_box?(address) when not is_list(address), do: false
  def contains_po_box?([]), do: false

  def contains_po_box?(address) do
    [head | _] = address
    full_address = address |> Enum.join(" ") |> safe_upcase
    !is_sec_unit_suffix_num_or_frac?(head) && String.match?(full_address, ~r/BOX\s/)
  end

  def is_highway?(word) when not is_binary(word), do: false

  def is_highway?(word) do
    String.contains?(word, "_")
  end

  # Determines if a value is a possible Suite value.
  def is_possible_suite_number?(value) do
    # units = AddressUSConfig.secondary_units()
    # values = Map.values(units) |> Enum.map(&String.downcase(&1))
    # keys = Map.keys(units) |> Enum.map(&String.downcase(&1))
    # (values ++ keys) |> Enum.member?(String.downcase(value))
    Enum.member?(AddressUSConfig.secondary_units_key_values(), value)
  end

  # Determines if a value is a number, fraction, or postal keyword.
  def is_sec_unit_suffix_num_or_frac?(word) when not is_binary(word), do: false

  def is_sec_unit_suffix_num_or_frac?(word) do
    units = AddressUSConfig.secondary_units()
    suffixes = AddressUSConfig.common_suffixes()
    keywords1 = Map.keys(units) ++ Map.values(units) ++ Map.values(suffixes)
    keywords2 = Map.keys(suffixes)

    cond do
      string_is_number_or_fraction?(word) -> true
      Enum.member?(keywords1, word) -> true
      Enum.member?(keywords2, word) -> true
      true -> false
    end
  end

  # Does a standard safe_upcase, unless the value to be upcased is a nil, in
  # which case it returns ""
  def safe_upcase(nil), do: ""
  def safe_upcase(value), do: String.upcase(value)

  # Does a standard safe_has_key, unless the value to be checked is a nil, in
  # which case it returns false.
  def safe_has_key?(_, nil), do: false
  def safe_has_key?(map, key), do: Map.has_key?(map, key)

  # Does a standard String.contains?, unless the value for which to search is
  # an empty string, in which case it returns false.
  def safe_contains?(_, ""), do: false
  def safe_contains?(value, k), do: String.contains?(value, k)

  # Does a standard safe_replace, unless the value to be modified is a nil in
  # which case it just returns a nil.
  def safe_replace(nil, _, _), do: nil
  def safe_replace(value, k, v), do: String.replace(value, k, v)

  def safe_replace_first_elem({nil, _, _} = tuple, _regex, _repl), do: tuple

  def safe_replace_first_elem({value, e1, e2}, regex, repl),
    do: {String.replace(value, regex, repl), e1, e2}

  # Does a standard safe_starts_with?, unless the value to be modified is a nil
  # in which case it returns false.
  def safe_starts_with?(nil, _), do: false
  def safe_starts_with?(value, k), do: String.starts_with?(value, k)

  # Capitalizes the first letter of every word in a string and returns the
  # title cased string.
  def title_case(value) when not is_binary(value), do: nil

  def title_case(value) do
    # word_endings = ["ST", "ND", "RD", "TH"]

    cap_unless_us = fn word ->
      if word in ["US", "FM", "PGA"], do: word, else: String.capitalize(word)
    end

    make_title_case = fn word ->
      # letters = safe_replace(word, ~r/\d+/, "")

      cond do
        word in ["US", "FM", "PGA"] ->
          word

        String.contains?(word, "_") ->
          String.split(word, "_") |> Enum.map(&cap_unless_us.(&1)) |> Enum.join("_")

        # Regex.match?(~r/^(\d)/, word) && Enum.member?(word_endings, letters) ->
        #   String.downcase(word)

        true ->
          String.split(word, "-")
          |> Enum.map(&String.capitalize(&1))
          |> Enum.map(&upcase_directions/1)
          |> Enum.join("-")
      end
    end

    String.split(value, " ")
    |> Enum.map(&make_title_case.(&1))
    |> Enum.join(" ")
    |> safe_replace("Po Box", "PO BOX")
  end

  # Determines if string can be cleanly converted into a number.
  def string_is_number?(value) when is_number(value), do: true
  def string_is_number?(value) when not is_binary(value), do: false

  def string_is_number?(value) do
    is_integer =
      case Integer.parse(value) do
        :error -> false
        {_, ""} -> true
        {_, _} -> false
      end

    is_float =
      case Float.parse(value) do
        :error -> false
        {_, ""} -> true
        {_, _} -> false
      end

    cond do
      is_integer -> true
      is_float -> true
      true -> false
    end
  end

  def string_starts_with_number?(value) when is_number(value), do: true
  def string_starts_with_number?(value) when not is_binary(value), do: false
  def string_starts_with_number?(value), do: string_is_number?(String.first(value))

  # Determines if value is a number or a fraction.
  def string_is_number_or_fraction?(value) when not is_binary(value), do: false

  def string_is_number_or_fraction?(value) do
    cond do
      string_is_number?(value) ->
        true

      String.match?(value, ~r/\//) ->
        values = String.split(value, "/")

        case Enum.count(values) do
          2 -> Enum.all?(values, &string_is_number?(&1))
          _ -> false
        end

      true ->
        false
    end
  end

  def string_is_fraction?(value) when not is_binary(value), do: false

  def string_is_fraction?(value) do
    cond do
      String.match?(value, ~r/\//) ->
        values = String.split(value, "/")

        case Enum.count(values) do
          2 -> Enum.all?(values, &string_is_number?(&1))
          _ -> false
        end

      true ->
        false
    end
  end

  def log_term(term \\ nil, label) do
    # Logger.debug(label <> ": " <> inspect(term))
    term
  end

  ############################################################################
  ## Private Functions
  ############################################################################

  defp upcase_directions(str) when str in ["Ne", "Nw", "Se", "Sw"], do: String.upcase(str)

  defp upcase_directions(str), do: str
end
