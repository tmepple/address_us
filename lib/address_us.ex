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
  import AddressUS.Parser.Helpers
  alias AddressUS.Parser.{AddrLine, Standardizer, CSZ}

  def parse_address(messy_address, opts \\ [])

  def parse_address(messy_address, _opts) when not is_binary(messy_address), do: nil

  def parse_address(messy_address, opts) do
    casing = Keyword.get(opts, :casing, :title)
    pre_std = Keyword.get(opts, :pre_std, true)

    address =
      messy_address
      |> Standardizer.pre_standardize_address(pre_std)
      |> Standardizer.standardize_intersections()
      |> Standardizer.standardize_address()

    log_term(address, "std addr")
    address = Enum.reverse(String.split(address, " "))
    {postal, plus_4, address_no_postal} = CSZ.get_postal(address)
    {state, address_no_state} = CSZ.get_state(address_no_postal)

    # OPTIMIZE: This is likely not good for performance but without refactoring get_postal and get_state this was the easiest way
    # to standardize the highways after we extract the State. 
    address_no_state =
      if address_no_state do
        Enum.reverse(address_no_state)
        |> Enum.join(" ")
        |> Standardizer.standardize_highways(state)
        |> String.split(" ")
        |> Enum.reverse()
      else
        nil
      end

    {city, address_no_city} = CSZ.get_city(address_no_state)
    street = AddrLine.parse_address_list(address_no_city, state, casing)

    %Address{
      postal: postal,
      plus_4: plus_4,
      state: state,
      city: apply_casing_replace_pins(city, casing),
      street: street
    }
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

  def parse_address_line(messy_address, state \\ "", opts \\ [])

  def parse_address_line(messy_address, _state, _opts) when not is_binary(messy_address),
    do: nil

  def parse_address_line(messy_address, state, opts) do
    casing = Keyword.get(opts, :casing, :title)
    pre_std = Keyword.get(opts, :pre_std, true)

    messy_address
    |> Standardizer.pre_standardize_address(pre_std)
    |> Standardizer.standardize_po_box_and_rrs_maybe_move(pre_std)
    |> Standardizer.standardize_intersections()
    |> Standardizer.standardize_address()
    |> Standardizer.standardize_highways(state)
    # |> Standardizer.move_pinned_po_boxes_to_addr2()
    # Text following a single comma hugging a suffix (ie 12 MAIN ST, HIGHWAY 31 S) is likely additional information which
    # causes issues when parsed (i.e. 12 MAIN ST S) so we should pipe delimit it here so when it gets parsed it is properly
    # called an "additional designation"
    |> Standardizer.pipe_single_comma_hugging_suffix()
    |> log_term("std addr")
    |> String.split(" ")
    |> Enum.reverse()
    |> AddrLine.parse_address_list(state, casing)
  end

  @doc """
  Standardizes the raw street portion of an address according to USPS suggestions for
  address parsing.  If given a state will apply custom standardizations (if they exist) for that state 
  """
  def standardize_address_line(messy_address, state \\ "", opts \\ [])

  def standardize_address_line(messy_address, _state, _opts) when not is_binary(messy_address),
    do: nil

  def standardize_address_line(messy_address, state, opts) do
    casing = Keyword.get(opts, :casing, :title)
    pre_std = Keyword.get(opts, :pre_std, true)

    messy_address
    |> Standardizer.pre_standardize_address(pre_std)
    |> Standardizer.standardize_po_box_and_rrs_maybe_move(pre_std)
    |> Standardizer.standardize_intersections()
    |> Standardizer.standardize_address()
    |> Standardizer.standardize_highways(state)
    # |> Standardizer.move_pinned_po_boxes_to_addr2()
    |> apply_casing_replace_pins(casing)
  end

  @doc """
  Given a messy address line, returns it standardized and cleaned.  If there is no valid street number
  or if an intersection is given it will only standardize the address, otherwise it will first parse
  the address to standardize directionals, suffixes, and separate additional information.
  """
  def clean_address_line(messy_address, state \\ "", opts \\ [])

  def clean_address_line(messy_address, _state, _opts) when not is_binary(messy_address), do: ""

  def clean_address_line(messy_address, state, opts) do
    casing = Keyword.get(opts, :casing, :upper)

    messy_address =
      messy_address
      |> Standardizer.pre_standardize_address(true)
      |> Standardizer.standardize_po_box_and_rrs_maybe_move(true)

    valid_number? =
      Regex.match?(
        ~r/^(\d+|[NEWS]\d+\s[NEWS]\d+|[NEWS]\d+[NEWS]\d+|[NEWS]\d+|\d+[NEWS]\d+|\d+[A-Z]|\d+\-[A-Z]|[\d\-\/]+)\s/,
        messy_address
      )

    # If there's no valid number of if the address has more than one commas + slashes or if it has a comma or slash that
    # is not pinned up against a suffix then it's too complex to attempt parsing so just standardize it.
    ret_val =
      if not valid_number? or not max_one_comma_slash_hugging_suffix_or_hwy?(messy_address) do
        standardize_address_line(messy_address, state, casing: casing, pre_std: false)
      else
        # standardize only the intersection & AND AT @ and split
        split_address =
          Standardizer.standardize_intersections(messy_address) |> String.split("&", parts: 2)

        # if no & is found (thus it's not an intersection) or if the intersection happens after a pipe (thus belongs in the second line)
        # then just parse it
        if length(split_address) == 1 or String.contains?(List.first(split_address), "|") do
          parse_address_line_fmt(messy_address, state, casing: casing, pre_std: false)
        else
          # We have an ampersand so may have an intersection
          # if there's a slash in the first item that's not a fraction then check to see if it's hugging a suffix or highway
          # if so then the intersection is additional information and is put in line 2.  If not then we should just standardize
          # as there is too much ambiguity. 
          if Regex.match?(~r/(\D\/|\/\D|\,)/, List.first(split_address)) do
            if max_one_comma_slash_hugging_suffix_or_hwy?(List.first(split_address)) do
              parse_address_line_fmt(messy_address, state, casing: casing, pre_std: false)
            else
              standardize_address_line(messy_address, state, casing: casing, pre_std: false)
            end
          else
            # run first portion through parse_address_line_fmt and second portion through standardize then recombine with " & "
            split_line =
              parse_address_line_fmt(List.first(split_address), state,
                casing: casing,
                pre_std: false
              )
              |> String.split("\n", parts: 2)

            std_after_ampersand =
              standardize_address_line(List.last(split_address), state,
                casing: casing,
                pre_std: false
              )

            if length(split_line) == 1 do
              List.first(split_line) <> " & " <> std_after_ampersand
            else
              List.first(split_line) <>
                " & " <> std_after_ampersand <> "\n" <> List.last(split_line)
            end
          end
        end
      end

    apply_casing_replace_pins(ret_val, casing)
  end

  def max_one_comma_slash_hugging_suffix_or_hwy?(addr) do
    split_by_commas = String.split(addr, ",")
    split_by_slashes = String.replace(addr, ~r/(\d\/|\/\d)/, "|") |> String.split("/")
    # if Regex.match?(~r/(\D\/|\/\D)/i, addr), do: String.split(addr, "/"), else: ["unimportant"]

    case {length(split_by_commas), length(split_by_slashes)} do
      {1, 1} ->
        true

      {2, 1} ->
        is_possible_suffix_or_hwy_before_comma_or_slash?(split_by_commas)

      {1, 2} ->
        is_possible_suffix_or_hwy_before_comma_or_slash?(split_by_slashes)

      _more ->
        false
    end
  end

  defp is_possible_suffix_or_hwy_before_comma_or_slash?(split_address) do
    possible_suffix_or_hwy =
      split_address
      |> List.first()
      # Next line a little inefficient (since it will be repeated) but only happens if single comma exists in address
      |> Standardizer.standardize_highways("")
      |> String.split(" ")
      |> List.last()

    if AddressUS.Parser.AddrLine.get_suffix_value(possible_suffix_or_hwy) ||
         String.contains?(possible_suffix_or_hwy, "_"),
       do: true,
       else: false
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
    state = safe_upcase(raw_state)

    states = AddressUSConfig.states()

    cond do
      safe_has_key?(states, state) == true ->
        Map.get(states, state)

      Enum.member?(Map.values(states), state) == true ->
        state

      true ->
        title_case(state)
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

  @doc "Given a street struct will return a tuple of formatted strings for the addr and addr2"
  def addr_and_addr2_from_street(%Street{} = addr) do
    {primary_number, secondary_value} =
      case {addr.secondary_value, addr.secondary_designator} do
        {"M", nil} ->
          {addr.primary_number <> "M", nil}

        {val, nil} when not is_nil(val) ->
          if Integer.parse(val) == :error,
            do: {addr.primary_number <> "-" <> addr.secondary_value, nil},
            else: {addr.primary_number <> " " <> addr.secondary_value, nil}

        _other ->
          {addr.primary_number, addr.secondary_value}
      end

    # if addr.secondary_value != nil and addr.secondary_designator == nil,
    #   do: {addr.primary_number <> "-" <> addr.secondary_value, nil},
    #   else: {addr.primary_number, addr.secondary_value}

    prim_line =
      [primary_number, addr.pre_direction, addr.name, addr.suffix, addr.post_direction]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")
      |> String.trim()

    # [addr.pmb, addr.secondary_designator, secondary_value, addr.additional_designation]
    sec_line =
      [addr.pmb, addr.additional_designation, addr.secondary_designator, secondary_value]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")
      |> String.trim()

    {prim_line, sec_line}
  end

  ############################################################################
  ## Private Functions
  ############################################################################

  def parse_address_line_fmt(messy_address, state \\ "", opts \\ [])

  def parse_address_line_fmt(messy_address, _state, _opts)
      when not is_binary(messy_address),
      do: nil

  def parse_address_line_fmt(messy_address, state, opts) do
    fmt_opt = Keyword.get(opts, :additional, :newline)
    casing = Keyword.get(opts, :casing, :title)
    pre_std = Keyword.get(opts, :pre_std, true)

    street = parse_address_line(messy_address, state, casing: casing, pre_std: pre_std)

    {prim_line, sec_line} = addr_and_addr2_from_street(street)

    case {fmt_opt, sec_line} do
      {_ad, sl} when sl == "" -> prim_line
      {:newline, _sl} -> prim_line <> "\n" <> sec_line
      {_parens, _sl} -> prim_line <> " (" <> sec_line <> ")"
    end
  end
end
