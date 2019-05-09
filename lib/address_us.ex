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

  def parse_address(messy_address, casing \\ :title)

  def parse_address(messy_address, _casing) when not is_binary(messy_address), do: nil

  def parse_address(messy_address, casing) do
    # NOTE: We don't standardize_highways here because it's done later as part of `parse_address_list`
    address =
      messy_address
      |> String.upcase()
      |> Standardizer.standardize_intersections()
      |> Standardizer.standardize_address()

    # |> Standardizer.standardize_highways(state)

    log_term(address, "std addr")
    {postal, plus_4, address_no_postal} = CSZ.get_postal(address)
    {state, address_no_state} = CSZ.get_state(address_no_postal)
    {city, address_no_city} = CSZ.get_city(address_no_state)
    street = AddrLine.parse_address_list(address_no_city, state, casing)

    %Address{
      postal: postal,
      plus_4: plus_4,
      state: state,
      city: apply_casing(city, casing),
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

  def parse_address_line(messy_address, state \\ "", casing \\ :title)

  def parse_address_line(messy_address, _state, _casing) when not is_binary(messy_address),
    do: nil

  def parse_address_line(messy_address, state, casing) do
    # NOTE: We don't standardize_highways here because it's done later as part of `parse_address_list`

    messy_address
    |> String.upcase()
    |> Standardizer.standardize_intersections()
    |> Standardizer.standardize_address()
    # |> Standardizer.standardize_highways(state)
    |> log_term("std addr")
    |> String.split(" ")
    |> Enum.reverse()
    |> AddrLine.parse_address_list(state, casing)
  end

  @doc """
  Standardizes the raw street portion of an address according to USPS suggestions for
  address parsing.  If given a state will apply custom standardizations (if they exist) for that state 
  """
  def standardize_address_line(messy_address, state \\ "", casing \\ :title)

  def standardize_address_line(messy_address, _state, _casing) when not is_binary(messy_address),
    do: nil

  def standardize_address_line(messy_address, state, casing) do
    messy_address
    |> String.upcase()
    |> Standardizer.standardize_intersections()
    |> Standardizer.standardize_address()
    |> Standardizer.standardize_highways(state)
    |> safe_replace("_", " ")
    |> apply_casing(casing)
  end

  @doc """
  Given a messy address line, returns it standardized and cleaned.  If there is no valid street number
  or if an intersection is given it will only standardize the address, otherwise it will first parse
  the address to standardize directionals, suffixes, and separate additional information.
  """
  def clean_address_line(messy_address, state \\ "", casing \\ :upper)

  def clean_address_line(messy_address, _state, _casing) when not is_binary(messy_address), do: ""

  def clean_address_line(messy_address, state, casing) do
    messy_address =
      messy_address
      |> String.upcase()
      |> Standardizer.postpend_prepended_po_box()

    # NOTE: Check for WI explicitly to avoid every address in the country to face expensive regex
    # TODO: Benchmark
    valid_number? =
      if state == "WI" do
        Regex.match?(~r/^(\d+|[NEWS]\d+[NEWS]\d+\s|[NEWS]\d+\s)/, messy_address)
      else
        Regex.match?(~r/^\d+\s/, messy_address)
      end

    ret_val =
      if not valid_number? do
        standardize_address_line(messy_address, state, casing)
      else
        # standardize only the intersection & AND AT @ and split
        split_address =
          Standardizer.standardize_intersections(messy_address) |> String.split(" & ", parts: 2)

        # if no & then just parse
        if length(split_address) == 1 do
          parse_address_line_fmt(messy_address, state, casing)
        else
          # if there's a slash in the first item that's not a fraction then just standardize as there's too much ambiguity
          # on what the slash means
          if Regex.match?(~r/(\D\/|\/\D)/i, List.first(split_address)) do
            standardize_address_line(messy_address, state, casing)
          else
            # run first portion through parse_address_line_fmt and second portion through standardize then recombine with " & "
            split_line =
              parse_address_line_fmt(List.first(split_address), state, casing)
              |> String.split("\n", parts: 2)

            if length(split_line) == 1 do
              List.first(split_line) <>
                " & " <> standardize_address_line(List.last(split_address), state, casing)
            else
              List.first(split_line) <>
                " & " <>
                standardize_address_line(List.last(split_address), state, casing) <>
                "\n" <> List.last(split_line)
            end
          end
        end
      end

    apply_casing(ret_val, casing)
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

  ############################################################################
  ## Private Functions
  ############################################################################

  defp parse_address_line_fmt(messy_address, state \\ "", casing \\ :title, opts \\ [])

  defp parse_address_line_fmt(messy_address, _state, _casing, _opts)
       when not is_binary(messy_address),
       do: nil

  defp parse_address_line_fmt(messy_address, state, casing, opts) do
    fmt_opt = Keyword.get(opts, :additional, :newline)

    addr = parse_address_line(messy_address, state, casing)

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

    case {fmt_opt, sec_line} do
      {_ad, sl} when sl == "" -> prim_line
      {:newline, _sl} -> prim_line <> "\n" <> sec_line
      {_parens, _sl} -> prim_line <> " (" <> sec_line <> ")"
    end
  end
end
