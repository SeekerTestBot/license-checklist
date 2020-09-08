TAP = ENV["TAP"] || "homebrew/core"

# default: false, set to true to only print formulae missing a license, without links
SIMPLE_LIST = ENV["SIMPLE_LIST"] || false

# default: true, set to true to print number of formulae with license
PRINT_TOTAL = ENV["PRINT_TOTAL"] || true

# default: true
PRINT_LIST = ENV["PRINT_LIST"] || true

# default: true, set to false to print all formulae as a single list
PRINT_SECTIONS = ENV["PRINT_SECTIONS"] || true

# default: "closed", possible values: "open" | "closed" | "headings"
SPOILER_TYPE = ENV["SPOILER_TYPE"] || "closed"

# default: true
INCLUDE_LINKS = ENV["INCLUDE_LINKS"] || true

# default: false, set to false to include links only for formulae missing a license
INCLUDE_LINKS_FOR_ALL = ENV["INCLUDE_LINKS_FOR_ALL"] || false

total = 0
licensed = 0

current_letter = nil

formulae = Formula.to_a.sort

formulae.each { |formula|
  next if formula.tap.name != TAP
  total += 1
  licensed += 1 if formula.license
}

if PRINT_TOTAL
  percent = licensed.to_f / total.to_f * 100.0
  puts "#{licensed} / #{total} (#{percent.round(1)}%) of formulae have a `license` stanza as of #{Time.now.utc}"
end

return unless PRINT_LIST

def optional_link(text, url)
  url ? "[#{text}](#{url})" : text
end

formulae.each { |formula|
  next if formula.tap.name != TAP

  license = formula.license
  name = formula.name
  first_letter = name[0].upcase
  homepage = formula.homepage
  head = formula.head&.url
  stable = formula.stable&.url
  formula_link = "https://github.com/Homebrew/homebrew-core/blob/master/Formula/#{name}.rb"

  if SIMPLE_LIST
    next if license
    puts "#{name} "
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
  checkmark = license ? "x" : " "
  description = name
  description += ": #{license}" if license
  if INCLUDE_LINKS && (!license || INCLUDE_LINKS_FOR_ALL)
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
