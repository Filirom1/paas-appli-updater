#!/usr/bin/env ruby

require 'daemons'

Daemons.run(File.expand_path("../configProxy.rb", __FILE__))
