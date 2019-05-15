defmodule AddressUS.Parser.Standardizer do
  import AddressUS.Parser.Helpers

  # Standardizes the spacing around the commas, periods, and newlines and then
  # deletes the periods per the best practices outlined by the USPS.  It also
  # replaces newline characters with commas, and replaces '# <value>' with
  # '#<value>' and then returns the string.
  def standardize_address(messy_address) when not is_binary(messy_address), do: nil

  def standardize_address(messy_address) do
    messy_address
    # |> safe_replace(~r/ United STATEs$/, "")
    |> safe_replace(~r/^\#\s?/, "")
    |> safe_replace(~r/ UNITED STATES$/, "")
    |> safe_replace(~r/ US$/, "")
    # |> safe_replace(~r/US$/, "")
    # |> safe_replace(~r/\(SEC\)/, "")
    |> safe_replace(~r/U\.S\./, "US")
    |> safe_replace(~r/\sU\sS\s/, " US ")
    |> safe_replace(~r/UNITED STATES/, "US")
    |> safe_replace(~r/\sM L KING\s/, " MARTIN LUTHER KING ")
    |> safe_replace(~r/\sMLK\s/, " MARTIN LUTHER KING ")
    |> safe_replace(~r/\sMLKING\s/, " MARTIN LUTHER KING ")
    |> safe_replace(~r/\sML KING\s/, " MARTIN LUTHER KING ")
    |> safe_replace(~r/(.+)\(/, "\\1 (")
    |> safe_replace(~r/\)(.+)/, ") \\1")
    # NOTE: Don't remove parenthesis yet
    # |> safe_replace(~r/\((.+)\)/, "\\1")
    |> safe_replace(~r/\sI.E.\s/, "")
    |> safe_replace(~r/\sET\sAL\s/, "")
    |> safe_replace(~r/\sIN\sCARE\sOF\s/, "")
    |> safe_replace(~r/\sCARE\sOF\s/, "")
    # C/O is Care Of
    |> safe_replace(~r/C\/O\s/, "")
    |> safe_replace(~r/\sBY\sPASS\b/, " BYPASS ")
    |> safe_replace(~r/\sBY\s/, "")
    |> safe_replace(~r/\sFOR\s/, "")
    |> safe_replace(~r/\sALSO\s/, "")
    |> safe_replace(~r/\sATTENTION\s/, "")
    |> safe_replace(~r/\sATTN\s/, "")
    # TODO: IS THE FOLLOWING LINE NEEDED?  NOT UNDERSTANDING IT
    # |> safe_replace(~r/\ss#\ss(\S)/, " #\\1")
    # # |> safe_replace(~r/(?i)P O BOX/, "PO BOX")
    # |> safe_replace(~r/\bUS (\d+)/, "US HIGHWAY \\1")
    # |> safe_replace(~r/\bUS HWY (\d+)/, "US HIGHWAY \\1")
    # |> safe_replace(~r/(\d+) HWY (\d+)/, "\\1 HIGHWAY \\2")
    # |> safe_replace(~r/\bCR (\d+)/, "COUNTY ROAD \\1")
    # |> safe_replace(~r/\bCO RD (\d+)/, "COUNTY ROAD \\1")
    # |> safe_replace(~r/\bST RD (\d+)/, "STATE ROAD \\1")
    # # TODO: In certain states, change this to STATE ROUTE instead
    # |> safe_replace(~r/SR (\d+)/, "STATE ROAD \\1")
    |> safe_replace(~r/(.+)#/, "\\1 #")
    |> safe_replace(~r/\n/, ", ")
    |> safe_replace(~r/\t/, " ")
    |> safe_replace(~r/\_/, " ")
    # Slashes could mean intersection or adding an additional designation to existing street name
    # Since it's ambiguous we need to retain them
    # |> safe_replace(~r/\/(\D)/, " \\1")
    # |> safe_replace(~r/(\D)\//, "\\1 ")
    |> safe_replace(~r/\"/, "")
    # Apostrophes or backticks against a number with a non-number afterwards usually refer to feet.  Otherwise remove them.
    |> safe_replace(~r/(\d+)[\'\`]\s?(\D)/, "\\1 FT \\2")
    |> safe_replace(~r/[\'\`]/, "")
    |> safe_replace(~r/\s+/, " ")
    |> safe_replace(~r/,(\S)/, ", \\1")
    |> safe_replace(~r/\s,(\S)/, ", \\1")
    |> safe_replace(~r/(\S),\s/, "\\1, ")
    # remove hypens that are surrounded by spaces and tighten if spaces appear on one side
    |> safe_replace(~r/\s\-+\s/, " ")
    |> safe_replace(~r/-\s+/, "-")
    |> safe_replace(~r/\s+\-/, "-")
    # |> safe_replace(~r/\.(\S)/, ". \\1")
    # |> safe_replace(~r/\s\.\s/, ". ")
    # |> safe_replace(~r/\s\.(\S)/, ". \\1")
    # |> safe_replace(~r/(\S)\.\s/, "\\1. ")
    |> safe_replace(~r/P O BOX/, "PO BOX")
    |> safe_replace(~r/P\.O\.BOX/, "PO BOX")
    |> safe_replace(~r/P\. O\. BOX/, "PO BOX")
    |> safe_replace(~r/PO BOX(\d+)/, "PO BOX \\1")
    |> safe_replace(~r/POB (\d+)/, "PO BOX \\1")
    |> safe_replace(~r/(RR|HC)\s?(\d+)\,\s?BOX\s?(\d+)/, "\\1 \\2 BOX \\3")

    # remove periods that are not adjacent to digits
    |> safe_replace(~r/(?!\d)\.(?!\d)/, " ")
    |> safe_replace(~r/\s,\s/, ", ")
    |> safe_replace("  ", " ")
    |> String.trim()
  end

  # def standardize_po_boxes(messy_address) do
  #   messy_address
  #   |> safe_replace(~r/P\.O\.BOX/, "PO BOX")
  #   |> safe_replace(~r/P O BOX/, "PO BOX")
  #   |> safe_replace(~r/PO BOX(\d+)/, "PO BOX \\1")
  # end

  @doc "Given the parsed street address or full address line will standardize highways into USPS standard abbreviations"
  def standardize_highways(street_addr_or_line, state, input \\ :line) do
    street_addr_or_line
    # |> safe_replace(~r/\#/, "")
    |> safe_replace(~r/\bI(-| )(\d+)/, "INTERSTATE_\\2")
    |> safe_replace(~r/\bI(\d+)/, "INTERSTATE_\\1")
    |> safe_replace(~r/\bUS(-| )\#?(\d+)/, "US_HIGHWAY_\\2")
    |> safe_replace(~r/\bUS (HWY|HIGHWAY) \#?(\d+)/, "US_HIGHWAY_\\2")
    # |> safe_replace(~r/\bUS HIGHWAY (\d+)/, "US_HIGHWAY_\\1")
    |> safe_replace(~r/\b(FM|FARM TO MARKET|FARM TO MKT|HWY FM) \#?(\d+)/, "FM_\\2")
    |> safe_replace(~r/\bCR \#?([\dA-Z]+)/, "COUNTY_ROAD_\\1")
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
    |> safe_replace(~r/(^|\&\s)ST (RD|ROAD) \#?(\d+)/, "\\1STATE_ROAD_\\3")
    |> safe_replace(~r/(^|\&\s)ST (RT|RTE) \#?(\d+)/, "\\1STATE_ROUTE_\\3")
    |> safe_replace(~r/\b(RT|RTE|ROUTE) \#?(\d+)/, "ROUTE_\\2")
    # TODO: The digits and the directionals are only there if we standardize_highways at the beginning of the process not the way that standardize_address_list does it
    # We can try doing standardize_highways at the beginning in those cases or we can make the digits optional in the regexes below.
    # Or we can split out these four lines into new functions (with and without digits) and call them appropriately at the right time.
    # |> safe_replace(~r/(\d+) OLD (HWY|HIGHWAY) \#?(\d+)/, "\\1 OLD_HIGHWAY_\\3")
    # |> safe_replace(~r/(\d+) (N|E|S|W) OLD (HWY|HIGHWAY) \#?(\d+)/, "\\1 \\2 OLD_HIGHWAY_\\4")
    # |> safe_replace(~r/(\d+) (HWY|HIGHWAY) \#?(\d+)/, "\\1 HIGHWAY_\\3")
    # |> safe_replace(~r/(\d+) (N|E|S|W) (HWY|HIGHWAY) \#?(\d+)/, "\\1 \\2 HIGHWAY_\\4")
    |> safe_replace(~r/\bSR \#?(\d+)/, standardize_sr(state))
    |> safe_replace(~r/\bSR\#?(\d+)/, standardize_sr(state))
    |> standardize_bare_highways(input)
  end

  defp standardize_bare_highways(street_addr_or_line, :line) do
    street_addr_or_line
    |> safe_replace(~r/(\d+) OLD (HWY|HIGHWAY) \#?(\d+)/, "\\1 OLD_HIGHWAY_\\3")
    |> safe_replace(~r/(\d+) (N|E|S|W) OLD (HWY|HIGHWAY) \#?(\d+)/, "\\1 \\2 OLD_HIGHWAY_\\4")
    |> safe_replace(~r/(\d+) (HWY|HIGHWAY) \#?(\d+)/, "\\1 HIGHWAY_\\3")
    |> safe_replace(~r/(\d+) (N|E|S|W) (HWY|HIGHWAY) \#?(\d+)/, "\\1 \\2 HIGHWAY_\\4")
  end

  defp standardize_bare_highways(street_addr_or_line, :street_addr) do
    street_addr_or_line
    |> safe_replace(~r/OLD (HWY|HIGHWAY) \#?(\d+)/, "OLD_HIGHWAY_\\2")
    |> safe_replace(~r/(HWY|HIGHWAY) \#?(\d+)/, "HIGHWAY_\\2")
  end

  def standardize_intersections(street_name) do
    street_name
    |> safe_replace(~r/\&AMP\;/, " & ")
    |> safe_replace(~r/\sAND\s/, " & ")
    |> safe_replace(~r/\sAT\s/, " & ")
    |> safe_replace(~r/\@/, " & ")
    |> safe_replace(~r/^JCT\.? (OF )?(.+\&.+)/, "\\2")
  end

  def postpend_prepended_po_box(messy_address) do
    messy_address
    |> safe_replace(~r/^((P O BOX|PO BOX)\s*(\d+))[\s\-\/]+(.+)/, "\\4 \\1")
  end

  ############################################################################
  ## Private Functions
  ############################################################################

  defp standardize_sr(state) when state in ["FL", "IN", "NM"], do: "STATE_ROAD_\\1"

  defp standardize_sr(_state), do: "STATE_ROUTE_\\1"
end
