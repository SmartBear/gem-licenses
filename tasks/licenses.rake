desc 'Gather open-source licenses.'
namespace :gem do
  task :licenses do
    Gem.licenses.sort_by { |k, v| [-v.count, k] }.each do |license, gems|
      puts license.to_s
      puts '=' * license.length
      gems.sort_by(&:name).each do |gem|
        puts "* #{gem.name} #{gem.version} (#{gem.homepage}) - #{gem.summary.strip}"
        puts gem.full_gem_path
      end
      puts ''
    end
  end

  namespace :licenses do
    task :csv, [:filename] do |_t, args|
      require 'csv'
      filename = File.expand_path(args[:filename], Dir.pwd)
      puts "Writing #{filename} ..."
      licenses = Gem.licenses
      total = 0
      CSV.open(filename, 'w') do |csv|
        csv << %w[name version license homepage summary]
        licenses.each do |license, gems|
          total += gems.count
          gems.sort_by(&:name).each do |gem|
            csv << [gem.name, gem.version, license, gem.homepage, gem.summary.strip]
          end
        end
      end
      puts "Written #{licenses.keys.count} license(s) for #{total} project(s): #{licenses.keys.join(', ')}"

      if licenses.key?('unknown')
        puts "IMPORTANT: You have #{licenses['unknown'].count} projects without a guessable license!"
        licenses['unknown'].each do |gem|
          puts "  #{gem.name}: #{gem.full_gem_path}"
        end
      end
    end

    namespace :copyrights do
      task :csv, [:filename] do |_t, args|
        string_filename = args[:filename]
        if(string_filename.blank?)
          string_filename = "licenses.csv"
          puts "No filename,  #{string_filename} was used by default"
        end
        require 'csv'
        filename = File.expand_path(string_filename, Dir.pwd)
        puts "Writing #{filename} ..."
        licenses, copyrights = Gem.licenses_and_copyright
        total = 0
        license_unknown = []
        copyright_unknown = []
        total_license_not_found=0
        total_copyright_not_found=0
        CSV.open(filename, 'w') do |csv|
          csv << %w[Library Name Version License Copyright Homepage]
          Gem.loaded_specs.each_value do |gem|
            total += licenses[gem.name].length
            if(licenses[gem.name]==nil || licenses[gem.name].join(', ').empty?)
              licenses[gem.name] = ['unknown']
            end
            if(copyrights[gem.name]==nil || copyrights[gem.name].join(', ').empty?)
              copyrights[gem.name] = ['unknown']
            end
            library = gem.name.to_s + '-' + gem.version.to_s
            csv << [library, gem.name, gem.version, licenses[gem.name].join(' | '), copyrights[gem.name].join(' | '), gem.homepage]
            if licenses[gem.name].include?('unknown')
              license_unknown << "IMPORTANT License is missing: The GEM #{gem.name} has an unknown license: #{gem.full_gem_path}"
              total_license_not_found += 1
            end
            if copyrights[gem.name].include?('unknown')
              copyright_unknown << "IMPORTANT Copyright is missing: The GEM #{gem.name} has no copyright: #{gem.full_gem_path}"
              total_copyright_not_found += 1
            end
          end
        end
        puts "Written #{total} license(s) for #{licenses.keys.count} project(s)"
        print "\n"
        puts "Written #{total_license_not_found} license(s) not found"
        license_unknown.each { |license| puts license }
        print "\n"
        puts "Written #{total_copyright_not_found} copyright(s) not found"
        copyright_unknown.each { |copyright| puts copyright }
      end
    end
  end
end
