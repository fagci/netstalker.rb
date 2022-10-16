#!/usr/bin/env ruby
# frozen_string_literal: true

require 'wan-ip-gen'
require 'multiprocess-threads'
require 'socket'

wan = IP::RandomWAN.new

mp = MPThreads::Parallel.new do |ip|
  puts ip
end

mp.work(256) do
  wan.each do |ip|
    Socket.tcp(ip, 80, connect_timeout: 0.75) do |_s|
      write ip
    end
  rescue Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ENETUNREACH => e
    next
  end
end
