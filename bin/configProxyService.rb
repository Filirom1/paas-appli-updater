#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'

Daemons.run(File.expand_path("../configProxy.rb", __FILE__))
