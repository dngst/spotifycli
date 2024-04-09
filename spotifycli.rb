#!/usr/bin/env ruby
# frozen_string_literal: true

require 'thor'
require 'httparty'

class SpotifyCLI < Thor
  include HTTParty
  base_uri 'https://api.spotify.com/v1'
  package_name 'SpotifyCLI'

  desc 'new', 'List new album releases'
  method_option :country, aliases: '-c', desc: 'Country code (e.g., US)', default: 'US'
  method_option :limit, aliases: '-l', desc: 'Limit the number of releases', type: :numeric, default: 50
  method_option :offset, aliases: '-o', desc: 'Offset for pagination', type: :numeric, default: 0
  def new
    country = options[:country].upcase
    limit = options[:limit]
    offset = options[:offset]
    url = '/browse/new-releases'
    params = { country: country, limit: limit, offset: offset }
    headers = { Authorization: "Bearer #{access_token}" }
    response = self.class.get("#{url}?#{URI.encode_www_form(params)}", headers: headers)
    handle_response(response)
  rescue SocketError
    handle_socket_error
  end

  desc 'year', 'Search for albums by year'
  method_option :country, aliases: '-c', desc: 'Country code (e.g., US)', default: 'US'
  method_option :limit, aliases: '-l', desc: 'Limit the number of releases', type: :numeric, default: 50
  method_option :offset, aliases: '-o', desc: 'Offset for pagination', type: :numeric, default: 0
  method_option :year, aliases: '-y', desc: 'Album release year', type: :numeric, default: Time.now.year
  def year
    year = options[:year]
    search_url = '/search'
    params = { q: "year:#{year}", type: 'album', limit: options[:limit], offset: options[:offset] }
    headers = { Authorization: "Bearer #{access_token}" }
    response = self.class.get("#{search_url}?#{URI.encode_www_form(params)}", headers: headers)
    handle_response(response)
  rescue SocketError
    handle_socket_error
  end

  desc 'feat', 'List featured playlists'
  method_option :country, aliases: '-c', desc: 'Country code (e.g., US)', default: 'US'
  method_option :limit, aliases: '-l', desc: 'Limit the number of playlists', type: :numeric, default: 50
  method_option :offset, aliases: '-o', desc: 'Offset for pagination', type: :numeric, default: 0
  def featured
    country = options[:country].upcase
    limit = options[:limit]
    offset = options[:offset]
    url = '/browse/featured-playlists'
    params = { country: country, limit: limit, offset: offset }
    headers = { Authorization: "Bearer #{access_token}" }
    response = self.class.get("#{url}?#{URI.encode_www_form(params)}", headers: headers)
    handle_response(response)
  rescue SocketError
    handle_socket_error
  end

  desc 'cat', 'List playlists by category'
  # sleep, focus, workout, party, chill, dinner, toplists, romance, wellness, anime, gaming,
  # classical, soul, ambient, travel, 80s, 90s, 00s, 10s, decades, inspirational, songwriters etc.
  method_option :locale, aliases: '-c', desc: 'Country code (e.g., sv_SE)', default: 'en_US'
  method_option :category, aliases: '-t', desc: 'Category', default: 'mood'
  def cat
    locale = options[:locale]
    category_id = options[:category]
    url = "/browse/categories/#{category_id}/playlists"
    params = { locale: locale }
    headers = { Authorization: "Bearer #{access_token}" }
    response = self.class.get("#{url}?#{URI.encode_www_form(params)}", headers: headers)
    handle_response(response)
  rescue SocketError
    handle_socket_error
  end

  desc 'pack', 'Update SpotifyCLI with local changes'
  def pack
    run_command('rm spotifycli')
    run_command('sudo rm /usr/local/bin/spotifycli')
    run_command('cp spotifycli.rb spotifycli')
    run_command('sudo cp spotifycli /usr/local/bin/spotifycli')
    say 'SpotifyCLI updated!', :green
  end

  private

  def run_command(command)
    result = system(command)
    return if result

    raise Thor::Error, "Command failed: #{command}"
  end

  def access_token
    client_id = ENV.fetch('SPOTIFY_CLIENT_ID', nil)
    client_secret = ENV.fetch('SPOTIFY_CLIENT_SECRET', nil)
    url = 'https://accounts.spotify.com/api/token'
    data = { grant_type: 'client_credentials' }
    headers = { Authorization: "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}" }
    response = self.class.post(url, { body: data, headers: headers })
    token_data = JSON.parse(response.body)
    token_data['access_token']
  end

  def handle_socket_error
    say 'Check your network connection and try again', :red
  end

  def handle_response(response)
    if response.code == 200
      response_body = JSON.parse(response.body)
      if response_body['albums']
        display_new_releases(response_body['albums']['items'])
      elsif response_body['playlists']
        display_playlists(response_body['playlists']['items'])
      else
        puts 'Error: Invalid response format'
      end
    else
      puts "Error retrieving response: #{response.code}, #{response.body}"
    end
  end

  def display_new_releases(new_releases)
    new_releases.each do |release|
      project_type = release['album_type'].capitalize
      release_date = release['release_date']
      formatted_date = if release_date.match?(/^\d{4}-\d{2}-\d{2}$/)
                         DateTime.parse(release_date).strftime('%d %b, %Y')
                       else
                         release_date
                       end

      next unless project_type != 'Single'

      puts "(#{formatted_date})"
      say "    #{release['name']}", :cyan
      puts "    Artists: #{release['artists'].map { |artist| artist['name'] }.join(', ')}"
      puts "    Tracks: #{release['total_tracks']}"
      puts "    #{project_type}: #{release['external_urls']['spotify']}"
      puts "\n#{'-' * 65}\n"
    end
  end

  def display_playlists(playlists)
    playlists.each do |playlist|
      say playlist['name'], :cyan
      puts ' '
      description = playlist['description'].gsub(/<.*?>/, '')
      puts "  #{description}"
      say "  Tracks: #{playlist['tracks']['total']}", :yellow
      puts "  #{playlist['type'].capitalize}: #{playlist['external_urls']['spotify']}"
      puts "\n#{'-' * 65}\n"
    end
  end

  def exit_on_failure?
    false
  end
end

SpotifyCLI.start(ARGV)
