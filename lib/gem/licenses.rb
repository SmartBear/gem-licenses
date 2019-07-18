module Gem
  def self.licenses
    licenses = {}
    config_path = File.expand_path('../../licenses/config.yml', __FILE__)
    config = YAML.safe_load(File.read(config_path))
    Gem.loaded_specs.each_value do |spec|
      spec.licenses.map(&:downcase).each do |license|
        license_name = config[license] || license
        licenses[license_name] ||= []
        licenses[license_name] << spec
      end
    end
    licenses
  end

  def self.licenses_and_copyright
    licenses = {}
    copyrights = {}
    config_path = File.expand_path('../../licenses/config.yml', __FILE__)
    config = YAML.safe_load(File.read(config_path))
    Gem.loaded_specs.each_value do |spec|
      licenses_received, copyrights_received = spec.licenses_and_copyright
      licenses_received.each do |license|
        license_name = config[license] || license
        licenses[spec.name] ||= []
        licenses[spec.name] << license_name
      end
      copyrights_received.each do |copyright|
        copyrights[spec.name] ||= []
        copyrights[spec.name] << copyright
      end
    end
    return licenses, copyrights
  end
end
