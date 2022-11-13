#!/usr/bin/env ruby
# frozen_string_literal: true

require 'wan-ip-gen'
require 'multiprocess-threads'
require 'socket'

wan = IP::RandomWAN.new

mp = MPThreads::Parallel.new do |ip|
  puts ip
end

REQ_TPL = <<~REQUEST.gsub("\n", "\r\n")
  GET /wp-content/uploads/ HTTP/1.1
  Host: %s
  User-Agent: Mozilla/5.0
  Connection: close

REQUEST

mp.work(1024) do
  wan.each do |ip|
    Socket.tcp(ip, 80, connect_timeout: 0.75) do |s|
      s << REQ_TPL % ip
      write("http://#{ip}/wp-content/uploads/") if s.recv(1024) =~ /Index of/
    end
  rescue Errno::ETIMEDOUT, Errno::EHOSTUNREACH, Errno::ECONNREFUSED, Errno::ENETUNREACH, Errno::ECONNRESET, Errno::ENOPROTOOPT
    next
  end
end
