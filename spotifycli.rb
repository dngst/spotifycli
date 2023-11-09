#!/usr/bin/env ruby

require 'thor'
require 'httparty'
require 'dotenv/load'

class SpotifyCLI < Thor
  package_name 'SpotifyCLI'
  desc 'discover', 'List new album releases on Spotify'
  method_option :country, aliases: '-c', desc: 'Country code (e.g., US)', default: 'US'
  method_option :limit, aliases: '-l', desc: 'Limit the number of releases', default: '50'
  method_option :offset, aliases: '-o', desc: 'Offset for pagination', default: '0'

  def discover
    access_token = fetch_access_token

    country = options[:country].upcase
    limit = options[:limit].to_i
    offset = options[:offset].to_i

    new_releases_url = 'https://api.spotify.com/v1/browse/new-releases'

    params = { country: country, limit: limit, offset: offset }
    headers = { Authorization: "Bearer #{access_token}" }

    response = HTTParty.get(new_releases_url, params: params, headers: headers)
    handle_response(response)
  end

  private

  def fetch_access_token
    client_id = ENV.fetch('CLIENT_ID', nil)
    client_secret = ENV.fetch('CLIENT_SECRET', nil)

    token_url = 'https://accounts.spotify.com/api/token'

    headers = { Authorization: "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}" }

    data = { grant_type: 'client_credentials' }

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
    new_releases.each_with_index do |release, index|
      project_type = release['album_type'].capitalize
      release_date = DateTime.parse(release['release_date']).strftime('%a, %d %b %Y')
      next unless project_type == 'Album'

      puts "#{index + 1}. #{release['name']}"
      puts "    Artists: #{release['artists'].map { |artist| artist['name'] }.join(', ')}"
      puts "    Tracks: #{release['total_tracks']}"
      puts "    Released: #{release_date}"
      puts "    #{project_type}: #{release['external_urls']['spotify']}"
      puts "\n#{'-' * 60}\n"
    end
  end
end

SpotifyCLI.start(ARGV)
