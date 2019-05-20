defmodule AddressUSTest do
  use ExUnit.Case

  import AddressUS.Parser

  test "Parse 5 digit postal code" do
    desired_result = %Address{postal: "80219"}
    result = parse_address("80219")
    assert desired_result == result
  end

  test "Parse 5 digit postal code with plus4" do
    desired_result = %Address{postal: "80219", plus_4: "1234"}
    result = parse_address("80219-1234")
    assert desired_result == result
  end

  test "Parse 3 digit postal code and pad it with zeros" do
    desired_result = %Address{postal: "00219"}
    result = parse_address("219")
    assert desired_result == result
  end

  test "Parse 4 digit postal code with 2 digit plus4 and pad both with zeros" do
    desired_result = %Address{postal: "00219", plus_4: "0023"}
    result = parse_address("219-23")
    assert desired_result == result
  end

  test "Parse a 6 digit postal code and return a blank field" do
    desired_result = %Address{street: %Street{primary_number: "123456"}}
    result = parse_address("123456")
    assert desired_result == result
  end

  test "Parse postal code and return a blank field" do
    desired_result = %Address{street: %Street{name: "Bob"}}
    result = parse_address("bob")
    assert desired_result == result
  end

  test "Parse address with every type of address field." do
    desired_result = %Address{
      city: "Denver",
      plus_4: "1234",
      postal: "80219",
      state: "CO",
      street: %Street{
        name: "B",
        pmb: "12",
        post_direction: "SW",
        pre_direction: "S",
        primary_number: "2345",
        secondary_designator: "Ste",
        secondary_value: "200",
        suffix: "St"
      }
    }

    result = parse_address("Parse 2345 S. B St. South West, Suite 200
      #12, Denver, Colorado 80219-1234")
    assert desired_result == result
  end

  test "Parse an address with a state abbreviation correctly" do
    desired_result = %Address{
      city: "Denver",
      plus_4: "1234",
      postal: "80219",
      state: "CO",
      street: %Street{
        name: "B",
        pmb: "12",
        post_direction: "SW",
        pre_direction: "S",
        primary_number: "2345",
        secondary_designator: "Ste",
        secondary_value: "200",
        suffix: "St"
      }
    }

    result = parse_address("Parse 2345 S. B St. South West, Suite 200
      #12, Denver, CO 80219-1234")
    assert desired_result == result
  end

  test "Parse an address with an unabbreviated 2-word state" do
    desired_result = %Address{
      city: "Charlotte",
      plus_4: "1234",
      postal: "80219",
      state: "NC",
      street: %Street{
        name: "B",
        pmb: "12",
        post_direction: "SW",
        pre_direction: "S",
        primary_number: "2345",
        secondary_designator: "Ste",
        secondary_value: "200",
        suffix: "St"
      }
    }

    result = parse_address("Parse 2345 S. B St. South West, Suite 200
      #12, Charlotte, North Carolina, 80219-1234")
    assert desired_result == result
  end

  test "Parse an address with an unabbreviated 3-word state" do
    desired_result = %Address{
      city: "Something",
      postal: "80219",
      state: "DC",
      street: %Street{name: "Bob", primary_number: "2345"}
    }

    result = parse_address("2345 Bob, Something, District of Columbia
      80219")
    assert desired_result == result
  end

  test "Parse an address with an unabbreviated 4-word state" do
    desired_result = %Address{
      city: "Something",
      postal: "80219",
      state: "AE",
      street: %Street{name: "Bob", primary_number: "2345"}
    }

    result = parse_address("2345 Bob, Something, Armed Forces Middle East
      80219")
    assert desired_result == result
  end

  test "Parse an address with a 2-word city" do
    desired_result = %Address{
      city: "Bob City",
      postal: "80219",
      state: "CA",
      street: %Street{name: "Blah", primary_number: "2345", suffix: "St"}
    }

    result = parse_address("2345 Blah St. Bob City, CA, 80219")
    assert desired_result == result
  end

  test "Parse an address with a business name" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Meade", primary_number: "2345", pre_direction: "SW", suffix: "St"}
    }

    result = parse_address("Bob's Dick Shack 2345 SW Meade St, Denver CO, 80219")
    assert desired_result == result
  end

  test "Parse an address that has an address number that ends with a letter" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{
        name: "Meade",
        primary_number: "2345",
        pre_direction: "SW",
        suffix: "St",
        secondary_value: "B"
      }
    }

    result = parse_address("2345B SW Meade St, Denver CO, 80219")
    assert desired_result == result
  end

  test "Parse an address that has a PO Box" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "PO BOX", primary_number: "18"}
    }

    result = parse_address("PO Box 18, Denver CO, 80219")
    assert desired_result == result
  end

  test "Parse an address that has a PO Box with funny spacing" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "PO BOX", primary_number: "18"}
    }

    result = parse_address("P. O. Box #18, Denver CO, 80219")
    assert desired_result == result
  end

  test "Parse an address that has a two-word pre_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", pre_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 South West Blah Street, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address that has a split abbreviated pre_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", pre_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 S W Blah Street, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address that has a joined two-word pre_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", pre_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 Southwest Blah Street, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address that has an abbreviated pre_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", pre_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 SW Blah Street, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address that has an 1/2 abbreviated two-word pre_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", pre_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 South W Blah Street, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address with a Suite" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{
        name: "Blah",
        primary_number: "2345",
        pre_direction: "SW",
        secondary_designator: "Ste",
        secondary_value: "200",
        suffix: "St"
      }
    }

    result = parse_address("2345 South W Blah Street, Suite 200, Denver
      CO, 80219")
    assert desired_result == result
  end

  # NOTE: Deviating from upstream -- Basement is an additional designation in this case
  # Corner cases made requiring a value with a secondary designator (unless it's of form #44)
  test "Parse an address with no secondary number" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{
        name: "Blah",
        primary_number: "2345",
        pre_direction: "SW",
        additional_designation: "Basement",
        suffix: "St"
      }
    }

    result = parse_address("2345 South W Blah Street, Basement, Denver
      CO, 80219")
    assert desired_result == result
  end

  test "Parse an address with a secondary number, designator, and pmb" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{
        name: "Blah",
        primary_number: "2345",
        pre_direction: "SW",
        secondary_designator: "Ste",
        secondary_value: "204",
        suffix: "St",
        pmb: "10"
      }
    }

    result = parse_address("2345 South W Blah Street, Suite 204 #10
      Denver CO, 80219")
    assert desired_result == result
  end

  test "Parse an address that has a highway for the street name." do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Highway 80", primary_number: "2345", pre_direction: "SW"}
    }

    result = parse_address("2345 SW Highway 80, Denver CO 80219")
    assert desired_result == result
  end

  test "Parse an address that has a two-word post_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", post_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 Blah Street South West, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address that has a split abbreviated post_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", post_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 Blah Street S W, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address that has a joined two-word post_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", post_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 Blah Street Southwest, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address that has an abbreviated post_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", post_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 Blah Street SW, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address that has an 1/2 abbreviated two-word post_direction" do
    desired_result = %Address{
      city: "Denver",
      postal: "80219",
      state: "CO",
      street: %Street{name: "Blah", primary_number: "2345", post_direction: "SW", suffix: "St"}
    }

    result = parse_address("2345 Blah Street South W, Denver CO
      80219")
    assert desired_result == result
  end

  test "Parse an address line with every type of address field" do
    desired_result = %Street{
      name: "B",
      pmb: "12",
      post_direction: "SW",
      pre_direction: "S",
      primary_number: "2345",
      secondary_designator: "Ste",
      secondary_value: "200",
      suffix: "St"
    }

    result = parse_address_line("Parse 2345 S. B St. South West Suite
      200 #12")
    assert desired_result == result
  end

  test "not choke on a garbage address line" do
    desired_result = nil
    result = parse_address_line("")
    assert desired_result == result
  end

  ############################################################################
  ## Random addresses that have broken this library at some point.
  ############################################################################

  test "Parse address: A. P. Croll & Son 2299 Lewes-Georgetown Hwy, Georgetown
      DE 19947-1114" do
    desired_result = %Address{
      city: "Georgetown",
      postal: "19947",
      plus_4: "1114",
      state: "DE",
      street: %Street{primary_number: "2299", suffix: "Hwy", name: "Lewes-Georgetown"}
    }

    result = parse_address("A. P. Croll & Son 2299 Lewes-Georgetown Hwy
      Georgetown, DE 19947-1114")
    assert desired_result == result
  end

  test "Parse address: 11522 Shawnee Road, Greenwood DE 19950" do
    desired_result = %Address{
      city: "Greenwood",
      postal: "19950",
      state: "DE",
      street: %Street{primary_number: "11522", suffix: "Rd", name: "Shawnee"}
    }

    result = parse_address("11522 Shawnee Road, Greenwood DE 19950")
    assert desired_result == result
  end

  test "Parse address: 144 Kings Highway, S.W. Dover, Delaware 19901" do
    desired_result = %Address{
      city: "SW Dover",
      postal: "19901",
      state: "DE",
      street: %Street{primary_number: "144", suffix: "Hwy", name: "Kings"}
    }

    result = parse_address("144 Kings Highway, S.W. Dover, Delaware 19901")
    assert desired_result == result
  end

  test "Parse address: Intergrated Const. Services 2 Penns Way Suite 405
      New Castle, DE 19720" do
    desired_result = %Address{
      city: "New Castle",
      postal: "19720",
      state: "DE",
      street: %Street{
        primary_number: "2",
        suffix: "Way",
        name: "Penns",
        secondary_designator: "Ste",
        secondary_value: "405"
      }
    }

    result = parse_address("Intergrated Const. Services 2 Penns Way Suite 405
      New Castle, DE 19720")
    assert desired_result == result
  end

  test "Parse address: Humes Realty 33 Bridle Ridge Court, Lewes, DE 19958" do
    desired_result = %Address{
      city: "Lewes",
      postal: "19958",
      state: "DE",
      street: %Street{primary_number: "33", suffix: "Ct", name: "Bridle Ridge"}
    }

    result = parse_address("Humes Realty 33 Bridle Ridge Court, Lewes, DE
      19958")
    assert desired_result == result
  end

  test "Parse address: Nichols Excavation 2742 Pulaski Hwy Newark, DE
      19711-8282" do
    desired_result = %Address{
      city: "Newark",
      postal: "19711",
      plus_4: "8282",
      state: "DE",
      street: %Street{primary_number: "2742", suffix: "Hwy", name: "Pulaski"}
    }

    result = parse_address("Nichols Excavation 2742 Pulaski Hwy Newark, DE
      19711-8282")
    assert desired_result == result
  end

  test "Parse address: 2284 Bryn Zion Road, Smyrna, DE 19904" do
    desired_result = %Address{
      city: "Smyrna",
      postal: "19904",
      state: "DE",
      street: %Street{primary_number: "2284", suffix: "Rd", name: "Bryn Zion"}
    }

    result = parse_address("2284 Bryn Zion Road, Smyrna, DE 19904")
    assert desired_result == result
  end

  test "Parse address: VEI Dover Crossroads, LLC 1500 Serpentine Road
      Suite 100 Baltimore MD 21" do
    desired_result = %Address{
      city: "Baltimore",
      postal: "00021",
      state: "MD",
      street: %Street{
        primary_number: "1500",
        suffix: "Rd",
        name: "Serpentine",
        secondary_designator: "Ste",
        secondary_value: "100"
      }
    }

    result = parse_address("VEI Dover Crossroads, LLC 1500 Serpentine Road
      Suite 100 Baltimore MD 21")
    assert desired_result == result
  end

  test "Parse address: 580 North Dupont Highway Dover, DE 19901" do
    desired_result = %Address{
      city: "Dover",
      postal: "19901",
      state: "DE",
      street: %Street{primary_number: "580", suffix: "Hwy", name: "Dupont", pre_direction: "N"}
    }

    result = parse_address("580 North Dupont Highway Dover, DE 19901")
    assert desired_result == result
  end

  test "Parse address: P.O. Box 778 Dover, DE 19903" do
    desired_result = %Address{
      city: "Dover",
      postal: "19903",
      state: "DE",
      street: %Street{primary_number: "778", name: "PO BOX"}
    }

    result = parse_address("P.O. Box 778 Dover, DE 19903")
    assert desired_result == result
  end

  test "Parse address: State Rd 2 & Carr #128, Yauco, PR" do
    desired_result = %Address{
      city: "Yauco",
      state: "PR",
      street: %Street{name: "Carr", pmb: "128"}
    }

    result = parse_address("State Rd 2 & Carr #128, Yauco, PR")
    assert desired_result == result
  end

  test "Parse address: Rr 2 Box 631, Bridgeport, WV" do
    desired_result = %Address{
      city: "Bridgeport",
      state: "WV",
      street: %Street{name: "PO BOX", primary_number: "631"}
    }

    result = parse_address("Rr 2 Box 631, Bridgeport, WV")
    assert desired_result == result
  end

  test "Parse address: 2155 SR-18, Brandon, MS" do
    desired_result = %Address{
      city: "Brandon",
      state: "MS",
      street: %Street{name: "State Route 18", primary_number: "2155"}
    }

    result = parse_address("2155 SR-18, Brandon, MS")
    assert desired_result == result
  end

  # I think this should be parsed as "W" street not West street (i.e. W Street, Lincoln, NE and W Street NW, Washington, DC are real streets)
  # test "Parse address: 804 & 806 W Street, Watertown, North Dakota" do
  #   desired_result = %Address{
  #     city: "Watertown",
  #     state: "ND",
  #     street: %Street{name: "West", primary_number: "806", suffix: "St"}
  #   }

  #   result = parse_address("804 & 806 W Street, Watertown, North Dakota")
  #   assert desired_result == result
  # end

  test "Parse address: 804 & 806 N West Street, Watertown, WI" do
    desired_result = %Address{
      city: "Watertown",
      state: "WI",
      street: %Street{name: "West", pre_direction: "N", primary_number: "806", suffix: "St"}
    }

    result = parse_address("804 & 806 N West Street, Watertown, WI")
    assert desired_result == result
  end

  test "Parse address: 804 & 806 1/2 North West Street, Bizarro, WI" do
    desired_result = %Address{
      city: "Bizarro",
      state: "WI",
      street: %Street{name: "West", pre_direction: "N", primary_number: "806 1/2", suffix: "St"}
    }

    result = parse_address("804 & 806 1/2 North West Street, Bizarro, WI")
    assert desired_result == result
  end

  test "Parse address: 804 & 806 1/2 North West West Street, Suite 11 #22
      Bizarro, WI" do
    desired_result = %Address{
      city: "Bizarro",
      state: "WI",
      street: %Street{
        name: "West",
        pre_direction: "NW",
        primary_number: "806 1/2",
        suffix: "St",
        secondary_designator: "Ste",
        secondary_value: "11",
        pmb: "22"
      }
    }

    result = parse_address("804 & 806 1/2 North West West Street, Suite 11 #22
      Bizarro, WI")
    assert desired_result == result
  end

  test "Parse address: 2345 Highway 3 Bypass Road, Suite 22 #65, Casper, WY
      82609" do
    desired_result = %Address{
      city: "Casper",
      state: "WY",
      postal: "82609",
      street: %Street{
        name: "Highway 3 Bypass",
        suffix: "Rd",
        primary_number: "2345",
        secondary_designator: "Ste",
        pmb: "65",
        secondary_value: "22"
      }
    }

    result = parse_address("2345 Highway 3 Bypass Road, Suite 22 #65, Casper
      WY 82609")
    assert desired_result == result
  end

  test "Parse address: 5567 IH-280, Suite 22 #65, Casper, WY, 82609" do
    desired_result = %Address{
      city: "Casper",
      state: "WY",
      postal: "82609",
      street: %Street{
        name: "Interstate 280",
        primary_number: "5567",
        secondary_designator: "Ste",
        pmb: "65",
        secondary_value: "22"
      }
    }

    result = parse_address("5567 IH-280, Suite 22 #65, Casper, WY, 82609")
    assert desired_result == result
  end

  test "Parse address: 5567 I-55 Bypass Road, Suite 22 #65, Casper, WY" do
    desired_result = %Address{
      city: "Casper",
      state: "WY",
      street: %Street{
        name: "Interstate 55 Bypass",
        primary_number: "5567",
        secondary_designator: "Ste",
        pmb: "65",
        secondary_value: "22",
        suffix: "Rd"
      }
    }

    result = parse_address("5567 I-55 Bypass Road, Suite 22 #65, Casper, WY")
    assert desired_result == result
  end

  test "Parse address: 2345 Highway 26 Frontage Road, Suite 22 #65, Casper
      WY, 82609" do
    desired_result = %Address{
      city: "Casper",
      state: "WY",
      postal: "82609",
      street: %Street{
        name: "Highway 26 Frontage",
        primary_number: "2345",
        secondary_designator: "Ste",
        pmb: "65",
        secondary_value: "22",
        suffix: "Rd"
      }
    }

    result = parse_address("2345 Highway 26 Frontage Road, Suite 22 #65
      Casper, WY, 82609")
    assert desired_result == result
  end

  test "Parse address: 2345 US Highway 44 SW, Suite 22, Casper, WY, 82609" do
    desired_result = %Address{
      city: "Casper",
      state: "WY",
      postal: "82609",
      street: %Street{
        name: "US Highway 44",
        primary_number: "2345",
        post_direction: "SW",
        secondary_designator: "Ste",
        secondary_value: "22"
      }
    }

    result = parse_address("2345 US Highway 44 SW, Suite 22, Casper, WY, 82609")
    assert desired_result == result
  end

  # NOTE: The new highway standardization code must treat the next term after "County Road" as part of the name since
  # frequently the county roads are named with sequences of letters (which may include N, S, E, and W) and "County Road" is
  # part of the name -- so we don't want the Road taken out as a suffix.  This test was modified to support that.
  test "Parse address: 14 County Road North East, Suite 22, Casper, WY
      82609" do
    desired_result = %Address{
      city: "Casper",
      state: "WY",
      postal: "82609",
      street: %Street{
        name: "County Road North",
        primary_number: "14",
        post_direction: "E",
        secondary_designator: "Ste",
        secondary_value: "22"
      }
    }

    result = parse_address("14 County Road North East, Suite 22, Casper, WY
      82609")
    assert desired_result == result
  end

  test "Parse address: Georgia 138 Riverdale, GA 30274" do
    desired_result = %Address{
      city: "Riverdale",
      state: "GA",
      postal: "30274",
      street: %Street{name: "Georgia 138"}
    }

    result = parse_address("Georgia 138 Riverdale, GA 30274")
    assert desired_result == result
  end

  # Change: Test standardizing FM roads per USPS Pub 28
  test "Parse address: 2230 Farm to Market 407, Highland Village, TX 75077" do
    desired_result = %Address{
      city: "Highland Village",
      state: "TX",
      postal: "75077",
      street: %Street{name: "FM 407", primary_number: "2230"}
    }

    result = parse_address("2230 Farm to Market 407, Highland Village, TX
      75077")
    assert desired_result == result
  end

  test "Parse address: 1700 Box Rd, Columbus, GA 75077" do
    desired_result = %Address{
      city: "Columbus",
      state: "GA",
      postal: "75077",
      street: %Street{name: "Box", suffix: "Rd", primary_number: "1700"}
    }

    result = parse_address("1700 Box Rd, Columbus, GA 75077")
    assert desired_result == result
  end

  test "Parse address: 3300 Bee Caves Rd Unit 670, Austin TX 78747" do
    desired_result = %Address{
      city: "Austin",
      state: "TX",
      postal: "78747",
      street: %Street{
        name: "Bee Caves",
        suffix: "Rd",
        primary_number: "3300",
        secondary_designator: "Unit",
        secondary_value: "670"
      }
    }

    result = parse_address("3300 Bee Caves Rd Unit 670, Austin TX 78747")
    assert desired_result == result
  end

  test "Parse address: 4423 E Thomas Rd Ste B Phoenix, AZ 85018" do
    desired_result = %Address{
      city: "Phoenix",
      state: "AZ",
      postal: "85018",
      street: %Street{
        name: "Thomas",
        suffix: "Rd",
        primary_number: "4423",
        pre_direction: "E",
        secondary_designator: "Ste",
        secondary_value: "B"
      }
    }

    result = parse_address("4423 E Thomas Rd Ste B Phoenix, AZ 85018")
    assert desired_result == result
  end

  test "Parse address: 4423 E Thomas Rd (SEC) Ste B Phoenix, AZ 85018" do
    desired_result = %Address{
      city: "Phoenix",
      state: "AZ",
      postal: "85018",
      street: %Street{
        name: "Thomas",
        suffix: "Rd",
        primary_number: "4423",
        pre_direction: "E",
        secondary_designator: "Ste",
        secondary_value: "B",
        additional_designation: "(sec)"
      }
    }

    result = parse_address("4423 E Thomas Rd (SEC) Ste B Phoenix, AZ 85018")
    assert desired_result == result
  end

  test "Parse address: 4423 E Thomas Rd (Ste B) Phoenix, AZ 85018" do
    desired_result = %Address{
      city: "Phoenix",
      state: "AZ",
      postal: "85018",
      street: %Street{
        name: "Thomas",
        suffix: "Rd",
        primary_number: "4423",
        pre_direction: "E",
        secondary_designator: "Ste",
        secondary_value: "B"
      }
    }

    result = parse_address("4423 E Thomas Rd (Ste B) Phoenix, AZ 85018")
    assert desired_result == result
  end

  test "Parse address: 11681 US HWY 70, Clayton, NC 27520" do
    desired_result = %Address{
      city: "Clayton",
      state: "NC",
      postal: "27520",
      street: %Street{name: "US Highway 70", primary_number: "11681"}
    }

    result = parse_address("11681 US HWY 70, Clayton, NC 27520")
    assert desired_result == result
  end

  test "Parse address: 435 N 1680 East Suite # 8, St. George, UT 8470" do
    desired_result = %Address{
      city: "St George",
      state: "UT",
      postal: "08470",
      street: %Street{
        name: "1680",
        primary_number: "435",
        pre_direction: "N",
        post_direction: "E",
        secondary_designator: "Ste",
        secondary_value: "8"
      }
    }

    result = parse_address("435 N 1680 East Suite # 8, St. George, UT 8470")
    assert desired_result == result
  end

  test "Parse address: 5 Bel Air S Parkway Suite L 1219, Bel Air, MD, 21015" do
    desired_result = %Address{
      city: "Bel Air",
      state: "MD",
      postal: "21015",
      street: %Street{
        name: "Bel Air S",
        primary_number: "5",
        suffix: "Pkwy",
        secondary_designator: "Ste",
        secondary_value: "L1219"
      }
    }

    result = parse_address("5 Bel Air S Parkway Suite L 1219, Bel Air, MD, 21015")
    assert desired_result == result
  end

  test "Parse address: 140 W Hively Avenue STE 2, Bel Air, MD, 21015" do
    desired_result = %Address{
      city: "Bel Air",
      state: "MD",
      postal: "21015",
      street: %Street{
        name: "Hively",
        primary_number: "140",
        pre_direction: "W",
        suffix: "Ave",
        secondary_designator: "Ste",
        secondary_value: "2"
      }
    }

    result = parse_address("140 W Hively Avenue STE 2, Bel Air, MD, 21015")
    assert desired_result == result
  end

  test "Parse address: 2242 W 5400 S, Salt Lake City, UT 75169" do
    addr = "2242 W 5400 S, Salt Lake City, UT 75169"

    desired_result = %Address{
      city: "Salt Lake City",
      state: "UT",
      postal: "75169",
      street: %Street{
        name: "5400",
        primary_number: "2242",
        pre_direction: "W",
        post_direction: "S"
      }
    }

    assert desired_result == parse_address(addr)
    assert desired_result == String.upcase(addr) |> parse_address()
  end

  test "Parse address: 2242 W 5400 S, West Valley City, UT 75169" do
    desired_result = %Address{
      city: "West Valley City",
      state: "UT",
      postal: "75169",
      street: %Street{
        name: "5400",
        primary_number: "2242",
        pre_direction: "W",
        post_direction: "S"
      }
    }

    result = parse_address("2242 W 5400 S, West Valley City, UT 75169")
    assert desired_result == result
  end

  test "Parse address: 227 Fox Hill Rd Unit C-3, Orlando, FL 32803" do
    desired_result = %Address{
      city: "Orlando",
      state: "FL",
      postal: "32803",
      street: %Street{
        name: "Fox Hill",
        primary_number: "227",
        secondary_designator: "Unit",
        secondary_value: "C-3",
        suffix: "Rd"
      }
    }

    result = parse_address("227 Fox Hill Rd Unit C-3, Orlando, FL 32803")
    assert desired_result == result
  end

  test "Parse address: 227 Fox Hill Rd Unit#7, Orlando, FL 32803" do
    desired_result = %Address{
      city: "Orlando",
      state: "FL",
      postal: "32803",
      street: %Street{
        name: "Fox Hill",
        primary_number: "227",
        secondary_designator: "Unit",
        secondary_value: "7",
        suffix: "Rd"
      }
    }

    result = parse_address("227 Fox Hill Rd Unit#7, Orlando, FL 32803")
    assert desired_result == result
  end

  test "Parse address: 227A Fox Hill Rd, Orlando, FL 32803" do
    desired_result = %Address{
      city: "Orlando",
      state: "FL",
      postal: "32803",
      street: %Street{name: "Fox Hill", primary_number: "227", secondary_value: "A", suffix: "Rd"}
    }

    result = parse_address("227A Fox Hill Rd, Orlando, FL 32803")
    assert desired_result == result
  end

  test "233-B South Country Drive, Waverly, VA 32803" do
    desired_result = %Address{
      city: "Waverly",
      state: "VA",
      postal: "32803",
      street: %Street{
        name: "Country",
        primary_number: "233",
        secondary_value: "B",
        pre_direction: "S",
        suffix: "Dr"
      }
    }

    result = parse_address("233-B South Country Drive, Waverly, VA 32803")
    assert desired_result == result
  end

  test "820 A South Country Drive, Waverly, VA 32803" do
    desired_result = %Address{
      city: "Waverly",
      state: "VA",
      postal: "32803",
      street: %Street{
        name: "Country",
        primary_number: "820",
        secondary_value: "A",
        pre_direction: "S",
        suffix: "Dr"
      }
    }

    result = parse_address("820 A South Country Drive, Waverly, VA 32803")
    assert desired_result == result
  end

  # test "15 North Main St C03, Waverly, VA 32803" do
  #   desired_result = %Address{city: "Waverly", state: "VA",
  #   postal: "32803", street: %Street{name: "Main",primary_number: "15",
  #   secondary_value: "C03", pre_direction: "N", suffix: "St"}}
  #   result = parse_address("15 North Main St C03, Waverly, VA 32803")
  #   assert desired_result == result
  # end

  test "820 A E. Admiral Doyle Dr, Waverly, VA 32803" do
    desired_result = %Address{
      city: "Waverly",
      state: "VA",
      postal: "32803",
      street: %Street{
        name: "Admiral Doyle",
        primary_number: "820",
        secondary_value: "A",
        pre_direction: "E",
        suffix: "Dr"
      }
    }

    result = parse_address("820 A E. Admiral Doyle Dr, Waverly, VA 32803")
    assert desired_result == result
  end

  test "820 a E. Admiral Doyle Dr, Waverly, VA 32803" do
    desired_result = %Address{
      city: "Waverly",
      state: "VA",
      postal: "32803",
      street: %Street{
        name: "Admiral Doyle",
        primary_number: "820",
        secondary_value: "A",
        pre_direction: "E",
        suffix: "Dr"
      }
    }

    result = parse_address("820 a E. Admiral Doyle Dr, Waverly, VA 32803")
    assert desired_result == result
  end

  # According to USPS Pub 28 "HWY" is standardized as "Highway"
  test "394 S. HWY 29, Cantonment, FL 32803" do
    desired_result = %Address{
      city: "Cantonment",
      state: "FL",
      postal: "32803",
      street: %Street{name: "Highway 29", primary_number: "394", pre_direction: "S"}
    }

    result = parse_address("394 S. HWY 29, Cantonment, FL 32803")
    assert desired_result == result
  end

  test "5810 Bellfort St Ste D & E, Cantonment, FL 32803" do
    desired_result = %Address{
      city: "Cantonment",
      state: "FL",
      postal: "32803",
      street: %Street{
        name: "Bellfort",
        primary_number: "5810",
        secondary_designator: "Ste",
        secondary_value: "D",
        suffix: "St"
      }
    }

    result = parse_address("5810 Bellfort St Ste D & E, Cantonment, FL 32803")
    assert desired_result == result
  end

  # test "5000-16 Norwood Avenue, Space A-16, Jacksonville, FL 32208" do
  #   desired_result = %Address{city: "Jacksonville", state: "FL",
  #   postal: "32208", street: %Street{name: "Norwood", primary_number: "5000",
  #   secondary_designator: "Spc", secondary_value: "A-16", suffix: "Ave"}}
  #   result = parse_address("5000-16 Norwood Avenue, Space A-16, Jacksonville, FL 32208")
  #   assert desired_result == result
  # end

  # test "605-13 New Market Dr. Newport News, VA 23605" do
  #   desired_result = %Address{city: "Newport News", state: "VA",
  #   postal: "23605", street: %Street{name: "New Market", primary_number: "605",
  #   secondary_value: "13", suffix: "Dr"}}
  #   result = parse_address("605-13 New Market Dr. Newport News, VA 23605")
  #   assert desired_result == result
  # end

  # test "21-41 Main Street, Lockport, NY 14094" do
  #   desired_result = %Address{city: "Lockport", state: "NY",
  #   postal: "14094", street: %Street{name: "Main", primary_number: "21",
  #   secondary_value: "41", suffix: "St"}}
  #   result = parse_address("21-41 Main Street, Lockport, NY 14094")
  #   assert desired_result == result
  # end

  # test "18115 Highway I-30, Benton, AZ, 72015" do
  #   desired_result = %Address{city: "Benton", state: "AZ",
  #   postal: "72015", street: %Street{name: "I-30", primary_number: "18115"}}
  #   result = parse_address("18115 Highway I-30, Benton, AZ, 72015")
  #   assert desired_result == result
  # end

  # test "230 E. State Route 89A, Cottonwood, AZ, 86326" do
  #   desired_result = %Address{city: "Cottonwood", state: "AZ",
  #   postal: "86326", street: %Street{name: "State Route 89A",
  #   primary_number: "230", pre_direction: "E"}}
  #   result = parse_address("230 E. State Route 89A, Cottonwood, AZ, 86326")
  #   assert desired_result == result
  # end

  test "5227 14th St W, Bradenton, FL, 34207" do
    desired_result = %Address{
      city: "Bradenton",
      state: "FL",
      postal: "34207",
      street: %Street{name: "14th", primary_number: "5227", post_direction: "W", suffix: "St"}
    }

    result = parse_address("5227 14th St W, Bradenton, FL, 34207")
    assert desired_result == result
  end

  test "1429 San Mateo Blvd NE, Albuquerque, NM, 87110" do
    desired_result = %Address{
      city: "Albuquerque",
      state: "NM",
      postal: "87110",
      street: %Street{
        name: "San Mateo",
        primary_number: "1429",
        post_direction: "NE",
        suffix: "Blvd"
      }
    }

    result = parse_address("1429 San Mateo Blvd NE, Albuquerque, NM, 87110")
    assert desired_result == result
  end

  test "10424 Campus Way South, Upper Marlboro, MD, 20774" do
    desired_result = %Address{
      city: "Upper Marlboro",
      state: "MD",
      postal: "20774",
      street: %Street{name: "Campus", primary_number: "10424", post_direction: "S", suffix: "Way"}
    }

    result = parse_address("10424 Campus Way South, Upper Marlboro, MD, 20774")
    assert desired_result == result
  end

  test "3101 PGA Blvd, Palm Beach Gardens, FL 33401" do
    desired_result = %Address{
      city: "Palm Beach Gardens",
      state: "FL",
      postal: "33401",
      street: %Street{name: "PGA", primary_number: "3101", suffix: "Blvd"}
    }

    result = parse_address("3101 PGA Blvd, Palm Beach Gardens, FL 33401")
    assert desired_result == result
  end

  test "2341 Rt 66, Ocean, NJ 7712" do
    desired_result = %Address{
      city: "Ocean",
      state: "NJ",
      postal: "07712",
      street: %Street{name: "Route 66", primary_number: "2341"}
    }

    result = parse_address("2341 Rt 66, Ocean, NJ 7712")
    assert desired_result == result
  end

  test "2407 M L King Ave, Flint, MI 48505" do
    desired_result = %Address{
      city: "Flint",
      state: "MI",
      postal: "48505",
      street: %Street{name: "Martin Luther King", primary_number: "2407", suffix: "Ave"}
    }

    result = parse_address("2407 M L King Ave, Flint, MI 48505")
    assert desired_result == result
  end

  # test "3590 W. South Jordan Pkwy, South Jordan, UT 84095" do
  #   desired_result = %Address{city: "South Jordan", state: "UT",
  #   postal: "84095", street: %Street{name: "South Jordan",
  #   primary_number: "3590", pre_direction: "W", suffix: "Pkwy"}}
  #   result = parse_address("3590 W. South Jordan Pkwy, South Jordan, UT 84095")
  #   assert desired_result == result
  # end

  # test "5th Street, Suite 100, Denver, CO 80219" do
  #   desired_result = %Address{city: "Denver", state: "CO",
  #   postal: "80219", street: %Street{name: "5th", suffix: "St"}}
  #   result = parse_address("5th Street, Suite 100, Denver, CO 80219")
  #   assert desired_result == result
  # end

  # test "1315 U.S. 80 E, Demopolis, AL 36732, United States" do
  #   desired_result = %Address{city: "Demopolis", state: "AL",
  #   postal: "36732", street: %Street{name: "US 80",
  #   primary_number: "1315", post_direction: "E"}}
  #   result = parse_address("1315 U.S. 80 E, Demopolis, AL 36732, United States")
  #   assert desired_result == result
  # end

  test "2345 Front Street, Denver, CO 80219" do
    desired_result = %Address{
      city: "Denver",
      state: "CO",
      postal: "80219",
      street: %Street{name: "Front", primary_number: "2345", suffix: "St"}
    }

    result = parse_address("2345 Front Street, Denver, CO 80219")
    assert desired_result == result
  end

  # test "5215 W Indian School Rd, Ste 103 & 104, Phoenix, AZ 85031" do
  #   desired_result = %Address{city: "Phoenix", state: "AZ",
  #   postal: "85031", street: %Street{name: "Indian School",
  #   primary_number: "5215", suffix: "Rd", pre_direction: "W",
  #   secondary_designator: "Ste", secondary_value: "103"}}
  #   result = parse_address("5215 W Indian School Rd, Ste 103 & 104, Phoenix, AZ 85031")
  #   assert desired_result == result
  # end

  test "1093 B St, Hayward, CA, 94541" do
    desired_result = %Address{
      city: "Hayward",
      state: "CA",
      postal: "94541",
      street: %Street{name: "B", primary_number: "1093", suffix: "St"}
    }

    result = parse_address("1093 B St, Hayward, CA, 94541")
    assert desired_result == result
  end

  test "1410 N Lynhurst Drive, Indianapolis, IN 46224" do
    addr = "1410 N Lynhurst Drive, Indianapolis, IN 46224"

    desired_result = %Address{
      city: "Indianapolis",
      state: "IN",
      postal: "46224",
      street: %Street{name: "Lynhurst", primary_number: "1410", pre_direction: "N", suffix: "Dr"}
    }

    assert desired_result == parse_address(addr)
    assert desired_result == String.upcase(addr) |> parse_address()
  end

  test "1410 East Boulevard, Kokomo, IN 46902" do
    addr = "1410 East Boulevard, Kokomo, IN 46902"

    desired_result = %Address{
      city: "Kokomo",
      state: "IN",
      postal: "46902",
      street: %Street{name: "East Boulevard", primary_number: "1410"}
    }

    assert desired_result == parse_address(addr)
    assert desired_result == String.upcase(addr) |> parse_address()
  end

  test "2060 Airport Drive Hanger #39, Elkhart, IN 46514" do
    desired_result = %Address{
      city: "Elkhart",
      state: "IN",
      postal: "46514",
      street: %Street{
        name: "Airport",
        primary_number: "2060",
        suffix: "Dr",
        secondary_designator: "Hngr",
        secondary_value: "39"
      }
    }

    assert desired_result == parse_address("2060 Airport Drive Hanger #39, Elkhart, IN 46514")
  end

  test "708 S. HEATON (STATE ROAD 35), KNOX, IN" do
    desired_result = %Address{
      city: "Knox",
      state: "IN",
      street: %Street{
        name: "Heaton",
        primary_number: "708",
        pre_direction: "S",
        additional_designation: "State Road 35"
      }
    }

    assert desired_result == parse_address("708 S HEATON (STATE ROAD 35), KNOX, IN")
  end

  test "114 US Hwy 27N, Fountain City, IN  47341" do
    desired_result = %Address{
      city: "Fountain City",
      state: "IN",
      postal: "47341",
      street: %Street{
        name: "US Highway 27n",
        primary_number: "114"
      }
    }

    assert desired_result == parse_address("114 US Hwy 27N, Fountain City, IN  47341")
  end

  # Retain decimal if adjacent to at least one number
  test "404 E Main St (1.3 mi south of Market)" do
    desired_result = %Street{
      additional_designation: "1.3 Mi South Of Market",
      name: "Main",
      pre_direction: "E",
      primary_number: "404",
      suffix: "St"
    }

    assert desired_result == parse_address_line("404 E Main St (1.3 mi south of Market)")
  end

  # Stop is used as a street name and shouldn't be called out as a secondary unit
  test "404 W Stop 18" do
    desired_result = %Street{
      name: "Stop 18",
      pre_direction: "W",
      primary_number: "404"
    }

    assert desired_result == parse_address_line("404 W Stop 18")
  end

  test "404 South St" do
    desired_result = %Street{
      name: "South",
      suffix: "St",
      primary_number: "404"
    }

    assert desired_result == parse_address_line("404 South St")
  end

  test "202 South" do
    desired_result = %Street{
      name: "South",
      primary_number: "202"
    }

    assert desired_result == parse_address_line("202 South")
  end

  # In this case 301 Main Street is the address to be parsed and the PO Box is additional information
  test "301 Main Street PO Box 358" do
    desired_result = %Street{
      name: "Main",
      suffix: "St",
      primary_number: "301",
      additional_designation: "PO BOX 358"
    }

    assert desired_result == parse_address_line("301 Main Street PO Box 358")
  end

  test "301 Main Street Milepost 12.2" do
    desired_result = %Street{
      name: "Main",
      suffix: "St",
      primary_number: "301",
      additional_designation: "Milepost 12.2"
    }

    assert desired_result == parse_address_line("301 Main Street Milepost 12.2")
  end

  test "59-36 COOPER AVENUE, GLENDALE, NY 11385" do
    desired_result = %Address{
      city: "Glendale",
      postal: "11385",
      state: "NY",
      street: %Street{
        name: "Cooper",
        primary_number: "59-36",
        suffix: "Ave"
      }
    }

    assert desired_result == parse_address("59-36 COOPER AVENUE, GLENDALE, NY 11385")
  end

  test "1201 North E Street" do
    desired_result = %Street{
      name: "E",
      suffix: "St",
      primary_number: "1201",
      pre_direction: "N"
    }

    assert desired_result == parse_address_line("1201 North E Street")
  end

  test "1201 E Street" do
    desired_result = %Street{
      name: "E",
      suffix: "St",
      primary_number: "1201"
    }

    assert desired_result == parse_address_line("1201 E Street")
  end

  test "1201 NE" do
    desired_result = %Street{
      name: "NE",
      primary_number: "1201"
    }

    assert desired_result == parse_address_line("1201 NE")
  end

  test "275 250 N, Warsaw, IN  46580" do
    desired_result = %Address{
      city: "Warsaw",
      postal: "46580",
      state: "IN",
      street: %Street{
        name: "250",
        post_direction: "N",
        primary_number: "275"
      }
    }

    assert desired_result == parse_address("275 250 N, Warsaw, IN  46580")
  end

  test "700 South Box 6e" do
    desired_result = %Street{
      name: "Box 6e",
      pre_direction: "S",
      primary_number: "700"
    }

    assert desired_result == parse_address_line("700 South Box 6e")
  end

  test "1332 State Road #2 West" do
    desired_result = %Street{
      name: "State Road 2",
      post_direction: "W",
      primary_number: "1332"
    }

    assert desired_result == parse_address_line("1332 State Road #2 West")
  end

  # Don't discard unparseable additional information at end of address
  test "15202 Edgerton Road T-209, New Haven, IN" do
    desired_result = %Address{
      city: "New Haven",
      state: "IN",
      street: %Street{
        additional_designation: "T-209",
        name: "Edgerton",
        primary_number: "15202",
        suffix: "Rd"
      }
    }

    assert desired_result == parse_address("15202 Edgerton Road T-209, New Haven, IN")
  end

  test "1040 A Avenue" do
    desired_result = %Street{
      name: "A",
      primary_number: "1040",
      suffix: "Ave"
    }

    assert desired_result == parse_address_line("1040 A Avenue")
  end

  test "201 E MAIN ST BOX 291" do
    desired_result = %Street{
      additional_designation: "Box 291",
      name: "Main",
      pre_direction: "E",
      primary_number: "201",
      suffix: "St"
    }

    assert desired_result == parse_address_line("201 E MAIN ST BOX 291")
  end

  # 2 pre-directions when combined are invalid
  test "3977 W N MICHIGAN RD" do
    desired_result = %Street{
      name: "W N Michigan",
      primary_number: "3977",
      suffix: "Rd"
    }

    assert desired_result == parse_address_line("3977 W N MICHIGAN RD")
  end

  test "600 W Avenue B" do
    desired_result = %Street{
      name: "Avenue B",
      primary_number: "600",
      pre_direction: "W"
    }

    assert desired_result == parse_address_line("600 W Avenue B")
  end

  # Test this works even if the avenue name looks like a post-direction
  test "600 W Avenue E" do
    desired_result = %Street{
      name: "Avenue E",
      primary_number: "600",
      pre_direction: "W"
    }

    assert desired_result == parse_address_line("600 W Avenue E")
  end

  test "154 W U S 30" do
    desired_result = %Street{
      name: "US Highway 30",
      primary_number: "154",
      pre_direction: "W"
    }

    assert desired_result == parse_address_line("154 W U S 30")
  end

  test "101 W North" do
    desired_result = %Street{
      name: "North",
      pre_direction: "W",
      primary_number: "101"
    }

    assert desired_result == parse_address_line("101 W North")
  end

  test "2709 PATTERSON ST. P.O.BOX 496" do
    desired_result = %Street{
      name: "Patterson",
      suffix: "St",
      additional_designation: "PO BOX 496",
      primary_number: "2709"
    }

    assert desired_result == parse_address_line("2709 PATTERSON ST. P.O.BOX 496")
  end

  test "2215 N STATE ROAD 3 BYPASS" do
    desired_result = %Street{
      name: "State Road 3",
      primary_number: "2215",
      suffix: "Byp",
      pre_direction: "N"
    }

    assert desired_result == parse_address_line("2215 N STATE ROAD 3 BYPASS")
  end

  test "1040 A AVE FREEMAN FIELD" do
    desired_result = %Street{
      additional_designation: "Freeman Field",
      name: "A",
      primary_number: "1040",
      suffix: "Ave"
    }

    assert desired_result == parse_address_line("1040 A AVE FREEMAN FIELD")
  end

  test "5875 CASTLE CREEK PKWY DR BLDG 4 STE 195" do
    desired_result = %Street{
      additional_designation: "Bldg 4",
      name: "Castle Creek Pkwy",
      primary_number: "5875",
      secondary_designator: "Ste",
      secondary_value: "195",
      suffix: "Dr"
    }

    assert desired_result == parse_address_line("5875 CASTLE CREEK PKWY DR BLDG 4 STE 195")
  end

  test "9704 BEAUMONT RD MAINT BLDG" do
    desired_result = %Street{
      additional_designation: "Maint Bldg",
      name: "Beaumont",
      primary_number: "9704",
      suffix: "Rd"
    }

    assert desired_result == parse_address_line("9704 BEAUMONT RD MAINT BLDG")
  end

  test "8356 N 600 W  W OF MAIN HANGER" do
    desired_result = %Street{
      name: "600 W W Of Main Hanger",
      pre_direction: "N",
      primary_number: "8356"
    }

    assert desired_result == parse_address_line("8356 N 600 W  W OF MAIN HANGER")
  end

  test "101 W 61ST AVE STATE ROAD 51" do
    desired_result = %Street{
      additional_designation: "State Road 51",
      name: "61st",
      pre_direction: "W",
      primary_number: "101",
      suffix: "Ave"
    }

    assert desired_result == parse_address_line("101 W 61ST AVE STATE ROAD 51")
  end

  test "1 N BROADWAY MAILSTOP 70" do
    desired_result = %Street{
      name: "Broadway",
      pre_direction: "N",
      primary_number: "1",
      secondary_designator: "Ms",
      secondary_value: "70"
    }

    assert desired_result == parse_address_line("1 N BROADWAY MS 70")
  end

  test "400 E MAIN ST RT #40, Cambridge City, IN" do
    desired_result = %Address{
      city: "Cambridge City",
      state: "IN",
      street: %Street{
        additional_designation: "Route 40",
        name: "Main",
        pre_direction: "E",
        primary_number: "400",
        suffix: "St"
      }
    }

    assert desired_result == parse_address("400 E MAIN ST RT #40, Cambridge City, IN")
    assert clean_address_line("400 E MAIN ST RT #40") == "400 E MAIN ST\nROUTE 40"
  end

  # With the embedded slash since this could be a intersection it's only standardized not parsed.
  test "127 WEST JASPER ST/US HWY 24 W" do
    assert clean_address_line("127 WEST JASPER ST/US HWY 24 W") ==
             "127 W JASPER ST/US HIGHWAY 24 W"
  end

  test "2128 MOUNDS ROAD & STATE ROAD 109" do
    assert clean_address_line("2128 MOUNDS ROAD & SR 109", "IN") ==
             "2128 MOUNDS RD & STATE ROAD 109"
  end

  # Prepended PO Box handling
  test "PO Box 423 - 18 West Main Street" do
    assert clean_address_line("PO Box 423 -  18 West Main Street") == "18 W MAIN ST\nPO BOX 423"
  end

  test "1400 OLD HWY. 69 S., Cambridge City, IN" do
    desired_result = %Address{
      city: "Cambridge City",
      state: "IN",
      street: %Street{
        name: "Old Highway 69",
        primary_number: "1400",
        post_direction: "S"
      }
    }

    assert desired_result == parse_address("1400 OLD HWY. 69 S., Cambridge City, IN")
  end

  test "400 N. SEPULVEDA BLVD. (LOWER)" do
    assert clean_address_line("400 N. SEPULVEDA BLVD. (LOWER)") == "400 N SEPULVEDA BLVD\nLOWER"
  end

  test "W146N9300 Held Drive, Menomonee Falls, WI  53051 and W146 N9300 Held Drive" do
    desired_result = %Address{
      city: "Menomonee Falls",
      state: "WI",
      postal: "53051",
      street: %Street{
        name: "Held",
        suffix: "Dr",
        primary_number: "W146N9300"
      }
    }

    assert desired_result == parse_address("W146N9300 Held Drive, Menomonee Falls, WI  53051")
    assert desired_result == parse_address("W146 N9300 Held Drive, Menomonee Falls, WI  53051")
  end

  test "149  W.CRAWFORD AVE" do
    assert clean_address_line("149  W.CRAWFORD AVENUE") == "149 W CRAWFORD AVE"
  end

  test "2561 - 190TH STREET" do
    assert clean_address_line("2561 - 190TH STREET") == "2561 190TH ST"
  end

  test "2021-1/2 E 4th Street" do
    assert clean_address_line("2012-1/2 E 4th Street") == "2012 1/2 E 4TH ST"
  end

  test "RR 1, BOX 241" do
    assert clean_address_line("RR 1, BOX 241") == "RR 1 BOX 241"
  end

  test "W5871 COUNTY HWY VV, SHELDON, WI  54766" do
    desired_result = %Address{
      city: "Sheldon",
      state: "WI",
      postal: "54766",
      street: %Street{
        name: "County Highway Vv",
        primary_number: "W5871"
      }
    }

    assert desired_result == parse_address("W5871 COUNTY HWY VV, SHELDON, WI  54766")
  end

  test "544 UNITED STATES HIGHWAY 31 N" do
    assert clean_address_line("544 UNITED STATES HIGHWAY 31 N") == "544 US HIGHWAY 31 N"
  end

  test "2500 N. ST. MARY'S" do
    assert clean_address_line("2500 N. ST. MARY'S") == "2500 N ST MARYS"
  end

  test "500' W OF TEMPLE ON SR 104" do
    assert clean_address_line("500' W OF TEMPLE ON SR 104") ==
             "500 FT W OF TEMPLE ON STATE ROUTE 104"
  end

  test "150 Ho'okele St, Kahului, HI 96732" do
    assert clean_address_line("150 Ho'okele St") == "150 HOOKELE ST"
  end

  test "W5871 COUNTY HWY VV WAUSAU WI" do
    desired_result = %Address{
      city: "Wausau",
      state: "WI",
      street: %Street{
        name: "County Highway Vv",
        primary_number: "W5871"
      }
    }

    assert desired_result == parse_address("W5871 COUNTY HWY VV WAUSAU WI")
  end

  test "11300 - 88TH AVENUE" do
    assert clean_address_line("11300 - 88TH AVENUE") == "11300 88TH AVE"
  end

  # Ensure single commas hugging suffixes properly remove to additional designation
  test "81 MORRIS ROAD, HIGHWAY 51 SOUTH" do
    assert clean_address_line("81 MORRIS ROAD, HIGHWAY 51 SOUTH") ==
             "81 MORRIS RD\nHIGHWAY 51 SOUTH"
  end

  test "81 SR 55, MAIN ST" do
    assert clean_address_line("81 SR 55, MAIN ST") == "81 STATE ROUTE 55\nMAIN ST"
  end

  test "6281 M 22, Glen Arbor, MI" do
    desired_result = %Address{
      city: "Glen Arbor",
      state: "MI",
      street: %Street{
        name: "M-22",
        primary_number: "6281"
      }
    }

    assert desired_result == parse_address("6281 M 22, Glen Arbor, MI")
  end

  test "8422 AR HWY 89 SOUTH" do
    assert clean_address_line("8422 AR HWY 89 SOUTH") == "8422 AR HIGHWAY 89 S"
  end

  test "420 THRU 429 MAIN STREET" do
    assert clean_address_line("420 THRU 429 MAIN STREET") == "420-429 MAIN ST"
  end

  test "Directionals like 506 S. 1ST S.E." do
    assert clean_address_line("506 S. 1ST S.E.") == "506 S 1ST SE"
    assert clean_address_line("716 N.E. HWY 66") == "716 NE HIGHWAY 66"
  end

  test "3421 8 Mile Road" do
    assert clean_address_line("3421 8 Mile Road") == "3421 8 MILE RD"
  end
end
