#!/usr/bin/env ruby

require 'thor'
require 'httparty'

class SpotifyCLI < Thor
  package_name 'SpotifyCLI'
  desc 'new', 'List new album releases'
  method_option :country, aliases: '-c', desc: 'Country code (e.g., US)', default: 'US'
  method_option :limit, aliases: '-l', desc: 'Limit the number of releases', type: :numeric, default: 50
  method_option :offset, aliases: '-o', desc: 'Offset for pagination', type: :numeric, default: 0

  def new
    access_token = fetch_access_token

    country = options[:country].upcase
    limit = options[:limit]
    offset = options[:offset]

    new_releases_url = 'https://api.spotify.com/v1/browse/new-releases'

    params = { country: country, limit: limit, offset: offset }
    headers = { Authorization: "Bearer #{access_token}" }

    response = HTTParty.get("#{new_releases_url}?#{URI.encode_www_form(params)}", headers: headers)
    handle_response(response)
  end

  desc 'update', 'Update SpotifyCLI with local changes'
  def update
    run_command('rm spotifycli')
    run_command('sudo rm /usr/local/bin/spotifycli')
    run_command('cp spotifycli.rb spotifycli')
    run_command('sudo cp spotifycli /usr/local/bin/spotifycli')

    puts 'SpotifyCLI updated!'
  end

  private

  def run_command(command)
    result = system(command)

    unless result
      raise Thor::Error,"Command failed: #{command}"
    end
  end

  def fetch_access_token
    client_id = ENV.fetch('CLIENT_ID', nil)
    client_secret = ENV.fetch('CLIENT_SECRET', nil)

    token_url = 'https://accounts.spotify.com/api/token'
    data = { grant_type: 'client_credentials' }
    headers = { Authorization: "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}" }

    response = HTTParty.post(token_url, { body: data, headers: headers })
    token_data = JSON.parse(response.body)

    return token_data['access_token'] if token_data['access_token']

    puts 'Error obtaining access token:', token_data
  end

  def handle_response(response)
    if response.code == 200
      new_releases = JSON.parse(response.body)['albums']['items']
      display_new_releases(new_releases)
    else
      puts "Error retrieving new releases: #{response.code}, #{response.body}"
    end
  end

  def display_new_releases(new_releases)
    new_releases.each do |release|
      project_type = release['album_type'].capitalize
      release_date = DateTime.parse(release['release_date']).strftime('%d %b, %y')
      next unless project_type == 'Album'

      puts "(#{release_date})"
      puts "    #{release['name']}"
      puts "    Artists: #{release['artists'].map { |artist| artist['name'] }.join(', ')}"
      puts "    Tracks: #{release['total_tracks']}"
      puts "    #{project_type}: #{release['external_urls']['spotify']}"
      puts "\n#{'-' * 65}\n"
    end
  end

  def self.exit_on_failure?
    false
  end
end

SpotifyCLI.start(ARGV)
