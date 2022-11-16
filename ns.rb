#!/usr/bin/env ruby
# frozen_string_literal: true

require 'wan-ip-gen'
require 'multiprocess-threads'
require 'socket'
require 'timeout'

URL = '/wp-content/uploads/'

WAN = IP::RandomWAN.new

REQ_TPL = <<~REQUEST.gsub("\n", "\r\n")
  GET #{URL} HTTP/1.1
  Host: %s
  User-Agent: Mozilla/5.0
  Connection: close

REQUEST

parallel = MPThreads::Parallel.new(&method(:puts))

parallel.work(1024) do
  WAN.each_socket do |s, ip|
    Timeout.timeout(15) do
      s << REQ_TPL % ip
      write("http://#{ip}#{URL}") if s.recv(1024) =~ /Index of/
    end
  rescue SystemCallError, Timeout::Error
    next
  end
end
