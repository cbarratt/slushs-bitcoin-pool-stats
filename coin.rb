#!/usr/bin/env ruby

require 'rubygems'
require 'json'
require 'net/http'
require 'ostruct'
require 'terminal-table'
require 'pry'

# Should go in a conf.yml file or set and ENV var. Not a hard coded constant
API_TOKEN = ''

module SlushsPool
  class API

    # Setup attributes
    attr_reader :api_key, :base_url, :data

    # Accepts the API key and gets the data
    def initialize(api_key)
      @api_key = api_key
      @base_url = 'https://mining.bitcoin.cz/accounts/profile/json/'

      # GET the API data. Store in the object instance
      url   = "#{@base_url}#{@api_key}"
      res   = Net::HTTP.get_response(URI.parse(url))
      body  = res.body
      @data = JSON.parse(body)

      return self
    end

    def workers
      @data['workers']
    end

    def username
      @data['username']
    end

    def wallet_address
      @data['wallet']
    end

    def confirmed_reward
      @data['confirmed_reward']
    end

    def unconfirmed_reward
      @data['unconfirmed_reward']
    end

    def workers_running?
      workers.each do |worker|
        if worker[1]['alive'] == false
          puts "#{worker[0]} is dead."
        else
          puts "#{worker[0]} is running."
        end
      end
    end

    def total_of(requested)
      value = 0

      workers.each do |worker|
        value += worker[1]["#{requested}"].to_i
      end

      return value
    end
  end
end

pool = SlushsPool::API.new(API_TOKEN)

rows = pool.workers.map do |worker|
  [worker[0], worker[1]['hashrate'], worker[1]['shares'], worker[1]['score'], Time.at(worker[1]['last_share']).strftime('%l:%M:%S %p / %d-%m-%Y'), worker[1]['alive'].to_s]
end

rows << :separator
rows << ['Totals', pool.total_of('hashrate'), pool.total_of('shares'), pool.total_of('score'), '', '']

worker_table = Terminal::Table.new headings: ['Worker', 'Hashrate', 'Current Shares', 'Score', 'Last Share' ,'Running?'], rows: rows, style: { width: 140 }

puts Time.now
puts "Username: " + pool.username
puts "Wallet Address: " + pool.wallet_address
puts "Unconfirmed reward: " + pool.unconfirmed_reward
puts "Confirmed reward: " + pool.confirmed_reward
puts "Number of workers: " + pool.workers.count.to_s
puts worker_table