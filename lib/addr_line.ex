defmodule AddressUS.Parser.AddrLine do
  import AddressUS.Parser.Helpers

  alias AddressUS.Parser.Standardizer

  # Parses an address list for all of the requisite address parts and returns
  # a Street struct.
  # p_val = possible secondary value
  # p_des = possible secondary designator
  # this line probably not needed as this is only called intra-library: def parse_address_list(address, state, casing \\ :title)

  def parse_address_list(address, _state, _casing) when not is_list(address), do: nil
  def parse_address_list([], _, _), do: nil
  def parse_address_list([""], _, _), do: nil

  def parse_address_list(address, state, casing) do
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
          log_term({box, pre_direction, suffix, p_val, post_direction}, "first case")

        # TODO: Check on what addresses would make this occur
        {nil, _, _, _, pv, nil, _} when pv != nil ->
          log_term({pv, pre_direction, suffix, nil, post_direction}, "second case")

        # If the Suffix is St or Dr (which would never be valid street names) leave it at suffix
        {nil, _, pre, suf, _, _, _} when pre != nil and suf in ["ST", "DR"] ->
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

    # In case the suffix wasn't parsed out due to extraneous designations still present in the street name
    # 5875 CASTLE CREEK PKWY DR BLDG 4 STE 195 is a good test -- Bldg 4 should be removed to additional
    # and 1040 A AVE FREEMAN FIELD
    # and 9704 BEAUMONT RD MAINT BLDG
    {final_name, additional, suffix} =
      strip_additional_and_suffix_from_name(final_name, additional, suffix)
      |> log_term("final_name, addtl, suffix after stripping")

    # final_name = standardize_highways(final_name, state)

    suffix = if suffix == "*", do: nil, else: suffix

    # If a post-direction was mistakenly taken from a Box, append it back on
    {final_name, post_direction} =
      if final_name && String.starts_with?(final_name, "BOX") && post_direction,
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
      secondary_designator: apply_casing(final_secondary_designator, casing),
      post_direction: post_direction,
      pre_direction: pre_direction,
      secondary_value: apply_casing(final_secondary_value, casing),
      pmb: apply_casing(pmb, casing),
      suffix: apply_casing(suffix, casing),
      primary_number: primary_number,
      name: apply_casing(final_name, casing),
      additional_designation: apply_casing(additional, casing)
    }
  end

  # PRIVATE FUNCTIONS (Alphabetical Order)

  # Returns the appropriate direction value if a direction is found.
  defp get_direction_value(value) when not is_binary(value), do: ""

  defp get_direction_value(value) do
    directions = AddressUSConfig.directions()

    cond do
      safe_has_key?(directions, value) ->
        Map.get(directions, value)

      Map.values(directions) |> Enum.member?(value) ->
        value

      true ->
        ""
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

    tail_tail_head = if length(tail_tail) > 0, do: hd(tail_tail), else: ""

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
        log_term("get_number - 1")
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
        log_term("get_number - 2")
        tail_head = safe_replace(tail_head, ~r/\(([A-Z0-9])\)/, "\\1")
        # Test for all alphanumerics except for directionals and "O" (i.e. 44 O HARA ST)
        alphanumeric = "ABCDFGHIJKLMPQRTUVXYZ1234567890"

        case safe_contains?(alphanumeric, tail_head) do
          false ->
            get_number(tail, backup, head, box, p_val, p_des, true)

          true ->
            # If the term after the number is a single alphanumeric then check to see if the term after that is
            # a valid suffix (i.e. 4400 A Avenue) or is it another single non-directional alphanumeric (then likely 3422 A J Green Ave)
            # before assuming it's a secondary_value
            case {get_suffix_value(tail_tail_head), safe_contains?(alphanumeric, tail_tail_head)} do
              {val, _other} when not is_nil(val) ->
                get_number(tail, backup, head, box, p_val, p_des, true)

              {nil, true} ->
                get_number(tail, backup, head, box, p_val, p_des, true)

              _other ->
                get_number(tail_tail, backup, head, box, tail_head, p_des, true)
            end

            # do: get_number(tail, backup, head, box, p_val, p_des, true),
            # else: get_number(tail_tail, backup, head, box, tail_head, p_des, true)
        end

      # number == nil && string_is_number_or_fraction?(safe_replace(head, regex, "\\1")) ->
      #   endings = ["ST", "ND", "RD", "TH"]
      #   new_number = safe_replace(head, regex, "\\1")
      #   new_value = safe_replace(head, regex, "\\2")

      #   case Enum.member?(endings, new_value) do
      #     false ->
      #       get_number(tail, backup, new_number, box, new_value, p_des, true)

      #     true ->
      #       get_number(backup, backup, number, box, new_value, p_des, true)
      #   end

      number == nil && is_state?(head) ->
        log_term("get_number - 3")

        get_number(address, backup, number, box, p_val, p_des, true)

      # Grid-style addresses (usually seen in Wisconsin)
      grid =
          Regex.run(
            # ~r/^([NEWS]\d+[NEWS]\d+|[NEWS]\d+\s[NEWS]\d+|[NEWS]\d+|\d+[NEWS]\d+)\s\w/,
            ~r/^([NEWS]\d+[NEWS]\d+|[NEWS]\d+\s[NEWS]\d+|[NEWS]\d+|\d+[NEWS]\d+)/,
            # <> " " <> tail_tail_head
            head <> " " <> tail_head
          ) ->
        log_term("get_number - 4")

        grid_number = Enum.at(grid, 1)

        # Remove embedded space to assist geocoders which frequently break with the added space
        if String.contains?(grid_number, " ") do
          get_number(
            tail_tail,
            backup,
            String.replace(grid_number, " ", ""),
            box,
            p_val,
            p_des,
            true
          )
        else
          get_number(tail, backup, grid_number, box, p_val, p_des, true)
        end

      # # If there is a dash in the number and the second part is not a fraction just return the whole thing including the dash
      # # It might be an address range (i.e. 101-102 E Washington) or it could be a valid Brooklyn-style address
      # # (59-36 Cooper Ave, Glendale, NY 11385).  If it is a fraction ("212-1/2 1st St") then replace dash with space.
      # safe_contains?(head, "-") ->
      #   log_term("get_number - 6")

      #   head = safe_replace(head, ~r/^(\d+)\-(\d+\/\d+)$/, "\\1 \\2")
      #   get_number(tail, backup, head, box, p_val, p_des, true)

      number == nil && string_is_number_or_fraction?(safe_replace(head, regex, "\\1")) ->
        log_term("get_number - 5")

        endings = ["ST", "ND", "RD", "TH"]
        new_number = safe_replace(head, regex, "\\1")
        new_value = safe_replace(head, regex, "\\2")

        case Enum.member?(endings, new_value) do
          false ->
            get_number(tail, backup, new_number, box, new_value, p_des, true)

          true ->
            get_number(backup, backup, number, box, new_value, p_des, true)
        end

      # If there is a dash in the number and the second part is not a fraction just return the whole thing including the dash
      # It might be an address range (i.e. 101-102 E Washington) or it could be a valid Brooklyn-style address
      # (59-36 Cooper Ave, Glendale, NY 11385).  If it is a fraction ("212-1/2 1st St") then replace dash with space.
      safe_contains?(head, "-") ->
        log_term("get_number - 6")

        head = safe_replace(head, ~r/^(\d+)\-(\d+\/\d+)$/, "\\1 \\2")
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
      get_suffix_value(head) == "AVE" &&
          (get_direction_value(tail_head) != "" or string_is_number_or_fraction?(tail_head)) ->
        get_post_direction(backup, backup, nil, raw_pd, true)

      # If there is only one term left (an address number) then we likely were too aggressive about
      # and we are not dealing with a post_direction anyway i.e. "101 W North" 
      address_length == 1 ->
        get_post_direction(backup, backup, nil, raw_pd, true)

      get_direction_value(head) == "" ->
        get_post_direction(address, backup, post_direction, raw_pd, true)

      true ->
        get_post_direction(tail, backup, new_direction, append_string(raw_pd, head), false)
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
        log_term("at 1")
        {single_word_direction, head, tail}

      single_word_direction != "" && next_is_direction &&
          tail_tail_head == nil ->
        log_term("at 2")

        {single_word_direction, head, tail}

      single_word_direction != "" && next_is_direction &&
        !tail_tail_head_is_keyword && double_word_direction != "" ->
        log_term("at 3")

        {double_word_direction, head <> tail_head, tail_tail}

      # Following case happens with an illegal double direction (i.e. W N Michigan Rd)
      # Since it's an illegal direction we punt so these terms are pre-pended to the street name
      single_word_direction != "" && next_is_direction &&
          !tail_tail_head_is_keyword ->
        log_term("at 4")
        {nil, nil, address}

      # single_word_direction != "" && tail == [] ->
      #   {nil, address}

      single_word_direction != "" ->
        log_term("at 5")

        {single_word_direction, head, tail}

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
          #   log_term("at 1")
          #   IO.inspect(backup, label: "at 1")
          #   get_secondary(tail, backup, pmb, designator, value, addit, false)

          tail_head == '&' ->
            log_term("at 2")

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
            log_term("at 3")
            get_secondary(tail, backup, pmb, designator, head, addit, false)

          tail_head == "#" ->
            log_term("at 4")
            get_secondary(tail_tail, backup, pmb, designator, head, addit, false)

          true ->
            log_term("at 5")
            get_secondary(tail, backup, pmb, designator, head, addit, false)
        end

      safe_has_key?(units, head) ->
        cond do
          safe_has_key?(suffixes, value) ->
            log_term("at 6")
            get_secondary(backup, backup, nil, nil, nil, addit, true)

          value ->
            log_term("at 6a")
            get_secondary(tail, backup, pmb, Map.get(units, head), value, addit, true)

          # For the secondary parsing to work when a valid Unit is provided we need to have a value
          true ->
            log_term("at 7")
            get_secondary(backup, backup, nil, nil, nil, addit, true)
        end

      value && Map.values(units) |> Enum.member?(head) ->
        log_term("at 8")
        get_secondary(tail, backup, pmb, head, value, addit, true)

      safe_starts_with?(head, "#") && !contains_po_box?(address) ->
        all_unit_values = Map.keys(units) ++ Map.values(units)

        cond do
          # TODO: Other highway selectors belong here - but with risk of false positives
          # plan to add as real cases appear
          Enum.member?(["RT"], tail_head) ->
            get_secondary(backup, backup, pmb, designator, nil, addit, true)

          Enum.member?(all_unit_values, tail_head) ->
            secondary_unit =
              cond do
                Map.values(units) |> Enum.member?(tail_head) ->
                  tail_head

                true ->
                  Map.get(units, tail_head)
              end

            log_term("at 9")

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
            log_term("at 10")

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
          Enum.member?(all_unit_values, tail_head) ->
            secondary_unit =
              cond do
                Map.values(units) |> Enum.member?(tail_head) ->
                  tail_head

                true ->
                  Map.get(units, tail_head)
              end

            log_term("at 11")
            get_secondary(tail_tail, backup, pmb, secondary_unit, head <> value, addit, true)

          Enum.member?(all_unit_values, head) ->
            secondary_unit =
              cond do
                Map.values(units) |> Enum.member?(head) ->
                  head

                true ->
                  Map.get(units, head)
              end

            log_term("at 12")
            get_secondary(tail, backup, pmb, secondary_unit, value, addit, true)

          true ->
            log_term("at 13")
            get_secondary(backup, backup, pmb, designator, nil, addit, true)
        end

      is_possible_suite_number?(tail_head) &&
          (safe_has_key?(units, tail_head) ||
             Map.values(units) |> Enum.member?(tail_head)) ->
        log_term("at 14")

        get_secondary(tail, backup, pmb, designator, safe_replace(head, ",", ""), addit, false)

      get_suffix_value(tail_head) != nil && get_suffix_value(head) == nil ->
        cond do
          is_possible_suite_number?(head) &&
              (String.length(hd(tail_tail)) < 2 ||
                 hd(tail_tail) == "STATE") ->
            log_term(backup, "at 15")
            get_secondary(backup, backup, pmb, designator, value, addit, true)

          Map.values(directions) |> Enum.member?(head) ||
              safe_has_key?(directions, head) ->
            log_term(backup, "at 16")
            get_secondary(backup, backup, pmb, designator, value, addit, true)

          # Handle "1400 W Avenue B"
          get_suffix_value(tail_head) == "AVE" && String.length(head) == 1 ->
            log_term(backup, "at 16a")
            get_secondary(backup, backup, pmb, designator, value, addit, true)

          true ->
            log_term(backup, "at 17")

            get_secondary(backup, backup, pmb, designator, value, addit, true)
            # get_secondary(
            #   tail,
            #   backup,
            #   pmb,
            #   designator,
            #   value,
            #   append_string_with_space(addit, head),
            #   true
            # )
        end

      tail_head == "&" ->
        log_term("at 18")
        get_secondary(tail_tail, backup, pmb, designator, value, addit, false)

      true ->
        log_term("at 19")
        get_secondary(backup, backup, pmb, designator, value, addit, true)
    end
  end

  # Parses the street out of the address list and returns the street name as a
  # string.
  defp get_street(address) when not is_list(address), do: nil
  defp get_street([]), do: nil
  defp get_street(address), do: get_street(address, nil, false)
  defp get_street([], street, false), do: get_street([], street, true)

  defp get_street(_address, street, true), do: street

  # defp get_street(_address, street, true) do
  #   corner_case_street_names = %{"PGA" => "PGA", "RT" => "ROUTE"}
  #   filtered_street = street |> safe_replace(~r/\s(\d+)/, "")
  #   # directions = AddressUSConfig.directions()
  #   # rev_directions = AddressUSConfig.reversed_directions()

  #   cond do
  #     safe_has_key?(corner_case_street_names, filtered_street) ->
  #       street_name =
  #         Map.get(corner_case_street_names, filtered_street)
  #         |> safe_replace(~r/\s(\d+)/, "")

  #       street_number = " " <> safe_replace(street, ~r/[a-zA-Z\s]+/, "")
  #       (street_name <> street_number) |> safe_replace(~r/\s$/, "")

  #     # # Can't assume "E" street is "East" street -- if it were a directional it would have already
  #     # # been parsed into the pre_direction field
  #     #
  #     # Enum.member?(
  #     #   Map.keys(directions) ++ Map.values(directions),
  #     #   title_case(street)
  #     # ) ->
  #     #   cond do
  #     #     Map.has_key?(directions, title_case(street)) ->
  #     #       title_case(street)

  #     #     true ->
  #     #       Map.get(rev_directions, String.upcase(street))
  #     #   end

  #     true ->
  #       street
  #   end
  # end

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
                Map.has_key?(directions, head) ->
                  Map.get(rev_directions, Map.get(directions, head))

                true ->
                  Map.get(rev_directions, head)
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
            street == nil -> head
            true -> street <> " " <> head
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
        get_suffix(tail, new_suffix, head, true)

      true ->
        get_suffix(address, nil, nil, true)
    end
  end

  # Returns the appropriate suffix value if one is found.
  # NOTE: this is a public function as it can be called externally to validate if a word is a suffix
  def get_suffix_value(value) when not is_binary(value), do: nil

  def get_suffix_value(value) do
    suffixes = AddressUSConfig.common_suffixes()
    # cleaned_value = title_case(value)
    # capitalized_keys = Map.keys(suffixes) |> Enum.map(&title_case(&1))
    # capitalized_values = Map.values(suffixes) |> Enum.map(&title_case(&1))
    suffix_values = Map.keys(suffixes) ++ Map.values(suffixes)

    cond do
      Enum.member?(suffix_values, value) ->
        case safe_has_key?(suffixes, value) do
          true -> Map.get(suffixes, value)
          false -> value
        end

      true ->
        nil
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

    if String.first(head) == "#" or Enum.member?(all_unit_values, head) do
      {nil, Enum.map(backup, fn x -> String.replace(x, ~r/(\(|\))/, "") end)}
    else
      {trailing_paren, Enum.map(address, fn x -> String.replace(x, ~r/(\(|\))/, "") end)}
    end
  end

  # First run-through
  defp get_trailing_parens(address, backup, nil, false) do
    # addr_str = Enum.reverse(address) |> Enum.join(" ")
    [head | tail] = address

    case {String.first(head), String.last(head), String.length(head)} do
      {"(", ")", len} when len > 2 ->
        get_trailing_parens(tail, backup, String.slice(head, 1..-2), true)

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

  # Detects if a string is a state or not.
  defp is_state?(state) when not is_binary(state), do: false

  defp is_state?(state) do
    states = AddressUSConfig.states()

    cond do
      safe_has_key?(states, state) -> true
      Map.values(states) |> Enum.member?(state) -> true
      true -> false
    end
  end

  # Additional designations and suffixes could be present in the final processed street name
  # This function isn't intended to solve all of these cases but common ones are covered
  defp strip_additional_and_suffix_from_name(street_name, additional, suffix) do
    {st, ad, su} =
      {street_name, additional, suffix}
      # |> safe_replace_first_elem(~r/\#/, "")
      |> strip_regex_to_additional(~r/( |\-)PO BOX \w+$/i)
      |> strip_regex_to_additional(~r/( |\-)BOX \w+$/i)
      |> strip_regex_to_additional(~r/( |\-)MILEPOST (\w|\.)+$/i)
      |> strip_embedded_suffix()

    {safe_replace(st, "_", " "), safe_replace(ad, "_", " "), su}
  end

  def strip_embedded_suffix({street_name, additional, nil} = tuple)
      when not is_nil(street_name) do
    # Checking if the string contains a suffix string before going through the expensive operation
    if String.contains?(street_name, AddressUSConfig.common_suffix_keys()) do
      rev_street_list = street_name |> String.split(" ") |> Enum.reverse()

      # rev_last_suffix_index =
      #   Enum.find_index(rev_street_list, fn x -> Enum.member?(suf_list, x) end)
      rev_last_suffix_index = get_valid_suffix_index(rev_street_list)

      cond do
        rev_last_suffix_index == nil ->
          tuple

        # If the first term in the street name is a suffix then ignore (as it's really the street name)
        rev_last_suffix_index == length(rev_street_list) - 1 ->
          tuple

        true ->
          street_list = Enum.reverse(rev_street_list)
          last_suffix_index = length(street_list) - 1 - rev_last_suffix_index
          ret_street = Enum.take(street_list, last_suffix_index) |> Enum.join(" ")
          ret_suffix = get_suffix_value(Enum.at(street_list, last_suffix_index))

          new_addtl =
            Enum.take(street_list, (length(street_list) - (last_suffix_index + 1)) * -1)
            |> Enum.join(" ")

          ret_addtl = append_string_with_space(additional, new_addtl)
          {ret_street, ret_addtl, ret_suffix}
      end
    else
      tuple
    end
  end

  def strip_embedded_suffix(tuple), do: tuple

  ############################################################################
  ## Private Functions
  ############################################################################

  defp get_valid_suffix_index(street_list) do
    Enum.with_index(street_list)
    |> Enum.reduce_while({"", -1}, &test_suffix/2)
    |> case do
      tuple when is_tuple(tuple) -> nil
      idx when is_integer(idx) -> idx
      _ -> nil
    end
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

  defp test_suffix(current, last) do
    if Enum.member?(AddressUSConfig.common_suffix_keys(), elem(last, 0)) do
      # NO LONGER NEEDED
      # && not Enum.member?(["COUNTY", "STATE", "US"], elem(current, 0)) do
      {:halt, elem(last, 1)}
    else
      {:cont, current}
    end
  end
end
