defmodule AddressUS.Parser.Standardizer do
  import AddressUS.Parser.Helpers

  # Standardizes the spacing around the commas, periods, and newlines and then
  # deletes the periods per the best practices outlined by the USPS.  It also
  # replaces newline characters with commas, and replaces '# <value>' with
  # '#<value>' and then returns the string.
  def standardize_address(address) when not is_binary(address), do: nil

  def standardize_address(address) do
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

  def standardize_intersections(street_name) do
    street_name
    |> safe_replace(~r/\sAND\s/i, " & ")
    |> safe_replace(~r/\sAT\s/i, " & ")
    |> safe_replace(~r/\@/i, " & ")
  end

  ############################################################################
  ## Private Functions
  ############################################################################

  defp standardize_sr(state) when state in ["FL", "IN", "NM"], do: "State_Road_\\1"

  defp standardize_sr(_state), do: "State_Route_\\1"
end
