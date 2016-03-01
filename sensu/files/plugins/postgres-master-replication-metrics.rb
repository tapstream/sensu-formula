#!/usr/bin/env ruby
#
# Postgres Connection Metrics
# ===
#
# Dependencies
# -----------
# - Ruby gem `pg`
#
#
# Copyright 2012 Kwarter, Inc <platforms@kwarter.com>
# Author Gilles Devaux <gilles.devaux@gmail.com>
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/metric/cli'
require 'pg'
require 'socket'

class PostgresMasterReplicationLagMetrics < Sensu::Plugin::Metric::CLI::Graphite
  option :user,
         description: 'Postgres User',
         short: '-u USER',
         long: '--user USER'

  option :password,
         description: 'Postgres Password',
         short: '-p PASS',
         long: '--password PASS'

  option :hostname,
         description: 'Hostname to login to',
         short: '-h HOST',
         long: '--hostname HOST',
         default: 'localhost'

  option :port,
         description: 'Database port',
         short: '-P PORT',
         long: '--port PORT',
         default: 5432

  option :scheme,
         description: 'Metric naming scheme, text to prepend to $queue_name.$metric',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.postgresql"

  def run
    timestamp = Time.now.to_i

    pg_clients = Hash.new(0)

    con     = PG::Connection.new(config[:hostname], config[:port], nil, nil, 'postgres', config[:user], config[:password])
    request = [
      'select client_hostname, pg_xlog_location_diff(pg_current_xlog_location(), pg_stat_replication.replay_location) from pg_stat_replication'
    ]

    con.exec(request.join(' ')) do |result|
      result.each do |row|
        pg_client_hostname = row['client_hostname'].gsub(/\./, '_')
        pg_clients[pg_client_hostname] = row['pg_xlog_location_diff']
      end
    end

    pg_clients.each do |metric, value|
      output "#{config[:scheme]}.replication_lag.#{metric}", value, timestamp
    end

    ok
  end
end