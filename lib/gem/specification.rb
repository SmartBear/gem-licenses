module Gem
  class Specification
    alias __licenses licenses

    LICENSE_REFERENCES = [
      /released under the (?<l>[\s\w]*) license/i,
      /same license as (?<l>[\s\w]*)/i,
      /^(?<l>[\s\w]*) License, see/i,
      /^(?<l>[\w]*) license$/i,
      /\(the (?<l>[\s\w]*) license\)/i,
      /^license: (?<l>[\s\w]*)/i,
      /^released under the (?<l>[\s\w]*) license/i,
      /Licensed under the (?<l>[\s\w]*) [L|l]icense/i,
      /license: (?<l>[\s\w]*)$/i,
      /^same as (?<l>[\s\w]*)/i,
      /license of (?<l>[\s\w]*)/i
    ].freeze

    COPYRIGHT_REFERENCES = [
      /^Copyright\s(?!(notice|owner|license|of|HOLDERS|holder|on|\[|\{|\([C|c]\)))(?<l>(.*))/i,
      /^Copyright\s\([C|c]\)\s(?<l>(.*))/i
    ].freeze

    def licenses
      ary = (__licenses || []).keep_if { |l| !l.empty? }
      ary.empty? ? guess_licenses : ary
    end

    def licenses_and_copyright
      ary = (__licenses || []).keep_if { |l| !l.empty? }
      licenses,copyright = guess_licenses_and_copyrights
      if (ary.empty?)
        return licenses,copyright
      else
        return ary,copyright
      end
    end

    def guess_licenses_and_copyrights
      licenses = []
      copyrights = []
      Dir.entries(full_gem_path).each do |filename|
        case File.basename(filename, File.extname(filename)).downcase
        when /license/
          parts = filename.split('-')
          if(parts.length >= 2 && parts[1] == "license")
            licenses << [parts[0].upcase]
          end
          temp, copyrights = guess_licenses_and_copyrights_from_file File.join(full_gem_path, filename)
          temp ||= []
          licenses.concat(temp)
        when /copying|readme/
          temp_licenses, temp_copyrights = guess_licenses_and_copyrights_from_file File.join(full_gem_path, filename)
          temp_licenses ||= []
          temp_copyrights ||= []
          licenses.concat(temp_licenses)
          copyrights.concat(temp_copyrights)
        end
      end
      licenses << 'unknown' if licenses.empty?
      copyrights << 'unknown' if copyrights.empty?
      return licenses.uniq, copyrights.uniq
    rescue Errno::ENOENT
      return licenses.uniq, copyrights.uniq
    end

    def guess_licenses
      licenses = []
      Dir.foreach(full_gem_path) do |filename|
        case File.basename(filename, File.extname(filename)).downcase
        when /license/
          parts = filename.split('-')
          return [parts[0].upcase] if parts.length >= 2
          licenses = guess_licenses_from_file File.join(full_gem_path, filename)
        when /copying|readme/
          licenses = guess_licenses_from_file File.join(full_gem_path, filename)
        end
        break unless licenses.empty?
      end
      licenses << 'unknown' if licenses.empty?
      licenses.uniq
    rescue Errno::ENOENT
      # TODO: warning
      []
    end

    def self.common_licenses
      @common_licenses ||= Hash[
        Dir.glob(File.expand_path('../../../common_licenses/*', __FILE__)).map do |f|
          [File.basename(f), normalize_text(File.read(f))]
        end
      ]
    end

    def self.normalize_text(text)
      text.downcase.to_s.gsub(/[[:space:]]+/, ' ').gsub(/[[:punct:]]/, '').strip
    rescue ArgumentError
      nil
    end

    private

    def guess_licenses_and_copyrights_from_file(path)
      licenses, copyright = guess_licenses_and_copyrights_from_reference(path)
      return licenses, copyright if licenses.any?
      licenses = guess_licenses_from_contents(path)
      return licenses, copyright
    end

    def guess_licenses_from_file(path)
      licenses = guess_licenses_from_reference(path)
      return licenses if licenses.any?
      guess_licenses_from_contents(path)
    end

    def guess_licenses_and_copyrights_from_reference(path)
      file_handle = File.new(path, 'r')
      begin
        licenses = []
        copyright = []
        while (line = file_handle.gets)
          line = line.strip
          # positive matches
          LICENSE_REFERENCES.each do |r|
            res = r.match(line)
            licenses << res['l']if res
          end
          COPYRIGHT_REFERENCES.each do |r|
            res = r.match(line)
            copyright << res['l'] if res
          end
        end
        return licenses.uniq, copyright.uniq
      rescue StandardError
        # TODO: warning
      ensure
        file_handle.close
      end
      return [], []
    end

    def guess_licenses_from_reference(path)
      file_handle = File.new(path, 'r')
      begin
        while (line = file_handle.gets)
          line = line.strip
          # positive matches
          LICENSE_REFERENCES.each do |r|
            res = r.match(line)
            return [res['l']] if res
          end
        end
      rescue StandardError
        # TODO: warning
      ensure
        file_handle.close
      end
      []
    end

    def guess_licenses_from_contents(path)
      if (File.file?(path))
        File.open(path, 'r') do |file|
          contents = file.read
          match, = self.class.common_licenses.detect do |_key, lic|
            normalized = self.class.normalize_text(contents)
            normalized.include?(lic) if normalized
          end
          return [match].uniq.compact
        end
      end
    end
  end
end
