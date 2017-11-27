# -*- coding: utf-8 -*-
module CeDict
  WORDS = {}
  IO.readlines(File.join(File.dirname(__FILE__), 'cedict.txt')).each { |w|
    w =~ /([^0-9]*)([0-9]*)/
    tone_numbers = $2.chars.map { |s| s.to_i }.to_a
    WORDS[$1] = if WORDS.has_key?($1) && WORDS[$1] != tone_numbers
                  [0] * tone_numbers.length
                else
                  tone_numbers
                end
  }

  def self.is_in_mdbg_word_dictionary(word)
    WORDS.has_key? word
  end

  # Returns an array of tone numbers 0 (for unknown) to 5 (for neutral).
  # phrase can be a string or an enumeration of characters
  def self.tones(phrase)
    case phrase.to_s
    when ''
      return []
    when /(.*)( *[;；＝=] *)(.*)/
      return tones($1) + [0] * $2.chars.to_a.length + tones($3)
    when /(.*)[(（](.+)[)）](.*)/
      len1, len2, len3 = [$1, $2, $3].map { |field| field.chars.to_a.length }
      t = tones $1 + $2 + $3
      return t[0, len1] + [0] + t[len1, len2] + [0] + t[len1+len2, len3]
    end
    chars = phrase.to_s.chars.to_a
    length = chars.size
    hit = WORDS[phrase.to_s]
    if hit
      hit
    elsif length == 1
      [0]
    else
      longest = (length-1).downto(2).find { |len|
        WORDS[chars.first(len).to_s]
      } || 1
      tones(chars.first(longest)) + tones(chars.last(length - longest))
    end
  end
end
