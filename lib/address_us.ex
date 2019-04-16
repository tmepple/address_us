defmodule Address do
  @moduledoc """
  Container for the struct that contains the Address information.
  """

  @doc """
  Struct containing Address information.
  """
  defstruct city: nil, plus_4: nil, street: nil, state: nil, postal: nil
end

defmodule Street do
  @moduledoc """
  Container for the struct that contains the Street information for an address.
  """

  @doc """
  Struct containing the Street information.
  """
  defstruct name: nil,
            pmb: nil,
            pre_direction: nil,
            primary_number: nil,
            post_direction: nil,
            secondary_designator: nil,
            secondary_value: nil,
            suffix: nil,
            additional_designation: nil
end

defmodule AddressUS.Parser do
  @moduledoc """
  Parses US Addresses.
  """

  @doc """
  Parses a raw address into all of its requisite parts according to USPS
  suggestions for address parsing.
  ## Known Bugs
      1) if street suffix is left off while parsing a full multi-line address,
      it will fail unless there is a comma or newline separating the street
      name from the city.
  ## Examples
      iex> AddressUS.Parser.parse_address("2345 S B Street, Denver, CO 80219")
      %Address{city: "Denver", plus_4: nil, postal: "80219",
      state: "CO", street: %Street{name: "B", pmb: nil,
      post_direction: nil, pre_direction: "S", primary_number: "2345",
      secondary_designator: nil, secondary_value: nil, suffix: "St"}}
  """

  require Logger

  def parse_address(messy_address) when not is_binary(messy_address), do: nil

  def parse_address(messy_address) do
    address = standardize_address(messy_address)
    log_term(address, "std addr")
    {postal, plus_4, address_no_postal} = get_postal(address)
    {state, address_no_state} = get_state(address_no_postal)
    {city, address_no_city} = get_city(address_no_state)
    street = parse_address_list(address_no_city, state)

    %Address{postal: postal, plus_4: plus_4, state: state, city: city, street: street}
  end

  @doc """
  Parses the raw street portion of an address into its requisite parts
  according to USPS suggestions for address parsing.
  ## Examples
      iex> AddressUS.Parser.parse_address_line("2345 S. Beade St")
      %Street{name: "Beade", pmb: nil, post_direction: nil, pre_direction: "S",
      primary_number: "2345", secondary_designator: nil, secondary_value: nil,
      suffix: "St"}
  """
  def parse_address_line(invalid) when not is_binary(invalid), do: nil

  def parse_address_line(messy_address, state \\ "") do
    messy_address
    |> standardize_address
    |> log_term("std addr")
    |> String.split(" ")
    |> Enum.reverse()
    |> parse_address_list(state)
  end

  @doc """
  Standardizes the raw street portion of an address according to USPS suggestions for
  address parsing.  If given a state will apply custom standardizations (if they exist) for that state 
  """
  def standardize_address_line(messy_address, state \\ "")

  def standardize_address_line(messy_address, _state) when not is_binary(messy_address), do: nil

  def standardize_address_line(messy_address, state) do
    messy_address
    |> standardize_address()
    |> standardize_highways(state)
    |> safe_replace("_", " ")
    |> title_case()
  end

  @doc """
  Given a messy address line, returns it standardized and cleaned.  If there is no valid street number
  or if an intersection is given it will only standardize the address, otherwise it will first parse
  the address to standardize directionals, suffixes, and separate additional information.
  """
  def clean_address_line(messy_address, state \\ "", opts \\ [])

  def clean_address_line(messy_address, _state, _opts) when not is_binary(messy_address), do: ""

  def clean_address_line(messy_address, state, opts) do
    {upcase?, opts} = Keyword.pop(opts, :upcase, true)

    # NOTE: Check for WI explicitly to avoid every address in the country to face expensive regex
    # TODO: Benchmark
    valid_number? =
      if state == "WI" do
        Regex.match?(~r/^(\d+|[NEWS]\d+[NEWS]\d+\s|[NEWS]\d+\s)/, messy_address)
      else
        Regex.match?(~r/^\d+/, messy_address)
      end

    ret_val =
      if not valid_number? do
        standardize_address_line(messy_address, state)
      else
        possible_intersection? =
          Regex.match?(~r/(\&|\sAND\s|\sAT\s|\@|\D\/|\/\D)/i, messy_address)

        if possible_intersection?,
          do: standardize_address_line(messy_address, state),
          else: parse_address_line_fmt(messy_address, state, opts)
      end

    if upcase?, do: String.upcase(ret_val), else: ret_val
  end

  # CONSIDER: make this private and remove upper case opt since it's always called from clean_address_line anyway
  def parse_address_line_fmt(messy_address, _state) when not is_binary(messy_address), do: nil

  def parse_address_line_fmt(messy_address, state \\ "", opts \\ []) do
    upcase? = Keyword.get(opts, :upcase, true)
    fmt_opt = Keyword.get(opts, :additional, :newline)

    addr = parse_address_line(messy_address, state)

    prim_line =
      [addr.primary_number, addr.pre_direction, addr.name, addr.suffix, addr.post_direction]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")
      |> String.trim()

    sec_line =
      [addr.pmb, addr.secondary_designator, addr.secondary_value, addr.additional_designation]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")
      |> String.trim()

    ret =
      case {fmt_opt, sec_line} do
        {_ad, sl} when sl == "" -> prim_line
        {:newline, _sl} -> prim_line <> "\n" <> sec_line
        {_parens, _sl} -> prim_line <> " (" <> sec_line <> ")"
      end

    if upcase?, do: String.upcase(ret), else: ret
  end

  @doc """
  Removes non-numeric characters from the phone number and then returns the
  integer.
  ## Examples
      iex> AddressUS.Parser.clean_phone_number("(303) 310-7802")
      3033107802
  """
  def clean_phone_number(nil), do: nil

  def clean_phone_number(phone) do
    {phone_integer, _} =
      phone
      |> safe_replace(~r/\s+/, "")
      |> safe_replace("+1", "")
      |> safe_replace("-", "")
      |> safe_replace("(", "")
      |> safe_replace(")", "")
      |> Integer.parse()

    phone_integer
  end

  @doc """
  Removes country code and associated punctuation from the phone number.
  ## Examples
      iex> AddressUS.Parser.filter_country_code("+1 303-310-7802")
      "303-310-7802"
      iex> AddressUS.Parser.filter_country_code("+1 (303) 310-7802")
      "(303) 310-7802"
      iex> AddressUS.Parser.filter_country_code("+1-303-310-7802")
      "303-310-7802"
      iex> AddressUS.Parser.filter_country_code("1-303-310-7802")
      "303-310-7802"
  """
  def filter_country_code(nil), do: nil

  def filter_country_code(phone) do
    phone
    |> safe_replace(~r/^1\s+|^1-|^\+1\s+|^\+1-/, "")
    |> safe_replace(~r/^1\(|^1\s+\(/, "(")
    |> safe_replace(~r/\)(\d)/, ") \\1")
  end

  @doc """
  Abbreviates the state provided.
  ## Example
      iex> AddressUS.Parser.abbreviate_state("Wyoming")
      "WY"
      iex> AddressUS.Parser.abbreviate_state("wyoming")
      "WY"
      iex> AddressUS.Parser.abbreviate_state("Wyomin")
      "Wyomin"
      iex> AddressUS.Parser.abbreviate_state(nil)
      nil
  """
  def abbreviate_state(nil), do: nil

  def abbreviate_state(raw_state) do
    state = title_case(raw_state)

    states = AddressUSConfig.states()

    cond do
      safe_has_key?(states, state) == true ->
        Map.get(states, state)

      Enum.member?(Map.values(states), safe_upcase(state)) == true ->
        safe_upcase(state)

      true ->
        state
    end
  end

  @doc """
  Converts the country to the 2 digit ISO country code.  "US" is default.
  ## Example
      iex> AddressUS.Parser.get_country_code(nil)
      "US"
      iex> AddressUS.Parser.get_country_code("Afghanistan")
      "AF"
      iex> AddressUS.Parser.get_country_code("AF")
      "AF"
  """
  def get_country_code(nil), do: "US"

  def get_country_code(country_name) do
    codes = AddressUSConfig.countries()
    country = safe_upcase(country_name)

    case Enum.member?(Map.values(codes), country) do
      true -> country
      false -> Map.get(codes, country, country_name)
    end
  end

  @doc """
  Parses a csv, but instead of parsing at every comma, it only splits at the
  last one found.  This allows it to handle situations where the first value
  parsed has a comma in it that is not part of what you want to parse.
  ## Example
      iex> AddressUS.Parser.parse_csv("test/test.csv")
      %{"Something Horrible, (The worst place other than Wyoming)" => "SH",
      "Wyoming" => "WY"}
  """
  def parse_csv(nil), do: %{}

  def parse_csv(csv) do
    String.split(File.read!(csv), ~r{\n|\r|\r\n|\n\r})
    |> Stream.map(&String.reverse(&1))
    |> Stream.map(&String.split(&1, ",", parts: 2))
    |> Stream.map(&Enum.reverse(&1))
    |> Stream.map(fn word -> Enum.map(word, &String.reverse(&1)) end)
    |> Stream.map(&List.to_tuple(&1))
    |> Stream.filter(&(tuple_size(&1) == 2))
    |> Enum.to_list()
    |> Enum.into(%{})
  end

  ############################################################################
  ## Parser Functions
  ############################################################################

  # Parses the city name out of the address list and returns
  # {city, leftover_address_list}
  defp get_city(address) when not is_list(address), do: {nil, nil}
  defp get_city([]), do: {nil, nil}
  defp get_city(address), do: get_city(address, address, nil, false)
  defp get_city([], backup, _city, false), do: {nil, backup}

  defp get_city(address, _backup, city, true) do
    {safe_replace(title_case(city), ",", ""), address}
  end

  defp get_city(address, backup, city, false) do
    log_term({address, city}, "get_city called")
    [head | tail] = address

    tail_head =
      case length(tail) > 0 do
        false -> ""
        true -> hd(tail)
      end

    cond do
      String.contains?(head, ")") or String.contains?(head, "(") ->
        get_city(address, backup, city, true)

      is_sec_unit_suffix_num_or_frac?(head) && city == nil ->
        get_city(tail, backup, merge_names(city, head), false)

      String.ends_with?(tail_head, ",") ->
        get_city(tail, backup, merge_names(city, head), true)

      head |> safe_starts_with?("#") ->
        get_city(address, backup, city, true)

      Enum.count(clean_hyphenated_street(head)) > 1 ->
        get_city(address, backup, city, true)

      city != nil && !is_sec_unit_suffix_num_or_frac?(head) && address != [] &&
          is_possible_suite_number?(tail_head) ->
        get_city(address, backup, city, true)

      city != nil && !is_sec_unit_suffix_num_or_frac?(head) && address != [] ->
        get_city(tail, backup, merge_names(city, head), false)

      city != nil && is_sec_unit_suffix_num_or_frac?(head) ->
        pre_keyword_white_list = ["SALT", "WEST", "PALM"]

        cond do
          Enum.member?(pre_keyword_white_list, safe_upcase(tail_head)) ->
            get_city(tail, backup, merge_names(city, head), false)

          true ->
            get_city(address, backup, city, true)
        end

      is_sec_unit_suffix_num_or_frac?(head) ->
        get_city(address, backup, city, true)

      contains_po_box?(tail) ->
        get_city(tail, backup, head, true)

      tail == [] ->
        get_city(address, backup, city, true)

      get_direction_abbreviation(head) != nil ->
        get_city(tail, backup, merge_names(city, head), false)

      true ->
        get_city(tail, backup, merge_names(city, head), false)
    end
  end

  # Parses the number out of the address list and returns
  # {number, box, possible_secondary_value, possible_secondary_designator}
  defp get_number(address) when not is_list(address) do
    {nil, nil, nil, nil, nil}
  end

  defp get_number([]), do: {nil, nil, nil, nil, nil}

  defp get_number(address) do
    get_number(address, address, nil, nil, nil, nil, false)
  end

  defp get_number(address, _backup, number, box, p_val, p_des, true) do
    n = if number == "", do: nil, else: number
    b = if box == "", do: nil, else: box
    v = if p_val == "", do: nil, else: p_val
    d = if p_des == "", do: nil, else: p_des
    {n, b, v, d, address}
  end

  defp get_number([], backup, _, _, _, _, false) do
    {nil, nil, nil, nil, backup}
  end

  defp get_number(address, backup, number, box, p_val, p_des, false) do
    [head | tail] = address

    {tail_head, tail_tail} =
      case length(tail) do
        0 -> {"", []}
        1 -> {hd(tail), []}
        _ -> {hd(tail), tl(tail)}
      end

    tail_tail_head = if length(tail_tail) > 0, do: hd(tail_tail), else: nil

    # next_is_number =
    #   if length(tail) == 0 do
    #     false
    #   else
    #     string_is_number_or_fraction?(hd(tail))
    #   end

    next_is_fraction =
      if length(tail) == 0 do
        false
      else
        string_is_fraction?(hd(tail))
      end

    regex = ~r/(\d+)[-\s]*([A-Za-z]+.*)/

    cond do
      address == [] ->
        get_number(backup, backup, number, box, p_val, p_des, true)

      contains_po_box?(address) ->
        number =
          address
          |> Enum.join(" ")
          |> String.split(~r/(?i)BOX\s/)
          |> tl
          |> hd

        get_number([], backup, safe_replace(number, "#", ""), "PO BOX", p_val, p_des, true)

      # If we have an address like "250 200 N" the "200 N" is really the street name.  Only if the
      # second number is a fraction do we want to keep it in the number.
      # number == nil && string_is_number_or_fraction?(head) && next_is_number ->
      #   get_number(tl(tail), backup, head <> " " <> hd(tail), box, p_val, p_des, true)

      number == nil && string_is_number_or_fraction?(head) && next_is_fraction ->
        get_number(tl(tail), backup, head <> " " <> hd(tail), box, p_val, p_des, true)

      Enum.member?(address, "&") ->
        new_address =
          address
          |> Enum.join(" ")
          |> String.split("&")
          |> tl()
          |> hd()
          |> String.split(" ")

        get_number(new_address, backup, nil, box, p_val, p_des, false)

      number == nil && string_is_number_or_fraction?(head) ->
        alphanumeric = "ABCDFHIJLKMOPQRGTUVXYZ1234567890"

        case safe_contains?(alphanumeric, safe_upcase(tail_head)) do
          false ->
            get_number(tail, backup, head, box, p_val, p_des, true)

          true ->
            # If the term after the number is a single alphanumeric then check to see if the term after that is
            # a valid suffix (i.e. 4400 A Avenue) before assuming it's a secondary_value
            if get_suffix_value(tail_tail_head),
              do: get_number(tail, backup, head, box, p_val, p_des, true),
              else: get_number(tail_tail, backup, head, box, safe_upcase(tail_head), p_des, true)
        end

      number == nil && string_is_number_or_fraction?(safe_replace(head, regex, "\\1")) ->
        endings = ["ST", "ND", "RD", "TH"]
        new_number = safe_replace(head, regex, "\\1")
        new_value = safe_replace(head, regex, "\\2")

        case Enum.member?(endings, new_value) do
          false ->
            get_number(tail, backup, new_number, box, new_value, p_des, true)

          true ->
            get_number(backup, backup, number, box, new_value, p_des, true)
        end

      number == nil && is_state?(head) ->
        get_number(address, backup, number, box, p_val, p_des, true)

      # If there is a dash in the number, just return the whole thing including the dash
      # It might be an address range (i.e. 101-102 E Washington) or it could be a valid Brooklyn-style address
      # (59-36 Cooper Ave, Glendale, NY 11385)
      safe_contains?(head, "-") ->
        # [h | t] = String.split("-")

        # secondary_value =
        #   case length(t) do
        #     0 -> nil
        #     _ -> hd(tail)
        #   end

        # get_number(tail, backup, h, box, secondary_value, "Ste", true)
        get_number(tail, backup, head, box, p_val, p_des, true)

      true ->
        get_number(tail, backup, number, box, p_val, p_des, false)
    end
  end

  # Parses the post direction field out of the address list and returns
  # {post_direction, leftover_address_list}.
  defp get_post_direction(address) when not is_list(address), do: {nil, nil, nil, nil}
  defp get_post_direction([]), do: {nil, nil, nil, nil}
  defp get_post_direction(address), do: get_post_direction(address, address, nil, nil, false)

  defp get_post_direction(address, _backup, post_direction, raw_pd, true) do
    {post_direction, raw_pd, address}
  end

  defp get_post_direction(address, backup, post_direction, raw_pd, false) do
    log_term({address, post_direction}, "get_post_direction_internals")

    [head | tail] = address

    address_length = length(address)

    {tail_head, _tail_tail} =
      case length(tail) do
        0 -> {"", []}
        1 -> {hd(tail), []}
        _ -> {hd(tail), tl(tail)}
      end

    ## NOTE: This may parse addresses like "County Hwy 3N" wrong.
    detect_attached_post_direction = Regex.run(~r/^\d+([a-zA-Z])$/, head)

    attached_post_direction =
      if detect_attached_post_direction,
        do: get_direction_value(List.last(detect_attached_post_direction)),
        else: nil

    attached_post_direction =
      if attached_post_direction == "", do: nil, else: attached_post_direction

    direction_value = get_direction_value(head)

    new_direction =
      case post_direction == nil do
        true -> direction_value
        false -> direction_value <> post_direction
      end

    log_term({head, direction_value, new_direction, post_direction, address, tail}, "before cond")

    cond do
      attached_post_direction ->
        get_post_direction(
          [attached_post_direction | [String.slice(head, 0..-2) | tail]],
          backup,
          post_direction,
          append_string(raw_pd, head),
          false
        )

      # Handle address like "1404 W Avenue E"
      get_suffix_value(head) == "Ave" &&
          (get_direction_value(tail_head) != "" or string_is_number_or_fraction?(tail_head)) ->
        get_post_direction(backup, backup, nil, title_case(raw_pd), true)

      # If there is only one term left (an address number) then we likely were too aggressive about
      # and we are not dealing with a post_direction anyway i.e. "101 W North" 
      address_length == 1 ->
        get_post_direction(backup, backup, nil, title_case(raw_pd), true)

      get_direction_value(head) == "" ->
        get_post_direction(address, backup, post_direction, title_case(raw_pd), true)

      true ->
        get_post_direction(tail, backup, new_direction, append_string(raw_pd, head), false)
    end
  end

  # Gets the postal code from an address and returns
  # {zip, zip_plus_4, leftover_address_list}.
  defp get_postal(address) when not is_binary(address), do: {nil, nil, nil}

  defp get_postal(address) do
    reversed_address = Enum.reverse(String.split(address, " "))
    [possible_postal | leftover_address] = reversed_address
    {postal, plus_4} = parse_postal(possible_postal)

    case postal do
      nil -> {nil, nil, reversed_address}
      _ -> {postal, plus_4, leftover_address}
    end
  end

  # Parses the pre direction field out of the address list and returns
  # {pre_direction, leftover_address_list}.
  defp get_pre_direction(address) when not is_list(address), do: {nil, nil, nil}
  defp get_pre_direction([]), do: {nil, nil, nil}
  defp get_pre_direction(address), do: get_pre_direction(address, nil, false)

  defp get_pre_direction(address, _pre_direction, false) do
    [head | tail] = address

    {tail_head, tail_tail} =
      case length(tail) do
        0 -> {"", []}
        1 -> {hd(tail), []}
        _ -> {hd(tail), tl(tail)}
      end

    tail_tail_head = if length(tail_tail) > 0, do: hd(tail_tail), else: nil
    single_word_direction = get_direction_value(head)
    next_is_direction = get_direction_value(tail_head) != ""

    double_word_direction =
      get_direction_value(get_direction_value(head) <> get_direction_value(tail_head))

    tail_tail_head_is_keyword = is_sec_unit_suffix_num_or_frac?(tail_tail_head)

    log_term({single_word_direction, next_is_direction, tail}, "get_pre_direction internals")

    cond do
      single_word_direction != "" && next_is_direction &&
          tail_tail_head_is_keyword ->
        IO.puts("at 1")
        {single_word_direction, title_case(head), tail}

      single_word_direction != "" && next_is_direction &&
          tail_tail_head == nil ->
        IO.puts("at 2")

        {single_word_direction, title_case(head), tail}

      single_word_direction != "" && next_is_direction &&
        !tail_tail_head_is_keyword && double_word_direction != "" ->
        IO.puts("at 3")

        {double_word_direction, title_case(head <> tail_head), tail_tail}

      # Following case happens with an illegal double direction (i.e. W N Michigan Rd)
      # Since it's an illegal direction we punt so these terms are pre-pended to the street name
      single_word_direction != "" && next_is_direction &&
          !tail_tail_head_is_keyword ->
        IO.puts("at 4")
        {nil, nil, address}

      # single_word_direction != "" && tail == [] ->
      #   {nil, address}

      single_word_direction != "" ->
        IO.puts("at 5")

        {single_word_direction, title_case(head), tail}

      true ->
        {nil, nil, address}
    end
  end

  # Parses out the secondary data from an address field and returns
  # {secondary_designator, secondary_value, private_mailbox_number,
  # leftover_address_list, additional}
  defp get_secondary(address, _addit) when not is_list(address), do: {nil, nil, nil, nil, []}
  defp get_secondary([], additional), do: {nil, nil, nil, additional, []}

  defp get_secondary(address, addit) do
    get_secondary(address, address, nil, nil, nil, addit, false)
  end

  defp get_secondary([], backup, _pmb, _designator, _number, addit, false) do
    {nil, nil, nil, addit, backup}
  end

  defp get_secondary(address, _backup, pmb, designator, value, addit, true) do
    [_ | tail] = address

    cond do
      value == nil && pmb != nil ->
        clean_designator = safe_replace(designator, ",", "")
        clean_pmb = safe_replace(pmb, ",", "")
        {clean_designator, nil, clean_pmb, addit, tail}

      true ->
        clean_designator = safe_replace(designator, ",", "")
        clean_value = safe_replace(value, ",", "")
        clean_pmb = safe_replace(pmb, ",", "")
        {clean_designator, clean_value, clean_pmb, addit, address}
    end
  end

  defp get_secondary(address, backup, pmb, designator, value, addit, false) do
    log_term({address, pmb, designator, value}, "get_secondary_internals")
    [head | tail] = address

    {tail_head, tail_tail} =
      case length(tail) do
        0 -> {"", []}
        1 -> {hd(tail), []}
        _ -> {hd(tail), tl(tail)}
      end

    units = AddressUSConfig.secondary_units()
    suffixes = AddressUSConfig.common_suffixes()
    directions = AddressUSConfig.directions()

    cond do
      string_is_number?(head) or string_starts_with_number?(head) ->
        cond do
          # NOTE: Unsure what this code does as all existing tests run without it and it caused Box parsing issues
          # contains_po_box?(tail) || is_state?(tail_head) ->
          #   Logger.debug("at 1")
          #   IO.inspect(backup, label: "at 1")
          #   get_secondary(tail, backup, pmb, designator, value, addit, false)

          tail_head == '&' ->
            Logger.debug("at 2")

            get_secondary(
              tail_tail,
              backup,
              pmb,
              designator,
              tail_head <> " " <> head,
              addit,
              false
            )

          safe_starts_with?(value, "&") ->
            Logger.debug("at 3")
            get_secondary(tail, backup, pmb, designator, head, addit, false)

          tail_head == "#" ->
            Logger.debug("at 4")
            get_secondary(tail_tail, backup, pmb, designator, head, addit, false)

          true ->
            Logger.debug("at 5")
            get_secondary(tail, backup, pmb, designator, head, addit, false)
        end

      safe_has_key?(units, title_case(head)) ->
        cond do
          safe_has_key?(suffixes, safe_upcase(value)) ->
            Logger.debug("at 6")
            get_secondary(backup, backup, nil, nil, nil, addit, true)

          value ->
            Logger.debug("at 6a")
            get_secondary(tail, backup, pmb, Map.get(units, title_case(head)), value, addit, true)

          # For the secondary parsing to work when a valid Unit is provided we need to have a value
          true ->
            Logger.debug("at 7")
            get_secondary(backup, backup, nil, nil, nil, addit, true)
        end

      value && Map.values(units) |> Enum.member?(title_case(head)) ->
        Logger.debug("at 8")
        get_secondary(tail, backup, pmb, title_case(head), value, addit, true)

      safe_starts_with?(head, "#") && !contains_po_box?(address) ->
        all_unit_values = Map.keys(units) ++ Map.values(units)

        cond do
          # TODO: Other highway selectors belong here - but with risk of false positives
          # plan to add as real cases appear
          Enum.member?(["Rt"], title_case(tail_head)) ->
            get_secondary(backup, backup, pmb, designator, nil, addit, true)

          Enum.member?(all_unit_values, title_case(tail_head)) ->
            secondary_unit =
              cond do
                Map.values(units) |> Enum.member?(title_case(tail_head)) ->
                  title_case(tail_head)

                true ->
                  Map.get(units, title_case(tail_head))
              end

            Logger.debug("at 9")

            get_secondary(
              tail_tail,
              backup,
              pmb,
              secondary_unit,
              safe_replace(head, "#", ""),
              addit,
              true
            )

          true ->
            Logger.debug("at 10")

            get_secondary(
              tail,
              backup,
              safe_replace(head, "#", ""),
              designator,
              value,
              addit,
              false
            )
        end

      value != nil && designator == nil ->
        all_unit_values = Map.keys(units) ++ Map.values(units)

        cond do
          Enum.member?(all_unit_values, title_case(tail_head)) ->
            secondary_unit =
              cond do
                Map.values(units) |> Enum.member?(title_case(tail_head)) ->
                  title_case(tail_head)

                true ->
                  Map.get(units, title_case(tail_head))
              end

            Logger.debug("at 11")
            get_secondary(tail_tail, backup, pmb, secondary_unit, head <> value, addit, true)

          Enum.member?(all_unit_values, title_case(head)) ->
            secondary_unit =
              cond do
                Map.values(units) |> Enum.member?(title_case(head)) ->
                  title_case(head)

                true ->
                  Map.get(units, title_case(head))
              end

            Logger.debug("at 12")
            get_secondary(tail, backup, pmb, secondary_unit, value, addit, true)

          true ->
            Logger.debug("at 13")
            get_secondary(backup, backup, pmb, designator, nil, addit, true)
        end

      is_possible_suite_number?(tail_head) &&
          (safe_has_key?(units, title_case(tail_head)) ||
             Map.values(units) |> Enum.member?(title_case(tail_head))) ->
        Logger.debug("at 14")

        get_secondary(tail, backup, pmb, designator, safe_replace(head, ",", ""), addit, false)

      get_suffix_value(tail_head) != nil && get_suffix_value(head) == nil ->
        cond do
          is_possible_suite_number?(head) &&
              (String.length(tail_tail) < 2 ||
                 String.upcase(hd(tail_tail)) == "STATE") ->
            Logger.debug("at 15")
            IO.inspect(backup, label: "at 15")
            get_secondary(backup, backup, pmb, designator, value, addit, true)

          Map.values(directions) |> Enum.member?(safe_upcase(head)) ||
              safe_has_key?(directions, title_case(head)) ->
            Logger.debug("at 16")
            IO.inspect(backup, label: "at 16")
            get_secondary(backup, backup, pmb, designator, value, addit, true)

          # Handle "1400 W Avenue B"
          get_suffix_value(tail_head) == "Ave" && String.length(head) == 1 ->
            Logger.debug("at 16a")
            IO.inspect(backup, label: "at 16a")
            get_secondary(backup, backup, pmb, designator, value, addit, true)

          true ->
            Logger.debug("at 17")
            IO.inspect(backup, label: "at 17")

            # get_secondary(backup, backup, pmb, designator, value, addit, true)
            get_secondary(
              tail,
              backup,
              pmb,
              designator,
              value,
              append_string_with_space(addit, head),
              true
            )
        end

      tail_head == "&" ->
        Logger.debug("at 18")
        get_secondary(tail_tail, backup, pmb, designator, value, addit, false)

      true ->
        Logger.debug("at 19")
        get_secondary(backup, backup, pmb, designator, value, addit, true)
    end
  end

  # Parses the state from the address list and returns
  # {state, leftover_address_list}.
  defp get_state(address) when not is_list(address), do: {nil, nil}
  defp get_state([]), do: {nil, nil}
  defp get_state(address), do: get_state(address, address, nil, 5)
  defp get_state([], backup, _, count) when count > 0, do: {nil, backup}

  defp get_state(address, _, state, 0) do
    {safe_replace(state, ",", ""), address}
  end

  defp get_state(address, address_backup, state, count) do
    states = AddressUSConfig.states()
    [head | tail] = address
    state_to_evaluate = safe_replace(merge_names(state, head), ",", "")

    cond do
      count == 5 && Enum.member?(Map.values(states), head) ->
        get_state(tail, address_backup, head, 0)

      safe_has_key?(states, state_to_evaluate) ->
        get_state(tail, address_backup, Map.get(states, state_to_evaluate), 0)

      Enum.member?(Map.values(states), safe_upcase(state_to_evaluate)) ->
        get_state(tail, address_backup, safe_upcase(state_to_evaluate), 0)

      count == 1 ->
        get_state(address_backup, address_backup, nil, 0)

      true ->
        get_state(tail, address_backup, state_to_evaluate, count - 1)
    end
  end

  # Parses the street out of the address list and returns the street name as a
  # string.
  defp get_street(address) when not is_list(address), do: nil
  defp get_street([]), do: nil
  defp get_street(address), do: get_street(address, nil, false)
  defp get_street([], street, false), do: get_street([], street, true)

  defp get_street(_address, street, true) do
    corner_case_street_names = %{"PGA" => "PGA", "ROUTE" => "Route", "RT" => "Route"}
    filtered_street = safe_upcase(street) |> safe_replace(~r/\s(\d+)/, "")
    # directions = AddressUSConfig.directions()
    # rev_directions = AddressUSConfig.reversed_directions()

    cond do
      safe_has_key?(corner_case_street_names, filtered_street) ->
        street_name =
          Map.get(corner_case_street_names, filtered_street)
          |> safe_replace(~r/\s(\d+)/, "")

        street_number = " " <> safe_replace(street, ~r/[a-zA-Z\s]+/, "")
        (street_name <> street_number) |> safe_replace(~r/\s$/, "")

      # # Can't assume "E" street is "East" street -- if it were a directional it would have already
      # # been parsed into the pre_direction field
      #
      # Enum.member?(
      #   Map.keys(directions) ++ Map.values(directions),
      #   title_case(street)
      # ) ->
      #   cond do
      #     Map.has_key?(directions, title_case(street)) ->
      #       title_case(street)

      #     true ->
      #       Map.get(rev_directions, String.upcase(street))
      #   end

      true ->
        street
    end
  end

  defp get_street(address, street, false) do
    [head | tail] = address

    cond do
      head == "&" || head == "AND" ->
        get_street(tail, nil, false)

      length(address) == 0 ->
        directions = AddressUSConfig.directions()
        rev_directions = AddressUSConfig.reversed_directions()
        keys = Map.keys(directions)
        values = Map.values(directions)
        street_is_direction = (keys ++ values) |> Enum.member?(head)

        street_name =
          cond do
            street_is_direction ->
              cond do
                Map.has_key?(directions, title_case(head)) ->
                  Map.get(rev_directions, Map.get(directions, title_case(head)))

                true ->
                  Map.get(rev_directions, String.upcase(head))
              end

            true ->
              street
          end

        get_street(address, street_name, true)

      length(clean_hyphenated_street(head)) > 1 ->
        cond do
          is_sec_unit_suffix_num_or_frac?(street) ->
            get_street(tail, street <> " " <> head, false)

          true ->
            get_street(clean_hyphenated_street(head) ++ tail, street, false)
        end

      true ->
        new_address =
          cond do
            street == nil -> title_case(head)
            true -> street <> " " <> title_case(head)
          end

        get_street(tail, new_address, false)
    end
  end

  # Parses the suffix out of the address list and returns
  # {processed suffix, raw suffix, leftover_address_list}
  defp get_suffix(address) when not is_list(address), do: {nil, nil, nil}
  defp get_suffix([]), do: {nil, nil, nil}
  defp get_suffix(address), do: get_suffix(address, nil, nil, false)
  defp get_suffix(address, suffix, raw_suffix, true), do: {suffix, raw_suffix, address}

  defp get_suffix(address, _, _, false) do
    [head | tail] = address
    new_suffix = get_suffix_value(head)

    cond do
      Enum.count(clean_hyphenated_street(head)) > 1 ->
        get_suffix(address, nil, nil, true)

      new_suffix != nil ->
        get_suffix(tail, new_suffix, title_case(head), true)

      true ->
        get_suffix(address, nil, nil, true)
    end
  end

  # Parses any trailing parenthesis out of the address list and returns
  # {additional designation in parenthesis, leftover_address_list}
  defp get_trailing_parens(address) when not is_list(address), do: {nil, nil}
  defp get_trailing_parens([]), do: {nil, nil}
  defp get_trailing_parens(address), do: get_trailing_parens(address, address, nil, false)
  defp get_trailing_parens([], backup, _city, false), do: {nil, backup}

  defp get_trailing_parens(address, _backup, nil, true) do
    {nil, address}
  end

  defp get_trailing_parens(address, backup, trailing_paren, true) do
    # Detect if trailing_paren is really a secondary designator/value.  If so then abort.
    # Also remove any remaining parens in the output
    units = AddressUSConfig.secondary_units()
    all_unit_values = Map.keys(units) ++ Map.values(units)
    head = String.split(trailing_paren, " ") |> List.first()

    if String.first(head) == "#" or Enum.member?(all_unit_values, title_case(head)) do
      {nil, Enum.map(backup, fn x -> String.replace(x, ~r/(\(|\))/, "") end)}
    else
      {title_case(trailing_paren),
       Enum.map(address, fn x -> String.replace(x, ~r/(\(|\))/, "") end)}
    end
  end

  # First run-through
  defp get_trailing_parens(address, backup, nil, false) do
    # addr_str = Enum.reverse(address) |> Enum.join(" ")
    [head | tail] = address

    case {String.first(head), String.last(head), String.length(head)} do
      {"(", ")", len} when len > 2 ->
        get_trailing_parens(tail, nil, String.slice(head, 1..-2), true)

      {_any, ")", _len} ->
        get_trailing_parens(tail, backup, String.slice(head, 0..-2), false)

      _ ->
        get_trailing_parens(address, backup, nil, true)
    end
  end

  defp get_trailing_parens(address, backup, trailing_paren, false) do
    [head | tail] = address

    case String.first(head) do
      # Found the open paren
      "(" ->
        get_trailing_parens(
          tail,
          backup,
          String.replace_leading(head, "(", "") <> " " <> trailing_paren,
          true
        )

      # Add word to accumulator and continue
      _ ->
        get_trailing_parens(tail, backup, head <> " " <> trailing_paren, false)
    end
  end

  # Additional designations and suffixes could be present in the final processed street name
  # This function isn't intended to solve all of these cases but common ones are covered
  defp strip_additional_and_suffix_from_name(street_name, additional, suffix) do
    {st, ad, su} =
      {street_name, additional, suffix}
      # |> safe_replace_first_elem(~r/\#/, "")
      |> strip_regex_to_additional(~r/( |\-)Po Box \w+$/)
      |> strip_regex_to_additional(~r/( |\-)Box \w+$/)
      |> strip_regex_to_additional(~r/( |\-)Milepost (\w|\.)+$/)
      |> strip_embedded_suffix()

    {safe_replace(st, "_", " "), safe_replace(ad, "_", " ") |> title_case(), su}
  end

  defp strip_regex_to_additional({nil, _, _} = tuple, _regex), do: tuple

  defp strip_regex_to_additional({street_name, additional, suffix} = tuple, regex) do
    parts = Regex.split(regex, street_name, include_captures: true)

    if length(parts) == 1 do
      tuple
    else
      {List.first(parts), append_string(additional, Enum.at(parts, 1)), suffix}
    end
  end

  def standardize_highways(street_name, state) do
    street_name
    |> safe_replace(~r/\#/, "")
    |> safe_replace(~r/\bI(-| )(\d+)/i, "Interstate_\\2")
    |> safe_replace(~r/\bI(\d+)/i, "Interstate_\\1")
    |> safe_replace(~r/\bUS(-| )(\d+)/i, "US_Highway_\\2")
    |> safe_replace(~r/\bUS (Hwy|Highway) (\d+)/i, "US_Highway_\\2")
    # |> safe_replace(~r/\bUS Highway (\d+)/i, "US_Highway_\\1")
    |> safe_replace(~r/\b(FM|FARM TO MARKET|FARM TO MKT|HWY FM) (\d+)/i, "FM_\\2")
    |> safe_replace(~r/\bCR ([\dA-Z]+)/i, "County_Road_\\1")
    |> safe_replace(~r/\b(CO|COUNTY|CNTY) (RD|ROAD) ([\dA-Z]+)/i, "County_Road_\\3")
    |> safe_replace(~r/\b(CO|COUNTY|CNTY) (HWY|HIGHWAY) ([\dA-Z]+)/i, "County_Highway_\\3")
    |> safe_replace(~r/\bCH (\d+|[A-Z]+)/i, "County_Highway_\\1")
    |> safe_replace(~r/\b(TWP|TOWNSHIP) (RD|ROAD) (\d+)/i, "Township_Road_\\3")
    |> safe_replace(~r/\b(TWP|TOWNSHIP) (HWY|HIGHWAY) (\d+)/i, "Township_Highway_\\3")
    |> safe_replace(~r/\b(ST|STATE) (HWY|HIGHWAY) (\d+)/i, "State_Highway_\\3")
    |> safe_replace(~r/\bSTH (\d+)/i, "State_Highway_\\1")
    |> safe_replace(~r/\bSH (\d+)/i, "State_Highway_\\1")
    # The prefix to ST|STATE avoids false positives like "MAIN ST RT 40"
    |> safe_replace(~r/\bSTATE (RD|ROAD) (\d+)/i, "State_Road_\\2")
    |> safe_replace(~r/\bSTATE (RT|RTE) (\d+)/i, "State_Route_\\2")
    |> safe_replace(~r/(^|\&\s)ST (RD|ROAD) (\d+)/i, "\\1State_Road_\\3")
    |> safe_replace(~r/(^|\&\s)ST (RT|RTE) (\d+)/i, "\\1State_Route_\\3")
    |> safe_replace(~r/\b(RT|RTE|ROUTE) (\d+)/i, "Route_\\2")
    |> safe_replace(~r/(\d+) (Hwy|Highway) (\d+)/i, "\\1 Highway_\\2")
    |> safe_replace(~r/(\d+) (N|E|S|W) (Hwy|Highway) (\d+)/i, "\\1 \\2 Highway_\\3")
    |> safe_replace(~r/\bSR (\d+)/i, standardize_sr(state))
    |> safe_replace(~r/\bSR(\d+)/i, standardize_sr(state))
  end

  defp standardize_sr(state) when state in ["FL", "IN", "NM"], do: "State_Road_\\1"

  defp standardize_sr(_state), do: "State_Route_\\1"

  def get_valid_suffix_index(street_list) do
    Enum.with_index(street_list)
    |> Enum.reduce_while({"", -1}, &test_suffix/2)
    |> case do
      tuple when is_tuple(tuple) -> nil
      idx when is_integer(idx) -> idx
      _ -> nil
    end
  end

  def test_suffix(current, last) do
    if Enum.member?(AddressUSConfig.common_suffix_keys(), elem(last, 0)) do
      # NO LONGER NEEDED
      # && not Enum.member?(["COUNTY", "STATE", "US"], elem(current, 0)) do
      {:halt, elem(last, 1)}
    else
      {:cont, current}
    end
  end

  def strip_embedded_suffix({street_name, additional, nil} = tuple)
      when not is_nil(street_name) do
    ucase_street_name = String.upcase(street_name)

    # Checking if the string contains a suffix string before going through the expensive operation
    if String.contains?(ucase_street_name, AddressUSConfig.common_suffix_keys()) do
      rev_street_list = ucase_street_name |> String.split(" ") |> Enum.reverse()

      # rev_last_suffix_index =
      #   Enum.find_index(rev_street_list, fn x -> Enum.member?(suf_list, x) end)
      rev_last_suffix_index = get_valid_suffix_index(rev_street_list)

      cond do
        rev_last_suffix_index == nil ->
          tuple

        # If the first term in the street name is a suffix then ignore (as it's really the street name)
        rev_last_suffix_index == length(rev_street_list) - 1 ->
          tuple

        # TODO: REMOVE - NO LONGER NEEDED
        # Don't mangle Highways
        # Enum.member?(
        #   ["COUNTY", "STATE", "US"],
        #   Enum.at(rev_street_list, rev_last_suffix_index + 1)
        # ) ->
        #   IO.puts("here!")
        #   tuple

        true ->
          street_list = Enum.reverse(rev_street_list)
          last_suffix_index = length(street_list) - 1 - rev_last_suffix_index
          ret_street = Enum.take(street_list, last_suffix_index) |> Enum.join(" ") |> title_case()
          ret_suffix = get_suffix_value(Enum.at(street_list, last_suffix_index))

          new_addtl =
            Enum.take(street_list, (length(street_list) - (last_suffix_index + 1)) * -1)
            |> Enum.join(" ")
            |> title_case()

          ret_addtl = append_string_with_space(additional, new_addtl)
          {ret_street, ret_addtl, ret_suffix}
      end
    else
      tuple
    end
  end

  def strip_embedded_suffix(tuple), do: tuple

  # Parses an address list for all of the requisite address parts and returns
  # a Street struct.
  # p_val = possible secondary value
  # p_des = possible secondary designator
  defp parse_address_list(address, _state) when not is_list(address), do: nil
  defp parse_address_list([], _), do: nil
  defp parse_address_list([""], _), do: nil

  defp parse_address_list(address, state) do
    cleaned_address =
      Enum.map(address, &safe_replace(&1, ",", ""))
      |> log_term("cleaned")

    {additional, address_no_trailing_parens} =
      get_trailing_parens(cleaned_address)
      |> log_term("get_trailing_parens")

    {designator, value, pmb, additional, address_no_secondary} =
      get_secondary(address_no_trailing_parens, additional)
      |> log_term("get_secondary")

    {post_direction, raw_post_direction, address_no_secondary_direction} =
      get_post_direction(address_no_secondary)
      |> log_term("get_post_direction")

    # get_suffix should move anything after the suffix to extraneous

    {suffix, raw_suffix, address_no_suffix} =
      get_suffix(address_no_secondary_direction)
      |> log_term("get_suffix")

    reversed_address_remnants =
      Enum.reverse(address_no_suffix)
      |> log_term("reversed")

    {primary_number, box, p_val, p_des, address_no_number} =
      get_number(reversed_address_remnants)
      |> log_term("get_number")

    {pre_direction, raw_pre_direction, address_no_pre_direction} =
      get_pre_direction(address_no_number)
      |> log_term("get_pre_direction")

    street_name =
      get_street(address_no_pre_direction)
      |> log_term("get_street")

    # Deal with a possible NIL street name after the above processing
    {final_name, pre_direction, suffix, final_secondary_val, post_direction} =
      case {street_name, box, pre_direction, suffix, p_val, p_des, post_direction} do
        # TODO: Check on what addresses would make this occur
        {nil, b, _, _, _, _, _} when b != nil ->
          IO.inspect({box, pre_direction, suffix, p_val, post_direction}, label: "first case")

        # TODO: Check on what addresses would make this occur
        {nil, _, _, _, pv, nil, _} when pv != nil ->
          IO.inspect({pv, pre_direction, suffix, nil, post_direction}, label: "second case")

        # If the Suffix is St or Dr (which would never be valid street names) leave it at suffix
        {nil, _, pre, suf, _, _, _} when pre != nil and suf in ["St", "Dr"] ->
          {raw_pre_direction, nil, suffix, p_val, post_direction}

        # Otherwise if the suffix is something else (like Blvd, Ct, etc) and there is a pre-direction
        # It's too ambiguous (i.e. 1410 East Boulevard or 720 Northwest Blvd) we we will just put both
        # identifiers in the name field.  
        # Note we are loading suffix with * in this case to avoid having it pulled back out by strip_additional_and_suffix_from_name
        # The * will be nilified after that function.
        {nil, _, pre, suf, _, _, _} when pre != nil and suf != nil ->
          {raw_pre_direction <> " " <> raw_suffix, nil, "*", p_val, post_direction}

        # Note we are loading suffix with * in this case to avoid having it pulled back out by strip_additional_and_suffix_from_name
        # The * will be nilified after that function.
        {nil, _, _pre, suf, _, _, _} when suf != nil ->
          {raw_suffix, pre_direction, "*", p_val, post_direction}

        {nil, _, pre, _suf, _, _, _} when pre != nil ->
          {raw_pre_direction, nil, suffix, p_val, post_direction}

        {nil, _, _, _, _, _, post} when post != nil ->
          {raw_post_direction, nil, suffix, p_val, nil}

        _ ->
          {street_name, pre_direction, suffix, p_val, post_direction}
      end

    log_term({final_name, final_secondary_val}, "final_name, secondary_val")

    final_name = standardize_highways(final_name, state)

    # In case the suffix wasn't parsed out due to extraneous designations still present in the street name
    # 5875 CASTLE CREEK PKWY DR BLDG 4 STE 195 is a good test -- Bldg 4 should be removed to additional
    # and 1040 A AVE FREEMAN FIELD
    # and 9704 BEAUMONT RD MAINT BLDG
    {final_name, additional, suffix} =
      strip_additional_and_suffix_from_name(final_name, additional, suffix)

    # final_name = standardize_highways(final_name, state)

    suffix = if suffix == "*", do: nil, else: suffix

    # If a post-direction was mistakenly taken from a Box, append it back on
    {final_name, post_direction} =
      if final_name && String.starts_with?(final_name, "Box") && post_direction,
        do: {final_name <> post_direction, nil},
        else: {final_name, post_direction}

    final_secondary_designator =
      cond do
        designator == nil && p_des != nil -> p_des
        true -> designator
      end

    log_term(final_secondary_designator, "final_secondary_designator")

    final_secondary_value =
      cond do
        p_val == nil ->
          value

        true ->
          cond do
            value == nil -> final_secondary_val
            true -> value
          end
      end

    log_term(final_secondary_value, "final_secondary_value")

    %Street{
      secondary_designator: final_secondary_designator,
      post_direction: post_direction,
      pre_direction: pre_direction,
      secondary_value: final_secondary_value,
      pmb: pmb,
      suffix: suffix,
      primary_number: primary_number,
      name: final_name,
      additional_designation: additional
    }
  end

  # Parses postal value passed to it and returns {zip_code, zip_plus_4}
  defp parse_postal(postal) when not is_binary(postal), do: {nil, nil}

  defp parse_postal(postal) do
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
  ## Helper Functions
  ############################################################################

  defp append_string(nil, str) do
    String.trim(str) |> String.replace_prefix("-", "")
  end

  defp append_string(str1, str2) do
    String.trim(str1) <> String.trim(String.replace_prefix(str2, "-", ""))
  end

  defp append_string_with_space(nil, str) do
    String.trim(str) |> String.replace_prefix("-", "")
  end

  defp append_string_with_space(str1, str2) do
    (String.trim(str1) <> " " <> String.trim(String.replace_prefix(str2, "-", "")))
    |> String.trim()
  end

  # Cleans up hyphenated street values by removing the hyphen and returing the
  # values or the appropriate USPS abbreviations for said values in a list.

  # TODO: is this to deal with I-15 and SR-44?  If so maybe it can be modified to do
  # general string substitution for the street name field
  defp clean_hyphenated_street(value) when not is_binary(value), do: [value]

  defp clean_hyphenated_street(value) do
    case value |> String.match?(~r/-/) do
      true ->
        sub_data = AddressUSConfig.street_name_subs()
        subs = Map.keys(sub_data) ++ Map.values(sub_data)
        values = value |> String.split("-")
        truths = Enum.map(values, &Enum.member?(subs, safe_upcase(&1)))

        new_values =
          Enum.map(values, fn v ->
            case safe_has_key?(sub_data, safe_upcase(v)) do
              true -> title_case(Map.get(sub_data, safe_upcase(v)))
              false -> title_case(v)
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

  # Gets direction abbreviation string.
  defp get_direction_abbreviation(value) when not is_binary(value), do: nil

  defp get_direction_abbreviation(value) do
    val = title_case(value)
    directions = AddressUSConfig.directions()

    cond do
      safe_has_key?(directions, val) -> Map.get(directions, val)
      Map.values(directions) |> Enum.member?(val) -> safe_upcase(val)
      true -> nil
    end
  end

  # Returns the appropriate direction value if a direction is found.
  defp get_direction_value(value) when not is_binary(value), do: ""

  defp get_direction_value(value) do
    directions = AddressUSConfig.directions()
    clean_value = title_case(value)

    cond do
      safe_has_key?(directions, clean_value) ->
        Map.get(directions, clean_value)

      Map.values(directions) |> Enum.member?(safe_upcase(clean_value)) ->
        safe_upcase(clean_value)

      true ->
        ""
    end
  end

  # Returns the appropriate suffix value if one is found.
  defp get_suffix_value(value) when not is_binary(value), do: nil

  defp get_suffix_value(value) do
    suffixes = AddressUSConfig.common_suffixes()
    cleaned_value = title_case(value)
    capitalized_keys = Map.keys(suffixes) |> Enum.map(&title_case(&1))
    capitalized_values = Map.values(suffixes) |> Enum.map(&title_case(&1))
    suffix_values = capitalized_keys ++ capitalized_values

    cond do
      Enum.member?(suffix_values, cleaned_value) ->
        case safe_has_key?(suffixes, safe_upcase(cleaned_value)) do
          true -> Map.get(suffixes, safe_upcase(cleaned_value))
          false -> cleaned_value
        end

      true ->
        nil
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

  # Does a standard safe_upcase, unless the value to be upcased is a nil, in
  # which case it returns ""
  defp safe_upcase(nil), do: ""
  defp safe_upcase(value), do: String.upcase(value)

  # Does a standard safe_has_key, unless the value to be checked is a nil, in
  # which case it returns false.
  defp safe_has_key?(_, nil), do: false
  defp safe_has_key?(map, key), do: Map.has_key?(map, key)

  # Does a standard String.contains?, unless the value for which to search is
  # an empty string, in which case it returns false.
  defp safe_contains?(_, ""), do: false
  defp safe_contains?(value, k), do: String.contains?(value, k)

  # Does a standard safe_replace, unless the value to be modified is a nil in
  # which case it just returns a nil.
  defp safe_replace(nil, _, _), do: nil
  defp safe_replace(value, k, v), do: String.replace(value, k, v)

  defp safe_replace_first_elem({nil, _, _} = tuple, _regex, _repl), do: tuple

  defp safe_replace_first_elem({value, e1, e2}, regex, repl),
    do: {String.replace(value, regex, repl), e1, e2}

  # Does a standard safe_starts_with?, unless the value to be modified is a nil
  # in which case it returns false.
  defp safe_starts_with?(nil, _), do: false
  defp safe_starts_with?(value, k), do: String.starts_with?(value, k)

  # Standardizes the spacing around the commas, periods, and newlines and then
  # deletes the periods per the best practices outlined by the USPS.  It also
  # replaces newline characters with commas, and replaces '# <value>' with
  # '#<value>' and then returns the string.
  defp standardize_address(address) when not is_binary(address), do: nil

  defp standardize_address(address) do
    address
    # |> safe_replace(~r/ United States$/, "")
    |> safe_replace(~r/ UNITED STATES$/i, "")
    |> safe_replace(~r/ US$/, "")
    # |> safe_replace(~r/US$/, "")
    # |> safe_replace(~r/\(SEC\)/, "")
    |> safe_replace(~r/U\.S\./, "US")
    |> safe_replace(~r/\sU\sS\s/, " US ")
    |> safe_replace(~r/\sM L King\s/, " Martin Luther King ")
    |> safe_replace(~r/\sMLK\s/, " Martin Luther King ")
    |> safe_replace(~r/\sMLKING\s/, " Martin Luther King ")
    |> safe_replace(~r/\sML KING\s/, " Martin Luther King ")
    |> safe_replace(~r/(.+)\(/, "\\1 (")
    |> safe_replace(~r/\)(.+)/, ") \\1")
    # NOTE: Don't remove parenthesis yet
    # |> safe_replace(~r/\((.+)\)/, "\\1")
    |> safe_replace(~r/\sAND\s/i, " & ")
    |> safe_replace(~r/\sAT\s/i, " & ")
    |> safe_replace(~r/\@/i, " & ")
    |> safe_replace(~r/\sI.E.\s/i, "")
    |> safe_replace(~r/\sET\sAL\s/i, "")
    |> safe_replace(~r/\sIN\sCARE\sOF\s/i, "")
    |> safe_replace(~r/\sCARE\sOF\s/i, "")
    # C/O is Care Of
    |> safe_replace(~r/C\/O\s/i, "")
    |> safe_replace(~r/\sBY\sPASS\b/i, " BYPASS ")
    |> safe_replace(~r/\sBY\s/i, "")
    |> safe_replace(~r/\sFOR\s/i, "")
    |> safe_replace(~r/\sALSO\s/i, "")
    |> safe_replace(~r/\sATTENTION\s/i, "")
    |> safe_replace(~r/\sATTN\s/i, "")
    |> safe_replace(~r/\ss#\ss(\S)/i, " #\\1")
    # # |> safe_replace(~r/(?i)P O BOX/, "PO BOX")
    # |> safe_replace(~r/\bUS (\d+)/i, "US Highway \\1")
    # |> safe_replace(~r/\bUS Hwy (\d+)/i, "US Highway \\1")
    # |> safe_replace(~r/(\d+) Hwy (\d+)/i, "\\1 Highway \\2")
    # |> safe_replace(~r/\bCR (\d+)/i, "County Road \\1")
    # |> safe_replace(~r/\bCO RD (\d+)/i, "County Road \\1")
    # |> safe_replace(~r/\bST RD (\d+)/i, "State Road \\1")
    # # TODO: In certain states, change this to State Route instead
    # |> safe_replace(~r/SR (\d+)/i, "State Road \\1")
    |> safe_replace(~r/(.+)#/, "\\1 #")
    |> safe_replace(~r/\n/, ", ")
    |> safe_replace(~r/\t/, " ")
    |> safe_replace(~r/\_/, " ")
    # Slashes could mean intersection or adding an additional designation to existing street name
    # Since it's ambiguous we need to retain them
    # |> safe_replace(~r/\/(\D)/, " \\1")
    # |> safe_replace(~r/(\D)\//, "\\1 ")
    |> safe_replace(~r/\"/, "")
    |> safe_replace(~r/\'/, "")
    |> safe_replace(~r/\s+/, " ")
    |> safe_replace(~r/,(\S)/, ", \\1")
    |> safe_replace(~r/\s,(\S)/, ", \\1")
    |> safe_replace(~r/(\S),\s/, "\\1, ")
    |> safe_replace(~r/-\s+/, "-")
    |> safe_replace(~r/\s+\-/, "-")
    # |> safe_replace(~r/\.(\S)/, ". \\1")
    # |> safe_replace(~r/\s\.\s/, ". ")
    # |> safe_replace(~r/\s\.(\S)/, ". \\1")
    # |> safe_replace(~r/(\S)\.\s/, "\\1. ")
    |> safe_replace(~r/(?i)P\.O\.BOX/, "PO BOX")
    # remove periods that are not adjacent to digits
    |> safe_replace(~r/(?!\d)\.(?!\d)/, "")
    |> safe_replace(~r/(?i)P O BOX/, "PO BOX")
    |> safe_replace(~r/PO BOX(\d+)/, "PO BOX \\1")
    |> safe_replace(~r/\s,\s/, ", ")
    |> String.trim()
  end

  # Capitalizes the first letter of every word in a string and returns the
  # title cased string.
  def title_case(value) when not is_binary(value), do: nil

  def title_case(value) do
    word_endings = ["ST", "ND", "RD", "TH"]

    make_title_case = fn word ->
      letters = safe_replace(word, ~r/\d+/, "")

      cond do
        String.downcase(word) == "us" ->
          "US"

        Regex.match?(~r/^(\d)/, word) && Enum.member?(word_endings, letters) ->
          String.downcase(word)

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
  end

  defp upcase_directions(str) when str in ["Ne", "Nw", "Se", "Sw"], do: String.upcase(str)

  defp upcase_directions(str), do: str

  # Determines if address list contains a PO Box.
  defp contains_po_box?(address) when not is_list(address), do: false
  defp contains_po_box?([]), do: false

  defp contains_po_box?(address) do
    [head | _] = address
    full_address = address |> Enum.join(" ") |> safe_upcase
    !is_sec_unit_suffix_num_or_frac?(head) && String.match?(full_address, ~r/BOX/)
  end

  # Determines if a value is a number, fraction, or postal keyword.
  defp is_sec_unit_suffix_num_or_frac?(value) when not is_binary(value), do: false

  defp is_sec_unit_suffix_num_or_frac?(value) do
    word = title_case(value)
    units = AddressUSConfig.secondary_units()
    suffixes = AddressUSConfig.common_suffixes()
    keywords1 = Map.keys(units) ++ Map.values(units) ++ Map.values(suffixes)
    keywords2 = Map.keys(suffixes)

    cond do
      string_is_number_or_fraction?(word) -> true
      Enum.member?(keywords1, word) -> true
      Enum.member?(keywords2, safe_upcase(word)) -> true
      true -> false
    end
  end

  # Detects if a string is a state or not.
  defp is_state?(value) when not is_binary(value), do: false

  defp is_state?(value) do
    state = title_case(value)
    states = AddressUSConfig.states()

    cond do
      safe_has_key?(states, state) -> true
      Map.values(states) |> Enum.member?(safe_upcase(state)) -> true
      true -> false
    end
  end

  # Determines if a value is a possible Suite value.
  defp is_possible_suite_number?(value) do
    units = AddressUSConfig.secondary_units()
    values = Map.values(units) |> Enum.map(&String.downcase(&1))
    keys = Map.keys(units) |> Enum.map(&String.downcase(&1))
    (values ++ keys) |> Enum.member?(String.downcase(value))
  end

  # Determines if string can be cleanly converted into a number.
  defp string_is_number?(value) when is_number(value), do: true
  defp string_is_number?(value) when not is_binary(value), do: false

  defp string_is_number?(value) do
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

  defp string_starts_with_number?(value) when is_number(value), do: true
  defp string_starts_with_number?(value) when not is_binary(value), do: false
  defp string_starts_with_number?(value), do: string_is_number?(String.first(value))

  # Determines if value is a number or a fraction.
  defp string_is_number_or_fraction?(value) when not is_binary(value), do: false

  defp string_is_number_or_fraction?(value) do
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

  defp string_is_fraction?(value) when not is_binary(value), do: false

  defp string_is_fraction?(value) do
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

  defp log_term(term, label) do
    Logger.debug(label <> ": " <> inspect(term))
    term
  end
end
