defmodule AddressUSConfig do
  @moduledoc """
  Contains all of the config parameters for the address parser.
  """

  def states do
    %{
      "ALABAMA" => "AL",
      "ALASKA" => "AK",
      "AMERICAN SAMOA" => "AS",
      "ARIZONA" => "AZ",
      "ARKANSAS" => "AR",
      "CALIFORNIA" => "CA",
      "COLORADO" => "CO",
      "CONNECTICUT" => "CT",
      "DELAWARE" => "DE",
      "DISTRICT OF COLUMBIA" => "DC",
      "FEDERATED STATES OF MICRONESIA" => "FM",
      "FLORIDA" => "FL",
      "GEORGIA" => "GA",
      "GUAM" => "GU",
      "GUAM GU" => "GU",
      "HAWAII" => "HI",
      "IDAHO" => "ID",
      "ILLINOIS" => "IL",
      "INDIANA" => "IN",
      "IOWA" => "IA",
      "KANSAS" => "KS",
      "KENTUCKY" => "KY",
      "LOUISIANA" => "LA",
      "MAINE" => "ME",
      "MARSHALL ISLANDS" => "MH",
      "MARYLAND" => "MD",
      "MASSACHUSETTS" => "MA",
      "MICHIGAN" => "MI",
      "MINNESOTA" => "MN",
      "MISSISSIPPI" => "MS",
      "MISSOURI" => "MO",
      "MONTANA" => "MT",
      "NEBRASKA" => "NE",
      "NEVADA" => "NV",
      "NEW HAMPSHIRE" => "NH",
      "NEW JERSEY" => "NJ",
      "NEW MEXICO" => "NM",
      "NEW YORK" => "NY",
      "NORTH CAROLINA" => "NC",
      "NORTH DAKOTA" => "ND",
      "NORTHERN MARIANA ISLANDS" => "MP",
      "OHIO" => "OH",
      "OKLAHOMA" => "OK",
      "OREGON" => "OR",
      "PALAU" => "PW",
      "PENNSYLVANIA" => "PA",
      "PUERTO RICO" => "PR",
      "RHODE ISLAND" => "RI",
      "SOUTH CAROLINA" => "SC",
      "SOUTH DAKOTA" => "SD",
      "TENNESSEE" => "TN",
      "TEXAS" => "TX",
      "UTAH" => "UT",
      "VERMONT" => "VT",
      "VIRGIN ISLANDS" => "VI",
      "VIRGINIA" => "VA",
      "WASHINGTON" => "WA",
      "WEST VIRGINIA" => "WV",
      "WISCONSIN" => "WI",
      "WYOMING" => "WY",
      "ARMED FORCES AFRICA" => "AE",
      "ARMED FORCES AMERICAS" => "AA",
      "ARMED FORCES CANADA" => "AE",
      "ARMED FORCES EUROPE" => "AE",
      "ARMED FORCES MIDDLE EAST" => "AE",
      "ARMED FORCES PACIFIC" => "AP"
    }
  end

  def countries do
    %{
      "AFGHANISTAN" => "AF",
      "ALBANIA" => "AL",
      "ALGERIA" => "DZ",
      "AMERICAN SAMOA" => "AS",
      "ANDORRA" => "AD",
      "ANGOLA" => "AO",
      "ANGUILLA" => "AI",
      "ANTARCTICA" => "AQ",
      "ANTIGUA AND BARBUDA" => "AG",
      "ARGENTINA" => "AR",
      "ARMENIA" => "AM",
      "ARUBA" => "AW",
      "AUSTRALIA" => "AU",
      "AUSTRIA" => "AT",
      "AZERBAIJAN" => "AZ",
      "BAHAMAS" => "BS",
      "BAHRAIN" => "BH",
      "BANGLADESH" => "BD",
      "BARBADOS" => "BB",
      "BELARUS" => "BY",
      "BELGIUM" => "BE",
      "BELIZE" => "BZ",
      "BENIN" => "BJ",
      "BERMUDA" => "BM",
      "BHUTAN" => "BT",
      "BOLIVIA" => "BO",
      "BOSNIA AND HERZEGOWINA" => "BA",
      "BOTSWANA" => "BW",
      "BOUVET ISLAND" => "BV",
      "BRAZIL" => "BR",
      "BRITISH INDIAN OCEAN TERRITORY" => "IO",
      "BRUNEI DARUSSALAM" => "BN",
      "BULGARIA" => "BG",
      "BURKINA FASO" => "BF",
      "BURUNDI" => "BI",
      "CAMBODIA" => "KH",
      "CAMEROON" => "CM",
      "CANADA" => "CA",
      "CAPE VERDE" => "CV",
      "CAYMAN ISLANDS" => "KY",
      "CENTRAL AFRICAN REPUBLIC" => "CF",
      "CHAD" => "TD",
      "CHILE" => "CL",
      "CHINA" => "CN",
      "CHRISTMAS ISLAND" => "CX",
      "COCOS (KEELING) ISLANDS" => "CC",
      "COLOMBIA" => "CO",
      "COMOROS" => "KM",
      "CONGO" => "CG",
      "CONGO, THE DRC" => "CD",
      "COOK ISLANDS" => "CK",
      "COSTA RICA" => "CR",
      "COTE D'IVOIRE" => "CI",
      "CROATIA (local name: Hrvatska)" => "HR",
      "CUBA" => "CU",
      "CYPRUS" => "CY",
      "CZECH REPUBLIC" => "CZ",
      "DENMARK" => "DK",
      "DJIBOUTI" => "DJ",
      "DOMINICA" => "DM",
      "DOMINICAN REPUBLIC" => "DO",
      "EAST TIMOR" => "TP",
      "ECUADOR" => "EC",
      "EGYPT" => "EG",
      "EL SALVADOR" => "SV",
      "EQUATORIAL GUINEA" => "GQ",
      "ERITREA" => "ER",
      "ESTONIA" => "EE",
      "ETHIOPIA" => "ET",
      "FALKLAND ISLANDS (MALVINAS)" => "FK",
      "FAROE ISLANDS" => "FO",
      "FIJI" => "FJ",
      "FINLAND" => "FI",
      "FRANCE" => "FR",
      "FRANCE, METROPOLITAN" => "FX",
      "FRENCH GUIANA" => "GF",
      "FRENCH POLYNESIA" => "PF",
      "FRENCH SOUTHERN TERRITORIES" => "TF",
      "GABON" => "GA",
      "GAMBIA" => "GM",
      "GEORGIA" => "GE",
      "GERMANY" => "DE",
      "GHANA" => "GH",
      "GIBRALTAR" => "GI",
      "GREECE" => "GR",
      "GREENLAND" => "GL",
      "GRENADA" => "GD",
      "GUADELOUPE" => "GP",
      "GUAM" => "GU",
      "GUATEMALA" => "GT",
      "GUINEA" => "GN",
      "GUINEA-BISSAU" => "GW",
      "GUYANA" => "GY",
      "HAITI" => "HT",
      "HEARD AND MC DONALD ISLANDS" => "HM",
      "HOLY SEE (VATICAN CITY STATE)" => "VA",
      "HONDURAS" => "HN",
      "HONG KONG" => "HK",
      "HUNGARY" => "HU",
      "ICELAND" => "IS",
      "INDIA" => "IN",
      "INDONESIA" => "ID",
      "IRAN (ISLAMIC REPUBLIC OF)" => "IR",
      "IRAQ" => "IQ",
      "IRELAND" => "IE",
      "ISRAEL" => "IL",
      "ITALY" => "IT",
      "JAMAICA" => "JM",
      "JAPAN" => "JP",
      "JORDAN" => "JO",
      "KAZAKHSTAN" => "KZ",
      "KENYA" => "KE",
      "KIRIBATI" => "KI",
      "KOREA, D.P.R.O." => "KP",
      "KOREA, REPUBLIC OF" => "KR",
      "KUWAIT" => "KW",
      "KYRGYZSTAN" => "KG",
      "LAOS?" => "LA",
      "LATVIA" => "LV",
      "LEBANON" => "LB",
      "LESOTHO" => "LS",
      "LIBERIA" => "LR",
      "LIBYAN ARAB JAMAHIRIYA" => "LY",
      "LIECHTENSTEIN" => "LI",
      "LITHUANIA" => "LT",
      "LUXEMBOURG" => "LU",
      "MACAU" => "MO",
      "MACEDONIA" => "MK",
      "MADAGASCAR" => "MG",
      "MALAWI" => "MW",
      "MALAYSIA" => "MY",
      "MALDIVES" => "MV",
      "MALI" => "ML",
      "MALTA" => "MT",
      "MARSHALL ISLANDS" => "MH",
      "MARTINIQUE" => "MQ",
      "MAURITANIA" => "MR",
      "MAURITIUS" => "MU",
      "MAYOTTE" => "YT",
      "MEXICO" => "MX",
      "MICRONESIA, FEDERATED STATES OF" => "FM",
      "MOLDOVA, REPUBLIC OF" => "MD",
      "MONACO" => "MC",
      "MONGOLIA" => "MN",
      "MONTENEGRO" => "ME",
      "MONTSERRAT" => "MS",
      "MOROCCO" => "MA",
      "MOZAMBIQUE" => "MZ",
      "MYANMAR (Burma)?" => "MM",
      "NAMIBIA" => "NA",
      "NAURU" => "NR",
      "NEPAL" => "NP",
      "NETHERLANDS" => "NL",
      "NETHERLANDS ANTILLES" => "AN",
      "NEW CALEDONIA" => "NC",
      "NEW ZEALAND" => "NZ",
      "NICARAGUA" => "NI",
      "NIGER" => "NE",
      "NIGERIA" => "NG",
      "NIUE" => "NU",
      "NORFOLK ISLAND" => "NF",
      "NORTHERN MARIANA ISLANDS" => "MP",
      "NORWAY" => "NO",
      "OMAN" => "OM",
      "PAKISTAN" => "PK",
      "PALAU" => "PW",
      "PANAMA" => "PA",
      "PAPUA NEW GUINEA" => "PG",
      "PARAGUAY" => "PY",
      "PERU" => "PE",
      "PHILIPPINES" => "PH",
      "PITCAIRN" => "PN",
      "POLAND" => "PL",
      "PORTUGAL" => "PT",
      "PUERTO RICO" => "PR",
      "QATAR" => "QA",
      "REUNION" => "RE",
      "ROMANIA" => "RO",
      "RUSSIAN FEDERATION" => "RU",
      "RWANDA" => "RW",
      "SAINT KITTS AND NEVIS" => "KN",
      "SAINT LUCIA" => "LC",
      "SAINT VINCENT AND THE GRENADINES" => "VC",
      "SAMOA" => "WS",
      "SAN MARINO" => "SM",
      "SAO TOME AND PRINCIPE" => "ST",
      "SAUDI ARABIA" => "SA",
      "SENEGAL" => "SN",
      "SERBIA" => "RS",
      "SEYCHELLES" => "SC",
      "SIERRA LEONE" => "SL",
      "SINGAPORE" => "SG",
      "SLOVAKIA (Slovak Republic)" => "SK",
      "SLOVENIA" => "SI",
      "SOLOMON ISLANDS" => "SB",
      "SOMALIA" => "SO",
      "SOUTH AFRICA" => "ZA",
      "SOUTH SUDAN" => "SS",
      "SOUTH GEORGIA AND SOUTH S.S." => "GS",
      "SPAIN" => "ES",
      "SRI LANKA" => "LK",
      "ST. HELENA" => "SH",
      "ST. PIERRE AND MIQUELON" => "PM",
      "SUDAN" => "SD",
      "SURINAME" => "SR",
      "SVALBARD AND JAN MAYEN ISLANDS" => "SJ",
      "SWAZILAND" => "SZ",
      "SWEDEN" => "SE",
      "SWITZERLAND" => "CH",
      "SYRIAN ARAB REPUBLIC" => "SY",
      "TAIWAN, PROVINCE OF CHINA" => "TW",
      "TAJIKISTAN" => "TJ",
      "TANZANIA, UNITED REPUBLIC OF" => "TZ",
      "THAILAND" => "TH",
      "TOGO" => "TG",
      "TOKELAU" => "TK",
      "TONGA" => "TO",
      "TRINIDAD AND TOBAGO" => "TT",
      "TUNISIA" => "TN",
      "TURKEY" => "TR",
      "TURKMENISTAN" => "TM",
      "TURKS AND CAICOS ISLANDS" => "TC",
      "TUVALU" => "TV",
      "UGANDA" => "UG",
      "UKRAINE" => "UA",
      "UNITED ARAB EMIRATES" => "AE",
      "UNITED KINGDOM" => "GB",
      "UNITED STATES" => "US",
      "UNITED STATES OF AMERICA" => "US",
      "USA" => "US",
      "U.S. MINOR ISLANDS" => "UM",
      "URUGUAY" => "UY",
      "UZBEKISTAN" => "UZ",
      "VANUATU" => "VU",
      "VENEZUELA" => "VE",
      "VIET NAM" => "VN",
      "VIRGIN ISLANDS (BRITISH)" => "VG",
      "VIRGIN ISLANDS (U.S.)" => "VI",
      "WALLIS AND FUTUNA ISLANDS" => "WF",
      "WESTERN SAHARA" => "EH",
      "YEMEN" => "YE",
      "ZAMBIA" => "ZM",
      "ZIMBABWE" => "ZW"
    }
  end

  def secondary_units() do
    %{
      "APARTMENT" => "APT",
      "BASEMENT" => "BSMT",
      "BUILDING" => "BLDG",
      "DEPARTMENT" => "DEPT",
      "FLOOR" => "FL",
      "FRONT" => "FRNT",
      "HANGAR" => "HNGR",
      "HANGER" => "HNGR",
      "LOBBY" => "LBBY",
      "LOT" => "LOT",
      # False positives with Roads including Lower
      # "LOWER" => "LOWR",
      "MAILSTOP" => "MS",
      "OFFICE" => "OFC",
      "PENTHOUSE" => "PH",
      "PIER" => "PIER",
      "REAR" => "REAR",
      "ROOM" => "RM",
      "SIDE" => "SIDE",
      "SLIP" => "SLIP",
      "SPACE" => "SPC",
      # FALSE POSITIVE WITH ROADS NAMED STOP
      # "STOP" => "STOP",
      "SUITE" => "STE",
      "TRAILER" => "TRLR",
      "UNIT" => "UNIT"
      # False positives with roads including Upper
      # "UPPER" => "UPPR"
    }
  end

  # Speeding up a hot-path
  def secondary_units_key_values do
    Map.keys(secondary_units()) ++ Map.values(secondary_units())
  end

  def street_suffixes do
    %{
      "ALLEE" => "ALY",
      "ALLEY" => "ALY",
      "ALLY" => "ALY",
      "ALY" => "ALY",
      "ANEX" => "ANX",
      "ANNEX" => "ANX",
      "ANX" => "ANX",
      "ARC" => "ARC",
      "ARCADE" => "ARC",
      "AV" => "AVE",
      "AVE" => "AVE",
      "AVEN" => "AVE",
      "AVENU" => "AVE",
      "AVENUE" => "AVE",
      "AVN" => "AVE",
      "AVNUE" => "AVE",
      "BAYOO" => "BYU",
      "BAYOU" => "BYU",
      "BCH" => "BCH",
      "BEACH" => "BCH",
      "BEND" => "BND",
      "BND" => "BND",
      "BLF" => "BLF",
      "BLUF" => "BLF",
      "BLUFF" => "BLF",
      "BLUFFS" => "BLFS",
      "BOT" => "BTM",
      "BOTTM" => "BTM",
      "BOTTOM" => "BTM",
      "BTM" => "BTM",
      "BLVD" => "BLVD",
      "BOUL" => "BLVD",
      "BOULEVARD" => "BLVD",
      "BOULV" => "BLVD",
      "BR" => "BR",
      "BRANCH" => "BR",
      "BRNCH" => "BR",
      "BRDGE" => "BRG",
      "BRG" => "BRG",
      "BRIDGE" => "BRG",
      "BRK" => "BRK",
      "BROOK" => "BRK",
      "BROOKS" => "BRKS",
      "BURG" => "BG",
      "BURGS" => "BGS",
      "BYP" => "BYP",
      "BYPA" => "BYP",
      "BYPAS" => "BYP",
      "BYPASS" => "BYP",
      "BYPS" => "BYP",
      "CAMP" => "CP",
      "CMP" => "CP",
      "CP" => "CP",
      "CANYN" => "CYN",
      "CANYON" => "CYN",
      "CNYN" => "CYN",
      "CYN" => "CYN",
      "CAPE" => "CPE",
      "CPE" => "CPE",
      "CAUSEWAY" => "CSWY",
      "CAUSWAY" => "CSWY",
      "CSWY" => "CSWY",
      "CEN" => "CTR",
      "CENT" => "CTR",
      "CENTER" => "CTR",
      "CENTR" => "CTR",
      "CENTRE" => "CTR",
      "CNTER" => "CTR",
      "CNTR" => "CTR",
      "CTR" => "CTR",
      "CENTERS" => "CTRS",
      "CIR" => "CIR",
      "CIRC" => "CIR",
      "CIRCL" => "CIR",
      "CIRCLE" => "CIR",
      "CRCL" => "CIR",
      "CRCLE" => "CIR",
      "CIRCLES" => "CIRS",
      "CLF" => "CLF",
      "CLIFF" => "CLF",
      "CLFS" => "CLFS",
      "CLIFFS" => "CLFS",
      "CLB" => "CLB",
      "CLUB" => "CLB",
      "COMMON" => "CMN",
      "COR" => "COR",
      "CORNER" => "COR",
      "CORNERS" => "CORS",
      "CORS" => "CORS",
      "COURSE" => "CRSE",
      "CRSE" => "CRSE",
      "COURT" => "CT",
      "CRT" => "CT",
      "CT" => "CT",
      "COURTS" => "CTS",
      "COVE" => "CV",
      "CV" => "CV",
      "COVES" => "CVS",
      "CK" => "CRK",
      "CREEK" => "CRK",
      "CRK" => "CRK",
      "CRECENT" => "CRES",
      "CRES" => "CRES",
      "CRESCENT" => "CRES",
      "CRESENT" => "CRES",
      "CRSCNT" => "CRES",
      "CRSENT" => "CRES",
      "CRSNT" => "CRES",
      "CREST" => "CRST",
      "CROSSING" => "XING",
      "CRSSING" => "XING",
      "CRSSNG" => "XING",
      "XING" => "XING",
      "CROSSROAD" => "XRD",
      "CURVE" => "CURV",
      "DALE" => "DL",
      "DL" => "DL",
      "DAM" => "DM",
      "DM" => "DM",
      "DIV" => "DV",
      "DIVIDE" => "DV",
      "DV" => "DV",
      "DVD" => "DV",
      "DR" => "DR",
      "DRIV" => "DR",
      "DRIVE" => "DR",
      "DRV" => "DR",
      "DRIVES" => "DRS",
      "EST" => "EST",
      "ESTATE" => "EST",
      "ESTATES" => "ESTS",
      "ESTS" => "ESTS",
      "EXP" => "EXPY",
      "EXPR" => "EXPY",
      "EXPRESS" => "EXPY",
      "EXPRESSWAY" => "EXPY",
      "EXPW" => "EXPY",
      "EXPY" => "EXPY",
      "EXT" => "EXT",
      "EXTENSION" => "EXT",
      "EXTN" => "EXT",
      "EXTNSN" => "EXT",
      "EXTENSIONS" => "EXTS",
      "EXTS" => "EXTS",
      "FALL" => "FALL",
      "FALLS" => "FLS",
      "FLS" => "FLS",
      "FERRY" => "FRY",
      "FRRY" => "FRY",
      "FRY" => "FRY",
      "FIELD" => "FLD",
      "FLD" => "FLD",
      "FIELDS" => "FLDS",
      "FLDS" => "FLDS",
      "FLAT" => "FLT",
      "FLT" => "FLT",
      "FLATS" => "FLTS",
      "FLTS" => "FLTS",
      "FORD" => "FRD",
      "FRD" => "FRD",
      "FORDS" => "FRDS",
      "FOREST" => "FRST",
      "FORESTS" => "FRST",
      "FRST" => "FRST",
      "FORG" => "FRG",
      "FORGE" => "FRG",
      "FRG" => "FRG",
      "FORGES" => "FRGS",
      "FORK" => "FRK",
      "FRK" => "FRK",
      "FORKS" => "FRKS",
      "FRKS" => "FRKS",
      "FORT" => "FT",
      "FRT" => "FT",
      "FT" => "FT",
      "FREEWAY" => "FWY",
      "FREEWY" => "FWY",
      "FRWAY" => "FWY",
      "FRWY" => "FWY",
      "FWY" => "FWY",
      "GARDEN" => "GDN",
      "GARDN" => "GDN",
      "GDN" => "GDN",
      "GRDEN" => "GDN",
      "GRDN" => "GDN",
      "GARDENS" => "GDNS",
      "GDNS" => "GDNS",
      "GRDNS" => "GDNS",
      "GATEWAY" => "GTWY",
      "GATEWY" => "GTWY",
      "GATWAY" => "GTWY",
      "GTWAY" => "GTWY",
      "GTWY" => "GTWY",
      "GLEN" => "GLN",
      "GLN" => "GLN",
      "GLENS" => "GLNS",
      "GREEN" => "GRN",
      "GRN" => "GRN",
      "GREENS" => "GRNS",
      "GROV" => "GRV",
      "GROVE" => "GRV",
      "GRV" => "GRV",
      "GROVES" => "GRVS",
      "HARB" => "HBR",
      "HARBOR" => "HBR",
      "HARBR" => "HBR",
      "HBR" => "HBR",
      "HRBOR" => "HBR",
      "HARBORS" => "HBRS",
      "HAVEN" => "HVN",
      "HAVN" => "HVN",
      "HVN" => "HVN",
      "HEIGHT" => "HTS",
      "HEIGHTS" => "HTS",
      "HGTS" => "HTS",
      "HT" => "HTS",
      "HTS" => "HTS",
      "HIGHWAY" => "HWY",
      "HIGHWY" => "HWY",
      "HIWAY" => "HWY",
      "HIWY" => "HWY",
      "HWAY" => "HWY",
      "HWY" => "HWY",
      "HILL" => "HL",
      "HL" => "HL",
      "HILLS" => "HLS",
      "HLS" => "HLS",
      "HLLW" => "HOLW",
      "HOLLOW" => "HOLW",
      "HOLLOWS" => "HOLW",
      "HOLW" => "HOLW",
      "HOLWS" => "HOLW",
      "INLET" => "INLT",
      "INLT" => "INLT",
      "IS" => "IS",
      "ISLAND" => "IS",
      "ISLND" => "IS",
      "ISLANDS" => "ISS",
      "ISLNDS" => "ISS",
      "ISS" => "ISS",
      "ISLE" => "ISLE",
      "ISLES" => "ISLE",
      "JCT" => "JCT",
      "JCTION" => "JCT",
      "JCTN" => "JCT",
      "JUNCTION" => "JCT",
      "JUNCTN" => "JCT",
      "JUNCTON" => "JCT",
      "JCTNS" => "JCTS",
      "JCTS" => "JCTS",
      "JUNCTIONS" => "JCTS",
      "KEY" => "KY",
      "KY" => "KY",
      "KEYS" => "KYS",
      "KYS" => "KYS",
      "KNL" => "KNL",
      "KNOL" => "KNL",
      "KNOLL" => "KNL",
      "KNLS" => "KNLS",
      "KNOLLS" => "KNLS",
      "LAKE" => "LK",
      "LK" => "LK",
      "LAKES" => "LKS",
      "LKS" => "LKS",
      "LAND" => "LAND",
      "LANDING" => "LNDG",
      "LNDG" => "LNDG",
      "LNDNG" => "LNDG",
      "LA" => "LN",
      "LANE" => "LN",
      "LANES" => "LN",
      "LN" => "LN",
      "LGT" => "LGT",
      "LIGHT" => "LGT",
      "LIGHTS" => "LGTS",
      "LF" => "LF",
      "LOAF" => "LF",
      "LCK" => "LCK",
      "LOCK" => "LCK",
      "LCKS" => "LCKS",
      "LOCKS" => "LCKS",
      "LDG" => "LDG",
      "LDGE" => "LDG",
      "LODG" => "LDG",
      "LODGE" => "LDG",
      "LOOP" => "LOOP",
      "LOOPS" => "LOOP",
      "MALL" => "MALL",
      "MANOR" => "MNR",
      "MNR" => "MNR",
      "MANORS" => "MNRS",
      "MNRS" => "MNRS",
      "MDW" => "MDW",
      "MEADOW" => "MDW",
      "MDWS" => "MDWS",
      "MEADOWS" => "MDWS",
      "MEDOWS" => "MDWS",
      "MEWS" => "MEWS",
      "MILL" => "ML",
      "ML" => "ML",
      "MILLS" => "MLS",
      "MLS" => "MLS",
      "MISSION" => "MSN",
      "MISSN" => "MSN",
      "MSN" => "MSN",
      "MSSN" => "MSN",
      "MOTORWAY" => "MTWY",
      "MNT" => "MT",
      "MOUNT" => "MT",
      "MT" => "MT",
      "MNTAIN" => "MTN",
      "MNTN" => "MTN",
      "MOUNTAIN" => "MTN",
      "MOUNTIN" => "MTN",
      "MTIN" => "MTN",
      "MTN" => "MTN",
      "MNTNS" => "MTNS",
      "MOUNTAINS" => "MTNS",
      "NCK" => "NCK",
      "NECK" => "NCK",
      "ORCH" => "ORCH",
      "ORCHARD" => "ORCH",
      "ORCHRD" => "ORCH",
      "OVAL" => "OVAL",
      "OVL" => "OVAL",
      "OVERPASS" => "OPAS",
      "PARK" => "PARK",
      "PK" => "PARK",
      "PRK" => "PARK",
      "PARKS" => "PARK",
      "PARKWAY" => "PKWY",
      "PARKWY" => "PKWY",
      "PKWAY" => "PKWY",
      "PKWY" => "PKWY",
      "PKY" => "PKWY",
      "PARKWAYS" => "PKWY",
      "PKWYS" => "PKWY",
      "PASS" => "PASS",
      "PASSAGE" => "PSGE",
      "PATH" => "PATH",
      "PATHS" => "PATH",
      "PIKE" => "PIKE",
      "PIKES" => "PIKE",
      "PINE" => "PNE",
      "PINES" => "PNES",
      "PNES" => "PNES",
      "PL" => "PL",
      "PLACE" => "PL",
      "PLAIN" => "PLN",
      "PLN" => "PLN",
      "PLAINES" => "PLNS",
      "PLAINS" => "PLNS",
      "PLNS" => "PLNS",
      "PLAZA" => "PLZ",
      "PLZ" => "PLZ",
      "PLZA" => "PLZ",
      "POINT" => "PT",
      "PT" => "PT",
      "POINTS" => "PTS",
      "PTS" => "PTS",
      "PORT" => "PRT",
      "PRT" => "PRT",
      "PORTS" => "PRTS",
      "PRTS" => "PRTS",
      "PR" => "PR",
      "PRAIRIE" => "PR",
      "PRARIE" => "PR",
      "PRR" => "PR",
      "RAD" => "RADL",
      "RADIAL" => "RADL",
      "RADIEL" => "RADL",
      "RADL" => "RADL",
      "RAMP" => "RAMP",
      "RANCH" => "RNCH",
      "RANCHES" => "RNCH",
      "RNCH" => "RNCH",
      "RNCHS" => "RNCH",
      "RAPID" => "RPD",
      "RPD" => "RPD",
      "RAPIDS" => "RPDS",
      "RPDS" => "RPDS",
      "REST" => "RST",
      "RST" => "RST",
      "RDG" => "RDG",
      "RDGE" => "RDG",
      "RIDGE" => "RDG",
      "RDGS" => "RDGS",
      "RIDGES" => "RDGS",
      "RIV" => "RIV",
      "RIVER" => "RIV",
      "RIVR" => "RIV",
      "RVR" => "RIV",
      "RD" => "RD",
      "ROAD" => "RD",
      "RDS" => "RDS",
      "ROADS" => "RDS",
      "ROUTE" => "RTE",
      "ROW" => "ROW",
      "RUE" => "RUE",
      "RUN" => "RUN",
      "SHL" => "SHL",
      "SHOAL" => "SHL",
      "SHLS" => "SHLS",
      "SHOALS" => "SHLS",
      "SHOAR" => "SHR",
      "SHORE" => "SHR",
      "SHR" => "SHR",
      "SHOARS" => "SHRS",
      "SHORES" => "SHRS",
      "SHRS" => "SHRS",
      "SKYWAY" => "SKWY",
      "SPG" => "SPG",
      "SPNG" => "SPG",
      "SPRING" => "SPG",
      "SPRNG" => "SPG",
      "SPGS" => "SPGS",
      "SPNGS" => "SPGS",
      "SPRINGS" => "SPGS",
      "SPRNGS" => "SPGS",
      "SPUR" => "SPUR",
      "SPURS" => "SPUR",
      "SQ" => "SQ",
      "SQR" => "SQ",
      "SQRE" => "SQ",
      "SQU" => "SQ",
      "SQUARE" => "SQ",
      "SQRS" => "SQS",
      "SQUARES" => "SQS",
      "STA" => "STA",
      "STATION" => "STA",
      "STATN" => "STA",
      "STN" => "STA",
      "STRA" => "STRA",
      "STRAV" => "STRA",
      "STRAVE" => "STRA",
      "STRAVEN" => "STRA",
      "STRAVENUE" => "STRA",
      "STRAVN" => "STRA",
      "STRVN" => "STRA",
      "STRVNUE" => "STRA",
      "STREAM" => "STRM",
      "STREME" => "STRM",
      "STRM" => "STRM",
      "ST" => "ST",
      "STR" => "ST",
      "STREET" => "ST",
      "STRT" => "ST",
      "STREETS" => "STS",
      "SMT" => "SMT",
      "SUMIT" => "SMT",
      "SUMITT" => "SMT",
      "SUMMIT" => "SMT",
      "TER" => "TER",
      "TERR" => "TER",
      "TERRACE" => "TER",
      "THROUGHWAY" => "TRWY",
      "TRACE" => "TRCE",
      "TRACES" => "TRCE",
      "TRCE" => "TRCE",
      "TRACK" => "TRAK",
      "TRACKS" => "TRAK",
      "TRAK" => "TRAK",
      "TRK" => "TRAK",
      "TRKS" => "TRAK",
      "TRAFFICWAY" => "TRFY",
      "TRFY" => "TRFY",
      "TR" => "TRL",
      "TRAIL" => "TRL",
      "TRAILS" => "TRL",
      "TRL" => "TRL",
      "TRLS" => "TRL",
      "TUNEL" => "TUNL",
      "TUNL" => "TUNL",
      "TUNLS" => "TUNL",
      "TUNNEL" => "TUNL",
      "TUNNELS" => "TUNL",
      "TUNNL" => "TUNL",
      "TPK" => "TPKE",
      "TPKE" => "TPKE",
      "TRNPK" => "TPKE",
      "TRPK" => "TPKE",
      "TURNPIKE" => "TPKE",
      "TURNPK" => "TPKE",
      "UNDERPASS" => "UPAS",
      "UN" => "UN",
      "UNION" => "UN",
      "UNIONS" => "UNS",
      "VALLEY" => "VLY",
      "VALLY" => "VLY",
      "VLLY" => "VLY",
      "VLY" => "VLY",
      "VALLEYS" => "VLYS",
      "VLYS" => "VLYS",
      "VDCT" => "VIA",
      "VIA" => "VIA",
      "VIADCT" => "VIA",
      "VIADUCT" => "VIA",
      "VIEW" => "VW",
      "VW" => "VW",
      "VIEWS" => "VWS",
      "VWS" => "VWS",
      "VILL" => "VLG",
      "VILLAG" => "VLG",
      "VILLAGE" => "VLG",
      "VILLG" => "VLG",
      "VILLIAGE" => "VLG",
      "VLG" => "VLG",
      "VILLAGES" => "VLGS",
      "VLGS" => "VLGS",
      "VILLE" => "VL",
      "VL" => "VL",
      "VIS" => "VIS",
      "VIST" => "VIS",
      "VISTA" => "VIS",
      "VST" => "VIS",
      "VSTA" => "VIS",
      "WALK" => "WALK",
      "WALKS" => "WALK",
      "WALL" => "WALL",
      "WAY" => "WAY",
      "WY" => "WAY",
      "WAYS" => "WAYS",
      "WELL" => "WL",
      "WELLS" => "WLS",
      "WLS" => "WLS"
    }
  end

  # NOTE: This list should be kept in sync with common_suffix_keys
  def common_suffixes do
    %{
      "AV" => "AVE",
      "AVE" => "AVE",
      "AVEN" => "AVE",
      "AVENU" => "AVE",
      "AVENUE" => "AVE",
      "AVN" => "AVE",
      "AVNUE" => "AVE",
      "BLVD" => "BLVD",
      "BOUL" => "BLVD",
      "BOULEVARD" => "BLVD",
      "BOULV" => "BLVD",
      "BYP" => "BYP",
      "BYPA" => "BYP",
      "BYPAS" => "BYP",
      "BYPASS" => "BYP",
      "BYPS" => "BYP",
      "COURT" => "CT",
      "CRT" => "CT",
      "CT" => "CT",
      "DR" => "DR",
      "DRIV" => "DR",
      "DRIVE" => "DR",
      "DRV" => "DR",
      "EXP" => "EXPY",
      "EXPR" => "EXPY",
      "EXPRESS" => "EXPY",
      "EXPRESSWAY" => "EXPY",
      "EXPW" => "EXPY",
      "EXPY" => "EXPY",
      "HIGHWAY" => "HWY",
      "HIGHWY" => "HWY",
      "HIWAY" => "HWY",
      "HIWY" => "HWY",
      "HWAY" => "HWY",
      "HWY" => "HWY",
      # "LA" => "LN",
      "LANE" => "LN",
      "LN" => "LN",
      "PARKWAY" => "PKWY",
      "PARKWY" => "PKWY",
      "PIKE" => "PIKE",
      "PKWAY" => "PKWY",
      "PKWY" => "PKWY",
      "PKY" => "PKWY",
      "RD" => "RD",
      "ROAD" => "RD",
      "ST" => "ST",
      "STR" => "ST",
      "STREET" => "ST",
      "STRT" => "ST",
      "TPK" => "TPKE",
      "TPKE" => "TPKE",
      "TR" => "TRL",
      "TRAIL" => "TRL",
      "TRL" => "TRL",
      "TRNPK" => "TPKE",
      "TRPK" => "TPKE",
      "TURNPIKE" => "TPKE",
      "TURNPK" => "TPKE",
      "WAY" => "WAY",
      "WY" => "WAY",
      # NOTE: WE ARE INTENTIONALLY NOT CHANGING "CROSSING" TO XING TO AVOID FALSE POSITIVES
      "XING" => "XING"
    }
  end

  # NOTE: This list should be kept in sync with common_suffixes
  # Exists to speed up hot path
  def common_suffix_keys do
    [
      "AV",
      "AVE",
      "AVEN",
      "AVENU",
      "AVENUE",
      "AVN",
      "AVNUE",
      "BLVD",
      "BOUL",
      "BOULEVARD",
      "BOULV",
      "BYP",
      "BYPA",
      "BYPAS",
      "BYPASS",
      "BYPS",
      "COURT",
      "CRT",
      "CT",
      "DR",
      "DRIV",
      "DRIVE",
      "DRV",
      "EXP",
      "EXPR",
      "EXPRESS",
      "EXPRESSWAY",
      "EXPW",
      "EXPY",
      "HIGHWAY",
      "HIGHWY",
      "HIWAY",
      "HIWY",
      "HWAY",
      "HWY",
      # "LA",
      "LANE",
      "LN",
      "PARKWAY",
      "PARKWY",
      "PIKE",
      "PKWAY",
      "PKWY",
      "PKY",
      "RD",
      "ROAD",
      "ST",
      "STR",
      "STREET",
      "STRT",
      "TPK",
      "TPKE",
      "TR",
      "TRAIL",
      "TRL",
      "TRNPK",
      "TRPK",
      "TURNPIKE",
      "TURNPK",
      "WAY",
      "WY"
    ]
  end

  def street_name_subs do
    %{
      "COUNTY HIGHWAY" => "COUNTY HIGHWAY",
      "COUNTY HWY" => "COUNTY HIGHWAY",
      "CNTY HWY" => "COUNTY HIGHWAY",
      "COUNTY RD" => "COUNTY ROAD",
      "COUNTRY ROAD" => "COUNTY ROAD",
      "CR" => "COUNTY ROAD",
      "CNTY RD" => "COUNTY ROAD",
      "FARM TO MARKET" => "FM",
      "FM" => "FM",
      "HWY FM" => "FM",
      "BYPASS HIGHWAY" => "BYP",
      "FRONTAGE ROAD" => "FRONTAGE RD",
      "FRONTAGE RD" => "FRONTAGE RD",
      "BYP ROAD HIGHWAY" => "BYPASS RD",
      "BYP ROAD" => "BYPASS RD",
      "BYP RD" => "BYPASS RD",
      "I" => "INTERSTATE",
      "IH" => "INTERSTATE",
      "INTERSTATE" => "INTERSTATE",
      "INTERSTATE HWY" => "INTERSTATE",
      "INTERSTATE HIGHWAY" => "INTERSTATE",
      "STATE HIGHWAY" => "STATE HIGHWAY",
      "ST HIGHWAY" => "STATE HIGHWAY",
      "ST HWY" => "STATE HIGHWAY",
      "STATE ROUTE" => "STATE ROUTE",
      "STATE ROAD" => "STATE ROAD",
      "SR" => "STATE ROUTE",
      "ST RD" => "STATE ROAD",
      "ST RT" => "STATE ROUTE",
      "STATE RD" => "STATE ROAD",
      "STATE RTE" => "STATE ROUTE",
      "TOWNSHIP ROAD" => "TOWNSHIP ROAD",
      "TOWNSHIP RD" => "TOWNSHIP ROAD",
      "TWP RD" => "TOWNSHIP ROAD",
      "TSR" => "TOWNSHIP ROAD",
      "US HIGHWAY" => "US HIGHWAY",
      "US" => "US HIGHWAY",
      "US HWY" => "US HIGHWAY",
      "USHWY" => "US HIGHWAY"
    }
  end

  def directions do
    %{
      "NORTH" => "N",
      "SOUTH" => "S",
      "EAST" => "E",
      "WEST" => "W",
      "NORTHEAST" => "NE",
      "NORTH EAST" => "NE",
      "NORTHWEST" => "NW",
      "NORTH WEST" => "NW",
      "SOUTHEAST" => "SE",
      "SOUTH EAST" => "SE",
      "SOUTHWEST" => "SW",
      "SOUTH WEST" => "SW"
    }
  end

  def reversed_directions do
    %{
      "N" => "NORTH",
      "S" => "SOUTH",
      "E" => "EAST",
      "W" => "WEST",
      "NE" => "NORTHEAST",
      "NW" => "NORTHWEST",
      "SE" => "SOUTHEAST",
      "SW" => "SOUTHWEST"
    }
  end
end
