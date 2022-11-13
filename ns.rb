#!/usr/bin/env ruby
# frozen_string_literal: true

require 'wan-ip-gen'
require 'multiprocess-threads'
require 'socket'

wan = IP::RandomWAN.new

mp = MPThreads::Parallel.new do |ip|
  puts ip
end

mp.work(1024) do
  wan.each do |ip|
    Socket.tcp(ip, 80, connect_timeout: 0.75) do |s|
      s << <<~REQUEST
        GET /wp-content/uploads/ HTTP/1.1\r
        Host: #{ip}\r
        User-Agent: Mozilla/5.0\r
        Connection: close\r\n\r\n
      REQUEST
      write("http://#{ip}/wp-content/uploads/") if s.recv(1024) =~ /Index of/
    end
  rescue Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ENETUNREACH, Errno::ECONNRESET
    next
  end
end
