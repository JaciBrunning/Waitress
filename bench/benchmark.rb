$LOAD_PATH.unshift File.expand_path( File.dirname(__FILE__) + '/../lib' )
require 'benchmark'
require 'io/console'
require 'scon'

BENCH = []

def defbench name, iterations=100, &block
  BENCH << { :n => name, :i => iterations, :c => block }
end

# Do loading
require 'waitress'
require_relative 'bench_querystring'
require_relative 'bench_response'

@width = 80
@width = IO.console.winsize[1] rescue nil
puts "All Benchmark Results are Averages and in Milliseconds"

@results = {}
@loaded = {}
@loaded = SCON.parse!(File.read("__bench_last.scon")) if File.exist?("__bench_last.scon")

RED = "\033[31m"
GREEN = "\033[32m"
YEL = "\033[33m"
NORM = "\033[0m"

BENCH.each do |b|
  puts "Starting Benchmark: #{b[:n]} (Running #{b[:i]} times)"

  meas = []
  bl = (b[:c])
  bl.call(:start)

  b[:i].times do
    meas << Benchmark.measure(&bl)
  end

  bl.call(:stop)

  res = {
    "cpusys" => 0,
    "cpuusr" => 0,
    "cpucsys" => 0,
    "cpucusr" => 0,
    "cputotal" => 0,
    "realtime" => 0
  }
  meas.each do |x|
    res['realtime'] += x.real
    res['cpucsys'] += x.cstime
    res['cpucusr'] += x.cutime
    res['cpusys'] += x.stime
    res['cpuusr'] += x.utime
    res['cputotal'] += x.total
  end

  # real, cs, cu, s, u, t = [real, cs, cu, s, u, t].map { |x| (x.to_f / b[:i]) * 1000 }
  res.each { |key, val| res[key] = (val.to_f / b[:i]) * 1000 }

  @results[b[:n]] = res
  loaded = @loaded[b[:n]]

  @delta = {}
  res.each do |nm, val|
    unless loaded.nil?
      unless loaded[nm] == 0
        d = ((val.to_f / loaded[nm]) - 1).round(2)
        @delta[nm] = d
      else
        @delta[nm] = 0
      end
    else
      @delta[nm] = 0
    end
  end

  pr = lambda do |statement, key|
    d = @delta[key]
    col = d == 0 ? YEL : d > 0 ? RED : GREEN
    i = "(#{d > 0 ? d : -d}x #{d > 0 ? "slower" : "faster"})"
    puts "\t#{col}#{statement} #{res[key].round(5)} #{d != 0 ? i : ""}#{NORM}"
  end

  puts "=== Results for Benchmark: #{b[:n]} (#{b[:i]} iterations) ".ljust(@width, "=")
  pr.call "CPU Time (sys):\t\t", "cpusys"
  pr.call "CPU Time (usr):\t\t", "cpuusr"
  pr.call "CPU Time (child-sys):\t", "cpucsys"
  pr.call "CPU Time (child-usr):\t", "cpucusr"
  puts
  pr.call "CPU Time (total):\t", "cputotal"
  pr.call "Real Time Elapsed:\t", "realtime"
  puts "".ljust(@width, "=")
  puts ""
end

File.write("__bench_last.scon", SCON.generate!(@results))
