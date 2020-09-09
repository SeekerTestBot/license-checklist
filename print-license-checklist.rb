require "utils/spdx"

TAP = "homebrew/core"

# default: false, set to true to only print formulae missing a license, without links
SIMPLE_LIST = ARGV.include?("simple_list")

# default: true, set to true to print number of formulae with license
PRINT_TOTAL = !ARGV.include?("no_print_total")

# default: true
PRINT_LIST = !ARGV.include?("no_print_list")

# default: true, set to false to print all formulae as a single list
PRINT_SECTIONS = !ARGV.include?("no_print_sections")

# default: "closed", possible values: "open" | "closed" | "headings"
SPOILER_TYPE = case
when ARGV.include?("open_spoiler") then "open"
when ARGV.include?("headings") then "headings"
else "closed"
end

# default: true
INCLUDE_LINKS = !ARGV.include?("no_include_links")

# default: false, set to false to include links only for formulae missing a license
INCLUDE_LINKS_FOR_ALL = ARGV.include?("include_links_for_all")

total_count = 0
licensed_count = 0
valid_count = 0

current_letter = nil

formulae = Tap.fetch(TAP).formula_files.map(&Formulary.method(:factory)).sort

formulae.each { |formula|
  next if formula.tap.name != TAP
  total_count += 1
  if formula.license
    licensed_count += 1
    licenses, = SPDX.parse_license_expression(formula.license)
    deprecated_licenses = licenses.filter { |license| SPDX.deprecated_license?(license) }
    valid_count += 1 if deprecated_licenses.empty?
  end
}

if PRINT_TOTAL
  deprecated_count = licensed_count - valid_count
  valid_percent = valid_count.to_f / total_count.to_f * 100.0
  deprecated_percent = deprecated_count.to_f / total_count.to_f * 100.0
  puts "#{valid_count} / #{total_count} (#{valid_percent.round(1)}%) of formulae have a valid `license` stanza as of #{Time.now.utc}."
  puts
  puts "#{deprecated_count} / #{total_count} (#{deprecated_percent.round(1)}%) contain a deprecated license (usually `GPL-2.0` or `GPL-3.0`)."
end

return unless PRINT_LIST

def optional_link(text, url)
  url ? "[#{text}](#{url})" : text
end

formulae.each { |formula|
  next if formula.tap.name != TAP

  license_val = formula.license
  name = formula.name
  first_letter = name[0].upcase
  homepage = formula.homepage
  head = formula.head&.url
  stable = formula.stable&.url
  formula_link = "https://github.com/Homebrew/homebrew-core/blob/master/Formula/#{name}.rb"
  licenses, = license_val ? SPDX.parse_license_expression(license_val) : []
  deprecated_licenses = licenses ? licenses.filter { |license| SPDX.deprecated_license?(license) } : []

  if SIMPLE_LIST
    next if license_val && deprecated_licenses.empty?
    puts name
    next
  end

  if first_letter != current_letter
    if current_letter && SPOILER_TYPE != "headings"
      puts
      puts "</details>"
    end
    if PRINT_SECTIONS
      puts
      if SPOILER_TYPE != "headings"
        puts "<details#{" #{SPOILER_TYPE}" if SPOILER_TYPE == "open"}><summary>#{first_letter}</summary>"
      else
        puts "### #{first_letter}"
      end
      puts
    end
    current_letter = first_letter
  end
  checkmark = license_val && deprecated_licenses.empty? ? "x" : " "
  description = name
  description += ": #{license_val}" if license_val
  description += " (deprecated)" if deprecated_licenses.present?
  if INCLUDE_LINKS && (!license_val || deprecated_licenses.present? || INCLUDE_LINKS_FOR_ALL)
    description += " [#{optional_link("homepage", homepage)}]"
    description += " [#{optional_link("head", head)}]"
    description += " [#{optional_link("stable", stable)}]"
    description += " [#{optional_link("formula", formula_link)}]"
  end
  puts "- [#{checkmark}] #{description}"
}

if current_letter && SPOILER_TYPE != "headings" && PRINT_LIST
  puts
  puts "</details>"
end
