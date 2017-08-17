require 'date'
require 'net/http'
require 'sqlite3'

class WeatherReport

  LOCATIONS = [{"Chichester" => "http://www.chimet.co.uk/csg/chi.html"}, {"Camber" => "http://www.cambermet.co.uk/csg/cam.html"}, { "Bramble" => "http://www.bramblemet.co.uk/csg/bra.html" },{ "Southampton" => "http://www.sotonmet.co.uk/csg/sot.html"}]

  attr_reader :date, :location, :wind_mean, :wind_gust, :wind_direction, :tide_height, :wave_height_mean, :wave_height_max, :wave_period, :temp_air, :temp_sea, :pressure, :visibility

  def initialize(location, data)
    @location = location
    array = data.strip.split(',')
    @date = DateTime.parse("#{array[0]} #{array[1]} #{DateTime.now.strftime("%Z")}")
    @wind_mean = array[2]
    @wind_gust = array[3]
    @wind_direction = array[4]
    @tide_height = array[5]
    @wave_height_mean = array[6]
    @wave_height_max = array[7]
    @wave_period = array[8]
    @temp_air = array[9]
    @temp_sea = array[10]
    @pressure = array[11]
    @visibility = array[12]
  end

  def to_a
    return [@location, @date.to_s, @wind_mean, @wind_gust, @wind_direction, @tide_height, @wave_height_mean, @wave_height_max, @wave_period, @temp_air, @temp_sea, @pressure, @visibility]
  end

end

database = SQLite3::Database.new(File.expand_path("../data/solent_met.db", __FILE__))
database.execute("CREATE TABLE IF NOT EXISTS 'weather_reports' ( 'location' TEXT, 'date' TEXT, 'wind_mean' TEXT, 'wind_gust' TEXT, 'wind_direction' TEXT, 'tide_height' TEXT, 'wave_height_mean' TEXT, 'wave_height_max' TEXT, 'wave_period' TEXT, 'temp_air' TEXT, 'temp_sea' TEXT, 'pressure' TEXT, 'visibility' TEXT); ")
database.execute("CREATE UNIQUE INDEX IF NOT EXISTS 'location_date' ON 'weather_reports' ('location','date');")

reports = WeatherReport::LOCATIONS.collect { |location|  WeatherReport.new(location.keys[0], Net::HTTP.get_response(URI.parse(location.values[0])).body) }
reports.each { |report| database.execute "insert or ignore into weather_reports values ( ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", report.to_a }
