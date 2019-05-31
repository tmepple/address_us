defmodule AddressUS.Parser.Standardizer do
  import AddressUS.Parser.Helpers

  @doc """
  Preliminiary standardizations to be done first before Parser.clean_address_line decides how to standardize and/or parse the address.
  """
  def pre_standardize_address(messy_address, _pre_std) when not is_binary(messy_address), do: nil

  def pre_standardize_address(messy_address, false), do: messy_address

  def pre_standardize_address(messy_address, true) do
    messy_address
    |> String.upcase()
    |> String.trim()
    # Remove any non-ASCII characters from address
    |> safe_replace(~r/[^\x00-\x7F]/, "")
    # Underscores, pipes, and carets are special characters in our future processing so ensure none exists in the source address
    |> safe_replace(~r/[\_\|\^]/, " ")
    # Embedded newlines and tabs should be replaced
    |> safe_replace(~r/\n/, ", ")
    |> safe_replace(~r/\t/, " ")
    # In FRS the number is frequently scrunched up against the first word -- if it's 3 chars or more it's not a unit or directional
    |> safe_replace(~r/^(\d+)([A-Z]{3,})/, "\\1 \\2")
    # Handle 123-44TH ST
    |> safe_replace(~r/^(\d+)\-(\d+(ST|ND|RD|TH))\s/, "\\1 \\2 ")
    # If the address ends with numbers or single characters seperated by an ampersand it's usually "12 MAIN ST STE 8 & 9"
    # This causes issues for the parser so we pin them together then after processing expand it back to ampersands
    |> safe_replace(~r/ (\d+|[A-Z]) \& (\d+|[A-Z])$/, " \\1^\\2")
    # Handle N.E., S.W., etc
    |> safe_replace(~r/\b(S|N)\.(E|W)\./, "\\1\\2")
    # Remove periods that are not adjacent to digits
    |> safe_replace(~r/(?!\d)\.(?!\d)/, " ")
    |> safe_replace("  ", " ")
    # Mark leading or trailing parenthesis or unclosed parens to second line represented by a pipe character at this point
    |> safe_replace(~r/^(.+)\((.+)\)$/, "\\1|\\2")
    |> safe_replace(~r/^\((.+)\)(.+)$/, "\\2|\\1")
    |> safe_replace(~r/^(.+)\(([^\)]+)$/, "\\1|\\2")
    # |> String.replace_suffix(")", "")
    |> safe_replace(~r/\s\|/, "|")
    |> eliminate_repitition()
  end

  # Standardizes the spacing around the commas, periods, and newlines and then
  # deletes the periods per the best practices outlined by the USPS.  It also
  # replaces newline characters with commas, and replaces '# <value>' with
  # '#<value>' and then returns the string.
  def standardize_address(messy_address) when not is_binary(messy_address), do: nil

  def standardize_address(messy_address) do
    messy_address
    # Remove leading pound signs
    |> safe_replace(~r/^\#\s?/, "")
    |> safe_replace(~r/ UNITED STATES$/, "")
    |> safe_replace(~r/ US$/, "")
    # Periods are already gone
    # |> safe_replace(~r/U\.S\./, "US")
    |> safe_replace(~r/\sU\sS\s/, " US ")
    |> safe_replace(~r/UNITED STATES/, "US")
    |> safe_replace(~r/\sM L KING\s/, " MARTIN LUTHER KING ")
    |> safe_replace(~r/\sMLK\s/, " MARTIN LUTHER KING ")
    |> safe_replace(~r/\sMLKING\s/, " MARTIN LUTHER KING ")
    |> safe_replace(~r/\sML KING\s/, " MARTIN LUTHER KING ")
    # If whole address is in parenthesis, remove them
    |> safe_replace(~r/^\((.+)\)$/, "\\1")
    # Punctuation replacements
    # Ensure space delimited parens, ampersands
    |> safe_replace(~r/(\S)\(/, "\\1 (")
    |> safe_replace(~r/\)(\S)/, ") \\1")
    |> safe_replace(~r/(\S)\&/, "\\1 &")
    |> safe_replace(~r/\&(\S)/, "& \\1")
    # Ensure space before but not after pound signs
    |> safe_replace(~r/(.+)#/, "\\1 #")
    |> safe_replace(~r/\#\s+/, "#")
    # Apostrophes or backticks against a number with a non-number afterwards usually refer to feet.  
    # Otherwise remove them and other quotes, question marks, and exclamation marks
    |> safe_replace(~r/(\d+)[\'\`]\s(\D)/, "\\1 FT \\2")
    |> safe_replace(~r/[\'\`\?\!\"]/, "")
    |> safe_replace(~r/\s+/, " ")
    # Properly space commas
    |> safe_replace(~r/,(\S)/, ", \\1")
    |> safe_replace(~r/\s,(\S)/, ", \\1")
    |> safe_replace(~r/(\S),\s/, "\\1, ")
    |> safe_replace(~r/\s,\s/, ", ")
    # Tighten hypens and remove them if they are surrounded on either side by words that are not all digits
    |> safe_replace(~r/\b(\d+)\s?\-\s?(\d+)\b/, "\\1-\\2")
    |> safe_replace(~r/\s\-+\s/, " ")
    |> safe_replace(~r/-\s+/, "-")
    |> safe_replace(~r/\s+\-/, "-")
    # |> safe_replace(~r/(\D+)\-(\D+)/, "\\1 \\2")
    |> safe_replace(~r/ ([A-Z]+)\-([A-Z]+) /, " \\1 \\2 ")
    # Tighten slashes and backslashes
    |> safe_replace(~r/\s?([\\\/])\s?/, "\\1")
    # Address ranges with THRU should use a dash instead
    |> safe_replace(~r/^(\d+) (THROUGH|THRU) (\d+)\s/, "\\1-\\3 ")
    # Tighten extraneous space for street names "1 ST", "2 ND", etc.
    |> safe_replace(~r/^(\d+) (\d+) (ST|ND|RD|TH)\s/, "\\1 \\2\\3 ")
    # If the street number has a letter appended to it, seperate it with a space (if a directional or "M" (Flint, MI)) or a dash (if not)
    |> safe_replace(~r/^(\d+)((?![NEWSM])[A-Z])\s/, "\\1-\\2 ")
    |> safe_replace(~r/^(\d+)([NEWS])\s/, "\\1 \\2 ")
    # Handle addresses without spaces such as "400N-300S"
    |> safe_replace(~r/^(\d+)([NEWS])\-?(\d+)([NEWS])$/, "\\1 \\2 \\3 \\4")

    # Remove mail routing instructions
    |> safe_replace(~r/\sI.E.\s/, "")
    |> safe_replace(~r/\sET\sAL\s/, "")
    |> safe_replace(~r/\sIN\sCARE\sOF\s/, "")
    |> safe_replace(~r/\sCARE\sOF\s/, "")
    |> safe_replace(~r/\sBY\sPASS\b/, " BYPASS ")
    |> safe_replace(~r/\sBY\s/, "")
    |> safe_replace(~r/\sFOR\s/, "")
    |> safe_replace(~r/\sALSO\s/, "")
    |> safe_replace(~r/\sATTENTION\s/, "")
    |> safe_replace(~r/\sATTN\s/, "")
    |> safe_replace("  ", " ")

    ## Following lines were commented out from the original implementation but were not covered by tests
    # Following line is commented out as not sure the purpose -- no existing tests target it
    # |> safe_replace(~r/\ss#\ss(\S)/, " #\\1")
    # Commented since the meaning "care of" wasn't covered by tests and frequently also means "corner of" which we want to retain
    # |> safe_replace(~r/C\/O\s/, "")
    # Slashes could mean intersection or adding an additional designation to existing street name
    # Since it's ambiguous we need to retain them
    # |> safe_replace(~r/\/(\D)/, " \\1")
    # |> safe_replace(~r/(\D)\//, "\\1 ")
    # Periods not involved in digits were removed in pre_standardization
    # |> safe_replace(~r/\.(\S)/, ". \\1")
    # |> safe_replace(~r/\s\.\s/, ". ")
    # |> safe_replace(~r/\s\.(\S)/, ". \\1")
    # |> safe_replace(~r/(\S)\.\s/, "\\1. ")
    # Slashes could mean intersection or adding an additional designation to existing street name
    # Since it's ambiguous we need to retain them
    # |> safe_replace(~r/\/(\D)/, " \\1")
    # |> safe_replace(~r/(\D)\//, "\\1 ")
    # |> safe_replace(~r/\(SEC\)/, "")

    |> String.trim()
  end

  def standardize_po_box_and_rrs_maybe_move(addr, false), do: addr

  def standardize_po_box_and_rrs_maybe_move(addr, true) do
    addr
    |> safe_replace(~r/^(R\s?R|RURAL ROUTE)\s?\#?/, "RR ")
    |> safe_replace(~r/^(RTE|RT|R)\s?\#?(\d+)\,?\s?BOX\s?([\dA-Z]+)$/, "RR \\2 BOX \\3")
    |> safe_replace(~r/(RR|HC)\s?(\d+)\,\s?BOX\s?([\dA-Z]+)/, "\\1 \\2 BOX \\3")
    |> safe_replace(~r/POST OFFICE BOX/, "PO BOX")
    |> safe_replace(~r/ BX /, " BOX ")
    |> safe_replace(~r/\bP\s?O BOX\s?([\dA-Z]+)/, "PO BOX \\1")
    |> safe_replace(~r/\bPOB ([\dA-Z]+)/, "PO BOX \\1")
    |> safe_replace(~r/[\/\-]PO BOX/, " PO BOX")
    # If a PO Box is not alone and not already moved to addr2, move it now
    |> safe_replace(~r/^([^\|]+) PO BOX ([\dA-Z]+)$/, "\\1|PO_BOX_\\2")
    |> safe_replace(~r/^PO BOX\s*([\dA-Z]+)[ \,\/\-]+(.+)$/, "\\2|PO_BOX_\\1")
    |> safe_replace(
      ~r/ (ROAD|RD|STREET|ST|BOULEVARD|BLVD|AVENUE|AVE|\w+\_\w+) BOX ([\dA-Z]+)$/,
      " \\1|BOX \\2"
    )
  end

  @doc "Given the parsed street address or full address line will standardize highways into USPS standard abbreviations"
  def standardize_highways(street_addr_or_line, state, input \\ :line) do
    street_addr_or_line
    # |> safe_replace(~r/\#/, "")
    |> safe_replace(~r/\bI(-| )(\d+)/, "INTERSTATE_\\2")
    |> safe_replace(~r/\bI(\d+)/, "INTERSTATE_\\1")
    |> safe_replace(~r/\bI\s?H\s?(\d+)/, "INTERSTATE_\\1")
    |> safe_replace(~r/\bUS(-| )?\#?(\d+)/, "US_HIGHWAY_\\2")
    |> safe_replace(~r/\bU\s?S (HWY|HIGHWAY) \#?(\d+)/, "US_HIGHWAY_\\2")
    # Although USPS Pub 28 seems to prefer US HIGHWAY many laws refer to "US ROUTE" which is favored in sections of the country
    |> safe_replace(~r/\bU\s?S (RT|RTE|ROUTE) \#?(\d+)/, "US_ROUTE_\\2")
    # |> safe_replace(~r/\bUS HIGHWAY (\d+)/, "US_HIGHWAY_\\1")
    |> safe_replace(~r/\b(FM|FARM TO MARKET|FARM TO MKT|HWY FM|FMR) \#?(\d+)/, "FM_\\2")
    |> safe_replace(~r/\bC\s?R\s\#?([\dA-Z]+)/, "COUNTY_ROAD_\\1")
    |> safe_replace(~r/\b(CO|COUNTY|CNTY|CTY) (RD|ROAD) \#?([\dA-Z]+)/, "COUNTY_ROAD_\\3")
    |> safe_replace(~r/\b(CO|COUNTY|CNTY|CTY) (HWY|HIGHWAY) \#?([\dA-Z]+)/, "COUNTY_HIGHWAY_\\3")
    |> safe_replace(~r/\bCH \#?(\d+|[A-Z]+)/, "COUNTY_HIGHWAY_\\1")
    |> safe_replace(~r/\bCTH \#?(\d+|[A-Z]+)/, "COUNTY_HIGHWAY_\\1")
    |> safe_replace(~r/\b(TWP|TOWNSHIP) (RD|ROAD) \#?(\d+)/, "TOWNSHIP_ROAD_\\3")
    |> safe_replace(~r/\b(TWP|TOWNSHIP) (HWY|HIGHWAY) \#?(\d+)/, "TOWNSHIP_HIGHWAY_\\3")
    |> safe_replace(~r/\b(ST|STATE) (HWY|HIGHWAY) \#?(\d+)/, "STATE_HIGHWAY_\\3")
    |> safe_replace(~r/\bSTH \#?(\d+)/, "STATE_HIGHWAY_\\1")
    |> safe_replace(~r/\bSH \#?(\d+)/, "STATE_HIGHWAY_\\1")
    # The prefix to ST|STATE avoids false positives like "MAIN ST RT 40"
    |> safe_replace(~r/\bSTATE (RD|ROAD) \#?(\d+)/, "STATE_ROAD_\\2")
    |> safe_replace(~r/\bSTATE (RT|RTE) \#?(\d+)/, "STATE_ROUTE_\\2")
    # The next two replacements are more complex to avoid false positives like 40 E MAIN ST RTE 4
    |> safe_replace(
      ~r/(^|\s)(\d+|[NEWS\&\(]|NORTH|EAST|WEST|SOUTH|OLD|OF|ON|FROM|TO|AVE|ST|BLVD|DR|RD|^)([\s\/\,\-]+)ST (RD|ROAD) \#?(\d+)/,
      "\\1\\2\\3 STATE_ROAD_\\5"
    )
    |> safe_replace(
      ~r/(^|\s)(\d+|[NEWS\&\(]|NORTH|EAST|WEST|SOUTH|OLD|OF|ON|FROM|TO|AVE|ST|BLVD|DR|RD|^)([\s\/\,\-]+)ST (RT|RTE|ROUTE) \#?(\d+)/,
      "\\1\\2\\3 STATE_ROUTE_\\5"
    )
    # The next two replacements clean up from the above ST RD and ST RT replacements
    |> safe_replace(~r/\s\s/, " ")
    |> safe_replace(~r/\(\s/, "(")
    |> safe_replace(~r/\|ST (RD|ROAD) \#?(\d+)/, "|STATE_ROAD_\\2")
    |> safe_replace(~r/\|ST (RT|RTE|ROUTE) \#?(\d+)/, "|STATE_ROUTE_\\2")
    |> safe_replace(~r/\b(RT|RTE|ROUTE) \#?(\d+)/, "ROUTE_\\2")
    |> safe_replace(~r/\b(ROAD|RD) (\d+)/, "ROAD_\\2")
    |> safe_replace(~r/\bS\s?R\s?\#?(\d+)/, standardize_sr(state))
    |> String.trim()
    |> standardize_bare_highways(input)
  end

  defp standardize_bare_highways(street_addr_or_line, :line) do
    street_addr_or_line
    |> safe_replace(~r/(HWY|HIGHWAY) \#?(\d+)/, "HIGHWAY_\\2")
    # The following four lines were simplified into the line above and all tests pass but are kept for now just in case
    # |> safe_replace(~r/(\d+) OLD (HWY|HIGHWAY) \#?(\d+)/, "\\1 OLD_HIGHWAY_\\3")
    # |> safe_replace(~r/(\d+) (N|E|S|W) OLD (HWY|HIGHWAY) \#?(\d+)/, "\\1 \\2 OLD_HIGHWAY_\\4")
    # |> safe_replace(~r/(\d+) (HWY|HIGHWAY) \#?(\d+)/, "\\1 HIGHWAY_\\3")
    # |> safe_replace(~r/(\d+) (N|E|S|W) (HWY|HIGHWAY) \#?(\d+)/, "\\1 \\2 HIGHWAY_\\4")

    # x MILE ROAD
    |> safe_replace(~r/(\d+) (\d+) MILE (ROAD|RD)/, "\\1 \\2_MILE_RD")

    # Some highways are a single letter (not NEWS) followed by a number which usually should have a dash but sometimes that's omitted
    |> safe_replace(~r/^(\d+) ([NEWS]\s)?((?![NEWS])[A-Z])\s(\d+)\b/, "\\1 \\2\\3-\\4")
  end

  # TODO: Remove this no-longer used block
  # defp standardize_bare_highways(street_addr_or_line, :street_addr) do
  #   street_addr_or_line
  #   |> safe_replace(~r/OLD (HWY|HIGHWAY) \#?(\d+)/, "OLD_HIGHWAY_\\2")
  #   |> safe_replace(~r/(HWY|HIGHWAY) \#?(\d+)/, "HIGHWAY_\\2")
  # end

  def standardize_intersections(street_name) do
    street_name
    |> safe_replace(~r/\&AMP\;/, " & ")
    |> safe_replace(~r/\sAND\s/, " & ")
    |> safe_replace(~r/\sAT\s/, " & ")
    |> safe_replace(~r/\@/, " & ")
    |> safe_replace(~r/^JCT\.? (OF )?(.+\&.+)/, "\\2")
  end

  # Occasionally addresses will include the whole address repeated twice
  defp eliminate_repitition(string) do
    no_spaces = String.replace(string, " ", "")
    len = String.length(no_spaces)

    if no_spaces != string and Integer.mod(len, 2) == 0 do
      if String.slice(no_spaces, 0..(div(len, 2) - 1)) == String.slice(no_spaces, div(len, 2)..-1) do
        String.slice(string, 0..div(String.length(string) - 1, 2)) |> String.trim()
      else
        string
      end
    else
      string
    end
  end

  def pipe_leading_corners(addr) do
    addr
    |> safe_replace(~r/^(N\s?E|N\s?W|S\s?E|S\s?W) CORNER (OF )?(.+)$/, "\\3|\\1 CORNER")
    |> safe_replace(~r/^CORNER (OF )?(.+ \& .+)$/, "\\2")
  end

  @doc """
  If there is a single comma in the addr hugging a suffix or highway and afterwards is text that is not a direction, 
  remove the trailing part to a pipe as it is an additional designation not suitable for normal parsing.  
  """
  def pipe_single_comma_slash_hyphen_hugging_suffix(addr) do
    split_by_commas = String.split(addr, ",")
    split_by_slash = String.split(addr, "/")
    split_by_hyphen = String.split(addr, "-")

    case {length(split_by_commas), length(split_by_slash), length(split_by_hyphen)} do
      {2, _, _} -> pipe_if_suffix(split_by_commas, addr)
      {_, 2, _} -> pipe_if_suffix(split_by_slash, addr)
      {_, _, 2} -> pipe_if_suffix(split_by_hyphen, addr)
      _ -> addr
    end
  end

  defp pipe_if_suffix(split_addr, addr) do
    [first | [last]] = split_addr
    possible_suffix_or_hwy = first |> String.split(" ") |> List.last()

    #! get_direction_value(last) do
    if (AddressUS.Parser.AddrLine.get_suffix_value(possible_suffix_or_hwy) ||
          String.contains?(possible_suffix_or_hwy, "_")) && get_direction_value(last) == "" do
      first <> "|" <> last
    else
      addr
    end
  end

  # def postpend_prepended_po_box(messy_address) do
  #   messy_address
  #   |> safe_replace(~r/^((P O BOX|PO BOX)\s*(\d+))[\s\-\/\,]+(.+)/, "\\4 \\1")
  # end

  ############################################################################
  ## Private Functions
  ############################################################################

  defp standardize_sr(state) when state in ["FL", "IN", "NM"], do: "STATE_ROAD_\\1"

  defp standardize_sr(_state), do: "STATE_ROUTE_\\1"
end
