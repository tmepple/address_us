defmodule AddressUS.Parser.CSZ do
  import AddressUS.Parser.Helpers

  # Parses the city name out of the address list and returns
  # {city, leftover_address_list}
  def get_city(address) when not is_list(address), do: {nil, nil}
  def get_city([]), do: {nil, nil}
  def get_city(address), do: get_city(address, address, nil, false)
  def get_city([], backup, _city, false), do: {nil, backup}

  def get_city(address, _backup, city, true) do
    {safe_replace(city, ",", ""), address}
  end

  def get_city(address, backup, city, false) do
    log_term({address, city}, "get_city called")
    [head | tail] = address

    tail_head =
      case length(tail) > 0 do
        false -> ""
        true -> hd(tail)
      end

    cond do
      String.contains?(head, ")") or String.contains?(head, "(") ->
        log_term("at 1")
        get_city(address, backup, city, true)

      is_sec_unit_suffix_num_or_frac?(head) && city == nil ->
        log_term("at 2")
        get_city(tail, backup, merge_names(city, head), false)

      String.ends_with?(tail_head, ",") ->
        log_term("at 3")
        get_city(tail, backup, merge_names(city, head), true)

      head |> safe_starts_with?("#") ->
        log_term("at 4")
        get_city(address, backup, city, true)

      Enum.count(clean_hyphenated_street(head)) > 1 ->
        log_term("at 5")
        get_city(address, backup, city, true)

      city != nil && !is_sec_unit_suffix_num_or_frac?(head) && address != [] &&
          is_possible_suite_number?(tail_head) ->
        log_term("at 6")
        get_city(address, backup, city, true)

      city != nil && !is_sec_unit_suffix_num_or_frac?(head) && address != [] &&
          is_highway?(head) ->
        log_term("at 6a")
        get_city(address, backup, city, true)

      city != nil && !is_sec_unit_suffix_num_or_frac?(head) && address != [] ->
        log_term("at 7")
        get_city(tail, backup, merge_names(city, head), false)

      city != nil && is_sec_unit_suffix_num_or_frac?(head) ->
        log_term("at 8")
        pre_keyword_white_list = ["SALT", "WEST", "PALM"]

        cond do
          Enum.member?(pre_keyword_white_list, tail_head) ->
            log_term("at 9")
            get_city(tail, backup, merge_names(city, head), false)

          true ->
            log_term("at 10")
            get_city(address, backup, city, true)
        end

      is_sec_unit_suffix_num_or_frac?(head) ->
        log_term("at 11")
        get_city(address, backup, city, true)

      contains_po_box?(tail) ->
        log_term("at 12")
        get_city(tail, backup, head, true)

      tail == [] ->
        log_term("at 13")
        get_city(address, backup, city, true)

      get_direction_abbreviation(head) != nil ->
        log_term("at 14")
        get_city(tail, backup, merge_names(city, head), false)

      true ->
        log_term("at 15")
        get_city(tail, backup, merge_names(city, head), false)
    end
  end

  # Gets the postal code from an address and returns
  # {zip, zip_plus_4, leftover_address_list}.
  def get_postal(address) when not is_list(address), do: {nil, nil, nil}

  def get_postal(address) do
    # The following line is now done in the caller as it's more explicit
    # reversed_address = Enum.reverse(String.split(address, " "))
    [possible_postal | leftover_address] = address
    {postal, plus_4} = parse_postal(possible_postal)

    case postal do
      nil -> {nil, nil, address}
      _ -> {postal, plus_4, leftover_address}
    end
  end

  # Parses the state from the address list and returns
  # {state, leftover_address_list}.
  def get_state(address) when not is_list(address), do: {nil, nil}
  def get_state([]), do: {nil, nil}
  def get_state(address), do: get_state(address, address, nil, 5)
  def get_state([], backup, _, count) when count > 0, do: {nil, backup}

  def get_state(address, _, state, 0) do
    {safe_replace(state, ",", ""), address}
  end

  def get_state(address, address_backup, state, count) do
    states = AddressUSConfig.states()
    [head | tail] = address
    state_to_evaluate = safe_replace(merge_names(state, head), ",", "")

    cond do
      count == 5 && Enum.member?(Map.values(states), head) ->
        get_state(tail, address_backup, head, 0)

      safe_has_key?(states, state_to_evaluate) ->
        get_state(tail, address_backup, Map.get(states, state_to_evaluate), 0)

      Enum.member?(Map.values(states), state_to_evaluate) ->
        get_state(tail, address_backup, state_to_evaluate, 0)

      count == 1 ->
        get_state(address_backup, address_backup, nil, 0)

      true ->
        get_state(tail, address_backup, state_to_evaluate, count - 1)
    end
  end

  # Parses postal value passed to it and returns {zip_code, zip_plus_4}
  def parse_postal(postal) when not is_binary(postal), do: {nil, nil}

  def parse_postal(postal) do
    cond do
      Regex.match?(~r/^\d?\d?\d?\d?\d-\d?\d?\d?\d$/, postal) ->
        [dirty_zip | tail] = String.split(postal, "-")
        [dirty_plus4 | _] = tail
        zip = dirty_zip |> safe_replace(",", "") |> String.pad_leading(5, "0")
        plus4 = dirty_plus4 |> safe_replace(",", "") |> String.pad_leading(4, "0")
        {zip, plus4}

      Regex.match?(~r/^\d?\d?\d?\d?\d$/, postal) ->
        clean_postal = postal |> String.pad_leading(5, "0") |> safe_replace(",", "")
        {clean_postal, nil}

      true ->
        {nil, nil}
    end
  end

  ############################################################################
  ## Private Functions
  ############################################################################

  # Gets direction abbreviation string.
  defp get_direction_abbreviation(val) when not is_binary(val), do: nil

  defp get_direction_abbreviation(val) do
    directions = AddressUSConfig.directions()

    cond do
      safe_has_key?(directions, val) -> Map.get(directions, val)
      Map.values(directions) |> Enum.member?(val) -> val
      true -> nil
    end
  end

  # Merges two strings into a single string and keeps the spacing correct.
  defp merge_names(nil, name2), do: name2

  defp merge_names(name1, name2) do
    direction1 = get_direction_abbreviation(hd(String.split(name1, " ")))
    direction2 = get_direction_abbreviation(name2)

    cond do
      direction1 != nil && direction2 != nil -> name2 <> name1
      name1 == nil -> name2
      true -> name2 <> " " <> name1
    end
  end
end
